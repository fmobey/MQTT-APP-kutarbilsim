import 'dart:async';
import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_wifi_setter_ble/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class wifipage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wifi Ayarları ',
      debugShowCheckedModeBanner: false,
      home: WifiSetter(),
      theme: ThemeData(
        primaryColor: Colors.greenAccent,
        backgroundColor: Colors.white30,
        textTheme: TextTheme(bodyText2: TextStyle(color: Colors.purple)),
      ),
    );
  }
}

class WifiSetter extends StatefulWidget {
  @override
  _WifiSetterState createState() => _WifiSetterState();
}

class _WifiSetterState extends State<WifiSetter> {
  // tanımlar ve uuidler
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String TARGET_DEVICE_NAME = "ESP32";

  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubscription;

  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;

  String connectionText = "";
  String _scanBarcode = "Okunan QR yok";
  String _scanveryf = "Bluetoothda Sıkıntı Olabilir";

  @override
  void initState() {
    super.initState();
    scanQR();

    startScan();
  }

  // qr tarama
  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScannMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

// tarama fonksiyonu
  startScan() {
    setState(() {
      connectionText = "Tarama Yapılıyor.";
    });

    scanSubscription = flutterBlue.scan().listen((scanResult) {
      print(scanResult.device.name);
      if (scanResult.device.name.contains(TARGET_DEVICE_NAME)) {
        stopScan();

        setState(() {
          connectionText = "Hedef Cihaz Bulundu";
        });

        targetDevice = scanResult.device;
        connectToDevice();
      }
    }, onDone: () => stopScan());
  }

// tarama durdur
  stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
  }

// cihaz bağlanma
  connectToDevice() async {
    if (targetDevice == null) {
      return;
    }

    if (targetDevice.id.toString() == _scanBarcode) {
      setState(() {
        connectionText = "Cihaz Bağlanılıyor";
      });
      setState(() {
        _scanveryf = "QR ve MAC Eşleşti.";
      });

      await targetDevice.connect();
    } else {
      setState(() {
        connectionText = "QR Kod Tanımsız";
      });
      setState(() {
        _scanveryf = "QR ve MAC Eşleşmedi.";
      });

      return;
    }

    setState(() {
      connectionText = "Cihaz bağlandı";
    });

    discoverServices();
  }

  disconnectFromDeivce() {
    if (targetDevice == null) {
      return;
    }

    targetDevice.disconnect();

    setState(() {
      connectionText = "Cihaz Bağlantısı Koptu";
    });
  }

// geri tuşunun fonksiyonu
  backpage() {
    flutterBlue.stopScan();
    disconnectFromDeivce();
    targetDevice = null;
  }

// reset tuşunun fonsiyonu
  reset() {
    flutterBlue.stopScan();
    disconnectFromDeivce();
    targetDevice = null;
    startScan();
  }

  qrreset() {
    flutterBlue.stopScan();
    disconnectFromDeivce();
    targetDevice = null;
    scanQR();
    startScan();
  }

  discoverServices() async {
    if (targetDevice == null) {
      return;
    }
// cihazların uuidlerini tarayan fonsiyon
    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristics) {
          if (characteristics.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristics;
            setState(() {
              connectionText = "Hazır Olan Cihaz: ${targetDevice.name}";
            });
          }
        });
      }
    });
  }

// verileri espye yollayan fonsiyon
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

  bool isSwitched = false;
// gönder button fonsiyon
  submitAction() {
    var wifiData =
        '${wifiNameController.text},${wifiPasswordController.text},${wifiipaddress.text},${dnsset1.text},${dnsset2.text},${wifimaskaddress.text},${wifimqttaddress.text}';

    writeData(wifiData);
  }

// verileri editore kaydeden yer
  TextEditingController wifiNameController = TextEditingController();
  TextEditingController wifiPasswordController = TextEditingController();
  TextEditingController wifiipaddress = TextEditingController();
  TextEditingController wifimaskaddress = TextEditingController();
  TextEditingController wifimqttaddress = TextEditingController();
  TextEditingController dnsset1 = TextEditingController();
  TextEditingController dnsset2 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          connectionText,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        // if else ile boşsa bekleme doluysa form açan kod
        child: targetCharacteristic == null
            ? Center(
                child:ListView(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        // bekleme sayfası
                        Container(
                          margin: EdgeInsets.only(top:100),
                          child: Text(
                            "Bekleyiniz...",
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
                                    primary: Colors.green[900]),
                                onPressed: () => reset(),
                                icon: Icon(Icons.refresh),
                                label: Text("RESET"),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 40),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.green[800]),
                                onPressed: () => qrreset(),
                                icon: Icon(Icons.refresh),
                                label: Text("TEKRAR QR OKUT"),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          // reset buttonu text
                          margin: EdgeInsets.only(top: 50),
                          child: Center(
                            child: Text(
                              "Çalışmadığı anda at bir RESET kendimize gelelim :)",
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
                              " OKUNAN QR : ${_scanBarcode}",
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
                    ),
                  ],
                ),
              )
            : ListView(
                children: <Widget>[
                  Padding(
                    // textfieldler
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: wifiNameController,
                      decoration: InputDecoration(labelText: 'Wifi Name'),
                      keyboardType: TextInputType.name,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: wifiPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(labelText: 'Wifi Password'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: wifimqttaddress,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'MQTT Server'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      enabled: isSwitched,
                      controller: wifiipaddress,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Wifi İP Address'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: wifimaskaddress,
                      enabled: isSwitched,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: 'Wifi Mask Adress'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: dnsset1,
                      enabled: isSwitched,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'DNS Settings 1'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: dnsset2,
                      enabled: isSwitched,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'DNS Settings 2'),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      // dhcp switch ve text
                      Container(
                        margin: EdgeInsets.only(left: 50),
                        child: Text(
                          "DHCP",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 80,
                        margin: EdgeInsets.only(left: 30),
                        child: Switch(
                          value: isSwitched,
                          onChanged: (value) {
                            setState(() {
                              isSwitched = value;
                              print(isSwitched);
                            });
                          },
                          activeTrackColor: Colors.green,
                          inactiveTrackColor: Colors.red,
                          activeColor: Colors.black12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton.icon(
                        // geri buttonu
                        style: ElevatedButton.styleFrom(primary: Colors.grey),
                        icon: Icon(Icons.keyboard_backspace),
                        label: Text(
                          'Back',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          backpage();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FirstRoute()),
                          );
                        },
                      ),
                      Padding(
                        // alert diolag
                        padding: const EdgeInsets.all(16),
                        child: RaisedButton(
                          onPressed: () => showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Uyarı!'),
                              content: const Text(
                                  'Bilgileri Doğru Şekilde Girdiğine Emin misin?'),
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
                          color: Colors.green,
                          child: Text('Send'),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    // mac adresi text
                    margin: EdgeInsets.only(top: 30, bottom: 100),
                    child: SizedBox(
                      child: Text(
                        "Şuanda Bağlı Olan Cihaz : ${targetDevice.id}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 18,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
