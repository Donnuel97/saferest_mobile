import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  bool isLoading = false;
  List<Map<String, dynamic>> friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => isLoading = true);
    // TODO: Implement friend loading logic
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (friends.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friends added yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend['avatar_url'] != null
                        ? NetworkImage(friend['avatar_url'])
                        : null,
                    child: friend['avatar_url'] == null
                        ? Text(
                            friend['first_name']?[0].toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(
                    '${friend['first_name']} ${friend['last_name']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    friend['phone'] ?? 'No phone number',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add friend functionality
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.person_add),
      ),
    );
  }
} 