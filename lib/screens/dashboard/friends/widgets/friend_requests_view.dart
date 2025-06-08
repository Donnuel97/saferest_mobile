import 'package:flutter/material.dart';
import 'package:saferest_mobile/controller/friend_controller.dart'; // Update the path as needed

class FriendRequestsView extends StatefulWidget {
  const FriendRequestsView({super.key});

  @override
  State<FriendRequestsView> createState() => _FriendRequestsViewState();
}

class _FriendRequestsViewState extends State<FriendRequestsView> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = FriendController.fetchFriendRequests();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = FriendController.fetchFriendRequests();
    });
  }

  void _handleAccept(String id, String name) async {
    final success = await FriendController.acceptFriendRequest(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Accepted $name' : 'Failed to accept $name'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    _refreshRequests();
  }

  void _handleDecline(String id, String name) async {
    final success = await FriendController.declineFriendRequest(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Declined $name' : 'Failed to decline $name'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    _refreshRequests();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No friend requests.'));
        }

        final requests = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshRequests,
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final name = "${request['first_name']} ${request['last_name']}";

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: request['avatar_url'] != null
                      ? NetworkImage(request['avatar_url'])
                      : null,
                  child: request['avatar_url'] == null ? const Icon(Icons.person_add) : null,
                ),
                title: Text(name),
                subtitle: Text(request['id']), // Optional: show ID
                trailing: Wrap(
                  spacing: 10,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _handleAccept(request['id'], name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleDecline(request['id'], name),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
