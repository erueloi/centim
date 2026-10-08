import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/retry_on_permission_denied.dart';
import '../../domain/models/user_profile.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await createUserProfile(); // Ensure profile exists
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await createUserProfile();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      await createUserProfile();
      return userCredential;
    } catch (e) {
      // ignore: avoid_print
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // Create or Update User Profile
  Future<void> createUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        currentGroupId: null,
      );
      await userDoc.set(profile.toJson());
    }
  }

  /// Perfil en viu de [uid]. Reintenta si la primera escolta arriba a
  /// Firestore abans que el token del nou usuari (vegeu
  /// [retryOnPermissionDenied]).
  Stream<UserProfile?> watchUserProfile(String uid) {
    final userDoc = _firestore.collection('users').doc(uid);
    return retryOnPermissionDenied(
      () => userDoc.snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserProfile.fromJson(doc.data()!);
      }),
    ).distinct();
  }

  /// Envia el correu de Firebase per restablir la contrasenya.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.setLanguageCode('ca');
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateCurrentGroupId(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'currentGroupId': groupId,
    });
  }

  /// Deixa l'usuari sense grup actual (l'app mostrarà la pantalla de crear
  /// o unir-se a un grup).
  Future<void> clearCurrentGroupId() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'currentGroupId': null,
    });
  }
}
