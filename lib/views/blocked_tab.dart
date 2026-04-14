import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../viewmodels/user_viewmodel.dart';

class BlockedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);

    if (userVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userVM.blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No blocked users',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Blocked users will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh will happen automatically
      },
      child: ListView.builder(
        itemCount: userVM.blockedUsers.length,
        itemBuilder: (context, index) {
          final user = userVM.blockedUsers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.name[0].toUpperCase()),
                backgroundColor: Colors.red[100],
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user.email),
              trailing: IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () => _showUnblockDialog(context, userVM, user),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUnblockDialog(
    BuildContext context,
    UserViewModel userVM,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Do you want to unblock ${user.name}? They will appear in users list again.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              userVM.unblockUser(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} has been unblocked')),
              );
            },
            child: const Text(
              'Unblock',
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
}
