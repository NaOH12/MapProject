import 'package:flutter/material.dart';
import '../ui_elements.dart';
import '../network/api.dart';

class Login extends StatefulWidget {
  final Network network = Network();

  Login();
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String _email;
  String _password;
  bool isLoginError = false;

  void onSubmit() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      login();
    } else {
      print("Failed validation");
    }
  }

  void login() async {
    bool success = await widget.network.login(_email, _password);
    if (success) {
      isLoginError = false;
//      Navigator.of(context).pushNamed(
//        '/map',
//      );
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/map', (Route<dynamic> route) => false);
    } else {
      setState(() {
        isLoginError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
//    return PageBackDrop();

    return MessageBoard(
      heading: "Welcome back!",
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(flex: 2),
            CurvedFormTextBox(
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              isError: isLoginError,
              validator: (value) {
                Pattern pattern =
                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                RegExp regex = new RegExp(pattern);
                if (!regex.hasMatch(value))
                  return "Please enter a valid email.";
                else {
                  return null;
                }
              },
              onSaved: (String val) {
                _email = val;
              },
            ),
            Spacer(flex: 1),
            CurvedFormTextBox(
              hintText: 'Password',
              keyboardType: TextInputType.visiblePassword,
              isError: isLoginError,
              errorText: "We can't seem to find you.",
              validator: (value) {
                if (value.isEmpty) {
                  return "Password is empty.";
                } else
                  return null;
              },
              onSaved: (String val) {
                _password = val;
              },
            ),
            Spacer(flex: 1),
            logInButton(
                150,
                50,
                "Login",
                Theme.of(context)
                    .textTheme
                    .button
                    .copyWith(color: Colors.white),
                onSubmit),
            Spacer(flex: 5),
          ],
        ),
      ),
    );
  }
}

//return MessageBoard (
//heading: "Pop in your login details",
//body: Form(
//key: _formKey,
//child: Column(
//mainAxisAlignment: MainAxisAlignment.center,
//crossAxisAlignment: CrossAxisAlignment.center,
//mainAxisSize: MainAxisSize.max,
//children: <Widget>[
//Spacer(flex: 5),
//Text(
//"Pop in your login details",
//style: Theme.of(context).textTheme.headline4,
//),
//Spacer(flex: 2),
//TextFormField(
//decoration: InputDecoration(
//labelText: 'Email', errorText: isLoginError ? "" : null),
//style: Theme.of(context).textTheme.headline6,
//keyboardType: TextInputType.emailAddress,
//validator: (value) {
//Pattern pattern =
//r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
//RegExp regex = new RegExp(pattern);
//if (!regex.hasMatch(value))
//return "Please enter a valid email!!";
//else {
//return null;
//}
//},
//onSaved: (String val) {
//_email = val;
//},
//),
//TextFormField(
//decoration: InputDecoration(
//labelText: 'Password',
//errorText: isLoginError ? "Invalid login details" : null),
//style: Theme.of(context).textTheme.headline6,
//keyboardType: TextInputType.visiblePassword,
//validator: (value) {
//if (value.isEmpty) {
//return "Password is empty!!";
//} else
//return null;
//},
//onSaved: (String val) {
//_password = val;
//},
//),
////              Material(
////                elevation: 5.0,
////                borderRadius: BorderRadius.circular(30.0),
////                color: Color(0xff01A0C7),
////                child: RaisedButton(
////                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
////                  onPressed: () {},
////                  child: Text(
////                    "Login",
////                    textAlign: TextAlign.center,
////                    style: Theme.of(context).textTheme.button,
////                  ),
////                ),
////              ),
//Spacer(flex: 1),
//logInButton("Login", Theme.of(context).textTheme.button, onSubmit),
//Spacer(flex: 5),
//],
//),
//),
//);
