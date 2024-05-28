import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import './create_sim_functions.dart';

var db = FirebaseFirestore.instance;

deleteSim(String simIdentifier) async {
    var thisSim = db.collection('/devs/$accountEmail/Simulations').doc(simIdentifier);
    recursiveDelete(thisSim);
    unpublish(simIdentifier);
}

recursiveDelete(var item) async {
  if (item is DocumentReference) {

    var nodes = await item.collection('Nodes').get();
    var children = await item.collection('Children').get();
    var parents = await item.collection('Parents').get();
    var results = await item.collection('results').get();
    var attempts = await item.collection('attempts').get();
    
    if (nodes.size > 0) recursiveDelete(item.collection('Nodes'));
    if (children.size > 0) recursiveDelete(item.collection('Children'));
    if (parents.size > 0) recursiveDelete(item.collection('Parents'));
    if (results.size > 0) recursiveDelete(item.collection('results'));
    if (attempts.size > 0) recursiveDelete(item.collection('attempts'));

    item.delete();
  }
  if (item is CollectionReference) {

    QuerySnapshot snapshot = await item.get();
    var documents = snapshot.docs;

    for (var doc in documents) {
      recursiveDelete(doc.reference);
    }
  }
}
