#include <ESPNtpClient.h>

#include "EEPROM.h"

#define EEPROM_SIZE 4096

#include <SPI.h>

#include <WiFi.h>

#include <ArduinoJson.h>

#include <Adafruit_MAX31856.h>

#include <PubSubClient.h>

#include <time.h>

#include <BLEDevice.h>

#include <BLEServer.h>

#include <BLEUtils.h>

#include <BLE2902.h>

#define SHOW_TIME_PERIOD 1000
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
Adafruit_MAX31856 maxthermo = Adafruit_MAX31856(17, 16, 5, 4);
BLEServer * pServer = NULL;
BLECharacteristic * pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
double tempSensorValue = 0;

const int ledPin = 22;
const int modeAddr = 0;
const int wifiAddr = 40;
const int dataAddr = 400;
WiFiClient espClient;
PubSubClient client(espClient);

int modeIdx;

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer * pServer) {
    deviceConnected = true;
    BLEDevice::startAdvertising();
  };

  void onDisconnect(BLEServer * pServer) {
    deviceConnected = false;
  }
};

class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic * pCharacteristic) {
    std::string value = pCharacteristic -> getValue();

    if (value.length() > 0) {
      Serial.print("Value : ");
      Serial.println(value.c_str());
      writeString(wifiAddr, value.c_str());
    }
  }

  void writeString(int add, String data) {
    int _size = data.length();
    for (int i = 0; i < _size; i++) {
      EEPROM.write(add + i, data[i]);
    }
    EEPROM.write(add + _size, '\0');
    EEPROM.commit();
  }

};

void setup() {

  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  if (!maxthermo.begin()) {
    Serial.println("Could not initialize thermocouple.");
    while (1) delay(10);
  }
  NTP.setTimeZone(TZ_Asia_Almaty);
  NTP.begin();
  maxthermo.setThermocoupleType(MAX31856_TCTYPE_K);

  Serial.print("Thermocouple type: ");
  switch (maxthermo.getThermocoupleType()) {
  case MAX31856_TCTYPE_B:
    Serial.println("B Type");
    break;
  case MAX31856_TCTYPE_E:
    Serial.println("E Type");
    break;
  case MAX31856_TCTYPE_J:
    Serial.println("J Type");
    break;
  case MAX31856_TCTYPE_K:
    Serial.println("K Type");
    break;
  case MAX31856_TCTYPE_N:
    Serial.println("N Type");
    break;
  case MAX31856_TCTYPE_R:
    Serial.println("R Type");
    break;
  case MAX31856_TCTYPE_S:
    Serial.println("S Type");
    break;
  case MAX31856_TCTYPE_T:
    Serial.println("T Type");
    break;
  case MAX31856_VMODE_G8:
    Serial.println("Voltage x8 Gain mode");
    break;
  case MAX31856_VMODE_G32:
    Serial.println("Voltage x8 Gain mode");
    break;
  default:
    Serial.println("Unknown");
    break;
  }

  maxthermo.setConversionMode(MAX31856_ONESHOT_NOWAIT);
  delay(10);
  if (!EEPROM.begin(EEPROM_SIZE)) {
    delay(1000);
  }

  modeIdx = EEPROM.read(modeAddr);
  Serial.print("modeIdx : ");
  Serial.println(modeIdx);

  EEPROM.write(modeAddr, modeIdx != 0 ? 0 : 1);
  EEPROM.commit();

  if (modeIdx != 0) {
    //BLE MODE
    digitalWrite(ledPin, true);
    Serial.println("BLE MODE");
    bleTask();
  } else {
    //WIFI MODE
    digitalWrite(ledPin, false);
    Serial.println("WIFI MODE");
    wifiTask();
  }

}

void bleTask() {
  // Create the BLE Device
  BLEDevice::init("ESP32");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer -> setCallbacks(new MyServerCallbacks());
  // Create the BLE Service
  BLEService * pService = pServer -> createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pCharacteristic = pService -> createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY |
    BLECharacteristic::PROPERTY_INDICATE
  );

  pCharacteristic -> setCallbacks(new MyCallbacks());

  pCharacteristic -> addDescriptor(new BLE2902());

  // Start the service
  pService -> start();

  // Start advertising
  BLEAdvertising * pAdvertising = BLEDevice::getAdvertising();
  pAdvertising -> addServiceUUID(SERVICE_UUID);
  pAdvertising -> setScanResponse(false);
  pAdvertising -> setMinPreferred(0x0); // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void wifiTask() {
    int g=11;
  while(10<g){
  String receivedData;
  receivedData = read_String(wifiAddr);

  if (receivedData.length() > 0) {
    String wifiName = getValue(receivedData, ',', 0);
    String wifiPassword = getValue(receivedData, ',', 1);
    String mqttbroker1 = getValue(receivedData, ',', 2);
    String mqttusername1 = getValue(receivedData, ',', 3);
    String mqttpassword1 = getValue(receivedData, ',', 4);
    String topic1 = getValue(receivedData, ',', 5);
    const int mqtt_port = 1883;

    int n = mqttbroker1.length();

    char mqtt_broker[n + 1];

    strcpy(mqtt_broker, mqttbroker1.c_str());

    int n1 = mqttusername1.length();

    char mqtt_username[n1 + 1];

    strcpy(mqtt_username, mqttusername1.c_str());
    int n2 = mqttpassword1.length();

    char mqtt_password[n2 + 1];

    strcpy(mqtt_password, mqttpassword1.c_str());
    int n3 = topic1.length();

    char topic[n3 + 1];

    strcpy(topic, topic1.c_str());

    if (wifiName.length() > 0 && wifiPassword.length() > 0) {
      Serial.print("WifiName : ");
      Serial.println(wifiName);
      Serial.print("wifiPassword : ");
      Serial.println(wifiPassword);

      WiFi.begin(wifiName.c_str(), wifiPassword.c_str());

      Serial.print("Connecting to Wifi");
      int z = 1;
      double array[z];

      while (WiFi.status() != WL_CONNECTED) {

        unsigned long eskiZaman = 0;
        unsigned long yeniZaman;

        Serial.print(".");
        delay(300);
        int adress = 400;

        yeniZaman = millis();

        if (yeniZaman - eskiZaman > 1000 * 5*60) {

          int x = 0;

          x++;

          maxthermo.triggerOneShot();
          double pressureSensorValue = 0;
          pressureSensorValue = maxthermo.readThermocoupleTemperature();
          array[x] = pressureSensorValue;
          int b = z + 1;
          array[b];

          // }
          if (x == 4000) {
            x = 0;
          }

          eskiZaman = yeniZaman;
        }

      }

      Serial.println();
      Serial.print("Connected with IP: ");
      Serial.println(WiFi.localIP());

      client.setServer(mqtt_broker, mqtt_port);
      client.setCallback(callback);
      while (!client.connected()) {
        String client_id = "esp32-client-";
        client_id += String(WiFi.macAddress());
        Serial.printf("The client %s connects to the public mqtt broker\n", client_id.c_str());
        if (client.connect(client_id.c_str(), mqtt_username, mqtt_password)) {

          Serial.println("Public emqx mqtt broker connected");
        } else {
          Serial.print("failed with state ");
          Serial.print(client.state());
          delay(2000);
          unsigned long eskiZaman1 = 0;
          unsigned long yeniZaman1;
          yeniZaman1 = millis();
          if (yeniZaman1 - eskiZaman1 > 1000 * 5*60) {

            int x = 0;

            x++;
            delay(1000);
            maxthermo.triggerOneShot();
            double pressureSensorValue = 0;
            pressureSensorValue = maxthermo.readThermocoupleTemperature();
            array[x] = pressureSensorValue;
            int b = z + 1;
            array[b];

            if (x == 4000) {
              x = 0;
            }

            eskiZaman1 = yeniZaman1;
          }
        }

        unsigned long previousMillis = 0;
        unsigned long interval = 5000;
        unsigned long currentMillis = millis();
        // if WiFi is down, try reconnecting
        if ((WiFi.status() != WL_CONNECTED) && (currentMillis - previousMillis >= interval)) {
          Serial.print(millis());
          Serial.println("Reconnecting to WiFi...");
          WiFi.disconnect();
          WiFi.reconnect();
          WiFi.begin(wifiName.c_str(), wifiPassword.c_str());
          previousMillis = currentMillis;
          unsigned long eskiZaman2 = 0;
          unsigned long yeniZaman2;
          yeniZaman2 = millis();
          if (yeniZaman2 - eskiZaman2 > 1000 * 5) {

            int x = 0;

            x++;
            delay(1000);
            maxthermo.triggerOneShot();
            double pressureSensorValue = 0;
            pressureSensorValue = maxthermo.readThermocoupleTemperature();
           
            array[x] = pressureSensorValue;
            int b = z + 1;
            array[b];

            if (x == 4000) {
              x = 0;
            }

            eskiZaman2 = yeniZaman2;
          }
        }

      }

      while (client.connected()) {

        delay(1000);
        StaticJsonDocument < 256 > JSONbuffer;
        JsonObject veri = JSONbuffer.createNestedObject();
        maxthermo.triggerOneShot();
        tempSensorValue = maxthermo.readThermocoupleTemperature();

        JsonObject date = JSONbuffer.createNestedObject();
        static int last = 0;

        if ((millis() - last) >= SHOW_TIME_PERIOD) {
          last = millis();
          date["dateData"] = NTP.getTimeDateStringUs();
        }
        char JSONmessageBuffer[200];

        veri["sensorValue"] = tempSensorValue;

        if (sizeof(array) > 3) {
          for (int i = 0; i < sizeof(array); i++) {
            veri["sensorValue"] = array[i];
            char JSONmessageBuffer[200];
            serializeJsonPretty(JSONbuffer, JSONmessageBuffer);
            if (client.publish(topic, JSONmessageBuffer) == true) {
              Serial.println("Success sending message");
            } else {
              Serial.println("Error sending message");
            }

            client.subscribe(topic);

          }
        }
        serializeJsonPretty(JSONbuffer, JSONmessageBuffer);
        if (client.publish(topic, JSONmessageBuffer) == true) {
          Serial.println("Success sending message");
        } else {
          Serial.println("Error sending message");
        }

        client.subscribe(topic);

      }
    }
  }
  }
}
void callback(char * topic, byte * payload, unsigned int length) {
  StaticJsonDocument < 200 > doc;

  char json[length + 1];
  strncpy(json, (char * ) payload, length);
  json[length] = '\0';
  Serial.print("Message arrived in topic: ");
  Serial.println(topic);
  Serial.print("Message:");
  DeserializationError error = deserializeJson(doc, json);

  for (int i = 0; i < length; i++) {
    Serial.print((char) payload[i]);
  }
  Serial.println();
  Serial.println("-----------------------");
  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    return;
  }
}

void loop() {
  if (modeIdx == 0) {
    client.loop();

  }

}

String read_String(int add) {
  char data[100];
  int len = 0;
  unsigned char k;
  k = EEPROM.read(add);
  while (k != '\0' && len < 500) {
    k = EEPROM.read(add + len);
    data[len] = k;
    len++;
  }
  data[len] = '\0';
  return String(data);
}

String getValue(String data, char separator, int index) {
  int found = 0;
  int strIndex[] = {
    0,
    -1
  };
  int maxIndex = data.length() - 1;

  for (int i = 0; i <= maxIndex && found <= index; i++) {
    if (data.charAt(i) == separator || i == maxIndex) {
      found++;
      strIndex[0] = strIndex[1] + 1;
      strIndex[1] = (i == maxIndex) ? i + 1 : i;
    }
  }
  return found > index ? data.substring(strIndex[0], strIndex[1]) : "";
}