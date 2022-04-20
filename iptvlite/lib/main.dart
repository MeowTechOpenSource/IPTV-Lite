import 'dart:convert';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:csv/csv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:iptvlite/mybutton.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bouncing.dart';
import 'dbservice.dart';
import 'iptv.dart';

var currver = "1.0.0";
var usingdata = false;
FijkPlayer player = FijkPlayer();
List tips = [];
Map Selected = {"TipName": "", "VideoUrl": ""};
bool ismobile = false;
var url = "";
var deviceid;
bool isActivated = true;
final DatabaseService _databaseService = DatabaseService();
Future<void> _onInsert(String name, String url) async {
  await _databaseService.insertData(IPTV(name: name, url: url));
}


Future<void> _onInsertUndo(IPTV iptv) async {
  await _databaseService.insertData(iptv);
}

// Call this function to delete a breed
Future<void> _onDelete(IPTV iptv) async {
  await _databaseService.delete(iptv.name);
}


Future<void> _onExport(String now) async {
  var b = await _databaseService.export();
  var status = await Permission.storage.status;
  //var status2 = await Permission.manageExternalStorage.status;
  if (status.isDenied) {
    if (await Permission.storage.request().isGranted) {
      var selectedDirectory;
      if (Platform.isAndroid) {
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        String? osVersion = androidInfo.version.release;
        if (int.parse(osVersion.toString()) > 10) {
          String? selectedDirectory =
              await ExternalPath.getExternalStoragePublicDirectory(
                  ExternalPath.DIRECTORY_DOWNLOADS);
          //Save in DL Folder.
        } else {
          String? selectedDirectory =
              await FilePicker.platform.getDirectoryPath();
        }
      }
      if (selectedDirectory == null) {
        // User canceled the picker
      } else {
        String dir = selectedDirectory + "/";
        File f = new File(dir + now + "_export.csv");
        f.writeAsString(b);
      }
    } else {
      print("No Perm");
    }
  } else {
    var now = DateFormat('yyyyMMddhhmmssa').format(DateTime.now());
    //String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    String? selectedDirectory =
        await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOADS);
    if (selectedDirectory == null) {
      // User canceled the picker
    } else {
      String dir = selectedDirectory + "/";
      File f = new File(dir + now + "_export.csv");
      f.writeAsString(b);
    }
  }
  //print(b);
}



// ignore: prefer_typing_uninitialized_variables
late final istvchk;
bool istv = false;
var needupdate = [false, "", "", ""];
Future<void> main() async {
  // final settings = await _getFlavorSettings();
  // istvchk = istvchk.istv;
  // if (istvchk){
  //   SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);
  // }
  runApp(Shortcuts(
    shortcuts: {
      LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
    },
    child: MaterialApp(
      home: ListPage(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', 'HK'),
      ],
      routes: {
        "/player": (context) => VideoPage(),
      },
      theme: ThemeData(
        listTileTheme:
            ListTileThemeData(selectedColor: Color.fromARGB(255, 147, 95, 252)),
        appBarTheme: AppBarTheme(
            backgroundColor: Color.fromARGB(255, 183, 147, 255),
            centerTitle: true),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: Color.fromARGB(255, 188, 149, 255)),
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(
                    Color.fromARGB(255, 226, 215, 245)),
                foregroundColor: MaterialStateProperty.all(
                    Color.fromARGB(255, 162, 119, 248)))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Color.fromARGB(255, 183, 147, 255)))),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(35)),
            fillColor: Colors.white,
            filled: true,
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(35)),
            iconColor: Colors.black,
            prefixIconColor: Colors.black),
        hintColor: Color.fromARGB(255, 96, 96, 96),
        progressIndicatorTheme:
            ProgressIndicatorThemeData(color: Color(0xFF0A59)),
        snackBarTheme: SnackBarThemeData(
            actionTextColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        useMaterial3: true,
      ),
    ),
  ));
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp
  ]);
  // if (Platform.isAndroid) {
  //   AndroidDeviceInfo androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
  //   istv = await androidDeviceInfo.systemFeatures
  //       .contains('android.software.leanback');
  //   print(istv);
  //   if (istv) {
  //     SystemChrome.setPreferredOrientations(
  //         [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  //   }
  // }
}

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {

  @override
  showUpdate(BuildContext context, String ver, String sha256) {
    Widget continueButton = TextButton(
      child: Text(
        AppLocalizations.of(context)!.update,
      ),
      onPressed: () async {
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/updateguide", (route) => false);
        // if (!await launch(needupdate[1].toString())) {
        // } else {}
        // SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.updateavalible),
      content: Text(ver + AppLocalizations.of(context)!.noteafter),
      actions: [
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void initState() {
    super.initState();
    // The equivalent of the "smallestWidth" qualifier on Android.
    tips = [];
  }

  @override
  dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    var smallestDimension = MediaQuery.of(context).size.shortestSide;
    ismobile = smallestDimension < 600;

    void initState() {
      super.initState();
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        if (needupdate[0] as bool) {
          print("shpw");
          showUpdate(
              context, needupdate[2].toString(), needupdate[3].toString());
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 183, 147, 255),
        leading: IconButton(
          onPressed: () {
            showAboutDialog(
                context: context,
                applicationName: "IPTV Lite",
                applicationVersion: currver,
                applicationLegalese: AppLocalizations.of(context)!.copyright,
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey,
                    child: Center(child: Text("TV",style: TextStyle(fontSize: 26,color: Colors.white),)),
                  )
                ),
                children: [
                  Column(
                    children: [
                      SizedBox(height: 15,),
                      Text(AppLocalizations.of(context)!.upgrade,),
                      SizedBox(height: 5,),
                      Text(AppLocalizations.of(context)!.player + "fijkplayer"),
                      SizedBox(
                        width: 20,
                      ),
                      // GestureDetector(
                      //   child: Text("Change ()",
                      //       style: TextStyle(
                      //           decoration: TextDecoration.underline,
                      //           color: Colors.blue)),
                      //   onTap: () {},
                      // )
                    ],
                  )
                ]);
          },
          icon: Icon(Icons.info_outline_rounded),
        ),
        actions: <Widget>[
          istv
              ? IconButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                        context: context,
                        //enableDrag: false,
                        isScrollControlled: true,
                        backgroundColor: Color.fromARGB(255, 241, 243, 245),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        //backgroundColor: dialogBG,
                        builder: (BuildContext context) {
                          TextEditingController name = TextEditingController();
                          TextEditingController url = TextEditingController();
                          return AnimatedPadding(
                              duration: Duration(milliseconds: 1000),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: Container(
                                height: 250,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 0, 10, 0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: MyButton(
                                          width: 25,
                                          height: 25,
                                          backgroundColor: Color.fromARGB(
                                              255, 221, 221, 221),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextField(
                                      controller: name,
                                      decoration: InputDecoration(
                                          //icon of text field
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .channel),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    TextField(
                                      controller: url,
                                      decoration: InputDecoration(
                                          //icon of text field
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .m3u8url),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: MyButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .cancel,
                                                style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 232, 64, 38)),
                                              ),
                                              backgroundColor:
                                                  Color.fromARGB(10, 0, 0, 0)),
                                        ),
                                        Expanded(
                                          child: MyButton(
                                              onPressed: () {
                                                if ((name.text != "") &
                                                    (url.text != "")) {
                                                  _onInsert(
                                                      name.text, url.text);
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .add)),
                                        )
                                      ],
                                    )
                                  ]),
                                ),
                              ));
                        });
                  },
                  icon: Icon(Icons.add_rounded))
              : Container(),
          IconButton(
              onPressed: () {
                var now = DateFormat('yyyyMMddhhmmssa').format(DateTime.now());
                _onExport(now);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(AppLocalizations.of(context)!.exportedto +
                      now +
                      "_export.csv" +
                      AppLocalizations.of(context)!.indlfolder),
                ));
              },
              icon: Icon(Icons.exit_to_app)),
        ],
        title: Text("IPTV Lite"),
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: _databaseService.showAll(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return Text("沒有找到數據");
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              case ConnectionState.active:
              case ConnectionState.done:
                var data = snapshot.data as List;
                if (data != null && data.length == 0) {
                  return Container(
                    child: Center(
                      child: TextButton(
                          onPressed: () async {
                            var result;
                            if (!istv) {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['csv'],
                              );
                            } else {
                              result = "222";
                            }
                            if (result == null) {
                              print("Exception:No File");
                            } else {
                              bool cont = true;
                              if (Platform.isAndroid && !istv) {
                                var androidInfo =
                                    await DeviceInfoPlugin().androidInfo;
                                String? osVersion = androidInfo.version.release;
                                if (int.parse(osVersion.toString()) > 10) {
                                  //cont = await Permission.storage.request().isGranted && await Permission.manageExternalStorage.request().isGranted;
                                  cont = await Permission.storage
                                      .request()
                                      .isGranted;
                                } else {
                                  cont = await Permission.storage
                                      .request()
                                      .isGranted;
                                }
                              }
                              if (cont && !istv) {
                                String? file2 = result.files.single.path;
                                var csvData = await new File(file2.toString())
                                    .readAsString();
                                try {
                                  List<List<dynamic>> csvTable =
                                      CsvToListConverter().convert(csvData);
                                  csvTable.removeAt(0);
                                  setState(() {
                                    csvTable.forEach((element) {
                                      if (element[0].toString() == "Name") {
                                        print("****");
                                      } else {
                                        _onInsert(element[0], element[1]);
                                      }
                                    });
                                  });
                                } catch (error) {
                                  if (false) {
                                    showError(context, error.toString());
                                  } else {
                                    showError(context,
                                        "發生內部錯誤，請嘗試檢查您的 CSV 文件或將您的 CSV 文件中的錯誤報告給開發人員。");
                                  }
                                }
                              } else {
                                print("No Perm");
                              }
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.import)),
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                        flex:20,
                        child: ListView(
                          children: data.map((item) {
                            return Column(
                              children: [
                                Dismissible(
                                  key: Key(item.name),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 9),
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    _onDelete(item);
                                    setState(() {});
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content:
                                          Text(AppLocalizations.of(context)!.deleted),
                                      action: SnackBarAction(
                                          label: AppLocalizations.of(context)!.undo,
                                          onPressed: () async {
                                            setState(() {
                                              _onInsertUndo(item);
                                            });
                                          }),
                                    ));
                                  },
                                  child: ListTile(
                                    title: Text(item.name),
                                    onTap: () async {
                                      if (needupdate[0] as bool) {
                                        print("shpw");
                                        await showUpdate(
                                            context,
                                            needupdate[2].toString(),
                                            needupdate[3].toString());
                                      } else {
                                        setState(() {
                                          Selected = {
                                            "TipName": item.name,
                                            "VideoUrl": item.url
                                          };
                                          player.pause();
                                          player.release();
                                          // Now check:

                                          player = FijkPlayer();
                                          player.setDataSource(Selected["VideoUrl"],
                                              autoPlay: true);
                                          Navigator.pushNamed(context, "/player")
                                              .then((_) => {
                                                    Selected = {
                                                      "TipName": "Default",
                                                      "VideoUrl": "DefaultUrl"
                                                    }
                                                  });
                                        });
                                      }
                                    },
                                    selected: Selected["TipName"] == item.name,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 5, right: 5),
                                  child: Divider(
                                    height: 1,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(child: TextButton(onPressed: (){},child: Text(AppLocalizations.of(context)!.upgrade,style: TextStyle(fontWeight: FontWeight.bold),)),flex: 2,),
                      Expanded(child: Container(),flex: 1,),
                    ],
                  );
                }
            }
          }),
      floatingActionButton: istv
          ? Container()
          : Bouncing(
              onPressed: () {
                showModalBottomSheet<void>(
                    context: context,
                    //enableDrag: false,
                    isScrollControlled: true,
                    backgroundColor: Color.fromARGB(255, 241, 243, 245),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    //backgroundColor: dialogBG,
                    builder: (BuildContext context) {
                      TextEditingController name = TextEditingController();
                      TextEditingController url = TextEditingController();
                      return AnimatedPadding(
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Container(
                            height: 250,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: MyButton(
                                      width: 25,
                                      height: 25,
                                      backgroundColor:
                                          Color.fromARGB(255, 221, 221, 221),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller: name,
                                  decoration: InputDecoration(
                                      //icon of text field
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      hintText: AppLocalizations.of(context)!
                                          .channel),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                  controller: url,
                                  decoration: InputDecoration(
                                      //icon of text field
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      hintText: AppLocalizations.of(context)!
                                          .m3u8url),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: MyButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .cancel,
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 232, 64, 38)),
                                          ),
                                          backgroundColor:
                                              Color.fromARGB(10, 0, 0, 0)),
                                    ),
                                    Expanded(
                                      child: MyButton(
                                          onPressed: () {
                                            if ((name.text != "") &
                                                (url.text != "")) {
                                              _onInsert(name.text, url.text);
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .add)),
                                    )
                                  ],
                                )
                              ]),
                            ),
                          ));
                    });
              },
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
    );
  }

  showError(BuildContext context, String error) {
    Widget continueButton = TextButton(
      child: Text(
        AppLocalizations.of(context)!.add,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("發生錯誤"),
      content: Text(error),
      actions: [
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  var subscription;
  void initState() {
    super.initState();
  }


  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        WidgetsFlutterBinding.ensureInitialized();
        player.enterFullScreen();
      }
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        WidgetsFlutterBinding.ensureInitialized();
        SchedulerBinding.instance?.addPostFrameCallback((_) {
          player.exitFullScreen();
        });
      }
      return WillPopScope(
        onWillPop: () async {
          player.pause();
          player.release();
          player = FijkPlayer();
          Navigator.of(context).popUntil((route) => route.isFirst);
          return false;
        },
        child: Scaffold(
          backgroundColor: Color.fromARGB(255, 241, 243, 245),
          body: SafeArea(
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FijkView(
                    player: player,
                    color: Colors.black,
                  ),
                ),
                (MediaQuery.of(context).orientation == Orientation.portrait)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  Selected["TipName"],
                                  style: TextStyle(fontSize: 25),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                    },
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                                Colors.black),
                                        padding: MaterialStateProperty.all<
                                            EdgeInsets>(EdgeInsets.all(10)),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ))),
                                    child: Column(
                                      children: [
                                        Icon(Icons.exit_to_app),
                                        Text(AppLocalizations.of(context)!.back)
                                      ],
                                    )),
                                TextButton(
                                    onPressed: () {
                                      SystemChannels.platform
                                          .invokeMethod('SystemNavigator.pop');
                                    },
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                                Colors.black),
                                        padding: MaterialStateProperty.all<
                                            EdgeInsets>(EdgeInsets.all(10)),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ))),
                                    child: Column(
                                      children: [
                                        Icon(Icons.close_rounded),
                                        Text(AppLocalizations.of(context)!.quit)
                                      ],
                                    ))
                              ],
                            ),
                          ),
                          Divider(
                            height: 20,
                            thickness: 3,
                          ),
                          FutureBuilder(
                              future: _databaseService.showAll(),
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return Text("沒有找到數據");
                                  case ConnectionState.waiting:
                                    return Center(
                                        child: CircularProgressIndicator());
                                  case ConnectionState.active:
                                  case ConnectionState.done:
                                    var data = snapshot.data as List;
                                    if (data != null && data.length == 0) {
                                      return Container(
                                        child: Center(
                                          child: Container(),
                                        ),
                                      );
                                    } else {
                                      return Container(
                                        height: 400,
                                        child: ListView(
                                          children: data.map((item) {
                                            return Column(
                                              children: [
                                                ListTile(
                                                  title: Text(item.name),
                                                  onTap: () {
                                                    setState(() {
                                                      Selected = {
                                                        "TipName": item.name,
                                                        "VideoUrl": item.url
                                                      };
                                                      player.release();
                                                      player = FijkPlayer();
                                                      setState(() {
                                                        player.setDataSource(
                                                          Selected["VideoUrl"],
                                                          autoPlay: true,
                                                        );
                                                      });
                                                      player.start();
                                                      Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          pageBuilder:
                                                              (c, a1, a2) =>
                                                                  VideoPage(),
                                                          transitionsBuilder: (c,
                                                                  anim,
                                                                  a2,
                                                                  child) =>
                                                              FadeTransition(
                                                                  opacity: anim,
                                                                  child: child),
                                                          transitionDuration:
                                                              Duration(
                                                                  milliseconds:
                                                                      2000),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                  selected:
                                                      Selected["TipName"] ==
                                                          item.name,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 5, right: 5),
                                                  child: Divider(
                                                    height: 1,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    }
                                }
                              }),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

