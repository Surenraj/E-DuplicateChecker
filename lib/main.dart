import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:core';
import 'dart:async';
import 'package:image_compare/image_compare.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:audio_picker/audio_picker.dart';
import 'package:id3/id3.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wave/config.dart';
import "./wave_widget.dart";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'e-Duplicate Checker'),
      builder: EasyLoading.init(),
    );
  }
}

bool toggle = true;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350),
      reverseDuration: Duration(milliseconds: 275),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Alignment alignment1 = Alignment(0.0, 0.0);
  Alignment alignment2 = Alignment(0.0, 0.0);
  Alignment alignment3 = Alignment(0.0, 0.0);
  double size1 = 50.0;
  double size2 = 50.0;
  double size3 = 50.0;

  final navigatorKey = GlobalKey<NavigatorState>();
  //
  Metadata metadata;
  String mediaFilePath;
  Widget mediaAlbumArt;
  Widget mediaMetadata;
  //
  File _image;
  Directory directory;
  String retrivePath;
  bool _decisionNotSave = false;
  var finals;
  var message = "";
  String _colorName = 'No';
  Color _color = Colors.black;
  String _absolutePathOfAudio;
  List<String> audioArray = [];
  var audioMetaValue;
  final ImagePicker _picker = ImagePicker();

  void showLoading() {
    showDialog(
      context: navigatorKey.currentState.overlay.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              new CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new Text("Loading"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future getVideo() async {
    final PickedFile file = await _picker.getVideo(
        source: ImageSource.gallery, maxDuration: const Duration(seconds: 10));
    setState(() {
      Fluttertoast.showToast(
        msg: "Video uploaded successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    });
  }

  Future<void> onSelected() async {
    // FocusScope.of(context).unfocus();
    var metadataRetriever = new MetadataRetriever();
    await metadataRetriever.setFile(File(_absolutePathOfAudio));
    metadata = await metadataRetriever.metadata;
    audioMetaValue = "${metadata.trackName}" +
        " " +
        "${metadata.trackArtistNames}" +
        " " +
        "${metadata.albumName}" +
        " " +
        "${metadata.albumArtistName}" +
        " " +
        "${metadata.trackNumber}" +
        " " +
        "${metadata.albumLength}" +
        " " +
        "${metadata.year}" +
        " " +
        "${metadata.genre}" +
        " " +
        "${metadata.authorName}" +
        " " +
        "${metadata.writerName}" +
        " " +
        "${metadata.discNumber}" +
        " " +
        "${metadata.mimeType}" +
        " " +
        "${metadata.trackDuration}" +
        " " +
        "${metadata.bitrate}";

    if (audioArray.isEmpty) {
      audioArray.insert(0, audioMetaValue);
      Fluttertoast.showToast(
        msg: "File uploaded successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    } else {
      var index = audioArray.length;
      for (int i = 0; i < index; i++) {
        if (audioArray[i].contains(audioMetaValue)) {
          print("Your value already exist");
          Fluttertoast.showToast(
            msg: "This file already exist, can't upload!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
          break;
        } else {
          audioArray.insert(index, audioMetaValue);
          Fluttertoast.showToast(
            msg: "uploaded",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
      print(audioArray.length);
    }
    setState(() async {
      print(audioArray);
      // print(audioArray.length);
      SharedPreferences myPrefs = await SharedPreferences.getInstance();
      myPrefs.setStringList('AudioArrayValue', audioArray);
    });
  }

  void dismissLoading() {
    Navigator.pop(navigatorKey.currentState.overlay.context);
  }

  void openAudioPicker() async {
    // showLoading();
    var path = await AudioPicker.pickAudio();
    // dismissLoading();
    setState(() {
      _absolutePathOfAudio = path;
      // metaDataFile();
      onSelected();
    });
  }

  void metaDataFile() {
    List<int> mp3Bytes = File(_absolutePathOfAudio).readAsBytesSync();
    MP3Instance mp3instance = new MP3Instance(mp3Bytes);
    // if (mp3instance.parseTagsSync()) {
    //   print(mp3instance.getMetaTags());
    // }
  }

  Future getImage() async {
    final File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    EasyLoading.show(status: 'checking...');
    setState(
      () {
        _image = image;
      },
    );
    var pickedImagePath = image.path;
    print('image path without save');

    print(pickedImagePath);
    var fileName = basename(pickedImagePath);

    // /data/user/0/comdesign.example.image_picker_test/cache/image_picker243630346894480709.jpg
    directory = await getExternalStorageDirectory();
    //get dir of app folder and store path in $pathDir variable

    final String pathDir = directory.path;
    print('path is:');
    print(
        pathDir); // storage/emulated/0/Android/data/comdesign.example.image_picker_test/files
    //store full path of where to store the image
    retrivePath = '$pathDir/Pictures/$fileName';

    List<FileSystemEntity> _folders;
    String dfDirectory = '$pathDir/Pictures/';
    final myDir = new Directory(dfDirectory);
    _folders = myDir.listSync(recursive: true, followLinks: false);

    print('Different between each image in Directory');
    var folderlen = _folders.length;
    if (folderlen > 0) {
      for (int i = 0; i < folderlen; i++) {
        var assetResult = await compareImages(
            src1: File(pickedImagePath),
            src2: File(_folders[i].path),
            algorithm: ChiSquareDistanceHistogram());
        finals = assetResult * 100;
        finals = finals.floor();
        print('Difference: $finals%');
        if (finals < 3) {
          _decisionNotSave = true;
        }

        switch (_decisionNotSave) {
          case true:
            print('Image is Duplicate');
            setState(() {
              EasyLoading.showError(
                  'Unable to upload since this image was already uploaded');
              message = 'Image is Duplicate';
            });
            break;
        }
      }
    }
    if (_decisionNotSave == false) {
      final File newImage = await image.copy(retrivePath); //no change
      setState(() {
        EasyLoading.showSuccess('Image uploaded successfully');
        message = 'Image uploaded successfully';
      });
      print('Image saved Successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height - 200,
                color: Colors.blue[400],
              ),
              WaveWidget(
                size: MediaQuery.of(context).size,
                yOffset: MediaQuery.of(context).size.height / 3.0,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 100.0, left: 20.0),
                child: Row(
                  children: <Widget>[
                    RichText(
                        text: TextSpan(
                            text: "E - Duplicate Checker v1.0",
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            children: <TextSpan>[
                          TextSpan(
                              text: "\nFind duplicates now!!",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white))
                        ]))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 160.0),
                child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                        child: Container(
                      height: 250.0,
                      width: 250.0,
                      child: Stack(children: [
                        AnimatedAlign(
                            duration: toggle
                                ? Duration(milliseconds: 275)
                                : Duration(milliseconds: 875),
                            alignment: alignment1,
                            curve: toggle ? Curves.easeIn : Curves.elasticOut,
                            child: AnimatedContainer(
                                duration: Duration(milliseconds: 275),
                                curve: toggle ? Curves.easeIn : Curves.easeOut,
                                height: size1,
                                width: size1,
                                decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(40.0)),
                                child: GestureDetector(
                                    onTap: () {
                                      getImage();
                                      setState(() {
                                        EasyLoading.dismiss();
                                        _decisionNotSave = false;
                                        message = "";
                                        _image = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.white,
                                    )))),
                        AnimatedAlign(
                            duration: toggle
                                ? Duration(milliseconds: 275)
                                : Duration(milliseconds: 875),
                            alignment: alignment2,
                            curve: toggle ? Curves.easeIn : Curves.elasticOut,
                            child: AnimatedContainer(
                                duration: Duration(milliseconds: 275),
                                curve: toggle ? Curves.easeIn : Curves.easeOut,
                                height: size2,
                                width: size2,
                                decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(40.0)),
                                child: GestureDetector(
                                    onTap: () {
                                      openAudioPicker();
                                    },
                                    child: Icon(
                                      Icons.audiotrack,
                                      color: Colors.white,
                                    )))),
                        AnimatedAlign(
                            duration: toggle
                                ? Duration(milliseconds: 275)
                                : Duration(milliseconds: 875),
                            alignment: alignment3,
                            curve: toggle ? Curves.easeIn : Curves.elasticOut,
                            child: AnimatedContainer(
                                duration: Duration(milliseconds: 275),
                                curve: toggle ? Curves.easeIn : Curves.easeOut,
                                height: size3,
                                width: size3,
                                decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(40.0)),
                                child: GestureDetector(
                                    onTap: () {
                                      getVideo();
                                    },
                                    child: Icon(
                                      Icons.video_library_outlined,
                                      color: Colors.white,
                                    )))),
                        Align(
                            alignment: Alignment.center,
                            child: Transform.rotate(
                                angle: _animation.value * pi * (3 / 4),
                                child: AnimatedContainer(
                                    duration: Duration(milliseconds: 375),
                                    curve: Curves.easeOut,
                                    height: toggle ? 70.0 : 60.0,
                                    width: toggle ? 70.0 : 60.0,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[400],
                                      borderRadius: BorderRadius.circular(60.0),
                                    ),
                                    child: Material(
                                        color: Colors.transparent,
                                        child: IconButton(
                                            splashColor: Colors.black54,
                                            splashRadius: 31.0,
                                            onPressed: () {
                                              setState(() {
                                                if (toggle) {
                                                  toggle = !toggle;
                                                  _controller.forward();
                                                  Future.delayed(
                                                      Duration(
                                                          milliseconds: 10),
                                                      () {
                                                    alignment1 =
                                                        Alignment(-0.7, -0.4);
                                                    size1 = 50.0;
                                                  });
                                                  Future.delayed(
                                                      Duration(
                                                          milliseconds: 100),
                                                      () {
                                                    alignment2 =
                                                        Alignment(0.0, -0.8);
                                                    size2 = 50.0;
                                                  });
                                                  Future.delayed(
                                                      Duration(
                                                          milliseconds: 200),
                                                      () {
                                                    alignment3 =
                                                        Alignment(0.7, -0.4);
                                                    size3 = 50.0;
                                                  });
                                                } else {
                                                  toggle = !toggle;
                                                  _controller.reverse();
                                                  alignment1 =
                                                      Alignment(0.0, 0.0);
                                                  alignment2 =
                                                      Alignment(0.0, 0.0);
                                                  alignment3 =
                                                      Alignment(0.0, 0.0);
                                                  size1 = size2 = size3 = 20.0;
                                                }
                                              });
                                            },
                                            icon: Icon(Icons.add,
                                                size: 40,
                                                color: Colors.white))))))
                      ]),
                    ))),
              ),
              // Icon(Icons.add, size: 40)
              // body: Container(
              //   child: CircularMenu(
              //     alignment: Alignment.center,
              //     toggleButtonColor: Colors.deepOrange,
              //     items: [
              //       CircularMenuItem(
              //           icon: Icons.audiotrack,
              //           color: Colors.green,
              //           onTap: () {
              //
              //           }),
              //       CircularMenuItem(
              //           icon: Icons.video_library_outlined,
              //           color: Colors.blue,
              //           onTap: () {}),
              //       CircularMenuItem(
              //           icon: Icons.image,
              //           color: Colors.purpleAccent[100],
              //           onTap: () {
              //             getImage();
              //             setState(() {
              //               EasyLoading.dismiss();
              //               _decisionNotSave = false;
              //               message = "";
              //               _image = null;
              //             });
              //           }),
              //     ],
              //   ),
              // ),
            ])));
  }
}
