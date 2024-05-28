
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:floating_dialog/floating_dialog.dart';
import 'package:flutter/material.dart';

// Link Files
import '../main.dart';
import '../nodes/node_functions.dart';
import '../devs/dev_main_menu.dart';
//media imports
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

Future<void> scenarioNode(BuildContext context, int numNodes) async {
  var db = FirebaseFirestore.instance;

  // Initial Variables
  String initDescription = '';

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
        imageUrl = doc.get('imageUrl');
        audioUrl = doc.get('audioUrl');
        videoUrl = doc.get('videoUrl');
        if (audioUrl!.isNotEmpty) {
          player.setUrl(audioUrl!);
        }
      } else {
      }
    } catch (e) {
    }
  }

  // Call getNodeInfo to fetch the description
  await getNodeInfo();

  // text variables
  final description = TextEditingController(text: initDescription);

  return showDialog<void>(
      context: context,
      builder: (BuildContext coontext) {
        return StatefulBuilder(builder: (context, setState) {
          return FloatingDialog(
              onClose: () {
                Navigator.of(context).pop();
              },
              child: SizedBox(
                height: 400, // Increased height to accommodate content
                width: 800,
                child: Padding(
                  padding: const EdgeInsets.all(10), // edge padding
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: <Widget>[
                      const Text('Scenario Node',
                          style: TextStyle(fontSize: 25)), //modal header
                      Center(
                        child:
                            Text(simName, style: const TextStyle(fontSize: 20)),
                      ),
                      // Displays a row of icons for uploading media files.
                      Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // IconButton for uploading images
                            IconButton(
                              onPressed: () async {
                                await iuputImage(context);
                              },
                              icon: const Icon(Icons.image),
                              tooltip: 'Upload Image',
                            ),
                            // IconButton for uploading videos
                            IconButton(
                              onPressed: () async {
                                await iuputVideo(context);
                              },
                              icon: const Icon(Icons.ondemand_video),
                              tooltip: 'Upload Video',
                            ),
                            // IconButton for uploading audio files
                            IconButton(
                              onPressed: () async {
                                await iuputAudio(context);
                              },
                              icon: const Icon(Icons.music_video),
                              tooltip: 'Upload Audio',
                            )
                          ]),
                      SizedBox(
                        //height: 100,
                        //width: 300,
                        child: TextField(
                          controller: description,
                          maxLines: 5,
                          decoration: const InputDecoration(
                              //story text
                              labelText: 'Description',
                              border: OutlineInputBorder()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20), 
                        child: OverflowBar(
                          alignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            //both ElevatedButtons will close the modal.
                            ElevatedButton(
                              onPressed: () {
                                // Creating Node object
                                final newNode = <String, dynamic>{
                                  "Type": "SCENARIO",
                                  "Description": description.text,
                                  "imageUrl": imageUrl,
                                  "videoUrl": videoUrl,
                                  "audioUrl": audioUrl,
                                };

                                // saving nodes
                                db
                                    .collection('devs')
                                    .doc(
                                        accountEmail) // email linked to account
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
                          ]
                        )
                      ),
                      //const SizedBox(height: 30,width: 200),
                    ],
                  ),
                ),
              )
            );
        });
      });
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

/// Displays a dialog for inputting and playing videos from YouTube or Vimeo URLs.
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
