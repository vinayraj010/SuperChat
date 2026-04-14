import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  List<AppUser> _friends = [];
  List<AppUser> _blockedUsers = [];
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  List<AppUser> get friends => _friends;
  List<AppUser> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;

  void init(String uid) {
    _listenToCurrentUser(uid);
    _listenToAllUsers(uid);
  }

  void _listenToCurrentUser(String uid) {
    _firebaseService.getUserStream(uid).listen((user) {
      if (user != null) {
        _currentUser = user;
        _updateFriendsList();
        _updateBlockedList();
        notifyListeners();
      }
    });
  }

  void _listenToAllUsers(String uid) {
    _firebaseService.getAllUsers(uid, []).listen((users) {
      _allUsers = users.where((user) => user.uid != uid).toList();
      _updateFriendsList();
      _updateBlockedList();
      notifyListeners();
    });
  }

  void _updateFriendsList() {
    if (_currentUser == null) return;
    _friends = _allUsers
        .where(
          (user) =>
              _currentUser!.friends.contains(user.uid) &&
              !_currentUser!.blockedUsers.contains(user.uid),
        )
        .toList();
  }

  void _updateBlockedList() {
    if (_currentUser == null) return;
    _blockedUsers = _allUsers
        .where((user) => _currentUser!.blockedUsers.contains(user.uid))
        .toList();
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
