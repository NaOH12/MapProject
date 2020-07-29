import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../authentication_ui/register.dart';
import '../network/api.dart';
import '../ui_elements.dart';
import 'authentication_page.dart';
import 'package:intl/intl.dart';

//class Register extends StatefulWidget {
//  final Network network = Network();
//
//  @override
//  _RegisterState createState() => _RegisterState();
//}
//
//class _RegisterState extends State<Register> {
//  final _formKey = GlobalKey<FormState>();
//
//  @override
//  Widget build(BuildContext context) {
//    return PageBackDrop(Form(key: _formKey, child: Container()));
//  }
//}

Widget getNamePage() {
  Network network = Network();
  Register registerData = Register();
  return FormEntryPage(
    key: UniqueKey(),
    nextRoute: '/register_form_email',
    addField: (Register register, String value) => {registerData.name = value},
    registerData: registerData,
    text: "What's your name?",
    inputType: TextInputType.text,
    formValidator: (String val) =>
        (val.isEmpty) ? "Your forgot to say what your name is!" : null,
  );
}

Widget getEmailPage(Register registerData) {
  return FormEntryPage(
    key: UniqueKey(),
    nextRoute: '/register_form_dob',
    addField: (Register register, String value) => {registerData.email = value},
    registerData: registerData,
    text: "What's your email?",
    inputType: TextInputType.emailAddress,
    formValidator: emailValidator,
  );
}

Widget getDateOfBirth(Register registerData) {
  return FormEntryPage(
    key: UniqueKey(),
    nextRoute: '/register_form_password',
    addField: (Register register, String value) => {registerData.email = value},
    registerData: registerData,
    text: "When were you born?",
    isDate: true,
  );
}

Widget getPassword(Register registerData) {
  return FormEntryPage(
    key: UniqueKey(),
    nextRoute: '/register_form_email',
    addField: (Register register, String value) =>
        {registerData.password = value},
    registerData: registerData,
    text: "Choose a password.",
    inputType: TextInputType.visiblePassword,
    formValidator: (String val) =>
        (val.isEmpty || val.length < 10) ? "It needs to be longer!" : null,
    isFinalStage: true,
  );
}

class FormEntryPage extends StatefulWidget {
//  final void Function(String) submitValue;
  final Function(Register, String) addField;
  final String nextRoute;
  final Register registerData;
  final String Function(String) formValidator;
  final TextInputType inputType;
  final String text;
  final String errorText;
  final bool isDate;
  final bool isFinalStage;
  final bool isError;

  FormEntryPage({
    Key key,
    this.nextRoute,
    this.addField,
    this.registerData,
    this.formValidator,
    this.text,
    this.inputType,
    this.errorText,
    this.isDate = false,
    this.isFinalStage = false,
    this.isError = false,
  }) : super(key: key);

  _FormEntryPageState createState() => _FormEntryPageState();
}

class _FormEntryPageState extends State<FormEntryPage> {
  final _formKey = GlobalKey<FormState>();
  String _value;
  DateTime _dateTime = DateTime.now();

  void onSubmit() {
    if (widget.isDate) {
      if (isDateValid(_dateTime)) {
        widget.registerData.dateOfBirth =
            DateFormat('yyyy/MM/dd').format(_dateTime);
        Navigator.of(context).pushNamed(
          widget.nextRoute,
          arguments: widget.registerData,
        );
      } else {
//        Navigator.of(context).pushNamed(
//          '/register_form_dob_fail',
//        );
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/register_form_dob_fail', (Route<dynamic> route) => false);
      }
    } else {
      if (_formKey.currentState.validate()) {
        _formKey.currentState.save();
        widget.addField(widget.registerData, _value);
        if (widget.isFinalStage) {
          register(widget.registerData);
        } else {
          Navigator.of(context).pushNamed(
            widget.nextRoute,
            arguments: widget.registerData,
          );
        }
      }
    }
  }

  bool isDateValid(DateTime submitDate) {
    DateTime currentDate = DateTime.now();
    DateTime threshold =
        DateTime.utc(currentDate.year - 18, currentDate.month, currentDate.day);
    if (submitDate.isBefore(threshold)) {
      return true;
    } else {
      return false;
    }
  }

  void register(Register register) async {
    Network network = Network();
    bool success = await network.register(
        register.name, register.email, register.dateOfBirth, register.password);
    if (success) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/map', (Route<dynamic> route) => false);
    } else {
      Navigator.of(context).pushNamed(
        '/',
      );
    }
  }

  Widget buildTextField() {
    return CurvedFormTextBox(
      hintText: '',
      keyboardType: widget.inputType,
      isError: widget.isError,
      errorText: widget.errorText,
      validator: widget.formValidator,
      onSaved: (String val) {
        _value = val;
      },
    );
  }

//  Widget buildTextFormField() {
//    return TextFormField(
//      style: new TextStyle(fontSize: 22.0, color: Color(0xFF0F0F0F)),
//      decoration: new InputDecoration(
//        filled: true,
//        fillColor: Colors.white,
//        hintText: '',
//        errorText: widget.errorText,
//        contentPadding:
//            const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
//        focusedBorder: OutlineInputBorder(
//          borderSide: new BorderSide(color: Colors.white),
//          borderRadius: new BorderRadius.circular(25.7),
//        ),
//        enabledBorder: UnderlineInputBorder(
//          borderSide: new BorderSide(color: Colors.white),
//          borderRadius: new BorderRadius.circular(25.7),
//        ),
//      ),
////            style: Theme.of(context).textTheme.headline6,
//      keyboardType: widget.inputType,
//      validator: widget.formValidator,
//      onSaved: (String val) {
//        _value = val;
//        print("VALIDATOR CALLED");
//      },
//    );
//  }

  Widget buildDatePicker() {
    return Container(
        height: 100,
        width: 300,
        decoration: new BoxDecoration(
            color: Colors.white,
            borderRadius: new BorderRadius.all(new Radius.circular(25.7))),
        child: CupertinoDatePicker(
          initialDateTime: DateTime.now(),
          maximumDate: DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (DateTime value) {
            _dateTime = value;
//            _dateTime.
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    print(widget.registerData.toString());
    return PageBackDrop(Column(
      mainAxisAlignment: MainAxisAlignment.center,
//      crossAxisAlignment: CrossAxisAlignment.center,
//      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Spacer(flex: 1),
        Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
                onTap: () => {Navigator.pop(context)},
                child: Container(
                  child: IconTheme(
                      data: IconThemeData(color: Colors.white),
                      child: Icon(Icons.chevron_left)),
                  width: 50,
                  height: 50,
//                  decoration: new BoxDecoration(
//                      color: Colors.blue,
//                      borderRadius:
//                          new BorderRadius.all(new Radius.circular(25.7))),
                ))),
        Spacer(flex: 9),
        Text(
          widget.text,
          style: Theme.of(context).textTheme.headline6,
        ),
        Spacer(flex: 2),
        Form(
          key: _formKey,
          child: Row(children: <Widget>[
            Expanded(
              child: widget.isDate ? buildDatePicker() : buildTextField(),
              flex: 20,
            ),
            Spacer(flex: 1),
            continueButton(47, 47, onSubmit),
          ]),
        ),
        Spacer(flex: 11),
      ],
    ));
  }
}

String emailValidator(String email) {
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  if (!regex.hasMatch(email))
    return "You call that an email?";
  else {
    return null;
  }
}

class AgeWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MessageBoard(
      heading: "Sorry.",
      body: Text(
        "It appears you're too young to be using this service. For your safety (and other legal reasons) we cannot allow you to create an account.",
        style:
            Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.black),
      ),
    );
  }
}
