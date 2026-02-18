import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart' as csv;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/transaction.dart' as t_model;

import '../../presentation/providers/auth_providers.dart';

part 'import_service.g.dart';

/// Represents a transaction parsed from CSV, pending user confirmation.
class ImportedTransaction {
  final String id; // Temporary ID
  final DateTime date;
  final String dateString; // Original date string for matching
  final String concept;
  final double amount;
  String? categoryId; // Auto-matched or manually selected
  String? subCategoryId;
  bool selected;
  bool isDuplicate;

  ImportedTransaction({
    required this.id,
    required this.date,
    required this.dateString,
    required this.concept,
    required this.amount,
    this.categoryId,
    this.subCategoryId,
    this.selected = true,
    this.isDuplicate = false,
  });
}

class ImportService {
  final Ref ref;

  ImportService(this.ref);

  Future<List<ImportedTransaction>> pickAndParseCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true, // Needed for web/memory access
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final file = result.files.first;
    String csvContent;

    // Handle encoding (CaixaBank uses ISO-8859-1 often, or UTF-8)
    // We try UTF-8 first, fallback to Latin1
    try {
      if (file.bytes != null) {
        csvContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        throw Exception("No file content found");
      }
    } catch (e) {
      // Fallback for Latin1
      if (file.bytes != null) {
        csvContent = latin1.decode(file.bytes!);
      } else if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        csvContent = latin1.decode(bytes);
      } else {
        throw Exception("Failed to read file");
      }
    }

    // Parse CSV
    // Suggestion: specific to CaixaBank format
    // Row 1-3: Headers/Metadata
    // Row 4: Column Names
    // Row 5+: Data

    // Using default CsvDecoder (available in 7.1.0)
    final List<List<dynamic>> rows = const csv.CsvDecoder(
      fieldDelimiter: ';', // CaixaBank often uses ; but sometimes ,
    ).convert(csvContent);

    // If rows < 5, probably empty or wrong format
    // But let's be flexible. Find the header row.
    // 'D. Operació' is a key column.

    int dataStartIndex = -1;
    Map<String, int> headerMap = {};

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isNotEmpty) {
        // Find header row
        // Looking for 'D. Operació' or similar
        // Convert dynamic to string safely
        final rowStrings = row.map((e) => e.toString().trim()).toList();
        if (rowStrings.contains('D. Operació') ||
            rowStrings.contains('Fecha') ||
            rowStrings.contains('Date')) {
          // Found header
          for (int j = 0; j < rowStrings.length; j++) {
            headerMap[rowStrings[j]] = j;
          }
          dataStartIndex = i + 1;
          break;
        }
      }
    }

    if (dataStartIndex == -1) {
      // Fallback: try reading from row 0 if it looks like data?
      // Or throw error
      throw Exception('Format no reconegut (no s\'ha trobat la capçalera)');
    }

    final List<ImportedTransaction> imported = [];
    final dateFormat = DateFormat('dd/MM/yyyy'); // CaixaBank format

    // Existing transactions for duplicate check
    final existingTransactions = await _fetchExistingTransactions();

    for (int i = dataStartIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        // Extract fields
        // Date
        String dateStr = _getValue(row, headerMap, [
          'D. Operació',
          'Fecha',
          'Date',
        ]);
        DateTime date;
        try {
          date = dateFormat.parse(dateStr);
        } catch (_) {
          continue; // Skip invalid dates
        }

        // Concept
        // 'Concepte' + 'Concepte complementari 1' (optional)
        String concept = _getValue(row, headerMap, [
          'Concepte',
          'Concepto',
          'Concept',
        ]);
        String extraInfo = _getValue(row, headerMap, [
          'Concepte complementari 1',
          'Más información',
        ]);
        if (extraInfo.isNotEmpty) {
          concept += " $extraInfo";
        }
        concept = concept.trim();

        // Amount
        // 'Ingrés (+)' or 'Import' (signed) or 'Despesa (-)'
        // CaixaBank often has 'Ingrés (+)' (positive) and 'Despesa (-)' (positive number, implies negative)
        // Or single 'Import' column.

        double amount = 0.0;

        String amountIncomeStr = _getValue(row, headerMap, [
          'Ingrés (+)',
          'Ingresos',
          'Income',
        ]);
        String amountExpenseStr = _getValue(row, headerMap, [
          'Despesa (-)',
          'Gastos',
          'Expense',
        ]);
        String amountSingleStr = _getValue(row, headerMap, [
          'Import',
          'Importe',
          'Amount',
        ]); // Sometimes signed

        if (amountIncomeStr.isNotEmpty) {
          amount = _parseAmount(amountIncomeStr);
        } else if (amountExpenseStr.isNotEmpty) {
          amount = -_parseAmount(amountExpenseStr); // Make negative
        } else if (amountSingleStr.isNotEmpty) {
          amount = _parseAmount(amountSingleStr);
        }

        if (amount == 0.0) continue; // Skip zero/empty

        // Create object
        final transaction = ImportedTransaction(
          id: UniqueKey().toString(), // Temp ID
          date: date,
          dateString: dateStr,
          concept: concept,
          amount: amount,
          selected: true,
        );

        // Duplicate Check
        transaction.isDuplicate = _checkIsDuplicate(
          transaction,
          existingTransactions,
        );
        if (transaction.isDuplicate) {
          transaction.selected = false;
        }

        // Auto Categorize
        await _autoCategorize(transaction);

        imported.add(transaction);
      } catch (e) {
        debugPrint('Error parsing row $i: $e');
      }
    }

    // Sort by date desc
    imported.sort((a, b) => b.date.compareTo(a.date));

    return imported;
  }

  String _getValue(
    List<dynamic> row,
    Map<String, int> headerMap,
    List<String> possibleHeaders,
  ) {
    for (final h in possibleHeaders) {
      if (headerMap.containsKey(h) && headerMap[h]! < row.length) {
        final val = row[headerMap[h]!];
        return val?.toString().trim() ?? '';
      }
    }
    return '';
  }

  double _parseAmount(String str) {
    // Formats: '1.200,50' (ES) or '1,200.50' (US)
    // CaixaBank usually ES: '1.234,56' or simple '1234,56'
    if (str.isEmpty) return 0.0;

    // Remove currency symbol if any
    str = str.replaceAll('€', '').trim();

    // Handle ES format: remove dots (thousands), replace comma with dot
    if (str.contains(',') && str.indexOf('.') < str.indexOf(',')) {
      // likely 1.234,56
      str = str.replaceAll('.', '').replaceAll(',', '.');
    } else if (str.contains(',') && !str.contains('.')) {
      // likely 1234,56
      str = str.replaceAll(',', '.');
    }
    // Else assume standard float format

    return double.tryParse(str) ?? 0.0;
  }

  Future<List<t_model.Transaction>> _fetchExistingTransactions() async {
    final groupId = await ref.read(currentGroupIdProvider.future);

    // Optimization: Maybe only fetch last 3 months?
    // For now, fetch all or last N
    // repository.getAllTransactions(groupId) returns a Stream...
    // We need a snapshot.
    // In a real app we might query by date range of CSV, but we don't know it yet.
    // Let's assume we can fetch recent ones. Or all if not too many.
    // For simplicity/robustness, let's look at the stream provider or just use repo.

    try {
      // We can't easily wait for stream here without subscription.
      // Just one-off query for last 1000?
      // Or filtering in memory.
      // Let's do a direct Firestore query if possible, or use existing provider data if available.
      // Accessing the repository directly:

      // Using `ref.read` on the provider might give us the current async value if loaded.
      // But better:
      // We will just fetch last 300 transactions for duplicate checking.
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(300)
          .get();

      return snapshot.docs
          .map((d) => t_model.Transaction.fromFirestore(d))
          .toList();
    } catch (e) {
      debugPrint('Error fetching existing: $e');
      return [];
    }
  }

  bool _checkIsDuplicate(
    ImportedTransaction newTx,
    List<t_model.Transaction> existing,
  ) {
    const dayWindow = 2; // Allow +/- days difference

    for (final old in existing) {
      if (old.amount == newTx.amount) {
        // Date check with window
        final diff = old.date.difference(newTx.date).inDays.abs();
        if (diff <= dayWindow) {
          // Same amount and close date.
          // Check concept similarity
          if (old.concept.trim() == newTx.concept.trim()) return true;
          if (newTx.concept.contains(old.concept) ||
              old.concept.contains(newTx.concept)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _autoCategorize(ImportedTransaction tx) async {
    // 1. Fetch history for exact match
    // final categories = await ref.read(categoryNotifierProvider.future);

    // Simple keyword matching against category names?
    // e.g. if concept contains "Mercadona", and there is a subcategory "Supermercat"...
    // But concept doesn't contain category name usually.
    // So better rely on History (Exact Match) as primary.

    // Only use categories if history fails?
    // Or if we had keywords in Category model.
    // For now, just use history lookup.
    // To silence unused variable warning, we can just not fetch categories if not used.
    // But let's check one thing: if concept *contains* subcategory name.

    // Fallback: Check if concept contains any subcategory name
    // ignore: unused_local_variable
    bool matched = false;

    try {
      final groupId = await ref.read(currentGroupIdProvider.future);
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('transactions')
          .where('concept', isEqualTo: tx.concept)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final t = t_model.Transaction.fromFirestore(snapshot.docs.first);
        tx.categoryId = t.categoryId;
        tx.subCategoryId = t.subCategoryId;
        return;
      }

      // Fuzzy search (manual implementation or expensive query)
      // Let's stick to exact match for MVP or simplified Keyword map if User had one.
      // Current system has no keyword map.

      // Basic Heuristics?
      // If concept contains "MERCADONA" -> Food?
      // This is hardcoded and bad.
      // Better: The User will just categorize manually in staging, and next time we should learn.

      // Let's try at least finding partial matches in local history if we had it.
      // But for now, Exact Match with past transactions is the "Smart" feature.
    } catch (e) {
      // ignore
    }
  }
}

@riverpod
ImportService importService(Ref ref) {
  return ImportService(ref);
}
