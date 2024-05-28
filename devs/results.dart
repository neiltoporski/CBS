import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './dev_menu_functions.dart';

//Void function to be called by the DevMainMenu.
//Accepts the simulations name and simulationID as arguments for query comparison.
//Uses the lastName list and userScore list to display them in the Dialog Box when 'Results' button
//is pressed.

void resultsDialog(BuildContext context,String simName, String simID) async {
  var db = FirebaseFirestore.instance;
  int? selectedIndex;

  // displays a dialog with clickable tiles. These tiles contain each user who has completed the simulation.
  showDialog(context: context, 
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text('$simName results'),
      content: Container(
        width: 800,
        height: 400,
        margin: const EdgeInsets.all(10.0),
        padding: const EdgeInsets.all(10.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey)
        ),
        child: Column(
          children: [
            Expanded(
              child: StatefulBuilder(
                builder: (context, StateSetter setState) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: db.collection('publishedsims/$simID/results').snapshots(),
                    builder: (context,snapshot) {
                      List<ListTile> userTiles = [];
                      
                      if(!snapshot.hasData) return const CircularProgressIndicator();

                      final usersCompleted = snapshot.data!.docs.reversed.toList();

                      for(var user in usersCompleted) {
                        final userTile = ListTile(
                          title: Text(user["lastname"]),
                          subtitle: Text("Email: ${user.id}"),
                          selectedTileColor: const Color.fromARGB(255, 206, 206, 206),
                          selectedColor: Colors.black,
                          selected: usersCompleted.indexOf(user) == selectedIndex,
                          onTap: () {
                            if (usersCompleted.indexOf(user) == selectedIndex) {
                              //open menu
                            }
                            setState(() {
                              selectedIndex = usersCompleted.indexOf(user);
                            });
                          },
                          trailing: (selectedIndex == usersCompleted.indexOf(user)) 
                            ? FractionallySizedBox(
                                widthFactor: 0.5,
                                heightFactor: 1,
                                alignment: FractionalOffset.centerRight,
                                child: ButtonBar(
                                  mainAxisSize: MainAxisSize.min,
                                  alignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    ElevatedButton(
                                      // Opens the menu to view/remove a user's individual attempt scores.
                                      onPressed: () => {viewAttempts(user, context)},
                                      child: const Text('Scores'),
                                    ),
                                    ElevatedButton(
                                      //deletes all of a user's attempt scores.
                                      onPressed: () => {removeAllAttempts(user, context)},
                                      child: const Text("Remove All Attempts"),
                                    ),
                                  ],
                                ),
                              )
                            : null
                        );

                        userTiles.add(userTile);
                      }
                      
                      return (userTiles.isNotEmpty)
                        ? ListView(children: userTiles.reversed.toList())
                        : Container(
                            margin: const EdgeInsets.all(10.0),
                            padding: const EdgeInsets.all(10.0),
                            alignment: Alignment.center,
                            child: const Text('No users have completed this simulation.')
                          );
                    }
                  );
                }
              )
            )
          ]
        )
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        )
      ],
    )
  );
}

// dialog to confirm attempt deletion
removeAllAttempts(QueryDocumentSnapshot user, BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Are you sure you wish to remove all of ${user.id}'s attempts?"),
          const Text('This user will be able to complete this simulation again.',textScaler: TextScaler.linear(0.65),)
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
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                recursiveDelete(user.reference);
                Navigator.pop(context);
              },
              child: const Text('Remove Attempts'),
            ),
          ]
        )
      ],
    ),
  );
}

// dialog for showing all attempt scores for the selected user.
Future<void> viewAttempts(QueryDocumentSnapshot user, BuildContext context) async {
  int? selectedIndex;

  QuerySnapshot attemptSnapshot = await user.reference.collection('attempts').get();
  final attempts = attemptSnapshot.docs.reversed.toList();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${user.id}'s attempts"),
          const Text('You can only remove the most recent attempt.',textScaler: TextScaler.linear(0.65))
        ]
      ),
      content: Container(
        height: 400,
        width: 400,
        margin: const EdgeInsets.all(10.0),
        padding: const EdgeInsets.all(10.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey)
        ),
        child: StatefulBuilder(
          builder: (context, StateSetter setState) {
            List<ListTile> attemptTiles = [];

            for (var attempt in attempts) {
              String userScore = attempt['score'].toString();
              String maxScore = attempt['maxscore'].toString();

              final attemptTile = ListTile(
                title: Text("Attempt ${attempt.id}: $userScore out of $maxScore"),
                selectedTileColor: const Color.fromARGB(255, 206, 206, 206),
                selectedColor: Colors.black,
                selected: attempts.indexOf(attempt) == selectedIndex,
                onTap: () {
                  setState(() {
                    selectedIndex = attempts.indexOf(attempt);
                  });
                },
                trailing: (selectedIndex == attempts.indexOf(attempt)) 
                  ? FractionallySizedBox(
                      widthFactor: 0.3,
                      heightFactor: 0.5,
                      alignment: FractionalOffset.centerRight,
                      child: ElevatedButton(
                        onPressed: (selectedIndex == 0) 
                        ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              scrollable: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.5),
                              title: Text("Are you sure you wish to remove ${user.id}'s latest attempt (attempt ${attempt.id})?"),
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
                                        attempt.reference.delete();
                                        if (attempts.indexOf(attempts.last) == 0) {
                                          user.reference.delete();
                                        }
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Remove Attempt'),
                                    ),
                                  ]
                                )
                              ],
                            ),
                          );
                        } 
                        : null,
                        child: const Text("Remove"),
                      ),
                    )
                  : null
                );

                attemptTiles.add(attemptTile);
              }
                
            return (attemptTiles.isNotEmpty)
              ? ListView(children: attemptTiles.reversed.toList())
              : Container(
                  margin: const EdgeInsets.all(10.0),
                  padding: const EdgeInsets.all(10.0),
                  alignment: Alignment.center,
                  child: const Text('No more attempts found.')
                );
          }
        )
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        )
      ],
    )
  );
}
