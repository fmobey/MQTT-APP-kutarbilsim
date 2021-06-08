import 'package:flutter/material.dart';
import 'package:flutter_wifi_setter_ble/etherpage.dart';
import 'package:flutter_wifi_setter_ble/wifipage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Bağlantı Noktasi',
    home: FirstRoute(),
    theme: ThemeData(
      primaryColor: Colors.greenAccent,
      backgroundColor: Colors.white30,
      textTheme: TextTheme(bodyText2: TextStyle(color: Colors.purple)),
    ),
  ));
}

class FirstRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bağlantı Sayfasi '),
      ),
      body: ListView(
        children: <Widget>[
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 180),
              child: Text(
                "Lütfen Bağlantı Noktanızı Seçin..",
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 24,
                    fontWeight: FontWeight.w400),
              ),
            ),
          ),
          Center(
            child: Container(
              height: 40,
              width: 140,
              margin: EdgeInsets.only(top: 50),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(primary: Colors.black87),
                icon: Icon(Icons.settings_ethernet),
                label: Text(
                  'Ethernet',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => etherpage()),
                  );
                },
              ),
            ),
          ),
          Center(
            child: Container(
              height: 40,
              width: 140,
              margin: EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                label: Text(
                  'Wifi',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(primary: Colors.black87),
                icon: Icon(Icons.wifi),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => wifipage()),
                  );
                },
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top:110),
            child: Row(
            
              mainAxisAlignment: MainAxisAlignment.center,
               children: <Widget>[
                
                  Text(
                    "With",
                    style: TextStyle(fontSize: 12, color: Colors.black38),
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
    );
  }
}
