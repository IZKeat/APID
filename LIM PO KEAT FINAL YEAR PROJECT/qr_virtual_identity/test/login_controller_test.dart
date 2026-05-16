import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:apid/controllers/login_controller.dart';
import 'package:apid/services/storage_service.dart';
import 'package:apid/repositories/user_repository.dart';
import 'package:apid/guards/biometric_guard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeUserRepository extends Fake implements UserRepository {
  @override
  bool isScanPointBlacklisted(String scanPointId) => false;
}

class FakeStorageService extends Fake implements StorageService {
  @override
  Future<void> saveSessionId(String sessionId) async {}
  @override
  Future<void> saveRememberMeEmail(String email) async {}
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<bool> isBiometricEnabled() async => false;
  @override
  Future<String?> getRememberMeEmail() async => null;
}

class FakeBiometricGuard extends Fake implements BiometricGuard {}

void main() {
  late LoginController loginController;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeUserRepository fakeUserRepository;
  late FakeStorageService fakeStorageService;
  late FakeBiometricGuard fakeBiometricGuard;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    fakeUserRepository = FakeUserRepository();
    fakeStorageService = FakeStorageService();
    fakeBiometricGuard = FakeBiometricGuard();

    loginController = LoginController(
      userRepository: fakeUserRepository,
      storageService: fakeStorageService,
      biometricGuard: fakeBiometricGuard,
      auth: mockAuth,
      firestore: fakeFirestore,
    );
    // No 'when' needed
  });

  test('Should reset attempts if last failure was > 15 minutes ago', () async {
    final email = 'test@example.com';
    
    // 1. Setup existing attempts (4 attempts, 16 minutes ago)
    await fakeFirestore.collection('login_attempts').doc(email).set({
      'attempts': 4,
      'last_attempt_at': DateTime.now().subtract(const Duration(days: 1)),
    });

    // Create user so we can fail password check
    await mockAuth.createUserWithEmailAndPassword(email: email, password: 'correctpassword');

    // 2. Simulate Login Failure (MockAuth doesn't throw by default, we need to ensure it fails)
    // MockFirebaseAuth behaves like real auth, so if user doesn't exist or wrong password, it fails.
    // But here we want to force a failure.
    // Actually MockFirebaseAuth might succeed if we create the user.
    // If we don't create the user, it throws user-not-found, which triggers _recordLoginFailure.
    
    // 2. Simulate Login Failure
    print('Calling loginUser...');
    await loginController.loginUser(
      email: email,
      password: 'wrongpassword',
      onSuccess: (_) { print('Login Success (Unexpected)'); },
      onError: (msg) { print('Login Error: $msg'); },
      onStopSessionListener: () {},
      onStartSessionListener: () {},
    );
    print('loginUser finished.');

    // 3. Verify attempts reset to 1 (0 + 1)
    final doc = await fakeFirestore.collection('login_attempts').doc(email).get();
    print('Doc data: ${doc.data()}');
    expect(doc.data()?['attempts'], 1, reason: 'Attempts should be reset to 1');
  });

  test('Should accumulate attempts if last failure was < 15 minutes ago', () async {
    final email = 'test@example.com';
    
    // 1. Setup existing attempts (4 attempts, 1 minute ago)
    await fakeFirestore.collection('login_attempts').doc(email).set({
      'attempts': 4,
      'last_attempt_at': DateTime.now().subtract(const Duration(minutes: 1)),
    });

    // Create user so we can fail password check
    await mockAuth.createUserWithEmailAndPassword(email: email, password: 'correctpassword');

    // 2. Simulate Login Failure
    await loginController.loginUser(
      email: email,
      password: 'wrongpassword',
      onSuccess: (_) {},
      onError: (_) {},
      onStopSessionListener: () {},
      onStartSessionListener: () {},
    );

    // 3. Verify attempts incremented to 5
    // 3. Verify attempts incremented to 5
    final doc = await fakeFirestore.collection('login_attempts').doc(email).get();
    print('Doc data (Accumulate): ${doc.data()}');
    expect(doc.data()?['attempts'], 5, reason: 'Attempts should accumulate to 5');
    
    // 4. Verify Lockout Triggered
    expect(doc.data()?['lockout_until'], isNotNull);
    expect(loginController.lockoutEndTime, isNotNull);
  });
}
