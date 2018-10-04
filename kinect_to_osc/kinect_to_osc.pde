import SimpleOpenNI.*;
import oscP5.*;
import netP5.*;


SimpleOpenNI  context;
color[]       userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };
PVector com = new PVector();                                   
PVector com2d = new PVector();       

PVector rightHandPos = new PVector();
PVector leftHandPos = new PVector();
PVector neckPos = new PVector();

//OSCP5クラスのインスタンス
OscP5 oscP5;
//OSC送出先のネットアドレス
NetAddress myRemoteLocation;

OscMessage msg;

void setup()
{
  size(640,480);
  
  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  
  // enable depthMap generation 
  context.enableDepth();
   
  // enable skeleton generation for all joints
  context.enableUser();
  
  context.setMirror(true);
 
  background(200,0,0);

  stroke(0,0,255);
  strokeWeight(3);
  smooth();  
  
  //ポートを12000に設定して新規にOSCP5のインスタンスを生成
  oscP5 = new OscP5(this,12000);
  //OSC送信先のIPアドレスとポートを指定
  myRemoteLocation = new NetAddress("192.168.4.127",12000);
}

void draw()
{
  // update the cam
  context.update();
  
  // draw depthImageMap
  //image(context.depthImage(),0,0);
  image(context.userImage(),0,0);
  
  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++)
  {
    if(context.isTrackingSkeleton(userList[i]))
    {
      stroke(userClr[ (userList[i] - 1) % userClr.length ] );
      drawSkeleton(userList[i]);
    }      
      
    // draw the center of mass
    if(context.getCoM(userList[i],com))
    {
      context.convertRealWorldToProjective(com,com2d);
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com2d.x,com2d.y - 5);
        vertex(com2d.x,com2d.y + 5);

        vertex(com2d.x - 5,com2d.y);
        vertex(com2d.x + 5,com2d.y);
      endShape();
      
      fill(0,255,100);
      text(Integer.toString(userList[i]),com2d.x,com2d.y);
    }
  }    
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{    
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
  
  
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_HAND,rightHandPos);
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_HAND,leftHandPos);
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,neckPos);
//  println(rightHandPos.x,leftHandPos.x);
//  float diff = rightHandPos.x - leftHandPos.x;
//  println("Distance betweens hands : ",int(diff/10),"cm");
//  println(rightHandPos.y,leftHandPos.y, neckPos.y);
//  println(rightHandPos.z);
  if (rightHandPos.y > neckPos.y && leftHandPos.y > neckPos.y){
    println(" 両手をあげた");
    msg = new OscMessage("/detected");
    msg.add("lr");
    println(msg.get(0));
    //OSCメッセージ送信
    oscP5.send(msg, myRemoteLocation);
  }else if (leftHandPos.y > neckPos.y){
    println(" 右手をあげた");
    msg = new OscMessage("/detected");
    msg.add("r");
    println(msg.get(0));
    //OSCメッセージ送信
    oscP5.send(msg, myRemoteLocation);
  }else if (rightHandPos.y > neckPos.y){
    println(" 左手をあげた");
    msg = new OscMessage("/detected");
    msg.add("l"); 
    //OSCメッセージ送信
    oscP5.send(msg, myRemoteLocation);
  }else{
    println(" 手を下げた");
    msg = new OscMessage("/detected");
    msg.add("n");
    //OSCメッセージ送信
    oscP5.send(msg, myRemoteLocation);
  }
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  
  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
//  println("onVisibleUser - userId: " + userId);
}

