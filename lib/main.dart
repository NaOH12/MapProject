import 'routing/route_generator.dart';
import 'package:flutterapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0x00FFFFFF),
    ));

    return new MaterialApp(
      title: 'Earth App',
      theme: getTheme(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );

  }
}
