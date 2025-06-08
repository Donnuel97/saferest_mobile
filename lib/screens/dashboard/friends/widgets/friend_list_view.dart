import 'package:flutter/material.dart';
import 'package:saferest_mobile/controller/friend_controller.dart'; // Adjust to your actual path

class FriendListView extends StatefulWidget {
  const FriendListView({super.key});

  @override
  State<FriendListView> createState() => _FriendListViewState();
}

class _FriendListViewState extends State<FriendListView> {
  late Future<List<Map<String, dynamic>>> _friendsFuture;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    _friendsFuture = FriendController.fetchFriends();
  }

  void _onSearch(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoadingSearch = true;
      _isSearching = true;
    });

    final results = await FriendController.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isLoadingSearch = false;
    });
  }

  void _sendFriendRequest(String id, String name) async {
    final success = await FriendController.sendFriendRequest(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Friend request sent to $name' : 'Failed to send request to $name'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    // Optionally refresh search
    _onSearch(_searchController.text);
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final name = "${friend['first_name']} ${friend['last_name']}";
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend['avatar_url'] != null
            ? NetworkImage(friend['avatar_url'])
            : null,
        child: friend['avatar_url'] == null ? const Icon(Icons.person) : null,
      ),
      title: Text(name),
      trailing: IconButton(
        icon: const Icon(Icons.message),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message $name')),
          );
        },
      ),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> user) {
    final name = "${user['first_name']} ${user['last_name']}";
    final isFriend = user['is_friends'] == true;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['avatar_url'] != null
            ? NetworkImage(user['avatar_url'])
            : null,
        child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
      ),
      title: Text(name),
      trailing: isFriend
          ? const Text("Friends", style: TextStyle(color: Colors.grey))
          : TextButton(
        child: const Text("Add"),
        onPressed: () => _sendFriendRequest(user['id'], name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search users...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _isSearching = false;
                    _searchResults.clear();
                  });
                },
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (query) {
              if (query.length >= 2) {
                _onSearch(query);
              } else {
                setState(() {
                  _isSearching = false;
                });
              }
            },
          ),
        ),

        // 🔄 Loading
        if (_isLoadingSearch) const LinearProgressIndicator(),

        // 📋 List Area
        Expanded(
          child: _isSearching
              ? (_searchResults.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) =>
                _buildSearchResultTile(_searchResults[index]),
          ))
              : FutureBuilder<List<Map<String, dynamic>>>(
            future: _friendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No friends found.'));
              }

              final friends = snapshot.data!;
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) => _buildFriendTile(friends[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
