import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import 'authentication_ui/authentication_page.dart';

Widget sendButton(double width, double height, VoidCallback callback) {
  return GestureDetector(
      onTap: callback,
      child: Container(
        child: IconTheme(
            data: IconThemeData(color: Colors.white), child: Icon(Icons.send)),
        width: width,
        height: height,
        decoration: new BoxDecoration(
            color: Colors.blue,
            borderRadius: new BorderRadius.all(new Radius.circular(25.7))),
      ));
}

Widget curvedTextBox(double width, double height) {
  return Container(
//      margin: const EdgeInsets.only(left: 30.0, top: 60.0, right:
//      30.0),
//      height: 40.0,
      width: width,
      height: height,
      decoration: new BoxDecoration(
          color: Colors.white,
          borderRadius: new BorderRadius.all(new Radius.circular(25.7))),
      child: TextField(
//            controller: null,
//            autofocus: false,

        style: new TextStyle(fontSize: 22.0, color: Color(0xFF0F0F0F)),
        decoration: new InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: '',
          contentPadding:
              const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
          focusedBorder: OutlineInputBorder(
            borderSide: new BorderSide(color: Colors.white),
            borderRadius: new BorderRadius.circular(25.7),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: new BorderSide(color: Colors.white),
            borderRadius: new BorderRadius.circular(25.7),
          ),
        ),
      ));
}

class CurvedFormTextBox extends FormField<String> {
  CurvedFormTextBox({
    FormFieldSetter<String> onSaved,
    FormFieldValidator<String> validator,
    String initialValue = "",
    bool autovalidate = false,
    TextInputType keyboardType = TextInputType.text,
    String hintText = "",
    double maxWidth = 300,
    double height = 55,
    bool isError = false,
    String errorText = "",
//    onChanged: (String val) => {state.didChange(val), print(val)},
  }) : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: initialValue,
            autovalidate: autovalidate,
            builder: (FormFieldState<String> state) {
              return Container(
//                color: Colors.transparent,
//                shadowColor: Colors.black54,
//                  elevation: 20,
                  child: TextField(
                style: new TextStyle(color: Colors.black),
                onChanged: (String val) => {state.didChange(val), print(val)},
                keyboardType: keyboardType,
                decoration: new InputDecoration(
                    contentPadding: EdgeInsets.only(
                        left: 15.0, right: 8.0, top: 15.0, bottom: 15.0),
                    border: new OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      borderSide: BorderSide(width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      borderSide: BorderSide(width: 2, color: Colors.lightBlue),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      borderSide: BorderSide(width: 0, color: Colors.white),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      borderSide: BorderSide(width: 2, color: Colors.red),
                    ),
                    errorText: state.hasError
                        ? state.errorText
                        : (isError ? errorText : null),
                    filled: true,
                    hintStyle: new TextStyle(color: Colors.grey),
                    hintText: hintText,
                    fillColor: Colors.white),
              ));

            });
}

class CurvedWidget extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  CurvedWidget({this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: new BoxDecoration(
            color: Colors.white,
            borderRadius: new BorderRadius.all(new Radius.circular(25.7))),
        child: child);
  }
}

Widget continueButton(double width, double height, VoidCallback callback) {
  return GestureDetector(
      onTap: callback,
      child: Container(
        child: IconTheme(
            data: IconThemeData(color: Colors.white),
            child: Icon(Icons.arrow_forward_ios)),
        width: width,
        height: height,
        decoration: new BoxDecoration(
            color: Colors.blue,
            borderRadius: new BorderRadius.all(new Radius.circular(25.7))),
      ));
}

Widget signUpButton(double width, double height, String text, TextStyle style,
    VoidCallback callback) {
  return GestureDetector(
      onTap: callback,
      child: Container(
          child: Center(
              child: Text(
            text,
            style: style,
          )),
          width: width,
          height: height,
          decoration: new BoxDecoration(
            color: Colors.blue,
            borderRadius: new BorderRadius.all(new Radius.circular(25.7)),
//            gradient: LinearGradient(
//              colors: [Colors.blue, Colors.lightBlueAccent],
//              stops: [0.0, 0.7],
//              begin: Alignment(0, -1.0),
//              end: Alignment(0, 1.0),
//            ),
          )));
}

Widget logInButtonText(String text, TextStyle style, VoidCallback callback) {
  return GestureDetector(
    onTap: callback,
    child: Center(
        child: Text(
      text,
      style: style,
    )),
  );
}

Widget logInButton(double width, double height, String text, TextStyle style,
    VoidCallback callback) {
  return Container(
      child: CupertinoButton(
        padding: EdgeInsets.only(left: 60.0, right: 60.0, top: 15, bottom: 15),
//    elevation: 5.0,
        color: Colors.blue,
        onPressed: callback,
        borderRadius: new BorderRadius.circular(30.0),
//    shape: RoundedRectangleBorder(
//        borderRadius: BorderRadius.all(Radius.circular(50.0))),
//  padding: inset,
        child: Text(
          text,
          style: style,
        ),
      ),
      decoration: new BoxDecoration(
//        color: Colors.blue,
        borderRadius: new BorderRadius.all(new Radius.circular(25.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(80),
            spreadRadius: 2,
            blurRadius: 20,
            offset: Offset(0, 12), // changes position of shadow
          )
        ],
      ));
}

class MessageBoard extends StatelessWidget {
  final String heading;
  final Widget body;

  MessageBoard({this.heading = "", this.body});

  @override
  Widget build(BuildContext context) {
    return PageBackDrop(
      Padding(
        padding: EdgeInsets.only(left: 10.0, top: 100.0, right: 10.0),
        child: Container(
            padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0),
            decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60))),
            child: Column(
              children: <Widget>[
                Spacer(flex: 4),
                Expanded(
                    child: Text(
                      heading,
                      style: Theme.of(context).textTheme.headline4.copyWith(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    flex: 2),
                Spacer(flex: 1),
                Expanded(child: body, flex: 15),
                Spacer(flex: 4),
              ],
            )),
      ),
      padding: 0.0,
    );
  }
}
