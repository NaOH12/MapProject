import 'dart:collection';

import 'package:flutter/material.dart';
import '../network/api.dart';
import '../ui_elements.dart';

class FrontPage extends StatelessWidget {
  Widget build(BuildContext context) {
    Network network = Network();

    return FutureBuilder(
      future: network.loadToken(),
      builder: (context, data) {
        if (data.connectionState == ConnectionState.done) {
          return EntryPage(
              () => {
                    Navigator.of(context).pushNamed(
                      '/register_form',
                    )
                  },
              () => {
                    Navigator.of(context).pushNamed(
                      '/login_form',
                    )
                  });
        } else {
          return Container();
        }
      },
    );
  }
}

class PageBackDrop extends StatelessWidget {
  final Widget child;
  final double padding;
  PageBackDrop(this.child, {this.padding=15.0});
//  _PageBackDropState createState() => _PageBackDropState();
//}
//
//class _PageBackDropState extends State<PageBackDrop> {
  @override
  Widget build(BuildContext context) {
    return Material(
        child: Container(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: child,
      ),
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [Colors.blue, Colors.deepPurple],
        stops: [0.3, 1],
        begin: Alignment(-1.0, -1.0),
        end: Alignment(1.0, 1.0),
      )),
    ));
  }
}

class EntryPage extends StatelessWidget {
  final VoidCallback onClickEntrySignUp;
  final VoidCallback onClickEntryLogIn;

  EntryPage(this.onClickEntrySignUp, this.onClickEntryLogIn);

  @override
  Widget build(BuildContext context) {
    return PageBackDrop( Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Spacer(flex: 8),
        Center(
          child: Text(
            "Map.",
            style: Theme.of(context).textTheme.headline2.copyWith(color: Colors.white),
          ),
        ),
        Spacer(flex: 10),
        signUpButton(300, 47, "Sign up", Theme.of(context).textTheme.button,
            onClickEntrySignUp),
        Spacer(flex: 1),
        logInButtonText("Already got an account?",
            Theme.of(context).textTheme.button, onClickEntryLogIn),
        Spacer(flex: 2),
      ],
    ));
  }
}
