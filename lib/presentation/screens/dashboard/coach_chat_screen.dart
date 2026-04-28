import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../providers/ai_coach_provider.dart';
import '../../../domain/models/chat_message.dart';

/// Bottom sheet de chat amb el coach financer.
/// S'obre amb showModalBottomSheet des del Dashboard.
class CoachChatSheet extends ConsumerStatefulWidget {
  const CoachChatSheet({super.key});

  @override
  ConsumerState<CoachChatSheet> createState() => _CoachChatSheetState();
}

class _CoachChatSheetState extends ConsumerState<CoachChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(aiCoachProvider);

    // Scroll to bottom when messages change
    ref.listen<AiCoachState>(aiCoachProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || !next.isLoading) {
        _scrollToBottom();
      }
    });

    return Container(
      // Responsive: constrains width on tablet/desktop
      constraints: const BoxConstraints(maxWidth: 600),
      // Ocupa fins al 90% de la pantalla
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle + Header
          _buildHeader(l10n, chatState),
          const Divider(height: 1),
          // Chat messages area
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildWelcomeView(l10n)
                : _buildChatList(chatState),
          ),
          // Input bar
          _buildInputBar(l10n, chatState.isLoading),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AiCoachState chatState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.copper.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.copper,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.coachChatTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.anthracite,
              ),
            ),
          ),
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: l10n.coachNewConversation,
              onPressed: () {
                ref.read(aiCoachProvider.notifier).clearHistory();
              },
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.copper.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: AppTheme.copper,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.coachChatWelcome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppTheme.anthracite,
              ),
            ),
            const SizedBox(height: 24),
            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(l10n.coachSuggestion1),
                _buildSuggestionChip(l10n.coachSuggestion2),
                _buildSuggestionChip(l10n.coachSuggestion3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
      backgroundColor: AppTheme.copper.withValues(alpha: 0.08),
      side: BorderSide(
        color: AppTheme.copper.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildChatList(AiCoachState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount:
          chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index == chatState.messages.length && chatState.isLoading) {
          return _buildTypingIndicator();
        }

        final message = chatState.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.copper.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.copper,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.copper.withValues(alpha: 0.15)
                    : AppTheme.sand.withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight:
                      isUser ? Radius.zero : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.copper.withValues(alpha: 0.2)
                      : AppTheme.sand.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: SelectableText(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppTheme.anthracite,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.copper.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.copper,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.sand.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.sand.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[400]!,
              highlightColor: Colors.grey[200]!,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(),
                  const SizedBox(width: 4),
                  _buildDot(),
                  const SizedBox(width: 4),
                  _buildDot(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.copper,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations l10n, bool isLoading) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isLoading,
              textInputAction: TextInputAction.send,
              onSubmitted: isLoading ? null : _sendMessage,
              maxLines: null,
              decoration: InputDecoration(
                hintText: l10n.coachChatHint,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: AppTheme.sand.withValues(alpha: 0.15),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.copper.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.copper,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: isLoading ? Colors.grey[300] : AppTheme.copper,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () => _sendMessage(_controller.text),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.send_rounded,
                  color: isLoading ? Colors.grey[500] : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
