import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/user_list_tile.dart';

class UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);

    if (userVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final availableUsers = userVM.allUsers.where((user) {
      if (user.uid == authVM.currentUser?.uid) return false;
      if (userVM.isFriend(user.uid)) return false;
      if (userVM.isBlocked(user.uid)) return false;
      return true;
    }).toList();

    if (availableUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No users available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'All users are either friends or blocked',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        userVM.init(authVM.currentUser!.uid);
      },
      child: ListView.builder(
        itemCount: availableUsers.length,
        itemBuilder: (context, index) {
          final user = availableUsers[index];
          return UserListTile(
            user: user,
            isFriend: userVM.isFriend(user.uid),
            isRequestSent: userVM.isRequestSent(user.uid),
            isRequestReceived: userVM.isRequestReceived(user.uid),
            onSendRequest: () => _showSendRequestDialog(context, userVM, user),
            onAcceptRequest: () =>
                _showAcceptRequestDialog(context, userVM, user),
            onRejectRequest: () =>
                _showRejectRequestDialog(context, userVM, user),
            onCancelRequest: () =>
                _showCancelRequestDialog(context, userVM, user),
            onBlock: () => _showBlockDialog(context, userVM, user),
          );
        },
      ),
    );
  }

  void _showSendRequestDialog(
    BuildContext context,
    UserViewModel userVM,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Friend Request'),
        content: Text('Do you want to send a friend request to ${user.name}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              userVM.sendFriendRequest(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Friend request sent to ${user.name}')),
              );
            },
            child: const Text(
              'Send',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptRequestDialog(
    BuildContext context,
    UserViewModel userVM,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Friend Request'),
        content: Text(
          'Do you want to accept friend request from ${user.name}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              userVM.acceptFriendRequest(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} is now your friend!')),
              );
            },
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectRequestDialog(
    BuildContext context,
    UserViewModel userVM,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Friend Request'),
        content: Text(
          'Do you want to reject friend request from ${user.name}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              userVM.rejectFriendRequest(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Friend request from ${user.name} rejected'),
                ),
              );
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelRequestDialog(
    BuildContext context,
    UserViewModel userVM,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Friend Request'),
        content: Text('Do you want to cancel friend request to ${user.name}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              userVM.cancelFriendRequest(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Friend request to ${user.name} cancelled'),
                ),
              );
            },
            child: const Text(
              'Cancel Request',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(
    BuildContext context,
    UserViewModel userVM,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${user.name}? You will no longer see them in users list.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              userVM.blockUser(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} has been blocked')),
              );
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
