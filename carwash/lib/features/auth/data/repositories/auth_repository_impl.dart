import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final userDoc = await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        }
      } catch (e) {
        // Handle error finding user doc
      }
      return null;
    });
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final userDoc = await _firestore
            .collection('usuarios')
            .doc(credential.user!.uid)
            .get();
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  @override
  Future<UserEntity> createCompanyUser({
    required String email,
    required String password,
    required String companyId,
    required String name,
    required String role,
    String? branchId,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Create a secondary Firebase App instance to avoid logging out the current user
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 2. Create user in Firebase Auth using the secondary app
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user in Firebase Auth');
      }

      final uid = credential.user!.uid;

      // 3. Create user model
      final newUser = UserModel(
        id: uid,
        email: email,
        companyId: companyId,
        role: role,
        name: name,
        branchId: branchId,
      );

      // 4. Create user document in Firestore 'usuarios' collection
      // Ensure we use the main firestore instance, not one attached to secondary app implicitly
      await _firestore.collection('usuarios').doc(uid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return newUser;
    } catch (e) {
      rethrow;
    } finally {
      // 5. Clean up secondary app
      await secondaryApp?.delete();
    }
  }

  @override
  Future<UserEntity?> registerOwner({
    required String email,
    required String password,
    required String companyId,
    required String name,
    required String branchId,
  }) async {
    try {
      // 1. Create User in Main Auth Instance (Logs in automatically)
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      final uid = credential.user!.uid;

      // 2. Create User Model
      final newUser = UserModel(
        id: uid,
        email: email,
        companyId: companyId,
        role: 'admin',
        name: name,
        branchId: branchId,
      );

      // 3. Save to Firestore (Now authorized because we are logged in)
      await _firestore.collection('usuarios').doc(uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUser({
    required String userId,
    required String name,
    String? branchId,
  }) async {
    final updates = <String, dynamic>{'nombre': name, 'sucursal_id': branchId};
    await _firestore.collection('usuarios').doc(userId).update(updates);
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Note: This only deletes the Firestore document.
    // Deleting the Auth user requires Admin SDK or Cloud Functions in a real production app.
    // For this prototype, removing from Firestore is sufficient to hide them from the app.
    await _firestore.collection('usuarios').doc(userId).delete();
  }
}
