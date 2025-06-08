class TripModel {
  final String id;
  final String title;
  final String rideDescription;
  final String logisticsCompany;
  final String plateNumber;
  final String tripType;
  final String tripStatus;
  final String? departureStation;
  final String? arrivalStation;
  final double departureLat;
  final double departureLong;
  final double arrivalLat;
  final double arrivalLong;
  final DateTime departureDate;
  final DateTime arrivalDate;

  TripModel({
    required this.id,
    required this.title,
    required this.rideDescription,
    required this.logisticsCompany,
    required this.plateNumber,
    required this.tripType,
    required this.tripStatus,
    this.departureStation,
    this.arrivalStation,
    required this.departureLat,
    required this.departureLong,
    required this.arrivalLat,
    required this.arrivalLong,
    required this.departureDate,
    required this.arrivalDate,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      title: json['title'],
      rideDescription: json['ride_description'],
      logisticsCompany: json['logistics_company'],
      plateNumber: json['plate_number'],
      tripType: json['trip_type'],
      tripStatus: json['trip_status'],
      departureStation: json['departure_station'],
      arrivalStation: json['arrival_station'],
      departureLat: double.parse(json['departure_lat']),
      departureLong: double.parse(json['departure_long']),
      arrivalLat: double.parse(json['arrival_lat']),
      arrivalLong: double.parse(json['arrival_long']),
      departureDate: DateTime.parse(json['departure_date']),
      arrivalDate: DateTime.parse(json['arrival_date']),
    );
  }
}
