import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

Widget sendButton(double width, double height, VoidCallback callback) {
//  return FlatButton(
//        color: Colors.blue,
//        textColor: Colors.white,
//        disabledColor: Colors.grey,
//        disabledTextColor: Colors.black,
////        padding: EdgeInsets.all(8.0),
//        splashColor: Colors.blueAccent,
//        onPressed: () {
//          /*...*/
//        },
//        child: Text(
//          "",
//          style: TextStyle(fontSize: 20.0),
//        ),
//      );
  return GestureDetector(
      onTap: callback,
      child: Container(
        child: IconTheme(
            data: IconThemeData(color: Colors.white),
            child: Icon(Icons.send)),
        width: width,
        height: height,
        decoration: new BoxDecoration(
            color: Colors.blue,
            borderRadius: new BorderRadius.all(new Radius.circular(25.7))),
      ));
}

Widget curvedTextBox(double width, double height) {
//  return new TextFormField(
//      textAlign: TextAlign.center,
//      decoration: new InputDecoration(
//        labelText: "",
//        hintText: "Message",
//        fillColor: Colors.white,
////        border: new OutlineInputBorder(
////          borderRadius: new BorderRadius.circular(25.0),
////          borderSide: BorderSide(
////            width: 5,
////            style: BorderStyle.solid,
////            color: Colors.red,
////          ),
////        ),
//      ),
////      validator: (val) {
////        if (val.length == 0) {
////          return "Message cannot be empty";
////        } else {
////          return null;
////        }
////      },
////      keyboardType: TextInputType.text,
////      style: new TextStyle(
////        fontFamily: "Poppins",
////      ));
//  );
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
