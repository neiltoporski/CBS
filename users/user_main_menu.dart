import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../firebase_options.dart';

import 'package:flutter/material.dart';

import '../main.dart';
import '../nodes/nodes.dart';
import '../nodes/node_functions.dart';
import './user_sim_menu.dart';

Map<String, NodeSim>? map;
String? currSimID;
int maxScore = 0;

//initializes a timer for checking simulation activation status.
Timer enabledTimer = Timer(Duration.zero, () { });

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UserMenu());
}

class UserMenu extends StatelessWidget {
  const UserMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Menu',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'User Menu'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomepageState();
}

class _MyHomepageState extends State<MyHomePage> {
  var db = FirebaseFirestore.instance;
  int? _selectedIndex;
  int? _selectedIndex2;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // creates the row at the top of the screen.
      appBar: AppBar(
        toolbarHeight: 115,
        backgroundColor: Colors.white,
        title: Column(children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            const Text('Case Based Simulation'),
            const SizedBox(width: 100,),
            ElevatedButton(onPressed: () => {logOutWarning(context)}, child: const Text('Log Out', style: TextStyle(color: Colors.black),)),
            ],
          )
        ],),
      ),

    // the simulation display
    body: Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(10.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey)
      ),
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1,
        alignment: FractionalOffset.topLeft,
          child: Column(
            children: <Widget>[
              Flexible(
                child: Container(
                  alignment: FractionalOffset.topLeft,
                  child: Scaffold(
                    // creates the list of simulations available for assessment
                    appBar: AppBar(title: const Text('Available Simulations')),
                    body: Card(
                      // listens for activity (published or edited simulations) and rebuilds when detected.
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('publishedsims').snapshots(),
                        builder: (context,snapshot) {
                          List<ListTile> availSimTiles = [];
                          
                          // while loading, show a progress indicator
                          if(!snapshot.hasData) return const CircularProgressIndicator();

                          // returns a list of all simulations in lexicographical order (capitals separate from lowercase)
                          final pubSimulations = snapshot.data!.docs.reversed.toList();

                          // on refresh, cancels the current timer
                          enabledTimer.cancel();
                          // makes a timer that checks the availbaility every x seconds.
                          enabledTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
                            int now = DateTime.now().millisecondsSinceEpoch;
                            for (var pubSim in pubSimulations) {
                              DocumentReference simRef = db.collection("/devs/${pubSim["owner"]}/Simulations").doc(pubSim["simname"]);
                              DocumentSnapshot sim = await simRef.get();

                              if (sim["enabled"] != pubSim["enabled"]) {
                                pubSim.reference.update({"enabled" : sim["enabled"]});
                              }

                              if ((!sim["manualdisable"] && !pubSim["availableforever"]) && (pubSim["starttime"] != null) && (pubSim["endtime"] != null)) {
                                bool change = ((now < pubSim["endtime"]) && (now > pubSim["starttime"]));
                                if (sim["enabled"] != change){
                                  sim.reference.update({"enabled": change});
                                }
                              }
                            }
                          });

                          // filters out and displays all enabled and published simulations
                          for(var pubSim in pubSimulations) {
                            if (pubSim["enabled"] == true) {
                              String timeLimitString = (!pubSim["notimelimit"]) 
                              ? _printDuration(Duration(minutes: pubSim["timelimit"]))
                              : "Unlimited";
                              String availTime = (!pubSim["availableforever"]) 
                              ? "${DateFormat('yMd').add_jm().format(DateTime.fromMillisecondsSinceEpoch(pubSim["starttime"]))} - ${
                                DateFormat('yMd').add_jm().format(DateTime.fromMillisecondsSinceEpoch(pubSim["endtime"]))}"
                              : "Always Available";
                              String maxAttempts = (!pubSim["unlimitedattempts"]) ? pubSim["maxattempts"].toString() : "Unlimited";
                              
                              // creates a ListTile for the simulation and adds it to the list
                              final simTile = ListTile(
                                title: Text("${pubSim['displayname']}, Time Limit: $timeLimitString (Available: $availTime, Max Attempts: $maxAttempts)"),
                                subtitle: Text("Author: ${pubSim['owner']}"),
                                selectedTileColor: const Color.fromARGB(255, 233, 233, 233),
                                selectedColor: Colors.black,
                                selected: pubSimulations.indexOf(pubSim) == _selectedIndex,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = pubSimulations.indexOf(pubSim);
                                  });
                                },
                                trailing: (_selectedIndex == pubSimulations.indexOf(pubSim)) 
                                  ? FractionallySizedBox(
                                      widthFactor: 0.12,
                                      heightFactor: 0.6,
                                      alignment: FractionalOffset.centerRight,
                                      child: ElevatedButton(
                                        // checks availability in case of simulation access between timer updates.
                                        // Additionally checks if maxAttempts have been reached, and if so, denies access to the sim.
                                        onPressed: () async {
                                          DocumentReference simRef = db.collection("/devs/${pubSim["owner"]}/Simulations").doc(pubSim["simname"]);
                                          DocumentSnapshot sim = await simRef.get();
                                          int now = DateTime.now().millisecondsSinceEpoch;
                                          bool change = false;
                                          bool maxed = false;

                                          if (sim["enabled"] != pubSim["enabled"]) {
                                            pubSim.reference.update({"enabled" : sim["enabled"]});
                                          }

                                          if ((!sim["manualdisable"] && !pubSim["availableforever"]) && (pubSim["starttime"] != null) && (pubSim["endtime"] != null)) {
                                            change = ((now < pubSim["endtime"]) && (now > pubSim["starttime"]));
                                            if (sim["enabled"] != change){
                                              sim.reference.update({"enabled": change});
                                            }
                                          } else if ((!sim["manualdisable"] && pubSim["availableforever"])) {
                                            change = pubSim["availableforever"];
                                            if (sim["enabled"] != change){
                                              sim.reference.update({"enabled": change});
                                            }
                                          }

                                          if (!pubSim["unlimitedattempts"] && pubSim["enabled"]) {
                                            var attemptRef = pubSim.reference.collection('results/$accountEmail/attempts');
                                            var attemptSnapshot = await attemptRef.get();
                                            var attempts = attemptSnapshot.docs.reversed.toList();

                                            if (attempts.length >= pubSim["maxattempts"]) {
                                              maxed = true;
                                            }
                                          }

                                          if (change && !maxed) {
                                            enabledTimer.cancel();
                                            currSimID = pubSim.id;
                                            simTimeLimit = pubSim['timelimit'];
                                            map = await createSimulationObjects("users", pubSim['owner'], pubSim['simname']);
                                            maxScore = pubSim['maxscore'];
                                            runApp(const UserSimMenu());
                                          } else {simError(context, pubSim, change, maxed);}
                                        },
                                        child: const Text('Enter Simulation'),
                                      ),
                                    )
                                  : null
                              );
                              
                              // adds the ListTile to the List
                              availSimTiles.add(simTile);
                            }
                          }
                          
                          // returns the list in a listview
                          return (availSimTiles.isNotEmpty)
                            ? ListView(children: availSimTiles.reversed.toList())
                            // if the list is empty, return a message.
                            : Container(
                                margin: const EdgeInsets.all(10.0),
                                padding: const EdgeInsets.all(10.0),
                                alignment: Alignment.topLeft,
                                child: const Text('You currently have no simulations available to complete.')
                              );
                        }
                      )
                    )
                  )
                )
              ),
              Flexible(
                child: Container(
                  alignment: FractionalOffset.bottomLeft,
                  child: Scaffold(
                    // the list of results from previously completed simulations (COMPLETELY INDEPENDENT FROM THE OTHER HALF)
                    appBar: AppBar(title: const Text('Saved Results')),
                    body: Card(
                      // Listens in on the user's personal results collection
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users/$accountEmail/results').snapshots(),
                        builder: (context,snapshot) {
                          List<ListTile> savedScoreSimTiles = [];
                          
                          if(!snapshot.hasData) return const CircularProgressIndicator();

                          // fetches all saved results and sorts in lexicographical order with capitals separate from lowercase
                          final savedScores = snapshot.data!.docs.reversed.toList();

                          // creates a ListTile for each result found
                          for(var score in savedScores) {
                            final simTile = ListTile(
                              title: Text(score['displayname']),
                              subtitle: Text("Completed: ${DateFormat.yMd().add_jm().format(score['completed'].toDate())}"),
                              selectedTileColor: const Color.fromARGB(255, 233, 233, 233),
                              selectedColor: Colors.black,
                              selected: savedScores.indexOf(score) == _selectedIndex2,
                              onTap: () {
                                setState(() {
                                  _selectedIndex2 = savedScores.indexOf(score);
                                });
                              },
                              trailing: (_selectedIndex2 == savedScores.indexOf(score)) 
                                ? FractionallySizedBox(
                                    widthFactor: 0.15,
                                    heightFactor: 0.6,
                                    alignment: FractionalOffset.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        var simRef = db.collection("/publishedsims/").doc(score.id);
                                        var sim = await simRef.get();

                                        // if the simulation cooresponding with the result is still published/enabled, this result is unable to be deleted.
                                        bool stillAround = sim.exists;
                                        if (sim.exists) {
                                          stillAround = sim["enabled"];
                                        }

                                        // show the latest/best score
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            scrollable: true,
                                            title: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("Latest Result on ${score['displayname']}"),
                                                const Text('You can only remove your attempt if its simulation is deleted.',textScaler: TextScaler.linear(0.65))
                                              ]
                                            ),
                                            content: Container(
                                              height: 100,
                                              width: 200,
                                              margin: const EdgeInsets.all(10.0),
                                              padding: const EdgeInsets.all(10.0),
                                              alignment: Alignment.center,
                                              child: Builder(builder: (context) {
                                                String userScore = score['score'].toString();
                                                String maxScore = score['maxscore'].toString();

                                                return Text("$userScore out of $maxScore", style: const TextStyle(fontSize: 25),);
                                              })
                                            ),
                                            actions: <Widget>[
                                              OverflowBar(
                                                alignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),

                                                  // if the simulation is not around, allow for deletion.
                                                  ElevatedButton(
                                                      onPressed: (!stillAround) 
                                                      ? () {
                                                          deleteAttemptWarning(context, score);
                                                        } 
                                                      : null,
                                                      child: const Text('Remove Attempt'),
                                                    )
                                                  
                                                ]
                                              )
                                            ],
                                          )
                                        );
                                      },
                                      child: const Text("Display Latest Result"),
                                    ),
                                  )
                                : null
                            );

                            // add the listTile to the list.
                            savedScoreSimTiles.add(simTile);
                          }
                          
                          return (savedScoreSimTiles.isNotEmpty)
                            // return the listview
                            ? ListView(children: savedScoreSimTiles.reversed.toList())
                            // if the listview is empty, return a message.
                            : Container(
                                margin: const EdgeInsets.all(10.0),
                                padding: const EdgeInsets.all(10.0),
                                alignment: Alignment.topLeft,
                                child: const Text('You currently have no simulations available to complete.')
                              );
                        }
                      )
                    )
                  )
                )
              ),
            ]
          )
        )
      )
    );
  }
}

// a simple error message for a sim that has been found inaccessible.
Future<void> simError(BuildContext context, DocumentSnapshot pubSim, bool change, bool maxed) async {
  String message = "Simulation ${pubSim["displayname"]} unavailable.";
  if (maxed && change) {
    message = 'You have reached the max attempts for the simulation ${pubSim["displayname"]}.';
  }

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: Text(message),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// warning for deleting an attempt
deleteAttemptWarning(BuildContext context, DocumentSnapshot score) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: const Text('Are you sure you wish to delete this attempt?'),
      actions: <Widget>[
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                score.reference.delete();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ]
        )
      ],
    ),
  );
}

/// Display to confirm that the user wants to log out of the application
logOutWarning(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: const Text('Are you sure you wish to log out?'),
      actions: <Widget>[
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                enabledTimer.cancel();
                runApp(const LoginTop());
                Navigator.pop(context);
              },
              child: const Text('Log Out'),
            ),
          ]
        )
      ],
    ),
  );
}

// return the string of a passed duration in the specified format
String _printDuration(Duration duration) {
  String negativeSign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  //String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  //return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes";
}
