import 'package:flutter/material.dart';
import 'package:saferest_mobile/screens/dashboard/friends/widgets/friend_list_view.dart';
import 'package:saferest_mobile/screens/dashboard/friends/widgets/friend_requests_view.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friend List'),
            Tab(text: 'Friend Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FriendListView(),
          FriendRequestsView(),
        ],
      ),
    );
  }
}
