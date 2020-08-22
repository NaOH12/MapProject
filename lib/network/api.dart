import 'dart:convert';
import 'package:flutterapp/post_data/post.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Network {
  final String _url = 'https://noah.business';
  var _token;

  int _requests = 0;

  printRequestCount() {
    _requests++;
    print("Request count : " + _requests.toString());
  }

  static final Network _network = Network._internal();

  factory Network() {
    return _network;
  }

  Network._internal();

  bool tokenExists() {
    return _token != null;
  }

  loadToken() async {
    if (_token == null) {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      _token = jsonDecode(localStorage.getString('token'))['token'];
    }
  }

  Future<http.Response> postData(data, apiUrl) async {
    printRequestCount();

    var fullUrl = _url + apiUrl;
    var response = await http.post(fullUrl,
        body: jsonEncode(data), headers: _setHeaders());
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception("Error! Status code: " + response.statusCode.toString());
    }
  }

  Future<Map<String, dynamic>> getData(apiUrl) async {
    printRequestCount();
    print("URL IS $apiUrl");
    // Build the URL for GET request
    var fullUrl = _url + apiUrl;
    // Get auth token
    await loadToken();
    // Make GET request and store response
    var response = await http.get(fullUrl, headers: _setHeaders());
    // Check if response is successful
    if (response.statusCode == 200) {
      // Decode response body to Map<String, dynamic>
      return jsonDecode(response.body);
    } else {
      throw Exception("Error! Status code: " + response.statusCode.toString());
    }
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token'
      };

  Future<bool> login(String email, String password) async {
    var data = {'email': email, 'password': password};

    var res = await Network().postData(data, '/api/login');
    Map<String, dynamic> body = json.decode(res.body);
    if (body['success']) {
      _token = body['access_token'];
//      SharedPreferences localStorage = await SharedPreferences.getInstance();
//      localStorage.setString('access_token', json.encode(body['access_token']));
//      localStorage.setString('user', json.encode(body['user']));
//      Navigator.push(
//        context,
//        new MaterialPageRoute(
//            builder: (context) => Home()
//        ),
//      );
//      await loadToken();
      print("PASSED");
      print(body['access_token']);
        print(body);
      return true;
    } else {
      print("FAILED");
      print(body['message']);
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String dob, String password) async {
    var data = {
      'name': name,
      'email': email,
      'date_of_birth': dob,
      'password': password,
      'password_confirmation': password
    };

    var res = await Network().postData(data, '/api/register');

    Map<String, dynamic> body = json.decode(res.body);
    if (body['success']) {
      _token = body['access_token'];
//      SharedPreferences localStorage = await SharedPreferences.getInstance();
//      localStorage.setString('access_token', json.encode(body['access_token']));
//      localStorage.setString('user', json.encode(body['user']));
//      Navigator.push(
//        context,
//        new MaterialPageRoute(
//            builder: (context) => Home()
//        ),
//      );
//      await loadToken();
      print("PASSED");
      print(body['access_token']);
      return true;
    } else {
      print("FAILED");
      print(body['message']);
      print(body);
      return false;
    }
  }

  Future<int> createPost(Post post) async {
    var data = {
      'post_content': post.postContent,
      'longitude': post.point.longitude,
      'latitude': post.point.latitude,
    };
    try {
      var response = await postData(data, '/api/posts/');
      return json.decode(response.body)['data'];
    } catch (e) {
      rethrow;
    }
  }

}
