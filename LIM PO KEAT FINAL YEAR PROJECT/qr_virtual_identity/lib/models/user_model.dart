import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String collection; // 'users' or 'admins'
  final String? scanPointId; // For merchants
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String? displayName;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.collection,
    this.scanPointId,
    this.createdAt,
    this.lastLoginAt,
    this.displayName,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid, String collection) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'unknown',
      collection: collection,
      scanPointId: data['scan_point_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['last_login_at'] as Timestamp?)?.toDate(),
      displayName: data['display_name'] ?? data['name'],
      photoUrl: data['photo_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'scan_point_id': scanPointId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'last_login_at': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'display_name': displayName,
      'photo_url': photoUrl,
    };
  }

  // Helper getters
  bool get isAdmin => role == 'admin';
  bool get isMerchant => role == 'merchant';
  bool get isStudent => role == 'student';
  bool get isLecturer => role == 'lecturer';
  bool get isGuest => role == 'guest';
}
