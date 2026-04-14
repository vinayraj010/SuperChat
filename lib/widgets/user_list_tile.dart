import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserListTile extends StatelessWidget {
  final AppUser user;
  final bool isFriend;
  final bool isRequestSent;
  final bool isRequestReceived;
  final VoidCallback onSendRequest;
  final VoidCallback onAcceptRequest;
  final VoidCallback onRejectRequest;
  final VoidCallback onCancelRequest;
  final VoidCallback onBlock;

  const UserListTile({
    Key? key,
    required this.user,
    required this.isFriend,
    required this.isRequestSent,
    required this.isRequestReceived,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onCancelRequest,
    required this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: _buildActionButton(),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Friend',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (isRequestSent) {
      return TextButton(
        onPressed: onCancelRequest,
        style: TextButton.styleFrom(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
      );
    }

    if (isRequestReceived) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onAcceptRequest,
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.green)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRejectRequest,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onSendRequest,
          style: TextButton.styleFrom(
            backgroundColor: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Add Friend', style: TextStyle(color: Colors.blue)),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.block, color: Colors.red),
          onPressed: onBlock,
          tooltip: 'Block User',
        ),
      ],
    );
  }
}
