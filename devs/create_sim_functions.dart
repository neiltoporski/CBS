import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// link pages
import '../main.dart';
import './dev_main_menu.dart';
import './dev_menu_functions.dart';
import './create_sim.dart';
import '../nodes/node_functions.dart';

// Checks number of nodes
Future<int> getNumChildren(int curr) async {

  var db = FirebaseFirestore.instance;

  final collectionRef = db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$curr')
      .collection('Children');

  final snapshot = await collectionRef.count().get();
  final numberNodes = snapshot.count;

  int total = numberNodes!;

  return total;
}

// Checks number of children
Future<bool> isMaxChildren(int curr, int max) async {

  var db = FirebaseFirestore.instance;

  final collectionRef = db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$curr')
      .collection('Children');

 
    final snapshot = await collectionRef.count().get();
    final numberNodes = snapshot.count;
 
  int total = numberNodes!;

  // if number of children is greater than 4 return true
  // else return true
  if (total >= max) {
    return true;
  } else {
    return false;
  }
}

// Max children reached
Future<void> maxChildren(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => const AlertDialog(
      title: Text('Max Children Reached'),
      content: SizedBox(
        height: 20,
        width: 200,
      ),
    ),
  );
}
// Max Nodes reached
Future<void> maxNodes(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => const AlertDialog(
      title: Text('Max Number of Nodes Reached: 10'),
      content: SizedBox(
        height: 20,
        width: 200,
      ),
    ),
  );
}
// Delete scenario error
Future<void> deleteScenario(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => const AlertDialog(
      title: Text('Can not delete scenario node!'),
      content: SizedBox(
        height: 20,
        width: 200,
      ),
    ),
  );
}

void initialGraphHelper() {
  var db = FirebaseFirestore.instance;

  for (int i = 0; i <= 8; i++) {}
  // Creating Node object
  final parentNode = <String, dynamic>{
    "Node": 0,
  };

  final childNode = <String, dynamic>{
    "Node": 1,
  };

  // saving Child
  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node0')
      .set(initialSCENARIO());
  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node0')
      .collection('Children')
      .doc('Node1')
      .set(childNode);
  // saving Parent
  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node1')
      .set(initialIG());
  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node1')
      .collection('Parents')
      .doc('Node0')
      .set(parentNode);
}
void initialGraphHelper0() {
  var db = FirebaseFirestore.instance;

  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node0')
      .set(initialSCENARIO());
}

// helper for add node
Future<void> addNodeHelper(String type, int curr, int n) async {
  var db = FirebaseFirestore.instance;

  // Creating Node object
  final parentNode = <String, dynamic>{
    "Node": curr,
  };
  final childNode = <String, dynamic>{
    "Node": n,
  };
  switch(type){
    case 'SCENARIO' :{
      db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$n')
      .set(initialSCENARIO());
    }
    case 'IG' :{
      db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$n')
      .set(initialIG());
    }
    case 'END' :{
      db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$n')
      .set(initialEND());
    }
    case 'DM' :{
      db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$n')
      .set(initialDM());
    }
    default : {
      db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$n')
      .set(initialSCENARIO());
    }
  }
  // Saving parent and child to firestore
  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$curr')
      .collection('Children')
      .doc('Node$n')
      .set(childNode);
  db
      .collection('devs')
      .doc(accountEmail) // email linked to account
      .collection('Simulations')
      .doc(simName) // simulation name
      .collection('Nodes')
      .doc('Node$n')
      .collection('Parents')
      .doc('Node$curr')
      .set(parentNode);
}

// inital objects for Nodes
initialSCENARIO() {
  final newNode = <String, dynamic>{
    "Type": "SCENARIO",
    "Description": "",
    "imageUrl": "",
    "videoUrl": "",
    "audioUrl": "",
  };
  return newNode;
}

initialIG() {
  final newNode = <String, dynamic>{
    "Type": "IG",
    "Description": "",
    "Option 1": "",
    "Information 1": "",
    "Score 1": 0,
    "Explanation 1": "",
    "Option 2": "",
    "Information 2": "",
    "Score 2": 0,
    "Explanation 2": "",
    "Option 3": "",
    "Information 3": "",
    "Score 3": 0,
    "Explanation 3": "",
    "Option 4": "",
    "Information 4": "",
    "Score 4": 0,
    "Explanation 4": "",
    "Option 5": "",
    "Information 5": "",
    "Score 5": 0,
    "Explanation 5": "",
    "Option 6": "",
    "Information 6": "",
    "Score 6": 0,
    "Explanation 6": "",
    "Option 7": "",
    "Information 7": "",
    "Score 7": 0,
    "Explanation 7": "",
    "Option 8": "",
    "Information 8": "",
    "Score 8": 0,
    "Explanation 8": "",
    "imageUrl": "",
    "videoUrl": "",
    "audioUrl": "",
  };
  return newNode;
}

initialDM() {
  final newNode = <String, dynamic>{
    "Type": "DM",
    "Description": "",
    "Option 1": "",
    "Information 1": "",
    "Score 1": 0,
    "Explanation 1": "",
    "Option 2": "",
    "Information 2": "",
    "Score 2": 0,
    "Explanation 2": "",
    "Option 3": "",
    "Information 3": "",
    "Score 3": 0,
    "Explanation 3": "",
    "Option 4": "",
    "Information 4": "",
    "Score 4": 0,
    "Explanation 4": "",
    "imageUrl": "",
    "videoUrl": "",
    "audioUrl": "",
  };
  return newNode;
}

initialEND() {
  final newNode = <String, dynamic>{
    "Type": "END",
    "Description": "",
  };
  return newNode;
}

String _printDuration(Duration duration) {
  String negativeSign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  //String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  //return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes";
}

void publish(PathInfo optimalPath) async {
  DateFormat dateFormat = DateFormat('yMd').add_jm();
  var db = FirebaseFirestore.instance;
  var sim = db
            .collection('devs')
            .doc(accountEmail)
            .collection('Simulations')
            .doc(simName);
  String simPath = sim.path;
  var docSnapshot = await sim.get();
  Map<String, dynamic>? data = docSnapshot.data();
  String simID = data?['simID'];

  int now = DateTime.now().millisecondsSinceEpoch;
  bool shouldEnable = (!isAvailableForever 
                && (startDateTime!.millisecondsSinceEpoch < now
                && endDateTime!.millisecondsSinceEpoch > now)) || isAvailableForever;

  final publishedSim = <String, dynamic>{
    "simname": simName,
    "displayname": simPubName,
    "owner": accountEmail,
    "path": simPath,
    "maxscore": optimalPath.getScore(),
    "notimelimit": noTimeLimit,
    "timelimit" : timeLimit,
    "availableforever": isAvailableForever,
    "starttime": startDateTime?.millisecondsSinceEpoch,
    "endtime": endDateTime?.millisecondsSinceEpoch,
    "unlimitedattempts": hasUnlimitedAttempts,
    "maxattempts": maxAttempts,
    "enabled" : shouldEnable
  };

    db
      .collection('publishedsims')
      .doc(simID) // simulation name
      .set(publishedSim);
    sim.update({"published": true});

    sim.update({"enabled": shouldEnable});
    if (!noTimeLimit) {
      sim.update({"timelimit" : _printDuration(Duration(minutes: timeLimit!))});
    } else {
      sim.update({"timelimit" : "Unlimited"});
    }
    if (!isAvailableForever) {
      sim.update({"availtime" : "${dateFormat.format(startDateTime!)} - ${dateFormat.format(endDateTime!)}"});
    } else {
      sim.update({"availtime" : "Always Available"});
    }
    if (!hasUnlimitedAttempts) {
      sim.update({"availattempts" : maxAttempts.toString()});
    } else {
      sim.update({"availattempts" : "Unlimited"});
    }
    sim.update({"displayname": simPubName});
    sim.update({"manualdisable" : false});
    return;
  }

void unpublish(String simIdentifier) async {
  var db = FirebaseFirestore.instance;
  var sim = db.collection('/devs/$accountEmail/Simulations/').doc(simIdentifier);
  var docSnapshot = await sim.get();
  Map<String, dynamic>? data = docSnapshot.data();
  String simID = data?['simID'];

  var publishedSim = await db.collection('publishedsims').doc(simID).get();
  
  if (publishedSim.exists) 
    {
      sim.update({"published": false});
      sim.update({"enabled" : true});
      sim.update({"displayname": null});
      sim.update({"timelimit": null});
      sim.update({"availtime" : null});
      sim.update({"availattempts" : null});
      sim.update({"manualdisable" : false});
      recursiveDelete(publishedSim.reference);
    }
}

Future<bool> isSimPublished(String simIdentifier) async {
  var db = FirebaseFirestore.instance;
  var sim = db.collection('/devs/$accountEmail/Simulations/').doc(simIdentifier);
  var docSnapshot = await sim.get();
  Map<String, dynamic>? data = docSnapshot.data();
  String simID = data?['simID'];

  var publishedSim = await db.collection('publishedsims').doc(simID).get();

  if (publishedSim.exists) {return true;}
  return false;
}

Future<void> deleteNode(int nodeIndex) async {
  var db = FirebaseFirestore.instance;
  String nodeName = 'Node$nodeIndex';
  CollectionReference nodeCollection = db.collection('/devs/$accountEmail/Simulations/$simName/Nodes');
  var item = nodeCollection.doc(nodeName);

  var parentsSnapshot = await item.collection('Parents').get();
  if (parentsSnapshot.size > 0) {
    var parents = parentsSnapshot.docs;

    for (var parent in parents) {
      DocumentReference parentNodeReference = nodeCollection.doc(parent.id);

      DocumentSnapshot<Object?> parentSnapshot = await parentNodeReference.get();
      Map<String, dynamic>? data = parentSnapshot.data() as Map<String, dynamic>?;
      // If the node to delete is the child of a DM node then the related choice to that node in the DM node is deleted
      // and all the subsequent choices move up in the node
      if (data?['Type'] == 'DM') {
        CollectionReference childrenRef = parentSnapshot.reference.collection('Children');
        QuerySnapshot childrenQuerySnapshot = await childrenRef.get();
        List<String>? children = [];
        for (QueryDocumentSnapshot childSnapshot in childrenQuerySnapshot.docs) {
          Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
          int childIndex = childData?['Node'];
          children.add('Node$childIndex');
        }
        // Have to order the children as firebase orders in alphabetical ordering but we need ordering by node number
        children = orderChildren(children);
        int choiceNum = 0;
        int numChildren = children.length;
        // Determines which choice the node to be deleted is related to
        for (int i = 0; i < numChildren; i++) {
          if (int.parse(children[i].substring(4)) == nodeIndex) {
            choiceNum = i + 1;
            break;
          }
        }
        // Updates the choices so that deleted node choice is gone but all choices still come one after the other
        for (int i = choiceNum; i < numChildren; i++) {
          await parentNodeReference.update({
            'Option $i': data?['Option ${i+1}'],
            'Score $i': data?['Score ${i+1}'],
            'Explanation $i': data?['Explanation ${i+1}']
          });
        }
        await parentNodeReference.update({
          'Option $numChildren': "",
          'Score $numChildren': 0,
          'Explanation $numChildren': ""
        });
      }

      DocumentReference childReference = parentNodeReference.collection('Children').doc(item.id);
      childReference.delete();
    }
  }

  await recursiveNodeDelete(item);
}

/// Sorts the children of a node to be in order based off their node number
/// 
/// Pass in the list of children of the node you want sorted
/// In firebase the nodes are sorted in alphabetical ordering which results in Node11 being before Node2 despite coming later in the simulation.
/// Therefore they need to be sorted before being accessed.
List<String> orderChildren(List<String>? children) {
  List<int> sortedInts = [];
  List<String> sortedChildren = [];
  int size = children!.length;
  for (int i = 0; i < size; i++) {
    sortedInts.add(int.parse(children[i].substring(4)));
  }
  sortedInts.sort();
  for (int i = 0; i < size; i++) {
    sortedChildren.add("Node${sortedInts[i]}");
  }
  return sortedChildren;
}

Future<void> recursiveNodeDelete(var item, {bool fromChildren = false}) async {
  var db = FirebaseFirestore.instance;
  var nodeCollection =  db.collection('/devs/$accountEmail/Simulations/$simName/Nodes');

  if (item is DocumentReference) {

    if (fromChildren == false) {
      var children = await item.collection('Children').get();
      if (children.size > 0) await recursiveNodeDelete(item.collection('Children'));
      var parents = await item.collection('Parents').get();
      if (parents.size > 0) await recursiveNodeDelete(item.collection('Parents'));
      item.delete();
    } 
    else if (fromChildren == true) {
      var referencedItem = nodeCollection.doc(item.id);
      await recursiveNodeDelete(referencedItem, fromChildren: false);
      item.delete();
    }
  }
  if (item is CollectionReference) {

    QuerySnapshot snapshot = await item.get();
    var documents = snapshot.docs;

    for (var doc in documents) {
      (item.id == 'Children') 
      ? await recursiveNodeDelete(doc.reference, fromChildren: true)
      : await recursiveNodeDelete(doc.reference, fromChildren: false);
    }
  }
}
