import 'package:flutter/material.dart';
import 'widgets/road_trip_form.dart';
import 'widgets/rail_trip_form.dart';
import 'widgets/sea_trip_form.dart';

class NewTripPage extends StatelessWidget {
  const NewTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Trip'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Road'),
              Tab(text: 'Rail'),
              Tab(text: 'Sea'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RoadTripForm(),
            RailTripForm(),
            SeaTripForm(),
          ],
        ),
      ),
    );
  }
}
