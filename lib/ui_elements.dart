import 'package:flutter/material.dart';

TextFormField curvedTextBox() {
  return new TextFormField(
      decoration: new InputDecoration(
        labelText: "",
        fillColor: Colors.white,
        border: new OutlineInputBorder(
          borderRadius: new BorderRadius.circular(25.0),
          borderSide: BorderSide(
            width: 5,
            style: BorderStyle.solid,
            color: Colors.red,
          ),
        ),
      ),
      validator: (val) {
        if (val.length == 0) {
          return "Message cannot be empty";
        } else {
          return null;
        }
      },
      keyboardType: TextInputType.text,
      style: new TextStyle(
        fontFamily: "Poppins",
      ));
}
