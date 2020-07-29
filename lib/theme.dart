import 'package:flutter/material.dart';

ThemeData getTheme() {
  return ThemeData(
      primarySwatch: Colors.teal,
      // Define the default brightness and colors.
      brightness: Brightness.dark,
      primaryColor: Colors.lightBlue[800],
      accentColor: Colors.cyan[600],

      // Define the default font family.
      fontFamily: 'Georgia',

      // Define the default TextTheme. Use this to specify the default
      // text styling for headlines, titles, bodies of text, and more.
      textTheme: TextTheme(
//            headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
//            headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
//            bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        headline1: TextStyle(
            debugLabel: 'whiteCupertino headline1',
            fontFamily: '.SF UI Display',
            inherit: true,
            color: Colors.white70,
            decoration: TextDecoration.none),
        headline2: TextStyle(
            debugLabel: 'whiteCupertino headline2',
            fontFamily: '.SF UI Display',
            inherit: true,
            color: Colors.white70,
            decoration: TextDecoration.none),
        headline3: TextStyle(
            debugLabel: 'whiteCupertino headline3',
            fontFamily: '.SF UI Display',
            inherit: true,
            color: Colors.white70,
            decoration: TextDecoration.none),
        headline4: TextStyle(
            debugLabel: 'whiteCupertino headline4',
            fontFamily: '.SF UI Display',
            inherit: true,
            color: Colors.white70,
            decoration: TextDecoration.none),
        headline5: TextStyle(
            debugLabel: 'whiteCupertino headline5',
            fontFamily: '.SF UI Display',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        headline6: TextStyle(
            debugLabel: 'whiteCupertino headline6',
            fontFamily: '.SF UI Display',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        subtitle1: TextStyle(
            debugLabel: 'whiteCupertino subtitle1',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        bodyText1: TextStyle(
            debugLabel: 'whiteCupertino bodyText1',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        bodyText2: TextStyle(
            debugLabel: 'whiteCupertino bodyText2',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        caption: TextStyle(
            debugLabel: 'whiteCupertino caption',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white70,
            decoration: TextDecoration.none),
        button: TextStyle(
            debugLabel: 'whiteCupertino button',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        subtitle2: TextStyle(
            debugLabel: 'whiteCupertino subtitle',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
        overline: TextStyle(
            debugLabel: 'whiteCupertino overline',
            fontFamily: '.SF UI Text',
            inherit: true,
            color: Colors.white,
            decoration: TextDecoration.none),
      ));
}
