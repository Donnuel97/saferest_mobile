class ConstApi {
  // Base API URL for local development
  static const String baseUrl = 'https://saferestapi-h6p5.onrender.com';
  // static const String basePath = '/api/v1';
  // 192.168.43.56
  //\ 10.0.2.2,  192.168.8.195

  // Define headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',  // Default Accept header for JSON responses
    
  };
  // Construct full API endpoint
  static String getFullApiPath(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
