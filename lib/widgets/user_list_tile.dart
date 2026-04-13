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
    super.key,
    required this.user,
    required this.isFriend,
    required this.isRequestSent,
    required this.isRequestReceived,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onCancelRequest,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: _buildActionButton(),
    );
  }

  Widget _buildActionButton() {
    if (isFriend) {
      return Icon(Icons.check_circle, color: Colors.green);
    }

    if (isRequestSent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: onCancelRequest,
            tooltip: 'Cancel Request',
          ),
        ],
      );
    }

    if (isRequestReceived) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: onAcceptRequest,
            tooltip: 'Accept',
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: onRejectRequest,
            tooltip: 'Reject',
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.person_add, color: Colors.blue),
          onPressed: onSendRequest,
          tooltip: 'Send Request',
        ),
        IconButton(
          icon: Icon(Icons.block, color: Colors.red),
          onPressed: onBlock,
          tooltip: 'Block',
        ),
      ],
    );
  }
}
