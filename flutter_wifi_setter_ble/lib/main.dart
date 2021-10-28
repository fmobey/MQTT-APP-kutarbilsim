import 'dart:async';
import 'dart:convert' show utf8;
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microzerr',
      debugShowCheckedModeBanner: false,
      home: WifiSetter(),
      theme: ThemeData(
          primaryColor: Colors.lime, backgroundColor: Colors.grey[300]),
    );
  }
}

class WifiSetter extends StatefulWidget {
  @override
  _WifiSetterState createState() => _WifiSetterState();
}

class _WifiSetterState extends State<WifiSetter> {
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String TARGET_DEVICE_NAME = "ESP32";
  TextEditingController _outputController;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubscription;
  String _scanBarcode = "";
  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;
  String _scanveryf = "There may be a problem with the Bluetooth.";
  String connectionText = "";

  @override
  void initState() {
    super.initState();
    baslangic();
  }

  baslangic() {
    if (targetDevice == null) {
      _scan();
    }
    startScan();
  }

  startScan() {
    setState(() {
      connectionText = "Start Scanning";
    });

    scanSubscription = flutterBlue.scan().listen((scanResult) {
      print(scanResult.device.id.toString() == _scanBarcode);

      if (scanResult.device.id.toString() == _scanBarcode) {
        stopScan();

        setState(() {
          connectionText = "Found Target Device";
        });

        targetDevice = scanResult.device;
        connectToDevice();
      }
    }, onDone: () => stopScan());
  }

  Future _scan() async {
    await Permission.camera.request();
    String barcode = await scanner.scan();
    if (barcode == null) {
      print('nothing return.');
    } else {
      setState(() {
        _scanBarcode = barcode;
      });
    }
  }

  backpage() {
    startScan();
    disconnectFromDeivce();
    targetDevice = null;
    baslangic();
  }

//qrreset buttonu
  qrreset() {
    stopScan();
    disconnectFromDeivce();
    targetDevice = null;
    baslangic();
  }

  reset() {
    stopScan();
    disconnectFromDeivce();

    startScan();
  }
  //reset için kullanılacak

  stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
    flutterBlue.stopScan();
  }

  connectToDevice() async {
    if (targetDevice == null) {
      return;
    }
    setState(() {
      _scanveryf = "QR and MAC Matched.";
    });
    setState(() {
      connectionText = "Device Connecting";
    });

    await targetDevice.connect();

    setState(() {
      connectionText = "Device Connected";
    });
    discoverServices();
  }

  disconnectFromDeivce() {
    if (targetDevice == null) {
      return;
    }

    targetDevice.disconnect();

    setState(() {
      connectionText = "Device Disconnected";
    });
  }

  discoverServices() async {
    if (targetDevice == null) {
      return;
    }

    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristics) {
          if (characteristics.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristics;
            setState(() {
              connectionText = "Connected Device: ${targetDevice.name}";
            });
          }
        });
      }
    });
  }

  writeData(String data) async {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes);
  }

  @override
  void dispose() {
    super.dispose();
    stopScan();
  }

  submitAction() {
    var wifiData =
        '${wifiNameController.text},${wifiPasswordController.text},${mqttbroker.text},${mqttusername.text},${mqttpassword.text},${topicc.text}';
    writeData(wifiData);
  }

  TextEditingController wifiNameController = TextEditingController();
  TextEditingController wifiPasswordController = TextEditingController();
  TextEditingController mqttbroker = TextEditingController();
  TextEditingController mqttusername = TextEditingController();
  TextEditingController mqttpassword = TextEditingController();
  TextEditingController topicc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottomOpacity: 0.8,
        title: Text(connectionText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
          child: targetCharacteristic == null
              ? Center(
                  child: ListView(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 100),
                          child: Text(
                            "Waiting..",
                            style: TextStyle(
                                fontSize: 34,
                                color: Colors.black,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(top: 40),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.teal),
                                onPressed: () => reset(),
                                icon: Icon(Icons.refresh),
                                label: Text("RESET"),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 40),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.teal),
                                onPressed: () => qrreset(),
                                icon: Icon(Icons.refresh),
                                label: Text("Try QR"),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          // reset buttonu text
                          margin: EdgeInsets.only(top: 50),
                          child: Center(
                            child: Text(
                              "if it doesn't work, reset it",
                              textAlign: TextAlign.center,
                              softWrap: false,
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black26,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text(
                              " Read QR : ${_scanBarcode}",
                              maxLines: 2,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black26,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text(
                              "${_scanveryf}",
                              maxLines: 2,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black26,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "With",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black38),
                              ),
                              Container(
                                height: 120,
                                width: 120,
                                child: Image.asset('lib/assets/images/a.png'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ))
              : ListView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: wifiNameController,
                        decoration: InputDecoration(labelText: 'Wifi Name'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: wifiPasswordController,
                        decoration: InputDecoration(labelText: 'Wifi Password'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: mqttbroker,
                        decoration: InputDecoration(labelText: 'MQTT Broker'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: mqttusername,
                        decoration: InputDecoration(labelText: 'MQTT Username'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: mqttpassword,
                        decoration: InputDecoration(labelText: 'MQTT Password'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: topicc,
                        decoration: InputDecoration(labelText: 'MQTT Topic'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 20, right: 30, left: 30, bottom: 20),
                      child: RaisedButton(
                        onPressed: () => showDialog<String>(
                          // showdialog kısmı
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Warning!'),
                            content: const Text(
                                'Are you sure you entered the information correctly?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, 'OK');
                                  submitAction();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                        color: Colors.lime[400],
                        child: Text('Send'),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Container(
                          width: 135,
                          height: 50,
                          child: ElevatedButton(
                            child: Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.teal,
                            ),
                            onPressed: () {
                              reset()();
                            },
                          ),
                        ),
                        Container(
                          width: 135,
                          height: 50,
                          child: ElevatedButton(
                            child: Text('New Devices'),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.teal,
                            ),
                            onPressed: () {
                              qrreset();
                            },
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 50),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "With",
                            style:
                                TextStyle(fontSize: 12, color: Colors.black38),
                          ),
                          Container(
                            height: 120,
                            width: 120,
                            child: Image.asset('lib/assets/images/a.png'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
    );
  }
}
