import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  final List<AppUser> _friends = [];
  List<AppUser> _blockedUsers = [];
  final bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  List<AppUser> get friends => _friends;
  List<AppUser> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;

  void init(String uid) {
    _listenToUserChanges(uid);
  }

  void _listenToUserChanges(String uid) {
    _firebaseService.getUserStream(uid).listen((user) {
      if (user != null) {
        _currentUser = user;
        _loadAllUsers();
        _loadFriends();
        _loadBlockedUsers();
        notifyListeners();
      }
    });
  }

  Future<void> _loadAllUsers() async {
    if (_currentUser == null) return;

    _firebaseService
        .getAllUsers(_currentUser!.uid, _currentUser!.blockedBy)
        .listen((users) {
          _allUsers = users;
          notifyListeners();
        });
  }

  Future<void> _loadFriends() async {
    if (_currentUser == null) return;

    _allUsers = _allUsers
        .where((user) => _currentUser!.friends.contains(user.uid))
        .toList();
    notifyListeners();
  }

  Future<void> _loadBlockedUsers() async {
    if (_currentUser == null) return;

    _firebaseService.getAllUsers(_currentUser!.uid, []).listen((users) {
      _blockedUsers = users
          .where((user) => _currentUser!.blockedUsers.contains(user.uid))
          .toList();
      notifyListeners();
    });
  }

  Future<void> sendFriendRequest(String toUid) async {
    if (_currentUser == null) return;
    await _firebaseService.sendFriendRequest(_currentUser!.uid, toUid);
  }

  Future<void> acceptFriendRequest(String requesterUid) async {
    if (_currentUser == null) return;
    await _firebaseService.acceptFriendRequest(_currentUser!.uid, requesterUid);
  }

  Future<void> rejectFriendRequest(String requesterUid) async {
    if (_currentUser == null) return;
    await _firebaseService.rejectFriendRequest(_currentUser!.uid, requesterUid);
  }

  Future<void> cancelFriendRequest(String targetUid) async {
    if (_currentUser == null) return;
    await _firebaseService.cancelFriendRequest(_currentUser!.uid, targetUid);
  }

  Future<void> blockUser(String userToBlock) async {
    if (_currentUser == null) return;
    await _firebaseService.blockUser(_currentUser!.uid, userToBlock);
  }

  Future<void> unblockUser(String userToUnblock) async {
    if (_currentUser == null) return;
    await _firebaseService.unblockUser(_currentUser!.uid, userToUnblock);
  }

  bool isFriend(String userId) {
    return _currentUser?.friends.contains(userId) ?? false;
  }

  bool isRequestSent(String userId) {
    return _currentUser?.pendingRequests.contains(userId) ?? false;
  }

  bool isRequestReceived(String userId) {
    return _currentUser?.receivedRequests.contains(userId) ?? false;
  }

  bool isBlocked(String userId) {
    return _currentUser?.blockedUsers.contains(userId) ?? false;
  }
}
