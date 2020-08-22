import 'package:flutter/material.dart';
import 'package:flutterapp/routing/page_route.dart';
import '../authentication_ui/register_form.dart';
import '../authentication_ui/register.dart';
import '../authentication_ui/authentication_page.dart';
import '../map/map_ui.dart';
import '../authentication_ui/login_form.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (context) => FrontPage());
      case '/login_form':
        return MaterialPageRoute(builder: (context) => Login());
//      case '/register_form':
//        return MaterialPageRoute(builder: (context) => Register());
      case '/register_form':
//        return MaterialPageRoute(builder: (context) => getNamePage());
        return SlideRightRoute(widget:getNamePage());
      case '/register_form_email':
        if (args is Register) {
//          return MaterialPageRoute(builder: (context) => getEmailPage(args));
          return SlideRightRoute(widget:getEmailPage(args));
        }
        return null;
      case '/register_form_dob':
        if (args is Register) {
//          return MaterialPageRoute(builder: (context) => getDateOfBirth(args));
          return SlideRightRoute(widget:getDateOfBirth(args));
        }
        return null;
      case '/register_form_dob_fail':
        return MaterialPageRoute(builder: (context) => AgeWarning());
      case '/register_form_password':
        if (args is Register) {
//          return MaterialPageRoute(builder: (context) => getPassword(args));
          return SlideRightRoute(widget:getPassword(args));
        }
        return null;
      case '/map':
        return MaterialPageRoute(builder: (context) => HomePage());
    }
  }
}
