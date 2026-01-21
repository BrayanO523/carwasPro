import 'package:firebase_auth/firebase_auth.dart';
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
            .collection('users')
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
            .collection('users')
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
  Future<UserEntity> createCompanyUser({
    required String email,
    required String password,
    required String companyId,
    required String name,
    required String role,
  }) async {
    // 1. Create user in Firebase Auth
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception('Failed to create user in Firebase Auth');
    }

    final uid = credential.user!.uid;

    final newUser = UserModel(
      id: uid,
      email: email,
      companyId: companyId,
      role: role,
      name: name,
    );

    // 2. Create user document in Firestore 'users' collection
    await _firestore.collection('users').doc(uid).set(newUser.toMap());

    // 3. (Optional) Add reference in company's users subcollection if needed
    // But requirement says "coleccion de clientes,usuarios,empresa" - assuming top level 'users'.

    return newUser;
  }
}
