import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../main.dart';
import '../devs/dev_main_menu.dart';
import './nodes.dart';

// Upload_File
enum SampleItem { image, video, audio }

/// Uploads a file of specified [mediaType] to Firebase Storage.
///
/// [mediaType]: The type of media to upload ('image', 'video', or 'audio').
///
/// Returns a [String] representing the download URL of the uploaded file, or `null` if the upload failed.
Future<String?> uploadFile(String mediaType) async {
  // Initialize Firebase Storage reference
  final db = FirebaseStorage.instance.ref();

  // Pick a file based on the specified media type
  var result = (mediaType == 'image')
      ? await FilePicker.platform
          .pickFiles(type: FileType.image, allowCompression: true)
      : (mediaType == 'video')
          ? await FilePicker.platform
              .pickFiles(type: FileType.video, allowCompression: true)
          : (mediaType == 'audio')
              ? await FilePicker.platform
                  .pickFiles(type: FileType.audio, allowCompression: true)
              : null;

  // Handle the result of file picking
  if (result != null) {
    PlatformFile file = result.files.first;
    String? fileExt = file.extension!.toLowerCase();
    var imageExts = ['bmp', 'gif', 'jpeg', 'jpg', 'png'];
    var videoExts = ['avi', 'flv', 'mkv', 'mov', 'mp4', 'mpeg', 'webm', 'wmv'];
    var audioExts = ['aac', 'midi', 'mp3', 'ogg', 'wav'];

    // Check if the file extension is supported
    if (((mediaType == 'image') && (imageExts.contains(fileExt))) ||
        ((mediaType == 'video') && (videoExts.contains(fileExt))) ||
        ((mediaType == 'audio') && (audioExts.contains(fileExt)))) {

      // Check if the file size is within the limit (25 MB)
      if ((file.size <= 26214400)) {
        // Read file bytes
        final fileBytes = file.bytes;
        final fileName = file.name;
        // Upload file to Firebase Storage
        await db
            .child('$accountEmail/$simName/$mediaType/$fileName')
            .putData(fileBytes!);
        // Get download URL of the uploaded file
        String downloadUrl = await db
            .child('$accountEmail/$simName/$mediaType/$fileName')
            .getDownloadURL();
        return downloadUrl;
      } else {
        return '';
      }
    } else {
      return '';
    }
  } else {
    // User canceled the picker
    return '';
  }
}

// End Upload_File

// Create Simulation Object Links

/// Creates a map from firebase where the keys are the node names and the values are the objects for each of the nodes
/// 
/// Account type is either devs or users, email is the accountEmail of the developer who owns the simulation you are accessing, simSection will be the collection the Simulations is in (defaults to Simulations), simName is the name of the simulation
Future<Map<String, NodeSim>?> createSimulationObjects(String accountType, String email, String simName, [String simSection = 'Simulations']) async {
  var db = FirebaseFirestore.instance;
  final docRef = db.collection('devs/$email/$simSection/$simName/Nodes');
  QuerySnapshot querySnapshot = await docRef.get();
  Map<String, NodeSim>? nodes = {};
  // Loops through each node in the simulation, determines the type of node it is then sets the fields of the object accordingly
  for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
    if (docSnapshot.exists) {
      Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;
      String nodeType = data?['Type'];
      String nodeName = docSnapshot.id;
      switch (nodeType) {
        case 'SCENARIO':
          NodeSim scenario = ScenarioNode(data?['audioUrl'], data?['imageUrl'], data?['videoUrl'], data?['Description'], true, null);
          CollectionReference childrenRef = docSnapshot.reference.collection('Children');
          QuerySnapshot childrenQuerySnapshot = await childrenRef.get();
          List<String> children = [];
          for (QueryDocumentSnapshot childSnapshot in childrenQuerySnapshot.docs) {
            Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
            int childIndex = childData?['Node'];
            children.add('Node$childIndex');
          }
          scenario.setChildren = children;
          nodes[nodeName] = scenario;
          break;
        case 'IG':
          List<IGChoice> igChoices = [];
          for (int i = 1; i <= 8; i++) {
            // Only adds choices that are at least partially complete, so no completely empty choices will be present in the object's choice field
            if ((data?['Option $i']?.toString())!.isNotEmpty || 
                (data?['Explanation $i']?.toString())!.isNotEmpty || 
                (data?['Information $i']?.toString())!.isNotEmpty) {
              IGChoice choice = IGChoice(data?['Option $i'], data?['Score $i'], data?['Explanation $i'], data?['Information $i']);
              igChoices.add(choice);
            }
          }
          String? parent;
          CollectionReference parentRef = docSnapshot.reference.collection('Parents');
          QuerySnapshot parentQuerySnapshot = await parentRef.get();
          if (parentQuerySnapshot.docs.isNotEmpty) {
            QueryDocumentSnapshot parentSnapshot = parentQuerySnapshot.docs.first;
            parent = parentSnapshot.id;
          }
          NodeSim ig = IGNode(data?['audioUrl'], data?['imageUrl'], data?['videoUrl'], data?['Description'], true, parent, igChoices);
          CollectionReference childrenRef = docSnapshot.reference.collection('Children');
          QuerySnapshot childrenQuerySnapshot = await childrenRef.get();
          List<String> children = [];
          for (QueryDocumentSnapshot childSnapshot in childrenQuerySnapshot.docs) {
            Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
            int childIndex = childData?['Node'];
            children.add('Node$childIndex');
          }
          ig.setChildren = children;
          nodes[nodeName] = ig;
          break;
        case 'DM':
          List<Choice> dmChoices = [];
          for(int i = 1; i <= 4; i++) {
            // Only adds choices that are at least partially complete, so no completely empty choices will be present in the object's choice field
            if ((data?['Option $i']?.toString())!.isNotEmpty || 
                (data?['Explanation $i']?.toString())!.isNotEmpty) {
              Choice choice = Choice(data?['Option $i'], data?['Score $i'], data?['Explanation $i']);
              dmChoices.add(choice);
            }
          }
          String? parent;
          CollectionReference parentRef = docSnapshot.reference.collection('Parents');
          QuerySnapshot parentQuerySnapshot = await parentRef.get();
          if (parentQuerySnapshot.docs.isNotEmpty) {
            QueryDocumentSnapshot parentSnapshot = parentQuerySnapshot.docs.first;
            parent = parentSnapshot.id;
          }
          NodeSim dm = DMNode(data?['audioUrl'], data?['imageUrl'], data?['videoUrl'], data?['Description'], true, parent, dmChoices);
          CollectionReference childrenRef = docSnapshot.reference.collection('Children');
          QuerySnapshot childrenQuerySnapshot = await childrenRef.get();
          List<String> children = [];
          for (QueryDocumentSnapshot childSnapshot in childrenQuerySnapshot.docs) {
            Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
            int childIndex = childData?['Node'];
            children.add('Node$childIndex');
          }
          dm.setChildren = children;
          nodes[nodeName] = dm;
          break;
        case 'END':
          String? parent;
          CollectionReference parentRef = docSnapshot.reference.collection('Parents');
          QuerySnapshot parentQuerySnapshot = await parentRef.get();
          if (parentQuerySnapshot.docs.isNotEmpty) {
            QueryDocumentSnapshot parentSnapshot = parentQuerySnapshot.docs.first;
            parent = parentSnapshot.id;
          }
          NodeSim end = EndNode(null, null, null, null, true, parent);
          nodes[nodeName] = end;
      }
    } else {
    }
  }
  return nodes;
}

// End Create Simulation Object Links



// Check Simulation Integrity

/// Ensures that the simulation is valid meaning that all paths lead to an end node, all filled options for DM and IG nodes are completely created, and all nodes except end nodes have a description
///
/// Pass in the sim map created from the createSimulationObjects method
/// Returns a list of the node names that have an integrity issue
List<String> checkSimulationIntegrity(Map<String, NodeSim>? simMap) {
  // Creates a stack to keep track of the paths that are still to be explored and starts with the scenario node
  final stack = <MapEntry<String, NodeSim?>>[MapEntry('Node0',simMap?['Node0'])];
  List<String> invalidNodes = [];
  while (stack.isNotEmpty) {
    MapEntry<String,NodeSim?> parentEntry = stack.removeLast();
    NodeSim? parentNode = parentEntry.value;
    String nodeType = parentNode.runtimeType.toString();
    if (nodeType != 'EndNode') {
      // Checks every node that isn't end node it it has children and the correct amount based off their number of choices and those choices are filled
      if (parentNode!.getChildren!.isEmpty || nodeType == 'DMNode' && parentNode.getChildren?.length != (parentNode as DMNode).getChoices.length || !isFilledChoices(parentNode))  {
        invalidNodes.add(parentEntry.key);
      }
      parentNode.getChildren?.forEach((nodeName) { 
          stack.add(MapEntry(nodeName,simMap?[nodeName]));
      });
    }
  }
  return invalidNodes;
}

/// Checks if the node has a description and all the fields of a choice for an IG or DM node are filled out
///
/// Pass in the node object that needs to be checked
bool isFilledChoices(NodeSim node) {
  String nodeType = node.runtimeType.toString();
  if (node.getStoryText!.isEmpty) {
    return false;
  }
  if (nodeType == 'DMNode') {
    DMNode dmNode = node as DMNode;
    List<Choice> choices = dmNode.getChoices;
    if (choices.isEmpty) {
      return false;
    } else {
      // Checks if all fields are filled for each choice
      for (Choice choice in choices) {
        if (choice.getExplanation.isEmpty || 
            choice.getOption.isEmpty) {
          return false;
        }
      }
    }
  } else if (nodeType == 'IGNode') {
    IGNode igNode = node as IGNode;
    List<IGChoice> choices = igNode.getChoices;
    if (choices.isEmpty) {
      return false;
    } else {
      // Checks if all fields are filled for each choice
      for (IGChoice choice in choices) {
        if (choice.getExplanation.isEmpty || 
            choice.getOption.isEmpty || 
            choice.getInformation.isEmpty) {
          return false;
        }
      }
    }
  }
  return true;
}

// End Check Simulation Integrity

/// Class to describe the information related to the connections between nodes in the simulation to be used in a linked list.
/// Holds the name of the node, the weight and the next graph node in the linked list
class GraphNode {
  String nodeName;
  int weight;
  GraphNode? next;

  GraphNode(this.nodeName, this.weight);

  int getWeight() {
    return weight;
  }

  String getNodeName() {
    return nodeName;
  }

  GraphNode? getNext() {
    return next;
  }

  void setWeight(int weight) {
    this.weight = weight;
  }

  void setNodeName(String nodeName) {
    this.nodeName = nodeName;
  }

  void setNext(GraphNode? next) {
    this.next = next;
  }

}

/// Elementary linked list for the adjacency list to store the connections from one node
class LinkedList {

  GraphNode? head;

  // Adds new element at the beginning of the linked list
  void insert(String nodeName, int weight) {
    GraphNode newNode = GraphNode(nodeName, weight);
    if (head == null) {
      head = newNode;
    } else {
      newNode.next = head;
      head = newNode;
    }
  }

  GraphNode? getHead() {
    return head;
  }

}

/// Creates a weighted directed graph by implementing an adjacency list which represents the simulation connections where the weight is the score of that path
/// 
/// Pass in the sim map created from the createSimulationObjects method
Map<String, LinkedList> createGraph(Map<String, NodeSim>? simMap) {
  Map<String, LinkedList> adjacencyList = {};
  simMap?.forEach((nodeName, node) {
    LinkedList linkedList = LinkedList();
    if (node is! EndNode) {
      if (node.getChildren!.isNotEmpty) {
        if (node is DMNode) {
          int index = node.getChildren!.length - 1;
          List<Choice> choices = node.getChoices;
          List<String>? children = node.getChildren;

          if (choices.length != children!.length) {
            for (int i = 0; i < children.length; i++) {
              // if there are more children than choices filled, adds temporary choices to allow them to be rendered
              if (i > choices.length - 1) {
                choices.add(Choice("",0,""));
              }
            }
          }

          // Since the linked list adds at the front want the children nodes to be in reverse order and you have to address the weights from the back
          List<String> revChildren = reverseOrderChildren(children);

          for (String childName in revChildren) {
            int weight = 0;
            if (isFilledChoices(node)) {
              weight = choices[index].getScore;
            }
            index--;
            linkedList.insert(childName, weight);
          }
        } else if (node is IGNode) {
          // Score of the IG node is the sum of all positive score options
          int totalScore = 0;
          for (Choice choice in node.getChoices) {
            int score = choice.getScore;
            if (score > 0) {
              totalScore += score;
            }
          }
          linkedList.insert(node.getChildren![0], totalScore);
        } else {
          // Scenario node connections do not have any scores associated
          linkedList.insert(node.getChildren![0], 0);
        }
      }
    }
    adjacencyList[nodeName] = linkedList;
  });
  return adjacencyList;
}

/// Sorts the children of a node to be in reverse order based off their node number
///
/// Pass in the list of children of the node you want sorted
/// In firebase the nodes are sorted in alphabetical ordering which results in Node11 being before Node2 despite coming later in the simulation.
/// Therefore they need to be sorted before being accessed.
List<String> reverseOrderChildren(List<String>? children) {
  List<int> sortedInts = [];
  List<String> reverseSortedChildren = [];
  int size = children!.length;
  // Gets the node number from the node name and puts it in a list to sort
  for (int i = 0; i < size; i++) {
    sortedInts.add(int.parse(children[i].substring(4)));
  }
  sortedInts.sort();
  // Reverses sorted list and adds back on the node name to the number
  for (int i = size - 1; i >= 0; i--) {
    reverseSortedChildren.add("Node${sortedInts[i]}");
  }
  return reverseSortedChildren;
}


/// Class to hold the score and path for the optimal path of the simulation
class PathInfo {
  int score;
  List<String> path;

  PathInfo(this.score, this.path);

  int getScore() {
    return score;
  }

  List<String> getPath() {
    return path;
  }

  void clearPath() {
    path = [];
  }

}

/// Calculates the optimal path of the simulation by doing a depth first search of the graph
///
/// Pass in the graph returned by createGraph
/// Returns a PathInfo object that holds the score of the optimal path and the optimal path as a list of node names
PathInfo checkOptimalPath(Map<String, LinkedList> graph) {
  // Create a stack to perform the DFS on the graph
  int maxScore = 0;
  List<String> optimalPath = [];
  List<MapEntry<String, PathInfo>> stack = [MapEntry("Node0", PathInfo(0, []))];
  while (stack.isNotEmpty) {
    MapEntry<String, PathInfo> current = stack.removeLast();
    String currentNode = current.key;
    int currentWeight = current.value.getScore();
    List<String> path = List<String>.from(current.value.getPath());
    GraphNode? child = graph[currentNode]!.getHead();
    // Reach an end node so need to determine if this path has the best score
    if (child == null && currentWeight > maxScore) {
      maxScore = currentWeight;
      path.add(currentNode);
      optimalPath = List<String>.from(path);
    }
    // Adds all the connected children to the stack to explore with the information of the path thus far
    while (child != null) {
      List<String> newPath = List<String>.from(path);
      newPath.add(currentNode);
      stack.insert(0, MapEntry(child.getNodeName(), PathInfo(currentWeight + child.getWeight(), newPath)));
      child = child.getNext();
    }
  }
  return PathInfo(maxScore, optimalPath);
}
