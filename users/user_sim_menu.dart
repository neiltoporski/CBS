import 'dart:async';

import 'package:floating_dialog/floating_dialog.dart';
import 'package:graphview/GraphView.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Link Pages
import '../../devs/dev_main_menu.dart';
import 'user_main_menu.dart';
import '../../main.dart';
import '../../firebase_options.dart';
import '../../nodes/nodes.dart';

import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:widget_zoom/widget_zoom.dart';
import 'package:vimeo_player_flutter/vimeo_player_flutter.dart';

final player = AudioPlayer();

NodeSim? currentNode;
String nodeName = 'Node0';
String path = 'Node0';

int score = 0;
int? simTimeLimit;
Column? data;
bool informationGathered = false;
List<Choice> resultsQueue = [];
Map<String, List<bool>> igTrack = {};

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UserSimMenu());
}

class UserSimMenu extends StatelessWidget {
  const UserSimMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Simulation Menu',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: _MyHomePage(
          title: 'User Simulation Menu', onBoolChange: (List<bool> args) {}),
    );
  }
}

// ignore: must_be_immutable
class _MyHomePage extends StatefulWidget {
  _MyHomePage({
    required this.title,
    required this.onBoolChange,
  });

  final String title;
  List<bool> bools = [];
  int choice = 0;
  final Function(List<bool>) onBoolChange;
  @override
  _MyHomepageState createState() => _MyHomepageState();
}

class _MyHomepageState extends State<_MyHomePage> {
  int selectNode = 0; // (Graph) selected node
  int curr = 0; // (Graph) current node of sim
  Map<String, List<int>> userChoices = {};
  bool end = false;

  bool noTimeLimit = false;
  int remainingSeconds = 12345678;
  Timer simTimer = Timer(Duration.zero, () { });

  bool outOfTime = false;

  @override
  Widget build(BuildContext context) {
    currentNode = map?[nodeName];

    if (currentNode.runtimeType == DMNode) {
      data = _buildDMNode(currentNode as DMNode, currentNode!.getStoryText!);
    } else if (currentNode.runtimeType == IGNode) {
      data = _buildIGNode(currentNode as IGNode, currentNode!.getStoryText!);
    } else if (currentNode.runtimeType == ScenarioNode) {
      data = _buildScenarioNode(currentNode, currentNode!.getStoryText!);
    } else {
      data = _buildEndNode();
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
                const Text('Case Based Simulation'),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(5),
                  margin: const EdgeInsets.fromLTRB(100, 0, 30, 0),
                  constraints: const BoxConstraints(minWidth: 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                  ),
                  child: StatefulBuilder(
                    builder: (context, setTimerState) {
                      if (!noTimeLimit) {
                        simTimer.cancel();
                        if (!outOfTime) {
                          simTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
                            if (remainingSeconds <= 1) {
                              outOfTime = true;
                              outOfTimePopup(context);
                              setState(() {
                                remainingSeconds--;
                                _endSimNode();
                              });
                            } else {
                              setTimerState(() {remainingSeconds--;});
                            }
                          });
                        }

                        return Text(((remainingSeconds < 10000000) ? _printDuration(Duration(seconds: remainingSeconds)) : 'Fetching...'), style: const TextStyle(fontSize: 14));
                      } else {
                        simTimer.cancel();
                        return const Text('No Time Limit', style: TextStyle(fontSize: 14));
                      }
                    }
                  )
                ),
                ElevatedButton(
                    onPressed: () => {
                      closeSimWarning(context)
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.black),
                    )),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey)
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 2.5), 
                      child: Text('Simulation View', style: TextStyle(fontSize: 20))
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(10.0),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey))
                        ),
                        child: InteractiveViewer(
                          constrained: true,
                          scaleEnabled: false,
                          // future goal to read the size of the tree and change this accordingly?
                          boundaryMargin: const EdgeInsets.fromLTRB(0,0,0,9999),
                          minScale: 0.01,
                          maxScale: 5.6,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width,
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: GraphView(
                                graph: graph,
                                algorithm: BuchheimWalkerAlgorithm(
                                    builder, TreeEdgeRenderer(builder)),
                                paint: Paint()
                                  ..color = Colors.green
                                  ..strokeWidth = 1
                                  ..style = PaintingStyle.stroke,
                                builder: (Node node) {
                                  // I can decide what widget should be shown here based on the id
                                  var a = node.key!.value as int?;
                                  String currType = getType(map!['Node$a']!);

                                  switch (currType) {
                                    case 'SCENARIO':
                                      return scenarioWidget(a);
                                    case 'IG':
                                      return igWidget(a);
                                    case 'END':
                                      return endWidget(a);
                                    case 'DM':
                                      return dmWidget(a);
                                    default:
                                      return scenarioWidget(a);
                                  }
                                },
                              ),
                            )
                          )
                        ),
                      ),
                    ),
                  ],
                )
              )
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey)
                ),
                child: Column(
                  children: <Widget>[
                    Flexible(
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: data
                            )
                          )
                        ]
                      )
                    ),
                  ]
                )
              )
            ),
          ]
        ),
      ),
    );
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = (duration.inHours != 0) ? '${duration.inHours}:' : '';
    String twoDigitMinutes = (duration.inHours != 0) 
                             ? twoDigits(duration.inMinutes.remainder(60).abs()) 
                             : duration.inMinutes.remainder(60).abs().toString();
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign$twoDigitHours$twoDigitMinutes:$twoDigitSeconds";
  }

  outOfTimePopup(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
        title: const Text('You are out of time.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ]
      )
    );
  }

  closeSimWarning(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you wish to close this simulation?'),
            Text('This will count as an attempt.',textScaler: TextScaler.linear(0.65),)
          ]
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
              ElevatedButton(
                onPressed: () {
                  simTimer.cancel();

                  if (!isDev) {_uploadScore(); runApp(const UserMenu());}
                  else {runApp(const DevMenu());}

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

  //--------- GRAPH------------------------------
  Widget igWidget(int? a) {
    Key key = Key('node_$a');
    bool selected = false;

    // Checks if the node is selected
    if (selectNode == a && !end) {
      selected = true;
    }

    return InkWell(
        key: key,
        onTap: () {
          setState(() {
            if (!end) {
              selectNode = a!;
              nodeName = 'Node$a';
            }
          });
        },
        child: Icon(
          Icons.star_outline_rounded,
          color: Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

  Widget dmWidget(int? a) {
    Key key = Key('node_$a');
    bool selected = false;

    // Checks if the node is selected
    if (selectNode == a && !end) {
      selected = true;
    }

    return InkWell(
        key: key,
        onTap: () {
          setState(() {
            if (!end) {
              selectNode = a!;
              nodeName = 'Node$a';
            }
          });
        },
        child: Icon(
          Icons.pentagon_outlined,
          color: Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

  Widget endWidget(int? a) {
    Key key = Key('node_$a');
    // ignore: unused_local_variable
    bool selected = false;

    return InkWell(
        key: key,
        onTap: () {},
        child: const Icon(
          Icons.crop_square,
          color: Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: Colors.red,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

  Widget scenarioWidget(int? a) {
    Key key = Key('node_$a');
    bool selected = false;

    // Checks if the node is selected
    if (selectNode == a && !end) {
      selected = true;
    }

    return InkWell(
        key: key,
        onTap: () {
          setState(() {
            if (!end) {
              selectNode = a!;
              nodeName = 'Node$a';
            }
          });
        },
        child: Icon(
          Icons.circle,
          color: Colors.blue,
          size: 50,
          shadows: [
            Shadow(
              color: selected ? Colors.red : Colors.transparent,
              blurRadius: 10.0,
            ),
          ],
        ));
  }

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

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  List<Node> nodeList = []; // Collection of nodes

  @override
  initState() {
    // creates initial graph upon opening sim
    super.initState();

    if (simTimeLimit != null) {remainingSeconds = simTimeLimit! * 60;} 
    else {noTimeLimit = true;}

    final node0 = Node.Id(0);
    final node1 = Node.Id(1);
    nodeList.add(node0);
    graph.addEdge(node0, node1);
    graph.removeNode(node1);

    // graph building specifications
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  //----------END GRAPH-------------------------------------------

  Column _buildEndNode() {
    List<Widget> list = [];
    end = true;
    outOfTime = true;
    simTimer.cancel();


    // display score
    list.add(
      Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.fromLTRB(0, 30, 0, 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(5))
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Score:', style: TextStyle(fontSize: 20)), 
              Text("$score out of $maxScore", style: const TextStyle(fontSize: 20))
            ]
          )
        )
      )
    );

    // display explanations
    list.add(
      Center(
        child: Expanded(
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.fromLTRB(0, 10, 0, 15),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey), bottom: BorderSide(color: Colors.grey)),
              borderRadius: BorderRadius.all(Radius.circular(20))
            ),
            child: ListView(
              children: List.generate(resultsQueue.length,
                (index) => Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey
                      )
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                    title: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: resultsQueue.elementAt(index).getOption,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade800
                            )
                          ),
                          TextSpan(
                            text: ", ${resultsQueue.elementAt(index).getExplanation}",
                            style: TextStyle(
                              color: Colors.grey.shade800
                            )
                          )
                        ]
                      )
                    ),
                    subtitle: Text(
                      "Score = ${resultsQueue.elementAt(index).getScore}"
                    )
                  )
                )
              )
            )
          )
        )
      )
    );

    // display exit button
    list.add(
      Center(
        child: ElevatedButton(
          onPressed: () => {
            setState(() {
              nodeName = 'Node0';

              score = 0;
              data;
              informationGathered = false;
              resultsQueue = [];
            }),
            if (!isDev)
              {runApp(const UserMenu())}
            else
              {runApp(const DevMenu())}
          },
          child: const Text("Exit")
        )
      )
    );
    list.add(const SizedBox(height: 100));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 2.5), 
          child: Text('End of Simulation', style: TextStyle(fontSize: 20))
        ),
        Container(
          margin: const EdgeInsets.all(10.0),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list
          ),
        )
      ]
    );
  }
  // adding nodes

  Column _buildScenarioNode(NodeSim? currentNode, String storyText) {
    List<Widget> list = [];

    // add scenario text
    list.add(
      const Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Text(
            'Scenario:',
            style: TextStyle(fontSize: 18)
          )
        )
      )
    );

    // add scenario description
    list.add(
      Center(
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(20))
          ), 
          child: SingleChildScrollView(
            child: Text(storyText)
          )
        )
      )
    );

    // Check if the current node has any associated media URLs (audio, image, or video)
    if (currentNode!.audioUrl!.isNotEmpty |
        currentNode.imageUrl!.isNotEmpty |
        currentNode.videoUrl!.isNotEmpty) {
      if (currentNode.audioUrl!.isNotEmpty) {
        // If the current node has an audio URL, set the player's URL to it
        player.setUrl(currentNode.audioUrl!);
      }
      // Add a media display widget to the list based on the current node's media URLs
      list.add(
        Padding(
          padding: const EdgeInsets.all(10),
          child: mediaDisplay(currentNode.imageUrl, currentNode.videoUrl, currentNode.audioUrl)
        )
      );
    }

    bool visited = userChoices.containsKey(nodeName);
    if (!visited) {
      list.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
          child: ElevatedButton(
            onPressed: () => {
              userChoices[nodeName] = [0],
              _getNextNode()
            },
            child: const Text("Continue")
          )
        )
      );
    }

    // Returns the final scenario node.
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 2.5), 
          child: Text('Simulation Data', style: TextStyle(fontSize: 20))
        ),
        Center(
          child: Expanded(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey))
              ),
              child: Column(
                children: list
              )
            )
          )
        )
      ]
    );
  }

  Column _buildDMNode(DMNode? currentNode, String storyText) {
    List<Widget> list = [];
    bool visited = userChoices.containsKey(nodeName) ? true : false;
    List<int> userSelected = [];

    // add DM text
    list.add(
      const Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Text(
            'Decision Making:',
            style: TextStyle(fontSize: 18)
          )
        )
      )
    );

    // add DM description
    list.add(
      Center(
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(20))
          ), 
          child: SingleChildScrollView(
            child: Text(storyText)
          )
        )
      )
    );

    // Check if the current node has any associated media URLs (audio, image, or video)
    if (currentNode!.audioUrl!.isNotEmpty |
        currentNode.imageUrl!.isNotEmpty |
        currentNode.videoUrl!.isNotEmpty) {
      if (currentNode.audioUrl!.isNotEmpty) {
        // If the current node has an audio URL, set the player's URL to it
        player.setUrl(currentNode.audioUrl!);
      }
      // Add a media display widget to the list based on the current node's media URLs
      list.add(
        Padding(
          padding: const EdgeInsets.all(10),
          child: mediaDisplay(currentNode.imageUrl, currentNode.videoUrl, currentNode.audioUrl)
        )
      );
    }

    ValueNotifier<int> notify = ValueNotifier<int>(widget.choice);
    list.add(
      Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(currentNode.getChoices.length, (index) {
            final key = UniqueKey();
            return ValueListenableBuilder<int>(
              valueListenable: notify,
              builder: (context, value, _) {
                if (visited) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Radio(
                        key: key,
                        value: index,
                        groupValue: notify.value,
                        onChanged: (int? value) {},
                      ),
                      Text(currentNode.getChoices.elementAt(index).getOption),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Radio(
                        key: key,
                        value: index,
                        groupValue: notify.value,
                        onChanged: (int? value) {
                          setState(() {
                            notify.value = value as int;
                            widget.choice = notify.value;
                          });
                        },
                      ),
                      Text(currentNode.getChoices.elementAt(index).getOption),
                    ],
                  );
                }
              }
            );
          })
        )
      )
    );

    if (!visited) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                userSelected.add(notify.value);
                userChoices[nodeName] =
                    userSelected; // store selection for this node
                Choice selection =
                    currentNode.getChoices.elementAt(widget.choice);
                score += selection.getScore;
                resultsQueue.add(selection);
                _getNextNode();
              });
            },
            child: const Text("Continue"),
          ),
        )
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 2.5), 
          child: Text('Simulation Data', style: TextStyle(fontSize: 20))
        ),
        Center(
          child: Expanded(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey))
              ),
              child: Column(
                children: list,
              )
            )
          )
        )
      ]
    );
  }

  Column _buildIGNode(IGNode? currentNode, String storyText) {
    bool visited = userChoices.containsKey(nodeName) ? true : false;
    List<int> userSelected = [];
    List<bool> bools = widget.bools;
    List<Widget> list = [];

    // add IG text
    list.add(
      const Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Text(
            'Information Gathering:',
            style: TextStyle(fontSize: 18)
          )
        )
      )
    );

    // add IG description
    list.add(
      Center(
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(20))
          ), 
          child: SingleChildScrollView(
            child: Text(storyText)
          )
        )
      )
    );

    // Check if the current node has any associated media URLs (audio, image, or video)
    if (currentNode!.audioUrl!.isNotEmpty |
        currentNode.imageUrl!.isNotEmpty |
        currentNode.videoUrl!.isNotEmpty) {
      if (currentNode.audioUrl!.isNotEmpty) {
        // If the current node has an audio URL, set the player's URL to it
        player.setUrl(currentNode.audioUrl!);
      }
      // Add a media display widget to the list based on the current node's media URLs
      list.add(
        Padding(
          padding: const EdgeInsets.all(10),
          child: mediaDisplay(currentNode.imageUrl, currentNode.videoUrl, currentNode.audioUrl)
        )
      );
    }

    list.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(30,30,30,10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(currentNode.getChoices.length, (index) {
            bools.add(false);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                  if (visited) {
                    return Checkbox(
                      isError: false,
                      tristate: false,
                      value: igTrack[nodeName]![index],
                      checkColor: Colors.white,
                      activeColor: Colors.blue,
                      onChanged: (bool? value) {}, // do nothing
                    );
                  } else {
                    return Checkbox(
                      isError: false,
                      tristate: false,
                      value: bools[index],
                      checkColor: Colors.white,
                      activeColor: Colors.blue,
                      onChanged: (bool? value) {
                        (!informationGathered)
                        // Update the corresponding checkbox value
                        ? setState(() {
                            bools[index] = value ?? false;
                            userSelected.add(index); // store selected choie
                          })
                        : null;
                      },
                    );
                  }
                }),
                const SizedBox(width: 8, height: 0),
                Text(currentNode.getChoices.elementAt(index).getOption),
                Visibility(
                  visible: (!visited) ? bools[index] && informationGathered : igTrack[nodeName]![index],
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Text.rich(TextSpan(
                        text: currentNode.getChoices
                            .elementAt(index)
                            .getInformation,
                        style: const TextStyle(fontStyle: FontStyle.italic))),
                  )
                )
              ]
            );
          })
        )
      )
    );

    if (!visited) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: ElevatedButton(
            style: const ButtonStyle(alignment: Alignment.center),
            onPressed: () {
              if (!informationGathered) {
                informationGathered = true;
                setState(() {
                  igTrack[nodeName] = [];
                  for (int i = 0; i < bools.length; i++) {
                    igTrack[nodeName]!.add(bools[i]);
                    if (bools[i]) {
                      IGChoice selection = currentNode.getChoices.elementAt(i);
                      score += selection.getScore;
                      resultsQueue.add(selection);
                    }
                  }
                });
              }
            },
            child: const Text("Gather Information"),
          )
        )
      );

      list.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: ElevatedButton(
            style: const ButtonStyle(alignment: Alignment.center),
            onPressed: () => {
              {
                if (informationGathered)
                  {
                    setState(() {
                      userChoices[nodeName] =
                          userSelected; // saves which options were selected for this node with indexes
                      widget.bools = [];
                      informationGathered = false;
                      _getNextNode();
                    })
                  }
                else
                  {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => const AlertDialog(
                              title: Text('Please select options first'),
                            ))
                  }
              }
            },
            child: const Text("Continue"),
          )
        )
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 2.5), 
          child: Text('Simulation Data', style: TextStyle(fontSize: 20))
        ),
        Center(
          child: Expanded(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey))
              ),
              child: Column(
                children: list,
              )
            )
          )
        )
      ]
    );
  }

  _getNextNode() {
    setState(() {
      nodeName = currentNode!.getChildren!.elementAt(widget.choice);
      path = "$path/$nodeName";
      currentNode = map?[nodeName];
      // Graph
      int newID = int.parse(nodeName.substring(4));
      final newNode = Node.Id(newID);
      nodeList.add(newNode);
      graph.addEdge(nodeList.elementAt(curr), newNode);
      selectNode = newID;
      curr++;
      // end Graph

      switch (currentNode.runtimeType) {
        case DMNode:
          data =
              _buildDMNode(currentNode as DMNode, currentNode!.getStoryText!);
          break;
        case IGNode:
          data =
              _buildIGNode(currentNode as IGNode, currentNode!.getStoryText!);
          break;
        default:
          data = _buildEndNode();
          if (!isDev) {
            _uploadScore();
          }
          break;
      }
      widget.choice = 0;
    });
  }

  _endSimNode() {
    setState(() {
      nodeName = "forcedEndNode";
      path = "$path/$nodeName";
      currentNode = EndNode(null,null,null,null,false,null);

      data = _buildEndNode();
      if (!isDev) {
        _uploadScore();
      }

      widget.choice = 0;
    });
  }

  _uploadScore() async {
    var pubSim = await FirebaseFirestore.instance.collection('publishedsims').doc(currSimID).get();
    final simScore = <String, dynamic>{
      "displayname": pubSim["displayname"],
      "email": accountEmail,
      "path": path,
      "score": score,
      "maxscore": maxScore,
      "completed": DateTime.now()
    };

    int i = 1;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('publishedsims/$currSimID/results/$accountEmail/attempts')
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          if (doc.id == i.toString()) {
            i++;
          }
        }
      }
    } catch (e) {}

    FirebaseFirestore.instance
        .collection('publishedsims')
        .doc(currSimID)
        .collection('results')
        .doc(accountEmail)
        .set({"lastname": lastName});

    FirebaseFirestore.instance
        .collection('publishedsims')
        .doc(currSimID)
        .collection('results')
        .doc(accountEmail)
        .collection('attempts')
        .doc(i.toString())
        .set(simScore);

    var userResultDoc = FirebaseFirestore.instance
        .collection('/users/$accountEmail/results')
        .doc(currSimID);

    //var docSnapshot = await userResultDoc.get();
    //Map<String, dynamic>? data = docSnapshot.data();
    userResultDoc.set(simScore);

    // await userResultDoc.get().then((snapshot) => {
    //   if (snapshot.exists && data != null) {
    //     if (data['score'] < score) {
    //       userResultDoc.update(simScore)
    //     } else {
    //       userResultDoc.set(simScore)
    //     }
    //   } else {
    //     userResultDoc.set(simScore)
    //   }
    // });
  }

/// Constructs a row of buttons based on the presence of image, video, or audio URLs.
/// Each button, when pressed, triggers a dialog to view the corresponding media content.
/// Returns a [Container] widget containing buttons for viewing each type of media content.
  Container mediaDisplay(String? imageUrl, String? videoUrl, String? audioUrl) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        color: Colors.grey.shade200,
      ),
      child: OverflowBar(
        overflowAlignment: OverflowBarAlignment.center,
        spacing: 5,
        children: <Widget>[
          if (imageUrl != null && imageUrl.isNotEmpty)
            ElevatedButton(
                onPressed: () {
                  viewImage(imageUrl);
                },
                child: const Text('View Image')),
          if (videoUrl != null && videoUrl.isNotEmpty)
            ElevatedButton(
                onPressed: () {
                  viewVideo(videoUrl);
                },
                child: const Text('View Video')),
          if (audioUrl != null && audioUrl.isNotEmpty)
            ElevatedButton(
                onPressed: () {
                  viewAudio(audioUrl);
                },
                child: const Text('View Audio')),
        ]
      )
    );
  }

/// Displays a dialog for viewing an image from a provided URL.
/// Allows the user to view an image from the provided [imageUrl] within a dialog.
/// [imageUrl]: The URL of the image to be displayed.
  Future<void> viewImage(String imageUrl) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (stfContext, stfSetState) {
            return FloatingDialog(
              onClose: () {
                Navigator.of(context).pop();
              },
              child: SizedBox(
                  height: 400,
                  width: 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (imageUrl.isNotEmpty)
                        SizedBox(
                            height: 350,
                            width: 450,
                            child: imageUrl.isNotEmpty
                                ? WidgetZoom(
                                    heroAnimationTag: 'tag',
                                    zoomWidget: Image.network(imageUrl))
                                : null),
                    ],
                  )),
            );
          });
        });
  }

/// Displays a dialog for viewing a video from a provided URL.
/// Allows the user to view a video from the provided [videoUrl] within a dialog.
/// [videoUrl]: The URL of the video to be displayed.
  Future<void> viewVideo(String videoUrl) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (stfContext, stfSetState) {
            return FloatingDialog(
              onClose: () {
                Navigator.of(context).pop();
              },
              child: SizedBox(
                  height: 400,
                  width: 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (videoUrl.isNotEmpty)
                        SizedBox(
                          height: 350,
                          width: 450,
                          child: videoUrl.isNotEmpty &&
                                  videoUrl.contains('vimeo')
                              ? VimeoPlayer(videoId: getVimeoID(videoUrl))
                              : YoutubePlayer(
                                  controller:
                                      YoutubePlayerController.fromVideoId(
                                    videoId:
                                        YoutubePlayerController.convertUrlToId(
                                            videoUrl)!,
                                    autoPlay: false,
                                    params: const YoutubePlayerParams(
                                        showFullscreenButton: true),
                                  ),
                                ),
                        )
                    ],
                  )),
            );
          });
        });
  }

/// Displays a dialog for playing an audio file from a provided URL.
/// Allows the user to play, pause, and seek an audio file from the provided [audioUrl] within a dialog.
/// [audioUrl]: The URL of the audio file to be played.
  Future<void> viewAudio(String audioUrl) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (stfContext, stfSetState) {
            return FloatingDialog(
              onClose: () {
                Navigator.of(context).pop();
                pauseAudio();
              },
              child: SizedBox(
                  height: 500,
                  width: 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text('mp3 Player', style: TextStyle(fontSize: 30)),
                      if (audioUrl.isNotEmpty)
                        SizedBox(
                          height: 350,
                          width: 400,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  playAudio();
                                },
                                child: const Text('Play'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setAudio();
                                },
                                child: const Text('Restart'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  pauseAudio();
                                },
                                child: const Text('Pause'),
                              ),
                              StreamBuilder<DurationState>(
                                stream: player.positionStream.map((position) =>
                                    DurationState(
                                        progress: position,
                                        buffered: player.bufferedPosition,
                                        total:
                                            player.duration ?? Duration.zero)),
                                builder: (context, snapshot) {
                                  final durationState = snapshot.data;
                                  final progress =
                                      durationState?.progress ?? Duration.zero;
                                  final buffered =
                                      durationState?.buffered ?? Duration.zero;
                                  final total =
                                      durationState?.total ?? Duration.zero;
                                  return ProgressBar(
                                    progress: progress,
                                    buffered: buffered,
                                    total: total,
                                    onSeek: (duration) {
                                      player.seek(duration);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () => {Navigator.pop(context), pauseAudio()},
                        child: const Text('Close'),
                      ),
                    ],
                  )),
            );
          });
        });
  }
}

/// Plays the audio clip.
/// Starts playback of the audio clip using the [player].
Future<void> playAudio() async {
  player.play();
}

/// Pauses playback of the audio clip.
/// Pauses playback of the audio clip using the [player].
Future<void> pauseAudio() async {
  await player.pause();
}

/// Sets the audio clip.
/// Sets the audio clip to be played using the [player].
Future<void> setAudio() async {
  await player.setClip();
}

/// Represents the state of a media player's playback duration.
/// Contains information about the progress, buffered duration, and total duration of media playback.
class DurationState {
  const DurationState(
      {required this.progress, required this.buffered, required this.total});
  final Duration progress;
  final Duration buffered;
  final Duration total;
}

/// Extracts the Vimeo video ID from a given URL.
/// Parses the provided [url] string using a regular expression to extract the Vimeo video ID.
/// [url]: The URL string from which to extract the Vimeo video ID.
/// Returns a [String] representing the Vimeo video ID if found; otherwise, returns an empty string.
String getVimeoID(String url) {
  RegExp regExp = RegExp(r"([0-9]{6,11})");
  RegExpMatch? match = regExp.firstMatch(url);
  if (match != null) {
    return url.substring(match.start, match.end);
  }
  return '';
}
