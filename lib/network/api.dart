import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Network {
  final String _url = 'https://noah.business';
  var _token;

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

  authData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    return await http.post(fullUrl,
        body: jsonEncode(data), headers: _setHeaders());
  }

  getData(apiUrl) async {
    var fullUrl = _url + apiUrl;
    await loadToken();
    return await http.get(fullUrl, headers: _setHeaders());
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token'
      };

  Future<bool> login(String email, String password) async {
    var data = {'email': email, 'password': password};

    var res = await Network().authData(data, '/api/login');
    Map<String, dynamic> body = json.decode(res.body);
    if (body['success']) {
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

    var res = await Network().authData(data, '/api/register');

    Map<String, dynamic> body = json.decode(res.body);
    if (body['success']) {
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
}
