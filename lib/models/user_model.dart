import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final List<String> friends; // Accepted friend UIDs
  final List<String> pendingRequests; // Sent requests
  final List<String> receivedRequests; // Received requests
  final List<String> blockedUsers; // Blocked user UIDs
  final List<String> blockedBy; // Users who blocked this user

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.friends,
    required this.pendingRequests,
    required this.receivedRequests,
    required this.blockedUsers,
    required this.blockedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': createdAt,
      'friends': friends,
      'pendingRequests': pendingRequests,
      'receivedRequests': receivedRequests,
      'blockedUsers': blockedUsers,
      'blockedBy': blockedBy,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      friends: List<String>.from(map['friends'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      receivedRequests: List<String>.from(map['receivedRequests'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      blockedBy: List<String>.from(map['blockedBy'] ?? []),
    );
  }
}
