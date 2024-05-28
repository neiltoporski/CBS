import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:floating_dialog/floating_dialog.dart';
import 'package:flutter/material.dart';

// Link Pages
import './node_functions.dart';
import '../main.dart';
import '../devs/dev_main_menu.dart';

// media packages
import 'package:just_audio/just_audio.dart';
import 'package:vimeo_player_flutter/vimeo_player_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:widget_zoom/widget_zoom.dart';

// Audio player instance for playing audio clips.
// Used to control playback of audio clips. Initialize with [AudioPlayer].
final player = AudioPlayer();

// Controller for managing the URL input.
final url = TextEditingController();

// Upload File Variables
String? imageUrl = '';
String? audioUrl = '';
String? videoUrl = '';

Future<void> dmNode(BuildContext context, int numNodes) async {
  var db = FirebaseFirestore.instance;
  const List<String> score = <String>[
    '5',
    '4',
    '3',
    '2',
    '1',
    '0',
    '-1',
    '-2',
    '-3',
    '-4',
    '-5'
  ];
  // Initial Variables
  String initDescription = '';
  List<List<String>>initChoices = [['']];

  getNodeInfo() async {
    final docRef = db
        .collection('devs')
        .doc(accountEmail) // email linked to account
        .collection('Simulations')
        .doc(simName) // simulation name
        .collection('Nodes')
        .doc('Node$numNodes');
    // Gets existing Node Information if available
    try {
      DocumentSnapshot doc = await docRef.get();
      if (doc.exists) {
        initDescription = doc.get('Description');
        initChoices = List.generate(4, (i) => <String>[
                doc.get('Option ${i+1}'),
                doc.get('Score ${i+1}').toString(),
                doc.get('Explanation ${i+1}')]);
        imageUrl = doc.get('imageUrl');
        audioUrl = doc.get('audioUrl');
        videoUrl = doc.get('videoUrl');
        if (audioUrl!.isNotEmpty) {
          player.setUrl(audioUrl!);
        }
      }
    } catch (e) {}
  }

  // Call getNodeInfo to fetch the description
  await getNodeInfo();
  // textVariables
  
  final description = TextEditingController(text: initDescription);
  List<List<TextEditingController>> choices = List.generate(4, (i) => List.generate(3, (j) => TextEditingController(text: initChoices[i][j])));
  return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return FloatingDialog(
              onClose: () {
                Navigator.of(context).pop();
              },
              child: SizedBox(
                height: 500, // Increased height to accommodate content
                width: 800,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Flexible(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: <Widget>[
                            const Text('Decision Making Node',
                                style: TextStyle(fontSize: 25)),
                            // Displays a row of icons for uploading media files.
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  // IconButton for uploading images
                                  IconButton(
                                    onPressed: () async {
                                      await iuputImage(context);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.image),
                                    tooltip: 'Upload Image',
                                  ),
                                  // IconButton for uploading videos
                                  IconButton(
                                    onPressed: () async {
                                      await iuputVideo(context);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.ondemand_video),
                                    tooltip: 'Upload Video',
                                  ),
                                  // IconButton for uploading audio files
                                  IconButton(
                                    onPressed: () async {
                                      await iuputAudio(context);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.music_video),
                                    tooltip: 'Upload Audio',
                                  )
                                ]
                                ),
                                SizedBox(
                                  //height: 100,
                                  //width: 300,
                                  child: TextField(
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                        labelText: 'Description',
                                        border: OutlineInputBorder()),
                                    controller: description,
                                  ),
                                ),
                                //const SizedBox(height: 30,width: 200),
                                const Padding(
                                  padding: EdgeInsets.only(top: 15),
                                  child: Text('Choices', style: TextStyle(fontSize: 20))
                                ),
                                Container(
                                  margin: const EdgeInsets.all(10.0),
                                  padding: const EdgeInsets.all(10.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: 4,
                                    itemBuilder: (context, index) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: <Widget>[
                                          SizedBox(
                                            height: 60,
                                            width: 300,
                                            child: FocusScope(
                                              child: Focus(
                                                onFocusChange: (focus) {
                                                  setState(() {
                                                    // Loop from the current row to the last row
                                                    for (int j = index; j < 3; j++) {
                                                      // Check if all fields in the current row are empty and the DropdownButton is 0
                                                      if (([choices[j][0]]+[choices[j][2]]).every((controller) => controller.text.isEmpty) && choices[j][1].text == '0') {
                                                        // Check if there is a next row and it has data
                                                        if (([choices[j+1][0]]+[choices[j+1][2]]).any((controller) => controller.text.isNotEmpty) || choices[j+1][1].text != '0') {
                                                          // Move data from the next row to the current row
                                                          for (int i = 0; i < choices[j].length; i++) {
                                                            if (i != 1) {
                                                              choices[j][i].text = choices[j+1][i].text;
                                                              choices[j+1][i].text = '';
                                                            }
                                                          }
                                                          // Update the DropdownButton value
                                                          choices[j][1].text = choices[j+1][1].text;
                                                          choices[j+1][1].text = '0';
                                                        }
                                                      }
                                                    }
                                                  });
                                                },
                                                child: TextField(
                                                  enabled: (index != 0) 
                                                  ? (choices[index-1][0].text.isNotEmpty
                                                      || int.parse(choices[index-1][1].text) != 0
                                                      || choices[index-1][2].text.isNotEmpty
                                                    )
                                                  : true,
                                                  decoration: InputDecoration(
                                                    labelText: 'Option ${index+1}'
                                                  ),
                                                  controller: choices[index][0], //options,
                                                )
                                              )
                                            )
                                          ),
                                          DropdownButton<String>( 
                                            value: choices[index][1].text.isNotEmpty ? choices[index][1].text : '0',
                                            icon: const Icon(Icons.arrow_downward),
                                            elevation: 16,
                                            style: const TextStyle(color: Colors.deepPurple),
                                            onChanged: (
                                              (index != 0) 
                                              ? (choices[index-1][0].text.isNotEmpty
                                                || int.parse(choices[index-1][1].text) != 0
                                                || choices[index-1][2].text.isNotEmpty
                                              )
                                              : true)
                                                ? (String? value) {
                                                  setState(() {
                                                    choices[index][1].text = value!;
                                                    // Loop from the current row to the last row
                                                    for (int j = index; j < 3; j++) {
                                                      // Check if all fields in the current row are empty and the DropdownButton is 0
                                                      if (([choices[j][0]]+[choices[j][2]]).every((controller) => controller.text.isEmpty) && choices[j][1].text == '0') {
                                                        // Check if there is a next row and it has data
                                                        if (([choices[j+1][0]]+[choices[j+1][2]]).any((controller) => controller.text.isNotEmpty) || choices[j+1][1].text != '0') {
                                                          // Move data from the next row to the current row
                                                          for (int i = 0; i < choices[j].length; i++) {
                                                            if (i != 1) {
                                                              choices[j][i].text = choices[j+1][i].text;
                                                              choices[j+1][i].text = '';
                                                            }
                                                          }
                                                          // Update the DropdownButton value
                                                          choices[j][1].text = choices[j+1][1].text;
                                                          choices[j+1][1].text = '0';
                                                        }
                                                      }
                                                    }
                                                  });
                                                } 
                                                : null,
                                            items: score.map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                          SizedBox(
                                            height: 60,
                                            width: 300,
                                            child: FocusScope(
                                              child: Focus(
                                                onFocusChange: (focus) {
                                                  setState(() {
                                                    // Loop from the current row to the last row
                                                    for (int j = index; j < 3; j++) {
                                                      // Check if all fields in the current row are empty and the DropdownButton is 0
                                                      if (([choices[j][0]]+[choices[j][2]]).every((controller) => controller.text.isEmpty) && choices[j][1].text == '0') {
                                                        // Check if there is a next row and it has data
                                                        if (([choices[j+1][0]]+[choices[j+1][2]]).any((controller) => controller.text.isNotEmpty) || choices[j+1][1].text != '0') {
                                                          // Move data from the next row to the current row
                                                          for (int i = 0; i < choices[j].length; i++) {
                                                            if (i != 1) {
                                                              choices[j][i].text = choices[j+1][i].text;
                                                              choices[j+1][i].text = '';
                                                            }
                                                          }
                                                          // Update the DropdownButton value
                                                          choices[j][1].text = choices[j+1][1].text;
                                                          choices[j+1][1].text = '0';
                                                        }
                                                      }
                                                    }
                                                  });
                                                },
                                                child: TextField(
                                                  enabled: (index != 0) 
                                                  ? (choices[index-1][0].text.isNotEmpty
                                                      || int.parse(choices[index-1][1].text) != 0
                                                      || choices[index-1][2].text.isNotEmpty
                                                    )
                                                  : true,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Explanation'
                                                  ),
                                                  controller: choices[index][2],
                                                )
                                              )
                                            )
                                          ),
                                          ]
                                      );
                                    }
                                  )
                                )
                          ]
                        )
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: OverflowBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              var scores = List<int>.filled(8, 0);
                              for (int i = 0; i < choices.length; i++) {
                                if (choices[i][1].text != "") {
                                  scores[i] = int.parse(choices[i][1].text);
                                }
                                }

                              // Creating Node object
                              final newNode = <String, dynamic>{
                                "Type": "DM",
                                "Description": description.text,
                                "Option 1": choices[0][0].text,
                                "Score 1": scores[0],
                                "Explanation 1": choices[0][2].text,
                                "Option 2": choices[1][0].text,
                                "Score 2": scores[1],
                                "Explanation 2": choices[1][2].text,
                                "Option 3": choices[2][0].text,
                                "Score 3": scores[2],
                                "Explanation 3": choices[2][2].text,
                                "Option 4": choices[3][0].text,
                                "Score 4": scores[3],
                                "Explanation 4": choices[3][2].text,
                                "imageUrl": imageUrl,
                                "videoUrl": videoUrl,
                                "audioUrl": audioUrl,
                              };

                              // saving nodes
                              db
                                  .collection('devs')
                                  .doc(accountEmail) // email linked to account
                                  .collection('Simulations')
                                  .doc(simName) // simulation name
                                  .collection('Nodes')
                                  .doc('Node$numNodes')
                                  .set(newNode);

                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          )
                        ],
                      ),
                    )
                  ])
                ),
              ));
        });
      },
    );
  }

/// Plays the audio clip.
/// Starts playback of the audio clip using the [player].
Future<void> playAudio() async {
  player.play();
}

/// Pauses the audio clip.
/// Pauses playback of the audio clip using the [player].
Future<void> pauseAudio() async {
  await player.pause();
}

/// Sets the audio clip.
/// Sets the audio clip to be played using the [player].
Future<void> setAudio() async {
  await player.setClip();
}

// Displays a dialog for inputting and playing videos from YouTube or Vimeo URLs.
/// Allows the user to input a YouTube or Vimeo URL, loads the video from the URL,
/// and plays it within the dialog using a [YoutubePlayer] or [VimeoPlayer] widget.
Future<void> iuputVideo(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (stfContext, stfSetState) {
        return FloatingDialog(
          onClose: () {
            Navigator.of(context).pop();
          },
          child: SizedBox(
              height: 500,
              width: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Enter Youtube/Vimeo URL:'),
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Enter URL here'),
                    controller: url,
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        {videoUrl = url.text, stfSetState(() {})},
                    child: const Text('Load Video'),
                  ),
                  if (videoUrl!.isNotEmpty)
                    SizedBox(
                        height: 300,
                        width: 450,
                        child: videoUrl!.isNotEmpty &
                                videoUrl!.contains('vimeo')
                            ? VimeoPlayer(videoId: getVimeoID(videoUrl!))
                            : YoutubePlayer(
                                controller:
                                    YoutubePlayerController.fromVideoId(
                                  videoId:
                                      YoutubePlayerController.convertUrlToId(
                                          videoUrl!)!,
                                  autoPlay: false,
                                  params: const YoutubePlayerParams(
                                      showFullscreenButton: true),
                                ),
                              )),
                  ElevatedButton(
                    onPressed: () => {videoUrl = '', stfSetState(() {})},
                    child: const Text('Delete'),
                  ),
                  ElevatedButton(
                    onPressed: () => {Navigator.pop(context)},
                    child: const Text('Close'),
                  ),
                ],
              )),
        );
      });
    });
}

/// Displays a dialog for selecting and displaying images.
/// Allows the user to select an image file from their device, uploads the selected image file,
/// and displays it within the dialog using an [Image.network] widget wrapped with a zoom effect.
Future<void> iuputImage(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (stfContext, stfSetState) {
          return FloatingDialog(
            onClose: () {
              Navigator.of(context).pop();
            },
            child: SizedBox(
                height: 500,
                width: 500,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async => {
                        imageUrl = await uploadFile('image'),
                        stfSetState(() {})
                      },
                      child: const Text('Pick a image'),
                    ),
                    if (imageUrl!.isNotEmpty) Text(getFileName(imageUrl!)),
                    if (imageUrl!.isNotEmpty)
                      SizedBox(
                          height: 350,
                          width: 450,
                          child: imageUrl!.isNotEmpty
                              ? WidgetZoom(
                                  heroAnimationTag: 'tag',
                                  zoomWidget: Image.network(imageUrl!))
                              : null),
                    if (imageUrl!.isNotEmpty)
                      ElevatedButton(
                        onPressed: () => {imageUrl = '', stfSetState(() {})},
                        child: const Text('Delete'),
                      ),
                    ElevatedButton(
                      onPressed: () => {Navigator.pop(context)},
                      child: const Text('Close'),
                    ),
                  ],
                )),
          );
        });
      });
}

/// Displays a dialog for selecting and playing audio files.
/// Allows the user to select an audio file from their device, uploads the selected audio file,
/// and plays it within the dialog using an [AudioPlayer] widget.
Future<void> iuputAudio(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (stfContext, stfSetState) {
        return FloatingDialog(
          onClose: () {
            Navigator.of(context).pop();
          },
          child: SizedBox(
              height: 500,
              width: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('mp3 Player', style: TextStyle(fontSize: 30)),
                  ElevatedButton(
                    onPressed: () async => {
                      audioUrl = await uploadFile('audio'),
                      player.setUrl(audioUrl!),
                      stfSetState(() {})
                    },
                    child: const Text('Pick an audio'),
                  ),
                  if (audioUrl!.isNotEmpty)
                    SizedBox(
                      height: 350,
                      width: 450,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(getFileName(audioUrl!)),
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
                                    total: player.duration ?? Duration.zero)),
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
                          ElevatedButton(
                            onPressed: () =>
                                {audioUrl = '', stfSetState(() {})},
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => {Navigator.pop(context)},
                    child: const Text('Close'),
                  ),
                ],
              )),
        );
      });
    });
}

/// Extracts the Vimeo video ID from a given URL.
/// Parses the provided [url] string using a regular expression to extract the Vimeo video ID.
/// If a valid Vimeo video ID is found, returns the ID; otherwise, returns an empty string.
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

/// Retrieves the file name from a Firebase Storage URL.
/// Parses the provided [url] string representing a Firebase Storage URL to extract the file name.
/// [url]: The Firebase Storage URL from which to retrieve the file name.
/// Returns a [String] representing the file name extracted from the URL.
String getFileName(String url) {
  var storageReference = FirebaseStorage.instance.refFromURL(url);
  String imgName = storageReference.name;
  return imgName;
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
