import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:superchat/models/message_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      AppUser newUser = AppUser(
        uid: result.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        friends: [],
        pendingRequests: [],
        receivedRequests: [],
        blockedUsers: [],
        blockedBy: [],
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());
      return result.user;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data stream
  Stream<AppUser?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromMap(uid, snapshot.data()!);
      }
      return null;
    });
  }

  // Get all registered users except current user and blocked users
  Stream<List<AppUser>> getAllUsers(String currentUid, List<String> blockedBy) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUid && !blockedBy.contains(doc.id))
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    final batch = _firestore.batch();

    // Add to sender's pending requests
    final senderRef = _firestore.collection('users').doc(fromUid);
    batch.update(senderRef, {
      'pendingRequests': FieldValue.arrayUnion([toUid]),
    });

    // Add to receiver's received requests
    final receiverRef = _firestore.collection('users').doc(toUid);
    batch.update(receiverRef, {
      'receivedRequests': FieldValue.arrayUnion([fromUid]),
    });

    await batch.commit();
  }

  // Accept friend request
  Future<void> acceptFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    final batch = _firestore.batch();

    final currentRef = _firestore.collection('users').doc(currentUid);
    final requesterRef = _firestore.collection('users').doc(requesterUid);

    // Add to friends list
    batch.update(currentRef, {
      'friends': FieldValue.arrayUnion([requesterUid]),
      'receivedRequests': FieldValue.arrayRemove([requesterUid]),
    });

    batch.update(requesterRef, {
      'friends': FieldValue.arrayUnion([currentUid]),
      'pendingRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }

  // Reject friend request
  Future<void> rejectFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    final batch = _firestore.batch();

    final currentRef = _firestore.collection('users').doc(currentUid);
    final requesterRef = _firestore.collection('users').doc(requesterUid);

    batch.update(currentRef, {
      'receivedRequests': FieldValue.arrayRemove([requesterUid]),
    });

    batch.update(requesterRef, {
      'pendingRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }

  // Cancel friend request
  Future<void> cancelFriendRequest(String currentUid, String targetUid) async {
    final batch = _firestore.batch();

    final currentRef = _firestore.collection('users').doc(currentUid);
    final targetRef = _firestore.collection('users').doc(targetUid);

    batch.update(currentRef, {
      'pendingRequests': FieldValue.arrayRemove([targetUid]),
    });

    batch.update(targetRef, {
      'receivedRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }

  // Block user
  Future<void> blockUser(String currentUid, String userToBlock) async {
    final batch = _firestore.batch();

    final currentRef = _firestore.collection('users').doc(currentUid);
    final blockedRef = _firestore.collection('users').doc(userToBlock);

    // Add to blocked list
    batch.update(currentRef, {
      'blockedUsers': FieldValue.arrayUnion([userToBlock]),
      'friends': FieldValue.arrayRemove([userToBlock]),
    });

    // Add to blockedBy list of the blocked user
    batch.update(blockedRef, {
      'blockedBy': FieldValue.arrayUnion([currentUid]),
      'friends': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }

  // Unblock user
  Future<void> unblockUser(String currentUid, String userToUnblock) async {
    final batch = _firestore.batch();

    final currentRef = _firestore.collection('users').doc(currentUid);
    final unblockedRef = _firestore.collection('users').doc(userToUnblock);

    batch.update(currentRef, {
      'blockedUsers': FieldValue.arrayRemove([userToUnblock]),
    });

    batch.update(unblockedRef, {
      'blockedBy': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }

  // Get chat ID for two users
  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  // Get messages stream
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Send message
  Future<void> sendMessage(Message message) async {
    await _firestore
        .collection('chats')
        .doc(message.chatId)
        .collection('messages')
        .add(message.toMap());
  }
}
