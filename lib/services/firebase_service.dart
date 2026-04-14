import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== AUTHENTICATION ====================

  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ==================== USER STREAMS ====================

  Stream<AppUser?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromMap(uid, snapshot.data()!);
      }
      return null;
    });
  }

  Stream<List<AppUser>> getAllUsers(String currentUid, List<String> blockedBy) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUid && !blockedBy.contains(doc.id))
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // ==================== FRIEND REQUESTS ====================

  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    try {
      final batch = _firestore.batch();

      final senderRef = _firestore.collection('users').doc(fromUid);
      batch.update(senderRef, {
        'pendingRequests': FieldValue.arrayUnion([toUid]),
      });

      final receiverRef = _firestore.collection('users').doc(toUid);
      batch.update(receiverRef, {
        'receivedRequests': FieldValue.arrayUnion([fromUid]),
      });

      await batch.commit();
      print('Friend request sent successfully');
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  Future<void> acceptFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    try {
      final batch = _firestore.batch();

      final currentRef = _firestore.collection('users').doc(currentUid);
      final requesterRef = _firestore.collection('users').doc(requesterUid);

      batch.update(currentRef, {
        'friends': FieldValue.arrayUnion([requesterUid]),
        'receivedRequests': FieldValue.arrayRemove([requesterUid]),
      });

      batch.update(requesterRef, {
        'friends': FieldValue.arrayUnion([currentUid]),
        'pendingRequests': FieldValue.arrayRemove([currentUid]),
      });

      await batch.commit();
      print('Friend request accepted successfully');

      // Create chat room immediately after accepting friend request
      await _createChatRoom(currentUid, requesterUid);

      // Verify chat was created
      await _verifyChatCreation(currentUid, requesterUid);
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  Future<void> rejectFriendRequest(
    String currentUid,
    String requesterUid,
  ) async {
    try {
      final batch = _firestore.batch();

      final currentRef = _firestore.collection('users').doc(currentUid);
      batch.update(currentRef, {
        'receivedRequests': FieldValue.arrayRemove([requesterUid]),
      });

      final requesterRef = _firestore.collection('users').doc(requesterUid);
      batch.update(requesterRef, {
        'pendingRequests': FieldValue.arrayRemove([currentUid]),
      });

      await batch.commit();
      print('Friend request rejected successfully');
    } catch (e) {
      print('Error rejecting friend request: $e');
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(String currentUid, String targetUid) async {
    try {
      final batch = _firestore.batch();

      final currentRef = _firestore.collection('users').doc(currentUid);
      batch.update(currentRef, {
        'pendingRequests': FieldValue.arrayRemove([targetUid]),
      });

      final targetRef = _firestore.collection('users').doc(targetUid);
      batch.update(targetRef, {
        'receivedRequests': FieldValue.arrayRemove([currentUid]),
      });

      await batch.commit();
      print('Friend request cancelled successfully');
    } catch (e) {
      print('Error cancelling friend request: $e');
      rethrow;
    }
  }

  // ==================== BLOCK FUNCTIONALITY ====================

  Future<void> blockUser(String currentUid, String userToBlock) async {
    try {
      final batch = _firestore.batch();

      final currentRef = _firestore.collection('users').doc(currentUid);
      final blockedRef = _firestore.collection('users').doc(userToBlock);

      batch.update(currentRef, {
        'blockedUsers': FieldValue.arrayUnion([userToBlock]),
        'friends': FieldValue.arrayRemove([userToBlock]),
        'pendingRequests': FieldValue.arrayRemove([userToBlock]),
        'receivedRequests': FieldValue.arrayRemove([userToBlock]),
      });

      batch.update(blockedRef, {
        'blockedBy': FieldValue.arrayUnion([currentUid]),
        'friends': FieldValue.arrayRemove([currentUid]),
        'pendingRequests': FieldValue.arrayRemove([currentUid]),
        'receivedRequests': FieldValue.arrayRemove([currentUid]),
      });

      await batch.commit();
      print('User blocked successfully');
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  Future<void> unblockUser(String currentUid, String userToUnblock) async {
    try {
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
      print('User unblocked successfully');
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  // ==================== CHAT FUNCTIONALITY ====================

  // Method 1: Manual fix to create missing chat rooms for existing friends
  Future<void> fixExistingChatRooms(String currentUserId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!userDoc.exists) return;

      final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
      print('Found ${friends.length} friends to create chats for');

      for (String friendId in friends) {
        await _createChatRoom(currentUserId, friendId);
        print('Created/verified chat room with friend: $friendId');
      }
    } catch (e) {
      print('Error fixing chat rooms: $e');
    }
  }

  // Method 2: Create chat room (updated version)
  Future<void> _createChatRoom(String uid1, String uid2) async {
    try {
      final chatId = getChatId(uid1, uid2);
      print('Creating chat room: $chatId for users: $uid1, $uid2');

      // Get user names first
      final user1Doc = await _firestore.collection('users').doc(uid1).get();
      final user2Doc = await _firestore.collection('users').doc(uid2).get();

      final user1Name = user1Doc.data()?['name'] ?? 'User';
      final user2Name = user2Doc.data()?['name'] ?? 'User';

      // Create all documents in a batch
      final batch = _firestore.batch();

      // 1. Create chat document
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.set(chatRef, {
        'chatId': chatId,
        'participants': [uid1, uid2],
        'participantNames': {uid1: user1Name, uid2: user2Name},
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create user1's chat reference
      final user1ChatRef = _firestore
          .collection('user_chats')
          .doc(uid1)
          .collection('chats')
          .doc(chatId);
      batch.set(user1ChatRef, {
        'chatId': chatId,
        'otherUserId': uid2,
        'otherUserName': user2Name,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      }, SetOptions(merge: true));

      // 3. Create user2's chat reference
      final user2ChatRef = _firestore
          .collection('user_chats')
          .doc(uid2)
          .collection('chats')
          .doc(chatId);
      batch.set(user2ChatRef, {
        'chatId': chatId,
        'otherUserId': uid1,
        'otherUserName': user1Name,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      }, SetOptions(merge: true));

      await batch.commit();
      print('Chat room created successfully: $chatId');
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // Method 3: Verify chat creation
  Future<void> _verifyChatCreation(String uid1, String uid2) async {
    final chatId = getChatId(uid1, uid2);

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final user1ChatDoc = await _firestore
        .collection('user_chats')
        .doc(uid1)
        .collection('chats')
        .doc(chatId)
        .get();
    final user2ChatDoc = await _firestore
        .collection('user_chats')
        .doc(uid2)
        .collection('chats')
        .doc(chatId)
        .get();

    print('Chat verification:');
    print('  Chat document exists: ${chatDoc.exists}');
    print('  User1 chat exists: ${user1ChatDoc.exists}');
    print('  User2 chat exists: ${user2ChatDoc.exists}');
  }

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  Stream<List<UserChat>> getUserChats(String userId) {
    return _firestore
        .collection('user_chats')
        .doc(userId)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserChat.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

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

  Future<void> sendMessage(Message message) async {
    try {
      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, message.toMap());

      final chatRef = _firestore.collection('chats').doc(message.chatId);
      batch.update(chatRef, {
        'lastMessage': message.type == 'text'
            ? message.text
            : '🎵 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': message.senderId,
      });

      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final participants = List<String>.from(
          chatDoc.data()?['participants'] ?? [],
        );

        for (var participant in participants) {
          final userChatRef = _firestore
              .collection('user_chats')
              .doc(participant)
              .collection('chats')
              .doc(message.chatId);

          if (participant == message.senderId) {
            batch.update(userChatRef, {
              'lastMessage': message.type == 'text'
                  ? message.text
                  : '🎵 Voice message',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'unreadCount': 0,
            });
          } else {
            final userChatDoc = await userChatRef.get();
            final currentUnread = userChatDoc.exists
                ? (userChatDoc.data()?['unreadCount'] ?? 0)
                : 0;
            batch.update(userChatRef, {
              'lastMessage': message.type == 'text'
                  ? message.text
                  : '🎵 Voice message',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'unreadCount': currentUnread + 1,
            });
          }
        }
      }

      await batch.commit();
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final userChatRef = _firestore
          .collection('user_chats')
          .doc(userId)
          .collection('chats')
          .doc(chatId);

      await userChatRef.update({'unreadCount': 0});
      print('Messages marked as read');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
