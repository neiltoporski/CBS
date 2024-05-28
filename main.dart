import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Linking files
import 'devs/dev_main_menu.dart';
import 'users/user_main_menu.dart';

// Global variable for account
// This will assist program to know which account to look for data
String accountEmail = "NULL";
String lastName = "NULL";
bool isDev = false;

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LoginTop());
}

class LoginTop extends StatelessWidget {
  const LoginTop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Test",
      home: Login(),
    );
  }
}

// ignore: must_be_immutable
class Login extends StatelessWidget {
  Login({super.key});
  var db = FirebaseFirestore.instance;
  final lastname = TextEditingController();
  final email = TextEditingController();
  bool validate = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Case Based Simulation',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(40.0),
            width: 750,
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(228, 199, 183, 183)),
              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              color: Colors.white,
              boxShadow: const [BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 1.0),
                blurRadius: 6.0
              )]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Case\nBased\nSimulation',
                      style: TextStyle(fontSize: 36),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      width: 200,
                    )
                  ],
                ),
                Container(
                  margin: const EdgeInsets.all(15.0),
                  padding: const EdgeInsets.all(20.0),
                  height: 300,
                  width: 425,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromARGB(228, 199, 183, 183)),
                    borderRadius: const BorderRadius.all(Radius.circular(5.0))
                  ),
                  child: Center(
                    heightFactor: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height: 60,
                          width: 300,
                          child: TextField(
                            decoration:
                                const InputDecoration(labelText: 'Last Name'),
                            controller: lastname,
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          width: 300,
                          child: TextField(
                            decoration:
                                const InputDecoration(labelText: 'Email Address'),
                            controller: email,
                          ),
                        ),
                        // Developers
                        Container(
                          margin: const EdgeInsets.all(15.0),
                          padding: const EdgeInsets.all(0.0),
                          decoration: BoxDecoration(
                            //border: Border.all(color: Colors.grey.shade400),
                            borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                            color: Colors.grey.shade200,
                          ),
                          child: ButtonBar(mainAxisSize: MainAxisSize.min, children: <Widget>[
                            // Signup
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(elevation: 2.5),
                              onPressed: () {
                                bool validate =
                                    lastname.text.isNotEmpty && email.text.isNotEmpty;

                                if (validate) {
                                  //checks if that users exists
                                  db
                                      .collection("devs")
                                      .where("lastname", isEqualTo: lastname.text)
                                      .where("email", isEqualTo: email.text)
                                      .get()
                                      .then(
                                    (QuerySnapshot qs) {
                                      if (qs.size == 0) {

                                        // Code to create new developer (sign up)
                                        final user = <String, dynamic>{
                                          "lastname": lastname.text,
                                          "email": email.text,
                                        };
                                        db
                                            .collection('devs')
                                            .doc(email.text)
                                            .set(user); // Adds dev to database
                                        accountEmail = email.text; // Set account email
                                        lastName = lastname.text;
                                        isDev = true;
                                        runApp(const DevMenu()); // Redirect to dev main menu
                                      } else {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                popupExists(context));
                                      }
                                    },
                                    onError: (e) {},
                                  );
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          popupEmpty(context));
                                }
                              },
                              child: const Text('Developer Signup')
                            ),
                            // Login
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(elevation: 2.5),
                              onPressed: () {
                                bool validate =
                                    lastname.text.isNotEmpty && email.text.isNotEmpty;

                                if (validate) {
                                  //checks if that users exists
                                  db
                                      .collection("devs")
                                      .where("lastname", isEqualTo: lastname.text)
                                      .where("email", isEqualTo: email.text)
                                      .get()
                                      .then(
                                    (QuerySnapshot qs) {
                                      if (qs.size == 0) {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                popupIncorrectCreds(context));
                                      } else {
                                        accountEmail = email.text; // Set account email
                                        lastName = lastname.text;
                                        isDev = true;
                                        runApp(const DevMenu()); // Redirect to dev main menu
                                      }
                                    },
                                    onError: (e) {},
                                  );
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          popupEmpty(context));
                                }
                              },
                              child: const Text('Developer Login'),
                            ),
                          ])
                        ),
                        // Users
                        Container(
                          padding: const EdgeInsets.all(0.0),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                            color: Colors.grey.shade200
                          ),
                          child: ButtonBar(mainAxisSize: MainAxisSize.min, children: <Widget>[
                            // Signup
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(elevation: 2.5),
                              onPressed: () {
                                bool validate =
                                    lastname.text.isNotEmpty && email.text.isNotEmpty;

                                if (validate) {
                                  //checks if that users exists
                                  db
                                      .collection("users")
                                      .where("lastname", isEqualTo: lastname.text)
                                      .where("email", isEqualTo: email.text)
                                      .get()
                                      .then(
                                    (QuerySnapshot qs) {

                                      if (qs.size == 0) {

                                        // Code to create new user (sign up)
                                        final user = <String, dynamic>{
                                          "lastname": lastname.text,
                                          "email": email.text,
                                        };
                                        db
                                            .collection('users')
                                            .doc(email.text)
                                            .set(user); // Adds user to database
                                        accountEmail = email.text; // Set account email
                                        lastName = lastname.text;
                                        isDev = false;
                                        runApp(const UserMenu());       // Redirect to user menu
                                      } else {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                popupExists(context));
                                      }
                                    },
                                    onError: (e) {},
                                  );
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          popupEmpty(context));
                                }
                              },
                              child: const Text('User Signup'),
                            ),
                            // Login
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(elevation: 2.5),
                              onPressed: () {
                                bool validate =
                                    lastname.text.isNotEmpty && email.text.isNotEmpty;

                                if (validate) {
                                  //checks if that users exists
                                  db
                                      .collection("users")
                                      .where("lastname", isEqualTo: lastname.text)
                                      .where("email", isEqualTo: email.text)
                                      .get()
                                      .then(
                                    (QuerySnapshot qs) {
                                      if (qs.size == 0) {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                popupIncorrectCreds(context));
                                      } else {
                                        accountEmail = email.text; // Set account email
                                        lastName = lastname.text;
                                        isDev = false;
                                        runApp(const UserMenu());       // Redirect to user menu
                                      }
                                    },
                                    onError: (e) {},
                                  );
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          popupEmpty(context));
                                }
                              },
                              child: const Text('User Login'),
                            ),
                          ])
                        ),
                      ],
                    ),
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modal for incorrect credentials
  Widget popupIncorrectCreds(BuildContext context) {
    return AlertDialog(
      title: const Text('Your email/password is incorrect.'),
      titlePadding: const EdgeInsets.fromLTRB(35,35,35,20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK')
        )
      ],
    );
  }

  // Modal for empty fields
  Widget popupEmpty(BuildContext context) {
    return AlertDialog(
      title: const Text('Please fill out both fields.'),
      titlePadding: const EdgeInsets.fromLTRB(35,35,35,20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK')
        )
      ],
    );
  }

  // Modal for existing email
  Widget popupExists(BuildContext context) {
    return AlertDialog(
      title: const Text('That email is already connected to an existing account.'),
      titlePadding: const EdgeInsets.fromLTRB(35,35,35,20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
          ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK')
        )
      ],
    );
  }
}
