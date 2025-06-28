import 'package:flutter/material.dart';
import 'package:saferest_mobile/controller/friend_controller.dart'; // Adjust to your actual path

class FriendListView extends StatefulWidget {
  const FriendListView({super.key});

  @override
  State<FriendListView> createState() => _FriendListViewState();
}

class _FriendListViewState extends State<FriendListView> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _friendsFuture;
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _friendsFuture = FriendController.fetchFriends();
    _requestsFuture = FriendController.fetchFriendRequests();
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
    _onSearch(_searchController.text);
  }

  void _removeFriend(String id, String name) async {
    // TODO: Implement remove friend logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed $name'), backgroundColor: Colors.red),
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final name = "${friend['first_name']} ${friend['last_name']}";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: friend['avatar_url'] != null && friend['avatar_url'].toString().isNotEmpty
                    ? NetworkImage(friend['avatar_url'])
                    : null,
                child: (friend['avatar_url'] == null || friend['avatar_url'].toString().isEmpty) 
                    ? const Icon(Icons.person, size: 28) 
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('Last seen', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(friend['last_seen'] ?? '12:44', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFE5E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => _removeFriend(friend['id'], name),
            child: const Text('Remove', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> request) {
    final name = "${request['first_name']} ${request['last_name']}";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: request['avatar_url'] != null && request['avatar_url'].toString().isNotEmpty
                ? NetworkImage(request['avatar_url'])
                : null,
            child: (request['avatar_url'] == null || request['avatar_url'].toString().isEmpty)
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                const Text('Incoming friend request', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () {
                  // TODO: Accept friend request
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () {
                  // TODO: Decline friend request
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> user) {
    final name = "${user['first_name']} ${user['last_name']}";
    final isFriend = user['is_friends'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty
                ? NetworkImage(user['avatar_url'])
                : null,
            child: (user['avatar_url'] == null || user['avatar_url'].toString().isEmpty)
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  isFriend ? 'Already friends' : 'Tap to add friend',
                  style: TextStyle(
                    color: isFriend ? Colors.grey : Colors.orange,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isFriend)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFF3E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _sendFriendRequest(user['id'], name),
              child: const Text('Add', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Friend list', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.orange),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for new friends...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          // Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Friends', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _friendsFuture,
                              builder: (context, snapshot) {
                                final count = snapshot.hasData ? snapshot.data!.length : 0;
                                return _TabBadge(count: count, color: Colors.orange);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 3,
                          color: _selectedTab == 0 ? Colors.orange : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Incoming Friends', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _requestsFuture,
                              builder: (context, snapshot) {
                                final count = snapshot.hasData ? snapshot.data!.length : 0;
                                return _TabBadge(count: count, color: Colors.grey);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 3,
                          color: _selectedTab == 1 ? Colors.orange : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loading indicator for search
          if (_isLoadingSearch) 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: LinearProgressIndicator(),
            ),
          // List Area
          Expanded(
            child: _isSearching
                ? (_searchResults.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) => _buildSearchResultTile(_searchResults[index]),
                      ))
                : _selectedTab == 0
                    ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: _friendsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No friends found.'));
                          }
                          final friends = snapshot.data!;
                          return ListView.separated(
                            itemCount: friends.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            itemBuilder: (context, index) => _buildFriendTile(friends[index]),
                          );
                        },
                      )
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _requestsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No incoming requests.'));
                          }
                          final requests = snapshot.data!;
                          return ListView.separated(
                            itemCount: requests.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            itemBuilder: (context, index) => _buildRequestTile(requests[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _TabBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString().padLeft(2, '0'),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
