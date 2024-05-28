import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../users/user_main_menu.dart';
import './create_sim.dart';
import './create_sim_functions.dart';
import './results.dart';
import './dev_menu_functions.dart';
import '../nodes/nodes.dart';
import '../nodes/node_functions.dart';
import '../users/user_sim_menu.dart';

// Global vars
bool isNew = true;
Map<String, NodeSim>? simulationMap;
Map<String, LinkedList>? nodeMap;
String simName = "";
Timer enabledTimer = Timer(Duration.zero, () { });

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DevMenu());
}

class DevMenu extends StatelessWidget {
  const DevMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Developer Menu',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Developer Menu'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 115,
        backgroundColor: Colors.white,
        title: Column(children: [
          // Header bar for the application
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            const Text('Case Based Simulation'),
            const SizedBox(width: 100,),
            TextButton(onPressed: () => {
              isNew = true,
              newSimPopUp(context)
              
              }, child: const Text('New', style: TextStyle(color: Colors.black),)),
            TextButton(onPressed: () => {logOutWarning(context)}, child: const Text('Log Out', style: TextStyle(color: Colors.black),)), 
            ],
          )
        ],),
      ),

    // displays a refreshable list of simulations
    body: Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(10.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey)
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('/devs/$accountEmail/Simulations').snapshots(),
        builder: (context,snapshot) {
          List<ListTile> simTiles = [];
          List<ListTile> pubSimTiles = [];
          
          if(!snapshot.hasData) return const CircularProgressIndicator();

          final simulations = snapshot.data!.docs.reversed.toList();

          //sets a timer that automatically checks for changes in status as if a simulation is due
          enabledTimer.cancel();
          enabledTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
            int now = DateTime.now().millisecondsSinceEpoch;
            for (var sim in simulations) {
              if (sim["published"]) {
                DocumentReference pubSimRef = db.collection("/publishedsims/").doc(sim.get('simID'));
                DocumentSnapshot pubSim = await pubSimRef.get();

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
            }
          });
          // splits off sims that have been published from sims that have not been published, creating two lists
          for(var sim in simulations) {
            if (sim["published"] == false) {
              final simTile = ListTile(
                title: Text(sim.id),
                subtitle: Text("Author: $accountEmail"),
                selectedTileColor: const Color.fromARGB(255, 233, 233, 233),
                selectedColor: Colors.black,
                selected: simulations.indexOf(sim) == _selectedIndex,
                onTap: () {
                  setState(() {
                    _selectedIndex = simulations.indexOf(sim);
                  });
                },
                trailing: (_selectedIndex == simulations.indexOf(sim)) 
                  ? FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      alignment: FractionalOffset.centerRight,
                      child: ButtonBar(
                        mainAxisSize: MainAxisSize.min,
                        alignment: MainAxisAlignment.end,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: (true) ? () async {
                              enabledTimer.cancel();
                              simulationMap = await createSimulationObjects("devs", accountEmail, sim.id);
                              nodeMap = createGraph(simulationMap);
                              simName = sim.id;
                              isNew = false;
                              runApp(const SimMenu());
                            }
                            // ignore: dead_code
                            : null,
                            child: const Text('Edit'),
                          ),
                          ElevatedButton(
                            onPressed: (true) ? () async {
                              List<String>? invalidNodes;
                              map = await createSimulationObjects("devs", accountEmail, sim.id);
                              nodeMap = createGraph(simulationMap);
                              
                              setState(() {
                                invalidNodes = checkSimulationIntegrity(map);
                              });
                              (invalidNodes!.isEmpty) 
                                ? {enabledTimer.cancel(), maxScore = checkOptimalPath(createGraph(map)).getScore(), runApp(const UserSimMenu())} 
                                : simulationIntegrityDisplay(context);
                            }
                            // ignore: dead_code
                            : null,
                            child: const Text("Test"),
                          ),
                          ElevatedButton(
                            // ignore: dead_code
                            onPressed: () async {
                              removeSimWarning(sim.id, context);
                            },
                            child: const Text("Remove"),
                          ),
                        ],
                      ),
                    )
                  : null
              );

              simTiles.add(simTile);
              // second list starts here
            } else if (sim["published"] == true) {
              final simTile = ListTile(
                title: Text('${sim.id} (Published as "${sim["displayname"]}")'),
                subtitle:  Text((sim["enabled"]) 
                           ? "Enabled, Time Limit: ${sim["timelimit"]} (Available: ${sim["availtime"]}, Max Attempts: ${sim["availattempts"]})" 
                           : !sim["manualdisable"] 
                             ? "Disabled, Time Limit: ${sim["timelimit"]} (Available: ${sim["availtime"]}, Max Attempts: ${sim["availattempts"]})" 
                             : "Manually Disabled (Will not turn on unless reactivated.)"),
                selectedTileColor: Colors.grey.shade300,
                textColor: (sim["enabled"]) ?  Colors.black : Colors.grey.shade500,
                selectedColor: (sim["enabled"]) ?  Colors.black : Colors.grey.shade500,
                selected: simulations.indexOf(sim) == _selectedIndex,
                onTap: () {
                  setState(() {
                    _selectedIndex = simulations.indexOf(sim);
                  });
                },
                trailing: (_selectedIndex == simulations.indexOf(sim)) 
                  ? FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      alignment: FractionalOffset.centerRight,
                      child: ButtonBar(
                        mainAxisSize: MainAxisSize.min,
                        alignment: MainAxisAlignment.end,
                        children: <Widget>[
                          (sim["enabled"]) 
                          ? ElevatedButton(
                            onPressed: () async {
                              deactivateWarning(sim.id, context);
                            },
                            child: const Text('Deactivate'),
                          )
                          : ElevatedButton(
                            onPressed: () async {
                              activatePopUp(context, sim.id);
                            },
                            child: const Text('Activate'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              unpublishWarning(sim.id, context);
                            },
                            child: const Text('Unpublish'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              List<String>? invalidNodes;
                              nodeMap = createGraph(simulationMap);
                              simName = sim.id;
                              currSimID = sim.id;
                              map = await createSimulationObjects("devs", accountEmail, sim.id);

                              setState(() {
                                invalidNodes = checkSimulationIntegrity(map);
                              });
                              (invalidNodes!.isEmpty)
                                ? {enabledTimer.cancel(), maxScore = checkOptimalPath(createGraph(map)).getScore(), runApp(const UserSimMenu())} 
                                : simulationIntegrityDisplay(context);
                            },
                            child: const Text("Test"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              resultsDialog(context, sim.id, sim['simID']);
                            },
                            child: const Text("Results"),
                          ),
                          ElevatedButton(
                            // ignore: dead_code
                            onPressed: () {
                              removeSimWarning(sim.id, context);
                            },
                            child: const Text("Remove"),
                          ),
                        ],
                      ),
                    )
                  : null
              );

              pubSimTiles.add(simTile);
            }
          }
          
          //displays the resulting two lists
          return FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 1,
            alignment: FractionalOffset.topLeft,
            child: Column(
              children: <Widget>[
                Flexible(
                  child: Container(
                    alignment: FractionalOffset.topLeft,
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Unpublished Simulations')),
                      body: Card(
                        child: (simTiles.isNotEmpty)
                        ? ListView(children: simTiles.reversed.toList())
                        : Container(
                            margin: const EdgeInsets.all(10.0),
                            padding: const EdgeInsets.all(10.0),
                            alignment: Alignment.topLeft,
                            child: const Text('You currently have no unpublished simulations. Create one by pressing New.')
                          )
                      )
                    )
                  )
                ),
                Flexible(
                  child: Container(
                    alignment: FractionalOffset.bottomLeft,
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Published Simulations')),
                      body: Card(
                        child: (pubSimTiles.isNotEmpty) 
                        ? ListView(children: pubSimTiles.reversed.toList())
                        : Container(
                            margin: const EdgeInsets.all(10.0),
                            padding: const EdgeInsets.all(10.0),
                            alignment: Alignment.topLeft,
                            child: const Text('You currently have no simulations published. Publish one by pressing Edit, then Publish.')
                          )
                      )
                    )
                  )
                )
              ]
            )
          );
        }
      )
    ),
  );
}
}

//displays if the simulation is unable to be tested.
simulationIntegrityDisplay(context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Center(child: Text('Invalid Simulation Integrity')),
        content: SizedBox(
          width: MediaQuery.of(context).size.width *
              0.3, // 30% of the screen width
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Ensure that the simulation is complete before attempting to test. Please click 'Edit' and then 'Check Simulation Integrity' to find nodes with problems.",
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    }
  );
}

// the dialog for creating a new simulation
newSimPopUp (BuildContext context) {
  var scenarioName = TextEditingController();
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.all(24.0),
      title: const Text('Enter Simulation Name:'),
      content: SizedBox(
        height: 85,
        width: 400,
        child: TextField(decoration: const InputDecoration(labelText: 'Enter name here'),
          maxLength: 24,
          controller: scenarioName,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            final newSim = <String, dynamic>{
              "simID": const Uuid().v4(),
              "published": false,
              "enabled" : true,
              "displayname": scenarioName.text,
              "availtime" : null,
              "availattempts" : null,
              "manualdisable" : false
            };
            scenarioName.text.isNotEmpty?
            {
              simName = scenarioName.text,
              db.collection('devs').doc(accountEmail).collection('Simulations').doc(scenarioName.text).set(newSim),
              runApp(const SimMenu()),
              scenarioName.clear()
            } 
            : null;
          },
          child: const Text('Create Simulation'),
        ),
      ],
    ),
  );
}

//warns the developer about deleting a simulation.
removeSimWarning(String simIdentifier, BuildContext context) {
  // TextEditingController confirmName = TextEditingController();
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you wish to PERMANENTLY delete "$simIdentifier"?'),
          const Text('THIS ACTION IS IRREVERSIBLE.',textScaler: TextScaler.linear(0.65),)
        ]
      ),
      /*content: const SizedBox(
        height: 60,
        width: 400,
        child: TextField(decoration: InputDecoration(labelText: 'To confirm this action, enter "$simIdentifier" here'), 
          controller: confirmName,
        ),
      ),*/
      actions: <Widget>[
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                /*(confirmName.text == simIdentifier) 
                  ? {deleteSim(simIdentifier), Navigator.pop(context)}
                  : null;*/
                deleteSim(simIdentifier);
                Navigator.pop(context);
              },
              child: const Text('Remove Simulation'),
            ),
          ]
        )
      ],
    ),
  );
}

// log out confirmation
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
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

//warns the developer about the consequences of unpublishing
unpublishWarning(String simIdentifier, BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you wish to unpublish "$simIdentifier"?'),
          const Text('THIS ACTION WILL REMOVE ALL USER RESULTS.',textScaler: TextScaler.linear(0.65),)
        ]
      ),
      actions: <Widget>[
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                unpublish(simIdentifier);
                Navigator.pop(context);
              },
              child: const Text('Unpublish Simulation'),
            ),
          ]
        )
      ],
    ),
  );
}

// warns the developer about sim deactivation
deactivateWarning(String simIdentifier, BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you wish to deactivate "$simIdentifier"?'),
          const Text('Users will be unable to interact with this simulation until it is reactivated.',textScaler: TextScaler.linear(0.65),)
        ]
      ),
      actions: <Widget>[
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                var sim = db.collection('/devs/$accountEmail/Simulations/').doc(simIdentifier);
                sim.update({"enabled": false});
                sim.update({"manualdisable" : true});
                Navigator.pop(context);
              },
              child: const Text('Deactivate Simulation'),
            ),
          ]
        )
      ],
    ),
  );
}

// pop up for altering sim due date and max attempts
Future activatePopUp(BuildContext context, String simIdentifier) async {
  DocumentReference simRef = db.collection('/devs/$accountEmail/Simulations/').doc(simIdentifier);
  DocumentSnapshot sim = await simRef.get();
  DocumentReference pubSimRef = db.collection("/publishedsims/").doc(sim.get('simID'));
  DocumentSnapshot pubSim = await pubSimRef.get();

  bool noTime = pubSim.get('notimelimit');
  int? currTimeLimit = pubSim.get('timelimit');
  TextEditingController timeLimitInput = TextEditingController(text: (currTimeLimit != null) ? currTimeLimit.toString() : "");

  bool isForever = pubSim.get('availableforever');
  int? milliStartTime = pubSim.get('starttime');
  int? milliEndTime = pubSim.get('endtime');
  DateTime? currStartDateTime = (milliStartTime != null) ? DateTime.fromMillisecondsSinceEpoch(milliStartTime) : null;
  DateTime? currEndDateTime = (milliEndTime != null) ? DateTime.fromMillisecondsSinceEpoch(milliEndTime) : null;
  TextEditingController startDateInput = TextEditingController(text: (currStartDateTime != null) ? DateFormat('MM-dd-yyyy').format(currStartDateTime) : "");
  TextEditingController startTimeInput = TextEditingController(text: (currStartDateTime != null) ? DateFormat("jm").format(currStartDateTime) : "");
  TextEditingController endDateInput = TextEditingController(text: (currEndDateTime != null) ? DateFormat('MM-dd-yyyy').format(currEndDateTime) : "");
  TextEditingController endTimeInput = TextEditingController(text: (currEndDateTime != null) ? DateFormat("jm").format(currEndDateTime) : "");

  bool isUnlimited = pubSim.get('unlimitedattempts');
  TextEditingController attemptInput = TextEditingController(text: (pubSim.get('maxattempts') != null) ? pubSim.get('maxattempts').toString() : "");

  DateTime startDate = currStartDateTime ?? DateTime.now();
  DateTime endDate = currEndDateTime ?? DateTime.now().add(const Duration(days: 7));
  TimeOfDay startTime = (currStartDateTime != null) ? TimeOfDay.fromDateTime(currStartDateTime) : TimeOfDay.now();
  TimeOfDay endTime = (currEndDateTime != null) ? TimeOfDay.fromDateTime(currEndDateTime) : const TimeOfDay(hour: 23, minute: 59);

  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.all(24.0),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Activate "$simIdentifier"'),
        const Text(
          'This will allow users to complete the simulation',
          textScaler: TextScaler.linear(0.65),
        )
      ]),
      content: StatefulBuilder (
        builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(5),
          height: 360,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    Text('Availability', style: TextStyle(fontSize: 20)),
                    Text('When these conditions are not met, users cannot complete simulations.', textScaler: TextScaler.linear(0.85))
                  ]
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Time Limit (in minutes): '),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(left: 10),
                        height: 50,
                        width: 80,
                        child: TextField(
                          controller: timeLimitInput,
                          enabled: !noTime,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4)
                          ],
                          minLines: 1,
                          expands: false,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                        )
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: noTime, 
                              onChanged: (bool? value) {
                                setState(() {
                                  noTime = value!;
                                });
                              }
                            ),
                            const Text('Unlimited Time?')
                          ]
                        )
                      ),
                    ]
                  )
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: TextField(
                          controller: startDateInput, //editing controller of this TextField
                          decoration: const InputDecoration( 
                            icon: Icon(Icons.calendar_today), //icon of text field
                            labelText: "Enter Start Date" //label text of field
                          ),
                          readOnly: true,  //set it true, so that user will not able to edit text
                          enabled: !isForever,
                          onTap: () async {
                            DateTime? pickedStartDate = await showDatePicker(
                              context: context, initialDate: currStartDateTime ?? DateTime.now(),
                              firstDate: (currStartDateTime != null) ? currStartDateTime : DateTime.now(), //DateTime.now() - not to allow to choose before today.
                              lastDate: DateTime.now().add(const Duration(days: 30))
                            );
                        
                            if(pickedStartDate != null){
                              startDate = pickedStartDate;
                              String formattedDate = DateFormat('MM-dd-yyyy').format(pickedStartDate); 
                                //you can implement different kind of Date Format here according to your requirement

                              setState(() {
                                startDateInput.text = formattedDate; //set output date to TextField value. 
                              });
                            }
                          }
                        )
                      )
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                        child: TextField(
                          controller: startTimeInput, //editing controller of this TextField
                          decoration: const InputDecoration( 
                            icon: Icon(Icons.schedule), //icon of text field
                            labelText: "Enter Start Time" //label text of field
                          ),
                          readOnly: true,  //set it true, so that user will not able to edit text
                          enabled: !isForever,
                          onTap: () async {
                            TimeOfDay? pickedStartTime = await showTimePicker(
                              initialTime: (currStartDateTime != null) ? TimeOfDay.fromDateTime(currStartDateTime) : TimeOfDay.now(),
                              context: context,
                            );
                            if(pickedStartTime != null){
                              startTime = pickedStartTime;
                              DateTime tempDate = DateFormat("Hm").parse('${pickedStartTime.hour.toString()}:${pickedStartTime.minute.toString()}');
                              var dateFormat = DateFormat("jm"); // you can change the format here

                              setState(() {
                                startTimeInput.text = dateFormat.format(tempDate); //set output date to TextField value. 
                              });
                            }
                          }
                        )
                      )
                    ),
                  ]
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                        child: TextField(
                          controller: endDateInput, //editing controller of this TextField
                          decoration: const InputDecoration( 
                            icon: Icon(Icons.event_busy), //icon of text field
                            labelText: "Enter End Date" //label text of field
                          ),
                          readOnly: true,  //set it true, so that user will not able to edit text
                          enableInteractiveSelection: false,
                          enabled: !isForever,
                          onTap: () async {
                            DateTime? pickedEndDate = await showDatePicker(
                              context: context, initialDate: currEndDateTime ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: (currEndDateTime != null) ? currEndDateTime : DateTime.now().add(const Duration(days: 1)), //DateTime.now() - not to allow to choose before today.
                              lastDate: DateTime.now().add(const Duration(days: 365))
                            );
                        
                            if(pickedEndDate != null ){
                              endDate = pickedEndDate;
                              String formattedDate = DateFormat('MM-dd-yyyy').format(pickedEndDate); 
                                //you can implement different kind of Date Format here according to your requirement

                              setState(() {
                                endDateInput.text = formattedDate; //set output date to TextField value. 
                              });
                            }
                          }
                        )
                      )
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                        child: TextField(
                          controller: endTimeInput, //editing controller of this TextField
                          decoration: const InputDecoration( 
                            icon: Icon(Icons.alarm), //icon of text field
                            labelText: "Enter End Time" //label text of field
                          ),
                          readOnly: true,  //set it true, so that user will not able to edit text
                          enabled: !isForever,
                          onTap: () async {
                            TimeOfDay? pickedEndTime = await showTimePicker(
                              initialTime: (currEndDateTime != null) ? TimeOfDay.fromDateTime(currEndDateTime) : TimeOfDay.now(),
                              context: context,
                            );
                            if(pickedEndTime != null){
                              endTime = pickedEndTime;
                              DateTime tempDate = DateFormat("Hm").parse('${pickedEndTime.hour.toString()}:${pickedEndTime.minute.toString()}');
                              var dateFormat = DateFormat("jm"); // you can change the format here

                              setState(() {
                                endTimeInput.text = dateFormat.format(tempDate); //set output date to TextField value. 
                              });
                            }
                          }
                        )
                      )
                    ),
                  ]
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: isForever, 
                        onChanged: (bool? value) {
                          setState(() {
                            isForever = value!;
                          });
                        }
                      ),
                      const Text('Available Forever?')
                    ]
                  )
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Maximum Attempts: '),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(left: 10),
                        height: 50,
                        width: 60,
                        child: TextField(
                          controller: attemptInput,
                          enabled: !isUnlimited,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2)
                          ],
                          minLines: 1,
                          expands: false,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                        )
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isUnlimited, 
                              onChanged: (bool? value) {
                                setState(() {
                                  isUnlimited = value!;
                                });
                              }
                            ),
                            const Text('Unlimited Attempts?')
                          ]
                        )
                      ),
                    ]
                  )
                ),
              ]
            )
          )
        );
      }),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            int now = DateTime.now().millisecondsSinceEpoch;
            DateFormat dateFormat = DateFormat('yMd').add_jm();
            DateTime? start;
            DateTime? end;
            int? attempts;

            (((startDateInput.text.isNotEmpty 
            && startTimeInput.text.isNotEmpty
            && endDateInput.text.isNotEmpty
            && endTimeInput.text.isNotEmpty) || isForever)
            && (timeLimitInput.text.isNotEmpty && int.parse(timeLimitInput.text) > 0 
            || noTime)
            && (attemptInput.text.isNotEmpty && int.parse(attemptInput.text) > 0 
            || isUnlimited)
            && (DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute).difference(
                DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute)).inSeconds > 0))
            ? {
                pubSimRef.update({"notimelimit": noTime}),
                pubSimRef.update({"availableforever": isForever}),
                pubSimRef.update({"unlimitedattempts": isUnlimited}),
                (!noTime)
                ? { timeLimit = int.parse(timeLimitInput.text),
                    pubSimRef.update({"timelimit": timeLimit}),
                    simRef.update({"timelimit" : _printDuration(Duration(minutes: timeLimit!))})
                  }
                : { timeLimit = null,
                    simRef.update({"timelimit" : "Unlimited"}),
                    pubSimRef.update({"timelimit": null}) },
                (!isForever) 
                ? { start = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute),
                    pubSimRef.update({"starttime": start.millisecondsSinceEpoch}),
                    end = DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute),
                    pubSimRef.update({"endtime": end.millisecondsSinceEpoch}),
                    simRef.update({"availtime" : "${dateFormat.format(start)} - ${dateFormat.format(end)}"}),
                    simRef.update({"enabled": (now > start.millisecondsSinceEpoch) && (now < end.millisecondsSinceEpoch)})
                  }
                : { simRef.update({"availtime" : "Always Available"}),
                    pubSimRef.update({"starttime": null}), 
                    pubSimRef.update({"endtime": endDateTime = null}),
                    simRef.update({"enabled": true})
                  },
                (!isUnlimited)
                ? { attempts = int.parse(attemptInput.text),
                    pubSimRef.update({"maxattempts": attempts}), 
                    simRef.update({"availattempts" : attempts.toString()}) 
                  }
                : { simRef.update({"availattempts" : "Unlimited"}),
                    pubSimRef.update({"maxattempts": null}) 
                  },

                simRef.update({"manualdisable" : false}),
                Navigator.pop(context)
              }
            : showDialog(context: context, builder: (BuildContext context) => popupIncomplete(context));
            },
          child: const Text('Activate Simulation'),
        ),
      ],
    ),
  );
}

Widget popupIncomplete(BuildContext context) {
  return AlertDialog(
    title: const Text('Please fill out all fields with valid information.'),
    titlePadding: const EdgeInsets.fromLTRB(35,35,35,20),
    actionsAlignment: MainAxisAlignment.center,
    actions: [TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('OK')
    )],
  );
}

String _printDuration(Duration duration) {
  String negativeSign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  //String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  //return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes";
}