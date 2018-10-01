import processing.serial.*;
import netP5.*;
import oscP5.*;
import java.net.InetAddress;

OscP5 oscP5;
NetAddress testOscClient;
Serial ser;

String OSC_URL = "127.0.0.1";
int OSC_PORT = 12000;
String SERIAL_PORT = "/dev/cu.usbmodem14131";
int SERIAL_BAUDRATE = 9600;

String receiveAddr = "";
String typeTag = "";

String myIp = "";
  
void setup() {
  frameRate(10);
  size(400, 400);
  
  oscP5 = new OscP5(this, OSC_PORT);
  testOscClient = new NetAddress(OSC_URL, OSC_PORT);
  
  ser = new Serial(this,SERIAL_PORT, SERIAL_BAUDRATE);
  
  try {
    InetAddress inet = InetAddress.getLocalHost();
    myIp = inet.getHostAddress();
  } catch (Exception e) {
    e.printStackTrace();
  }
}

void draw() {
  background(0);
  text("IP         :" + myIp, 20, 20);
  text("SERIAL_PORT:" + SERIAL_PORT, 20, 40);
  text("OSC_URL:    " + OSC_URL + ":" + OSC_PORT, 20, 60);
  
  text(receiveAddr + " " + typeTag, 20, height/2);
  if (ser.available() > 0) {
    String data = ser.readString();
    text(data, 20, height/2 + 20);
  }
}

void mousePressed() {
  OscMessage msg = new OscMessage("/test");
  msg.add("aaa");
  
  oscP5.send(msg, testOscClient);
}

void oscEvent(OscMessage msg) {
  receiveAddr = msg.addrPattern();
  typeTag = msg.typetag();
  print("### received an osc message.");
  print(" addrpattern: "+msg.addrPattern());
  println(" typetag: "+msg.typetag());
  
  if (receiveAddr.equals("/test")) {
    ser.write("TEST\0");
  } else if (receiveAddr.equals("/detected")) {
    println(msg.get(0).stringValue());
    ser.write(msg.get(0).stringValue() + "\0");
  }
}
