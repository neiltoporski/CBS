import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../firebase_options.dart';
import 'package:intl/intl.dart';

import 'package:graphview/GraphView.dart';

// Link Pages
import './dev_main_menu.dart';
import './create_sim_functions.dart';
import '../main.dart';
import '../nodes/node_functions.dart';

// link Nodes
import '../nodes/nodes.dart';
import '../nodes/ig_node.dart';
import '../nodes/scenario_node.dart';
import '../nodes/dm_node.dart';

String simPubName = "";
int? timeLimit;
DateTime? startDateTime;
DateTime? endDateTime;
int? maxAttempts;
bool noTimeLimit = false;
bool isAvailableForever = false;
bool hasUnlimitedAttempts = false;

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SimMenu());
}

class SimMenu extends StatelessWidget {
  const SimMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editing Simulation: $simName',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Editing Simulation: $simName'),
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
  int curr = 0; // Current Node Selected
  var type = <String>[]; //Collection of "node types" related to their node name
  int max = 1; // Max children of curr node
  List<int> nodeIDs = []; // Collection of nodeIds
  List<Node> nodeList = []; // Collection of nodes
  List<String> invalidNodes = [];
  PathInfo optimalPathResult = PathInfo(0, []);
  int key = 0;

  @override
  Widget build(BuildContext context) {
    // determines max children
    int currIndex = nodeIDs.indexOf(curr);
    if (type[currIndex] == "DM") {
      max = 4;
    } else if (type[currIndex] == "END") {
      max = 0;
    } else {
      max = 1;
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 115,
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Simulation: $simName'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(100,0,0,5), 
                  child: ElevatedButton(
                    onPressed: () => {closeSimWarning(context)},
                    child: const Text(
                      'Close Simulation',
                      style: TextStyle(color: Colors.black),
                    )
                  )
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                    onPressed: () async => {
                          if (await isMaxChildren(curr, max))
                            {maxChildren(context)}
                          else
                            {
                              // Returns false if max children (4)
                              type.add('IG'),
                              addNode('IG')
                            }
                        },
                    icon: const Icon(Icons.star_outline_rounded),
                    tooltip: 'New Information Gathering Node'),
                IconButton(
                  onPressed: () async => {
                    if (await isMaxChildren(curr, max))
                      {maxChildren(context)}
                    else
                      {
                        // Returns false if max children (1)
                        type.add('DM'),
                        addNode('DM')
                      }
                  },
                  icon: const Icon(Icons.pentagon_outlined),
                  tooltip: 'New Decision Making Node',
                ),
                IconButton(
                  onPressed: () async => {
                    if (await isMaxChildren(curr, max))
                      {maxChildren(context)}
                    else
                      {
                        // Returns false if max children (1)
                        type.add('END'),
                        addNode('END')
                      }
                  },
                  icon: const Icon(Icons.crop_square),
                  tooltip: 'Add End Node',
                ),
                IconButton(
                  onPressed: () async => {
                    // Can not delete scenario ndoe
                    if (type[currIndex] == 'SCENARIO')
                      {
                        deleteScenario(context),
                      }
                    else
                      {await deletion(currIndex, nodeList), curr = 0},
                  },
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Node',
                ),
                Padding(
                  padding: const EdgeInsets.all(5), 
                  child: ElevatedButton(
                    onPressed: () async => {
                      simulationMap = await createSimulationObjects(
                          "devs", accountEmail, simName),
                      setState(() {
                        invalidNodes =
                            checkSimulationIntegrity(simulationMap);
                      }),
                      // Simulation has to be valid to calculate the optimal path
                      if (invalidNodes.isEmpty)
                        {
                          optimalPathResult =
                              checkOptimalPath(createGraph(simulationMap)),
                          optimalPathDisplay(optimalPathResult)
                        }
                      else
                        {simulationIntegrityDisplay(invalidNodes)}
                    },
                    child: const Text(
                      'Check Optimal Path',
                      style: TextStyle(color: Colors.black),
                    )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(5), 
                  child: ElevatedButton(
                    onPressed: () async => {
                          simulationMap = await createSimulationObjects(
                              "devs", accountEmail, simName),
                          // Need to update display to reflect color change in invalid nodes
                          setState(() {
                            invalidNodes =
                                checkSimulationIntegrity(simulationMap);
                          }),
                          simulationIntegrityDisplay(invalidNodes)
                        },
                    child: const Text(
                      'Check Simulation Integrity',
                      style: TextStyle(color: Colors.black),
                    )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(5), 
                  child: ElevatedButton(
                    onPressed: () async => {
                          simulationMap = await createSimulationObjects("devs", accountEmail, simName),
                          setState(() {
                            invalidNodes =
                                checkSimulationIntegrity(simulationMap);
                          }),
                          // Ensures the simulation is valid before publishing and calculates the optimal score for storing
                          if (invalidNodes.isEmpty)
                            {publishMenu(context,checkOptimalPath(createGraph(simulationMap)))}
                          else
                            {simulationIntegrityDisplay(invalidNodes)}
                        },
                    child: const Text(
                      'Publish',
                      style: TextStyle(color: Colors.black),
                    )
                  )
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey)
            ),
            child: InteractiveViewer(
              //alignment: Alignme,
              constrained: false,
              scaleEnabled: false,
              // future goal to read the size of the tree and change this accordingly?
              boundaryMargin: const EdgeInsets.fromLTRB(500,25,500,99999),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GraphView(
                    graph: graph,
                    algorithm:
                        BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                    paint: Paint()
                      ..color = Colors.green
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      // I can decide what widget should be shown here based on the id
                      int index = node.key!.value as int;
                      var a = node.key!.value as int?;
                      int nodeIndex = nodeIDs.indexOf(index);
                      String currType = type[nodeIndex];
                      // Following booleans determine if the node is part of the invalid nodes or optimal path which would change the color of the node
                      bool isInvalid = invalidNodes.contains('Node$a');
                      bool isOptimal = optimalPathResult.getPath().contains('Node$a');

                      switch (currType) {
                        case 'SCENARIO':
                          {
                            return scenarioWidget(a, isInvalid, isOptimal);
                          }

                        case 'IG':
                          {
                            return igWidget(a, isInvalid, isOptimal);
                          }

                        case 'END':
                          {
                            return endWidget(a, isInvalid, isOptimal);
                          }

                        case 'DM':
                          {
                            return dmWidget(a, isInvalid, isOptimal);
                          }

                        default:
                          {
                            return scenarioWidget(a, isInvalid, isOptimal);
                          }
                      }
                    },
                  ),
                )
              )
            ),
          )
        ),
      ]),
    );
  }

  // Node widgets

  Widget igWidget(int? a, bool isInvalid, bool isOptimal) {
    Key key = Key('node_$a');

    bool selected = false;

    // Checks if the node is selected

    if (curr == a) {
      selected = true;
    }


    return InkWell(
        key: key,
        onTap: () {
          setState(() {

            curr = a!;
          });
        },
        onDoubleTap: () async {
          setState(() {
            igNode(context, a!);

            // Node is removed from invalid nodes as it could've been fixed on the node edit and editing may have changed the optimal path so that is cleared
            invalidNodes.remove('Node$a');

            optimalPathResult.clearPath();
          });
        },
        child: Icon(
          Icons.star_outline_rounded,
          color: isInvalid
              ? Colors.red
              : isOptimal
                  ? Colors.green
                  : Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

  Widget dmWidget(int? a, bool isInvalid, bool isOptimal) {
    Key key = Key('node_$a');

    bool selected = false;

    // Checks if the node is selected

    if (curr == a) {
      selected = true;
    }

    return InkWell(
        key: key,
        onTap: () {
          setState(() {

            curr = a!;
          });
        },
        onDoubleTap: () async {
          setState(() {
            dmNode(context, a!);

            // Node is removed from invalid nodes as it could've been fixed on the node edit and editing may have changed the optimal path so that is cleared
            invalidNodes.remove('Node$a');

            optimalPathResult.clearPath();
          });
        },
        child: Icon(
          Icons.pentagon_outlined,
          color: isInvalid
              ? Colors.red
              : isOptimal
                  ? Colors.green
                  : Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

  Widget endWidget(int? a, bool isInvalid, bool isOptimal) {
    Key key = Key('node_$a');

    bool selected = false;

    // Checks if the node is selected

    if (curr == a) {
      selected = true;
    }

    return InkWell(
        key: key,
        onTap: () {
          setState(() {

            curr = a!;
          });
        },
        onDoubleTap: () async {
          setState(() {
            invalidNodes.remove('Node$a');

            optimalPathResult.clearPath();
          });
        },
        child: Icon(
          Icons.crop_square,
          color: isInvalid
              ? Colors.red
              : isOptimal
                  ? Colors.green
                  : Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

  Widget scenarioWidget(int? a, bool isInvalid, bool isOptimal) {
    Key key = Key('node_$a');

    bool selected = false;

    // Checks if the node is selected

    if (curr == a) {
      selected = true;
    }

    return InkWell(
        key: key,
        onTap: () {
          setState(() {

            curr = a!;
          });
        },
        onDoubleTap: () async {
          setState(() {
            scenarioNode(context, a!);

            // Node is removed from invalid nodes as it could've been fixed on the node edit and editing may have changed the optimal path so that is cleared
            invalidNodes.remove('Node$a');

            optimalPathResult.clearPath();
          });
        },
        child: Icon(
          Icons.circle,
          color: isInvalid
              ? Colors.red
              : isOptimal
                  ? Colors.green
                  : Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }
  // ---------Initial Graph Building----------

  // Function to determine type of node
  String getType(NodeSim node) {
    switch (node.runtimeType.toString()) {
      case 'ScenarioNode':
        {
          return 'SCENARIO';
        }
      case 'IGNode':
        {
          return 'IG';
        }
      case 'EndNode':
        {
          return 'END';
        }
      case 'DMNode':
        {
          return 'DM';
        }
      default:
        {
          return 'SCENARIO';
        }
    }
  }

  // Builds nodList, NodeIDs, and Type lists in order
  void buildLists(Map<String, LinkedList> adjacencyList) {
    Set<String> visited = {};

    void dfs(String currentNodeName) {
      if (visited.contains(currentNodeName)) {
        return; // Skip already visited nodes
      }
      visited.add(currentNodeName);

      // build nodeList/nodeIDs/type
      int currInt = int.parse(currentNodeName.substring(4));
      nodeList.add(Node.Id(currInt));
      nodeIDs.add(currInt);
      type.add(getType(simulationMap![currentNodeName]!));

      LinkedList? linkedList = adjacencyList[currentNodeName];
      GraphNode? currentNode = linkedList?.getHead();

      while (currentNode != null) {
        String neighborNodeName = currentNode.getNodeName();

        if (!visited.contains(neighborNodeName)) {
          dfs(neighborNodeName);
        }

        currentNode = currentNode.getNext();
      }
    }

    dfs('Node0');
  }

  // Function to build the visual graph
  void buildGraph() {
    for (var curr in nodeIDs) {
      int index = nodeIDs.indexOf(curr);

      LinkedList? linkedList = nodeMap!['Node$curr'];
      GraphNode? childNode = linkedList?.getHead();

      while (childNode != null) {
        int child = int.parse(childNode.getNodeName().substring(4));
        int childIndex = nodeIDs.indexOf(child);

        graph.addEdge(nodeList[index], nodeList[childIndex]);
        childNode = childNode.getNext();
      }
    }
  }

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  initState() {
    super.initState();
    if (isNew) {
      // NEW SIM
      // Creates a starting node
      key = 1;
      final node0 = Node.Id(0);
      final node1 = Node.Id(1);
      type.add('SCENARIO');
      nodeIDs.add(0);
      nodeList.add(node0);
      graph.addEdge(node0, node1);
      graph.removeNode(node1);
      initialGraphHelper0();
    } else {
      // EXISTING SIM

      // Builds the graph from map
      int highest = -1;
      simulationMap?.forEach((k, v) {
        int curr = int.parse(k.substring(4));
        if (curr > highest) {
          highest = curr;
        }
      });
      key = highest + 1;

      // Checks if there is one node in the existing sim
      if (simulationMap!.length == 1) {
        final newNode = Node.Id(highest);
        final tmpNode = Node.Id(highest + 1);

        simulationMap?.forEach((k, v) {
          type.add(getType(simulationMap![k]!));
        });
        nodeIDs.add(highest);
        nodeList.add(newNode);
        graph.addEdge(newNode, tmpNode);
        graph.removeNode(tmpNode);
      } else {
        // build lists
        buildLists(nodeMap!);

        // build graph
        buildGraph();
      }
    }
    // graph building specifications
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  // adding Node
  void addNode(String type) {

    nodeList.add(Node.Id(key));
    nodeIDs.add(key);

    addNodeHelper(type, curr, key);
    final node = Node.Id(key);

    int currIndex = nodeIDs.indexOf(curr);
    var edge = graph.getNodeAtPosition(currIndex);

    graph.addEdge(edge, node);

    key++;
    setState(() {});
  }
  // ------------END GRAPH BUILD---------------

  // Deleting a node
  Future<void> deletion(int currIndex, List<Node> nodeList) async {
    bool delete = await removeNode(context, curr);

    if (delete) {
      await deleteNode(curr);

      // remove node from visual graph
      graph.removeNode(nodeList[currIndex]);

      // update the map to the curren
      Map<String, NodeSim>? simulationMap;
      simulationMap =
          await createSimulationObjects("devs", accountEmail, simName);
      Map<String, LinkedList>? nodeMap = createGraph(simulationMap);

      // rebuild the lists
      rebuildDelete(nodeMap, simulationMap);

      setState(() {});
    }
  }

  // function to rebuild the lists in order
  void rebuildDelete(Map<String, LinkedList> adjacencyList, Map<String, NodeSim>? simulationMap) {
    Set<String> visited = {};
    // ensure empty lists
    nodeIDs.clear();
    nodeList.clear();
    type.clear();

    void dfs(String currentNodeName) {
      if (visited.contains(currentNodeName)) {
        return; // Skip already visited nodes
      }

      visited.add(currentNodeName);
      int currInt = int.parse(currentNodeName.substring(4));
      nodeList.add(Node.Id(currInt));
      nodeIDs.add(currInt);
      type.add(getType(simulationMap![currentNodeName]!));

      LinkedList? linkedList = adjacencyList[currentNodeName];
      GraphNode? currentNode = linkedList?.getHead();

      while (currentNode != null) {
        String neighborNodeName = currentNode.getNodeName();

        if (!visited.contains(neighborNodeName)) {
          dfs(neighborNodeName);
        }
        currentNode = currentNode.getNext();
      }
    }

    dfs('Node0');
  }

  closeSimWarning(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
        title: const Text('Are you sure you wish to close this simulation?'),
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
                  runApp(const DevMenu());
                  Navigator.pop(context);
                },
                child: const Text('Close & Return to Menu'),
              ),
            ]
          )
        ],
      ),
    );
  }

  Future<bool> removeNode(BuildContext context, int curr) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
            title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete Node?'),
                ]),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Remove Node'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future publishMenu(BuildContext context, PathInfo optimalPathResult) async {
    TextEditingController scenarioPubName = TextEditingController(text: simName);
    TextEditingController attemptInput = TextEditingController(text: '3');
    TextEditingController timeLimitInput = TextEditingController();
    TextEditingController startDateInput = TextEditingController();
    TextEditingController startTimeInput = TextEditingController();
    TextEditingController endDateInput = TextEditingController();
    TextEditingController endTimeInput = TextEditingController();
    bool noTime = false;
    bool isForever = false;
    bool isUnlimited = false;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);

    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        contentPadding: const EdgeInsets.all(24.0),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Publish "$simName" as'),
          const Text(
            'WARNING: You will no longer be able to edit this simulation unless it is unpublished.',
            textScaler: TextScaler.linear(0.65),
          )
        ]),
        content: StatefulBuilder (
          builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(5),
            height: 450,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Enter public display name here'),
                    controller: scenarioPubName
                  ),
                  const Padding (
                    padding: EdgeInsets.only(top: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, 
                      children: [
                        Text('Availability', style: TextStyle(fontSize: 20)),
                        Text('When these conditions are not met, users cannot complete simulations.', textScaler: TextScaler.linear(0.85))
                      ]
                    )
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
                                context: context, initialDate: DateTime.now(),
                                firstDate: DateTime.now(), //DateTime.now() - not to allow to choose before today.
                                lastDate: DateTime.now().add(const Duration(days: 30))
                              );
                          
                              if(pickedStartDate != null) {
                                //print(pickedStartDate);  //pickedDate output format => 2021-03-10 00:00:00.000
                                startDate = pickedStartDate;
                                String formattedDate = DateFormat('MM-dd-yyyy').format(pickedStartDate); 
                                //print(formattedDate); //formatted date output using intl package =>  2021-03-16
                                  //you can implement different kind of Date Format here according to your requirement

                                setState(() {
                                  startDateInput.text = formattedDate; //set output date to TextField value. 
                                });
                              }else{
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
                                initialTime: TimeOfDay.now(),
                                context: context,
                              );
                              if(pickedStartTime != null){
                                startTime = pickedStartTime;
                                DateTime tempDate = DateFormat("Hm").parse('${pickedStartTime.hour.toString()}:${pickedStartTime.minute.toString()}');
                                var dateFormat = DateFormat("jm"); // you can change the format here

                                setState(() {
                                  startTimeInput.text = dateFormat.format(tempDate); //set output date to TextField value. 
                                });
                              }else{
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
                            enabled: !isForever,
                            onTap: () async {
                              DateTime? pickedEndDate = await showDatePicker(
                                context: context, initialDate: DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now().add(const Duration(days: 1)), //DateTime.now() - not to allow to choose before today.
                                lastDate: DateTime.now().add(const Duration(days: 365))
                              );
                          
                              if(pickedEndDate != null ){
                                //print(pickedEndDate);  //pickedDate output format => 2021-03-10 00:00:00.000
                                endDate = pickedEndDate;
                                String formattedDate = DateFormat('MM-dd-yyyy').format(pickedEndDate); 
                                //print(formattedDate); //formatted date output using intl package =>  2021-03-16
                                  //you can implement different kind of Date Format here according to your requirement

                                setState(() {
                                  endDateInput.text = formattedDate; //set output date to TextField value. 
                                });
                              }else{
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
                                initialTime: TimeOfDay.now(),
                                context: context,
                              );
                              if(pickedEndTime != null){
                                endTime = pickedEndTime;
                                DateTime tempDate = DateFormat("Hm").parse('${pickedEndTime.hour.toString()}:${pickedEndTime.minute.toString()}');
                                var dateFormat = DateFormat("jm"); // you can change the format here

                                setState(() {
                                  endTimeInput.text = dateFormat.format(tempDate); //set output date to TextField value. 
                                });
                              }else{
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
          ElevatedButton(
            onPressed: () {
              (scenarioPubName.text.isNotEmpty 
              && ((startDateInput.text.isNotEmpty 
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
                  simPubName = scenarioPubName.text,
                  noTimeLimit = noTime,
                  isAvailableForever = isForever,
                  hasUnlimitedAttempts = isUnlimited,
                  (!noTime)
                  ? {timeLimit = int.parse(timeLimitInput.text)}
                  : {timeLimit = null},
                  (!isForever) 
                  ? {startDateTime = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute),
                    endDateTime = DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute)} 
                  : {startDateTime = null, endDateTime = null},
                  (!isUnlimited)
                  ? {maxAttempts = int.parse(attemptInput.text)}
                  : {maxAttempts = null},
                  publish(optimalPathResult),
                  runApp(const DevMenu()), 
                  Navigator.pop(context)
                }
              : showDialog(context: context, builder: (BuildContext context) => popupIncomplete(context));
              },
            child: const Text('PUBLISH'),
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
      actions: [ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('OK')
      )],
    );
  }

  /// Creates the simulation integrity display either stating that the simulation is valid or invalid in which case it describes what to fix
  Future simulationIntegrityDisplay(List<String> invalidNodes) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          if (invalidNodes.isEmpty) {
            return AlertDialog(
              title: const Center(child: Text('Valid Simulation Integrity')),
              content: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.3, // 30% of the screen width
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'All paths lead to an end node, all selected choices are completelfy filled, and each node has the correct amount of children.',
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          } else {
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
                        'Ensure that the highlighted node(s) have all their selected choice fields filled, have the correct number of children for its choices, and are part of a path that leads to an end node.',
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          }
        });
  }

  // Creates the optimal path display stating the best possible score and mentioning the color change of the tree display
  Future optimalPathDisplay(PathInfo optimalPathResult) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
                child: Text(
                    'Optimal Path Score: ${optimalPathResult.getScore()}')),
            content: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.3, // 30% of the screen width
              child: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'The optimal path of the simulation is highlighted with green nodes on the tree display.',
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        });
  }
}
