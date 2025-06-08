import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../controller/create_trip.dart';
import '../../../utils/routes.dart';
import 'map_location_picker.dart';

class RoadTripForm extends StatefulWidget {
  const RoadTripForm({super.key});

  @override
  _RoadTripFormState createState() => _RoadTripFormState();
}

class _RoadTripFormState extends State<RoadTripForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _logisticsCompanyController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  DateTime? _departureDate;
  DateTime? _arrivalDate;
  List<Map<String, dynamic>> _allFriends = [];
  // List<int> _selectedFriendIds = [];
  // List<String> selectedFriendIds = [];
  // Set<String> _selectedFriendIds = <String>{};
  // Set<int> _selectedFriendIds = <int>{};
  Set<String> _selectedFriendIds = <String>{};

  bool _isLoading = false;
  bool _isSearchingLocation = false;
  bool _isFetchingDepartureLocation = false;

  double? _departureLat;
  double? _departureLong;
  double? _arrivalLat;
  double? _arrivalLong;

  static const String _googleApiKey = 'AIzaSyB30ed-a_mKI1FAzfhDye4zGg45kthVUmc';

  @override
  void initState() {
    super.initState();
    _destinationController.addListener(_onDestinationChanged);
  }

  @override
  void dispose() {
    _destinationController.removeListener(_onDestinationChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _logisticsCompanyController.dispose();
    _plateNumberController.dispose();
    _modelController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _searchDepartureLocation() async {
    final location = _departureController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a departure location')),
      );
      return;
    }

    setState(() => _isFetchingDepartureLocation = true);

    final result = await LocationController.getLocationCoordinates(location);

    setState(() => _isFetchingDepartureLocation = false);

    if (result['success']) {
      final resolvedName = result['locationData']['name'] ?? location;
      _departureController.text = resolvedName;
      setState(() {
        _departureLat = result['locationData']['latitude'];
        _departureLong = result['locationData']['longitude'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Departure location found: $resolvedName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message']}')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getPlaceSuggestions(String input) async {
    if (input.isEmpty) return [];

    // Removed types=geocode restriction and added components=country: to make it worldwide
    // Also added more comprehensive place types for better coverage
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_googleApiKey&types=(cities)&language=en';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(json['predictions']);
        } else if (json['status'] == 'ZERO_RESULTS') {
          // Try again with broader search if no cities found
          return await _getPlaceSuggestionsWithFallback(input);
        }
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
    return [];
  }

  // Fallback method for broader place search when cities don't return results
  Future<List<Map<String, dynamic>>> _getPlaceSuggestionsWithFallback(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_googleApiKey&language=en';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(json['predictions']);
        }
      }
    } catch (e) {
      print('Error fetching fallback suggestions: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    // Enhanced place details to get comprehensive location information
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&fields=name,formatted_address,geometry,address_components,place_id&language=en';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return json['result'];
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  Future<void> _searchLocation() async {
    final location = _destinationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    setState(() => _isSearchingLocation = true);

    final result = await LocationController.getLocationCoordinates(location);

    setState(() => _isSearchingLocation = false);

    if (result['success']) {
      setState(() {
        _arrivalLat = result['locationData']['latitude'];
        _arrivalLong = result['locationData']['longitude'];
      });
      final resolvedName = result['locationData']['name'] ?? location;
      _destinationController.text = resolvedName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location found: $resolvedName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message']}')),
      );
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingDepartureLocation = true);

    final result = await LocationController.getCurrentLocation();

    setState(() => _isFetchingDepartureLocation = false);

    if (result['success']) {
      final name = result['locationData']['name'] ?? 'Current location';
      _departureController.text = name;
      setState(() {
        _departureLat = result['locationData']['latitude'];
        _departureLong = result['locationData']['longitude'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Current location: $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  Future<void> _onDestinationChanged() async {
    final location = _destinationController.text.trim();
    if (location.isNotEmpty) {
      final result = await LocationController.getLocationCoordinates(location);
      if (result['success'] && mounted) {  // Add mounted check here
        setState(() {
          _arrivalLat = result['locationData']['latitude'];
          _arrivalLong = result['locationData']['longitude'];
        });
      }
    }
  }



// If your API returns int IDs, use:
// Set<int> _selectedFriendIds = <int>{};

  // FIRST: At the top of your class, change your Set declaration to match your API
// If your API returns String IDs, use:
  

// If your API returns int IDs, use:
// Set<int> _selectedFriendIds = <int>{};

  Future<void> _showFriendSelector() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Select Friends"),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: LocationController.getFriends(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error loading friends: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setModalState(() {}); // Trigger rebuild to retry
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber, size: 48, color: Colors.orange),
                            SizedBox(height: 16),
                            Text('No data received from server'),
                          ],
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    List<dynamic> friendsList = [];

                    // FIXED: Handle the direct list response from your API
                    if (data is List) {
                      friendsList = data as List;
                    } else if (data['data'] != null && data['data'] is List) {
                      friendsList = data['data'] as List;
                    } else if (data['friends'] != null && data['friends'] is List) {
                      friendsList = data['friends'] as List;
                    } else if (data['results'] != null && data['results'] is List) {
                      friendsList = data['results'] as List;
                    } else {
                      // Look for any List in the response
                      for (final value in data.values) {
                        if (value is List) {
                          friendsList = value;
                          break;
                        }
                      }
                    }

                    if (friendsList.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No friends found'),
                          ],
                        ),
                      );
                    }

                    _allFriends = List<Map<String, dynamic>>.from(friendsList);

                    return Column(
                      children: [
                        // Select All/None buttons
                        if (_allFriends.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      setState(() {
                                        _selectedFriendIds.clear();
                                        for (final friend in _allFriends) {
                                          final friendId = _parseFriendId(friend['id']);
                                          if (friendId != null) {
                                            _selectedFriendIds.add(friendId);
                                          }
                                        }
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.select_all),
                                  label: const Text('Select All'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      setState(() {
                                        _selectedFriendIds.clear();
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Clear All'),
                                ),
                              ],
                            ),
                          ),

                        // Selection counter
                        if (_selectedFriendIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_selectedFriendIds.length} friend${_selectedFriendIds.length == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Friends list
                        Expanded(
                          child: ListView.builder(
                            itemCount: _allFriends.length,
                            itemBuilder: (context, index) {
                              final friend = _allFriends[index];
                              final friendId = _parseFriendId(friend['id']);

                              if (friendId == null) {
                                return const SizedBox.shrink();
                              }

                              final firstName = friend['first_name']?.toString() ?? '';
                              final lastName = friend['last_name']?.toString() ?? '';
                              final fullName = '$firstName $lastName'.trim();
                              final avatarUrl = friend['avatar_url']?.toString();
                              final isFriends = friend['is_friends'] ?? false;
                              final isSelected = _selectedFriendIds.contains(friendId);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                child: CheckboxListTile(
                                  title: Text(
                                    fullName.isEmpty ? 'Unknown User' : fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('ID: ${friendId.length > 8 ? friendId.substring(0, 8) + '...' : friendId}'),
                                      if (isFriends)
                                        const Text(
                                          'Friends ✓',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null || avatarUrl.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? selected) {
                                    setModalState(() {
                                      setState(() {
                                        if (selected == true) {
                                          print('Adding friend ID: $friendId'); // Debug print
                                          _selectedFriendIds.add(friendId);
                                        } else {
                                          print('Removing friend ID: $friendId'); // Debug print
                                          _selectedFriendIds.remove(friendId);
                                        }
                                      });
                                      print('Current selected friends: $_selectedFriendIds'); // Debug print
                                    });
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _selectedFriendIds.isNotEmpty
                      ? () => Navigator.of(context).pop()
                      : null,
                  child: Text("Done (${_selectedFriendIds.length})"),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Fixed helper method with proper type handling
//   int? _parseFriendId(dynamic id) {
//     if (id == null) return null;
//     // Convert to int since _selectedFriendIds is now Set<int>
//     if (id is int) return id;
//     if (id is String) {
//       return int.tryParse(id);
//     }
//     return int.tryParse(id.toString());
//   }

  // String? _parseFriendId(dynamic id) {
  //   if (id == null) return null;
  //   // Return as String since your API returns UUID strings
  //   return id.toString();
  // }

// IMPORTANT: Make sure your _selectedFriendIds is declared as:
// Set<int> _selectedFriendIds = <int>{};

// Alternative Solution: If your API consistently returns String IDs,
// change your Set declaration to:
// Set<String> _selectedFriendIds = <String>{};
// And use this helper method instead:
/*
String _parseFriendId(dynamic id) {
  if (id == null) return '';
  return id.toString();
}
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          SingleChildScrollView(
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Vehicle details card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Vehicle details', style: TextStyle(color: Colors.orange)),
                              const Divider(),
                              const SizedBox(height: 10),
                              const Text('Logistics company', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _logisticsCompanyController,
                                decoration: const InputDecoration(filled: true, hintText: 'Input company name'),
                                validator: (value) =>
                                value == null || value.isEmpty ? 'Please input the logistics company' : null,
                              ),
                              const SizedBox(height: 15),
                              const Text('Plate number', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _plateNumberController,
                                decoration: const InputDecoration(filled: true, hintText: 'Input plate number'),
                                validator: (value) =>
                                value == null || value.isEmpty ? 'Please input the plate number' : null,
                              ),
                              const SizedBox(height: 15),
                              const Text('Model/Colour', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _modelController,
                                decoration: const InputDecoration(filled: true, hintText: 'Input model/colour'),
                                validator: (value) =>
                                value == null || value.isEmpty ? 'Please input the model/colour' : null,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Journey details card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Trip Title', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  filled: true,
                                  hintText: 'Enter a title for your trip',
                                ),
                                validator: (value) =>
                                value == null || value.isEmpty ? 'Trip title is required' : null,
                              ),
                              const SizedBox(height: 15),

                              // Trip description
                              const Text('Trip Description', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  filled: true,
                                  hintText: 'Enter a description for your trip...',
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Please add a trip description' : null,
                              ),
                              const SizedBox(height: 15),

                              // Dates
                              const Text('Departure Date', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () => _pickDate(context, true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(filled: true, hintText: 'Pick date'),
                                  child: Text(
                                    _departureDate != null
                                        ? _departureDate!.toLocal().toString().split(' ')[0]
                                        : 'Select departure date',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text('Arrival Date', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () => _pickDate(context, false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(filled: true, hintText: 'Pick date'),
                                  child: Text(
                                    _arrivalDate != null
                                        ? _arrivalDate!.toLocal().toString().split(' ')[0]
                                        : 'Select arrival date',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Departure location with TypeAhead
                              const Text('Advanced From (Departure)', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    child: TypeAheadField<Map<String, dynamic>>(
                                      controller: _departureController,
                                      builder: (context, controller, focusNode) {
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            filled: true,
                                            hintText: 'Search or use GPS',
                                            border: OutlineInputBorder(),
                                          ),
                                        );
                                      },
                                      suggestionsCallback: (pattern) async {
                                        return await _getPlaceSuggestions(pattern);
                                      },
                                      itemBuilder: (context, suggestion) {
                                        final mainText = suggestion['structured_formatting']?['main_text'] ?? suggestion['description'] ?? '';
                                        final secondaryText = suggestion['structured_formatting']?['secondary_text'] ?? '';

                                        return ListTile(
                                          title: Text(
                                            mainText,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: secondaryText.isNotEmpty ? Text(
                                            secondaryText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ) : null,
                                          leading: Icon(
                                            Icons.location_on,
                                            color: Colors.orange[300],
                                            size: 20,
                                          ),
                                          dense: true,
                                        );
                                      },
                                      onSelected: (suggestion) async {
                                        final placeId = suggestion['place_id'];
                                        final details = await _getPlaceDetails(placeId);
                                        if (details != null) {
                                          final name = details['formatted_address'] ?? details['name'] ?? suggestion['description'];
                                          final lat = details['geometry']['location']['lat'];
                                          final lng = details['geometry']['location']['lng'];

                                          setState(() {
                                            _departureController.text = name;
                                            _departureLat = lat?.toDouble();
                                            _departureLong = lng?.toDouble();
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Selected: $name'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      emptyBuilder: (context) => const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('No suggestions found'),
                                      ),
                                      loadingBuilder: (context) => const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Loading...'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _isFetchingDepartureLocation
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.map, color: Colors.blue),
                                        onPressed: () => _showMapPicker(true),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search, color: Colors.orange),
                                        onPressed: _searchDepartureLocation,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.gps_fixed, color: Colors.green),
                                        onPressed: _fetchCurrentLocation,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // Destination location
                              const Text('Advanced To (Arrival)', style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    child: TypeAheadField<Map<String, dynamic>>(
                                      controller: _destinationController,
                                      builder: (context, controller, focusNode) {
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            filled: true,
                                            hintText: 'Search destination',
                                            border: OutlineInputBorder(),
                                          ),
                                        );
                                      },
                                      suggestionsCallback: (pattern) async {
                                        return await _getPlaceSuggestions(pattern);
                                      },
                                      itemBuilder: (context, suggestion) {
                                        final mainText = suggestion['structured_formatting']?['main_text'] ?? suggestion['description'] ?? '';
                                        final secondaryText = suggestion['structured_formatting']?['secondary_text'] ?? '';

                                        return ListTile(
                                          title: Text(
                                            mainText,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: secondaryText.isNotEmpty ? Text(
                                            secondaryText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ) : null,
                                          leading: Icon(
                                            Icons.place,
                                            color: Colors.orange[300],
                                            size: 20,
                                          ),
                                          dense: true,
                                        );
                                      },
                                      onSelected: (suggestion) async {
                                        final placeId = suggestion['place_id'];
                                        final details = await _getPlaceDetails(placeId);
                                        if (details != null) {
                                          final name = details['formatted_address'] ?? details['name'] ?? suggestion['description'];
                                          final lat = details['geometry']['location']['lat'];
                                          final lng = details['geometry']['location']['lng'];

                                          setState(() {
                                            _destinationController.text = name;
                                            _arrivalLat = lat?.toDouble();
                                            _arrivalLong = lng?.toDouble();
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Selected: $name'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      emptyBuilder: (context) => const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('No suggestions found'),
                                      ),
                                      loadingBuilder: (context) => const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Loading...'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _isSearchingLocation
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.map, color: Colors.blue),
                                        onPressed: () => _showMapPicker(false),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.search, color: Colors.orange),
                                        onPressed: _searchLocation,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tracking section
                      _buildTrackingSection(),

                      // Save button
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        height: 60,
                        width: MediaQuery.of(context).size.width,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTrip,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.orange),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isDeparture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
        } else {
          _arrivalDate = picked;
        }
      });
    }
  }

  // Future<void> _saveTrip() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // Format coordinates to meet API requirements
  //     double? formattedDepartureLat = _departureLat != null ? double.parse(_departureLat!.toStringAsFixed(6)) : null;
  //     double? formattedDepartureLong = _departureLong != null ? double.parse(_departureLong!.toStringAsFixed(6)) : null;
  //     double? formattedArrivalLat = _arrivalLat != null ? double.parse(_arrivalLat!.toStringAsFixed(6)) : null;
  //     double? formattedArrivalLong = _arrivalLong != null ? double.parse(_arrivalLong!.toStringAsFixed(6)) : null;
  //
  //     // FIXED: Handle UUID strings properly for API submission
  //     List<Map<String, dynamic>>? watchers;
  //
  //     if (_selectedFriendIds.isNotEmpty) {
  //       watchers = _selectedFriendIds.map((stringId) {
  //         // Option 1: If your API accepts string UUIDs (recommended)
  //         return {
  //           'user': stringId, // Keep as UUID string
  //           'status': 'PENDING'
  //         };
  //
  //         // Option 2: If your API requires integers, convert UUID to int
  //         // Note: UUIDs can't be directly converted to meaningful integers
  //         // You might need to use a hash or check with your backend team
  //         /*
  //         return {
  //           'user': stringId.hashCode.abs(), // Convert to positive integer
  //           'status': 'PENDING'
  //         };
  //         */
  //       }).toList();
  //     }
  //
  //     // Debug: Print the watchers to see the format
  //     print('Watchers being sent: $watchers');
  //     print('Selected friend IDs: $_selectedFriendIds');
  //
  //     final responseMessage = await LocationController.createTrip(
  //       title: _titleController.text.trim(),
  //       tripType: "ROAD",
  //       rideDescription: _descriptionController.text.trim(),
  //       watchers: watchers,
  //       logisticsCompany: _logisticsCompanyController.text.trim(),
  //       plateNumber: _plateNumberController.text.trim(),
  //       departureLat: formattedDepartureLat,
  //       departureLong: formattedDepartureLong,
  //       arrivalLat: formattedArrivalLat,
  //       arrivalLong: formattedArrivalLong,
  //       departureStation: _departureController.text.trim(),
  //       arrivalStation: _destinationController.text.trim(),
  //       departureDate: _departureDate?.toIso8601String(),
  //       arrivalDate: _arrivalDate?.toIso8601String(),
  //     );
  //
  //     if (!mounted) return;
  //
  //     final isSuccess = responseMessage.toLowerCase().contains("success");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(responseMessage),
  //         backgroundColor: isSuccess ? Colors.green : Colors.red,
  //       ),
  //     );
  //
  //     if (isSuccess) {
  //       Navigator.pushReplacementNamed(context, Routes.trips_list);
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to save trip: ${e.toString()}'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  // Here's the corrected _saveTrip method with proper debugging and UUID handling

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Format coordinates
      double? formattedDepartureLat = _departureLat != null ? double.parse(_departureLat!.toStringAsFixed(6)) : null;
      double? formattedDepartureLong = _departureLong != null ? double.parse(_departureLong!.toStringAsFixed(6)) : null;
      double? formattedArrivalLat = _arrivalLat != null ? double.parse(_arrivalLat!.toStringAsFixed(6)) : null;
      double? formattedArrivalLong = _arrivalLong != null ? double.parse(_arrivalLong!.toStringAsFixed(6)) : null;

      // Debug print before creating watchers
      print('Selected friend IDs before formatting: $_selectedFriendIds');

      // Create watchers array with proper format
      final List<Map<String, dynamic>> watchers = _selectedFriendIds
          .where((id) => id != null && id.isNotEmpty) // Filter out any null or empty IDs
          .map((id) => {
                'user': id, // Use the UUID string directly
                'status': 'PENDING'
              })
          .toList();

      // Debug print the formatted watchers
      print('Formatted watchers array: $watchers');

      final responseMessage = await LocationController.createTrip(
        title: _titleController.text.trim(),
        tripType: "ROAD",
        rideDescription: _descriptionController.text.trim(),
        watchers: watchers.isNotEmpty ? watchers : null, // Only send if we have watchers
        logisticsCompany: _logisticsCompanyController.text.trim(),
        plateNumber: _plateNumberController.text.trim(),
        // model: _modelController.text.trim(),
        departureLat: formattedDepartureLat,
        departureLong: formattedDepartureLong,
        arrivalLat: formattedArrivalLat,
        arrivalLong: formattedArrivalLong,
        departureStation: _departureController.text.trim(),
        arrivalStation: _destinationController.text.trim(),
        departureDate: _departureDate?.toIso8601String(),
        arrivalDate: _arrivalDate?.toIso8601String(),
      );

      // Debug print the response
      print('API Response: $responseMessage');

      if (!mounted) return;

      final isSuccess = responseMessage.toLowerCase().contains("success");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseMessage),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );

      if (isSuccess) {
        Navigator.pushReplacementNamed(context, Routes.trips_list);
      }
    } catch (e) {
      print('Error in _saveTrip: $e');
      print('Stack trace: ${StackTrace.current}');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Also add this method to debug your LocationController.createTrip method
// Check what parameters it's actually expecting and how it's handling the watchers array

// ADDITIONAL DEBUGGING: Add this method to check your LocationController
  void _debugLocationController() async {
    print('=== DEBUGGING LOCATION CONTROLLER ===');

    // Test with a simple watchers array
    final testWatchers = [
      {
        'user': '550e8400-e29b-41d4-a716-446655440000', // Sample UUID
        'status': 'PENDING'
      }
    ];

    print('Test watchers: $testWatchers');

    // You might want to check the LocationController.createTrip method
    // to see how it's processing the watchers parameter
  }

// IMPORTANT: Check your LocationController.createTrip method
// Make sure it's properly handling the watchers parameter and sending it to the API
// The issue might be in how the controller is processing or sending the data

// Here's what you should verify in your LocationController.createTrip method:
/*
1. Is the watchers parameter being properly included in the API request?
2. Is it being sent as JSON in the correct format?
3. Are there any transformations happening to the watchers array?
4. Check the actual HTTP request being sent to the API
5. Verify the API endpoint expects the watchers in this exact format

Example of what the API request should look like:
{
  "title": "abc",
  "trip_type": "ROAD",
  "ride_description": "abc",
  "watchers": [
    {
      "user": "67e7495e-9fc6-4f92-85be-c52e5c221dc3",
      "status": "PENDING"
    }
  ],
  // ... other fields
}
*/
  // REMOVE this alternative method that's causing confusion
  // Future<void> _saveTrip_Alternative() async { ... }

  // Keep your helper method as is (it's correct)
  String? _parseFriendId(dynamic id) {
    if (id == null) return null;
    // Return as String since API returns UUID strings
    return id.toString();
  }


  // 4. Alternative approach if you need to keep String IDs but convert for API
  Future<void> _saveTrip_Alternative() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ... coordinate formatting code ...

      // Convert string IDs to integers for the API
      // List<Map<String, dynamic>>? watchers = _selectedFriendIds.isNotEmpty
      //     ? _selectedFriendIds
      //     .map((stringId) {
      //   final intId = int.tryParse(stringId);
      //   if (intId != null) {
      //     return {
      //       'user': intId, // Convert to int
      //       'status': 'PENDING'
      //     };
      //   }
      //   return null;
      // })
      //     .where((watcher) => watcher != null)
      //     .cast<Map<String, dynamic>>()
      //     .toList()
      //     : null;
      List<Map<String, dynamic>>? watchers = _selectedFriendIds.isNotEmpty
          ? _selectedFriendIds.map((id) => {
        'user': id, // id is already an int
        'status': 'PENDING'
      }).toList()
          : null;

      // ... rest of the method ...
    } catch (e) {
      // ... error handling ...
    }
  }

  Widget _buildTrackingSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Want friends to track your journey? (Optional)',
                style: TextStyle(color: Colors.orange)),
            const Divider(),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _showFriendSelector,
              child: const Text(
                'Select friends (optional)',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (_selectedFriendIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Selected Friends:"),
                    const SizedBox(height: 8),
                    ..._selectedFriendIds.map((id) {
                      final friend = _allFriends.firstWhere(
                            (f) => _parseFriendId(f['id']) == id, // Compare String to String now
                        orElse: () => {},
                      );
                      final name = friend.isNotEmpty
                          ? "${friend['first_name']} ${friend['last_name']}"
                          : id.substring(0, 8) + '...'; // Show truncated UUID
                      return Text("- $name");
                    }),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange.shade100,
                ),
                child: const Text('No friends selected - your trip will be private'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMapPicker(bool isDeparture) async {
    LatLng? initialLocation;
    if (isDeparture && _departureLat != null && _departureLong != null) {
      initialLocation = LatLng(_departureLat!, _departureLong!);
    } else if (!isDeparture && _arrivalLat != null && _arrivalLong != null) {
      initialLocation = LatLng(_arrivalLat!, _arrivalLong!);
    }

    await showDialog(
      context: context,
      builder: (context) => MapLocationPicker(
        initialLocation: initialLocation,
        onLocationSelected: (location, address) {
          setState(() {
            if (isDeparture) {
              _departureLat = location.latitude;
              _departureLong = location.longitude;
              _departureController.text = address;
            } else {
              _arrivalLat = location.latitude;
              _arrivalLong = location.longitude;
              _destinationController.text = address;
            }
          });
        },
      ),
    );
  }
}