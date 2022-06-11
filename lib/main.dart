import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRCord client',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lastTxt = "";
  bool _serverOk = false;
  bool _serverChecking = false;
  Timer? _serverFieldTimerChk;
  TextEditingController serverFieldController = TextEditingController();

  @override
  void dispose() {
    _serverFieldTimerChk?.cancel();
    serverFieldController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    serverFieldController.addListener(_onServerAddrFieldUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("QRCord"),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(['Let\'s scan!', "You just scanned $_lastTxt"].join('\n')),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 48), child: Row(
                    children: [
                      Expanded(child: TextField(
                          controller: serverFieldController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Server address',
                          ))),
                      TextButton.icon(
                          onPressed: () {
                            serverFieldController.clear();
                          },
                          icon: const Icon(
                            Icons.backspace,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            "CLEAR",
							style: TextStyle(color: Colors.grey),
							textScaleFactor: 0.75
                          ))
                    ],
                  )),
              ElevatedButton(
                onPressed: (!_serverChecking && _serverOk)
                    ? () {
                        _scanBarcode(context);
                      }
                    : null,
                child: const Text('Scan'),
              ),
            ],
          ),
        ));
  }

  Future<void> onBarcode(String data) async {
    await http.post(
        Uri(host: '192.168.1.200', port: 8000, scheme: 'http', path: '/'),
        body: data,
        headers: {
          'Content-Type': 'application/text'
        }).timeout(const Duration(milliseconds: 2500));

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _lastTxt = data;
    });
  }

  void _onServerAddrFieldUpdate() {
    setState(() {
      _serverChecking = true;
    });
    _serverFieldTimerChk?.cancel();
    _serverFieldTimerChk = Timer(const Duration(milliseconds: 650), () {
      _checkServer();
    });
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final String result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodePage()),
    );

    onBarcode(result);
  }

  Future<void> _checkServer() async {
    try {
      await http
          .get(Uri.parse(serverFieldController.text))
          .timeout(const Duration(milliseconds: 3250));
      setState(() {
        _serverOk = true;
        _serverChecking = false;
      });
    } catch (e) {
      setState(() {
        _serverOk = false;
        _serverChecking = false;
      });
    }
  }
}

class BarcodePage extends StatelessWidget {
  const BarcodePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
          allowDuplicates: false,
          onDetect: (barcode, args) {
            if (barcode.rawValue == null) {
              debugPrint('Failed to scan Barcode');
              Navigator.pop(context, "Fail");
            } else {
              final String code = barcode.rawValue!;
              debugPrint('Barcode found! $code');
              Navigator.pop(context, code);
            }
          }),
    );
  }
}
