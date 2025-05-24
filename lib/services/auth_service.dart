import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<fb.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<fb.User?> registerUser({
    required String name,
    required String mobileNumber,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fb.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('User creation failed');

      // 2. Prepare user data for Firestore
      final userData = {
        'id': firebaseUser.uid,
        'name': name,
        'mobileNumber': mobileNumber,
        'email': email,
        'role': role.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore users collection
      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      // 4. Add role-specific data
      if (role == UserRole.driver) {
        await _firestore.collection('drivers').doc(firebaseUser.uid).set({
          'userId': firebaseUser.uid,
          'name': name,
          'busNo': '', // To be assigned later by admin
          'mobileNumber': mobileNumber,
          'parentIds': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (role == UserRole.parent) {
        await _firestore.collection('parents').doc(firebaseUser.uid).set({
          'userId': firebaseUser.uid,
          'name': name,
          'mobileNumber': mobileNumber,
          'driverId': '', // To be assigned later by admin
          'paymentIds': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return firebaseUser;
    } catch (e) {
      // If Firebase Auth succeeds but Firestore fails, delete the auth user
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.currentUser!.delete();
      }
      throw Exception('Registration failed: $e');
    }
  }

  Future<UserRole> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final roleString = doc.data()?['role'] as String? ?? '';
        return UserRole.values.firstWhere(
          (role) => role.toString().split('.').last == roleString,
          orElse: () => UserRole.parent,
        );
      }
      throw Exception('User document not found');
    } catch (e) {
      throw Exception('Failed to fetch user role: $e');
    }
  }

  // Admin credentials (remove in production)
  static const String adminEmail = "admin@schoolbus.com";
  static const String adminPassword = "admin123";
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<fb.User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);