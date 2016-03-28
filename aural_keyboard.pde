/* aural_keyboard: 2015-12-19 : ylh
 on github.com as blink_based_aural_scanning_keyboard_with_Morse_code_option
 
 based on blink_opencv3 20150219 - 20150225
 see manual file for Manual
 
 Phases: (when pressed)
 0 - test
 1 - reset eye position, waiting for detection of left eye
 2 - when, 1 pressed, registered 'normal' eye configuration
 3 - 'yes' registered
 4 - 'no' registered; now loop around waiting to go to aural kb
 5 - aural keyboard/ mail
 9 - go to Morse mode ( "......" 6 dits get back to scanning mode
 
 mode: 0=regular keyboard; 1=browser; 2=email
 inputType: 0 = regular aural, 1 = Morse
 */

import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import ddf.minim.*;
import ddf.minim.ugens.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.Mat;
import org.opencv.core.Core.MinMaxLocResult;
import org.opencv.core.Core;

import java.io.*;

boolean testing = false;  // jump to new code in 'test'
boolean useOldcode = false; // testing fragments

boolean useWebcam = false; // use webcam (true) or eye cam (false)
boolean debug = false;
boolean useColor = false;
boolean useGoogle = false;
boolean useBrowser = false;

// 0 - waiting; when both eyes closed, triggered alarmStartTime ->1
// 1 && alarmStartTime > x msec, buzzAlarm.on -> 2
// 2 && both eyes open -> 0


final int seconds = 1000;  
int pauseFor;
boolean showCountDown = false; // pause countdown indicator
int alarmThreshold = 9*seconds; 

int SCALE = 1;

Minim gMinim;
AudioPlayer[] sounds;

// audio alarms
Buzzer buzzDash, buzzDot, buzzAlarm;

Capture video;
OpenCV opencv, opencv2;
import java.awt.Robot;
import java.awt.event.KeyEvent;

Robot robot;

int phase=1; //lastTime;
// int iters = 0;
//ClickButton clk;

// phase 1
String instruction = "1=Reset  2=register 'Normal'  3=register 'Eyes Up'  4=register 'Eyes Down' 5=Run";
String instruction2 = "a=announce p=pause s=sound v=voice feedback j=slower k=faster Shift-R=ready alarm";

Rectangle ROI = new Rectangle(0, 0, 0, 0);
Rectangle foundROI = new Rectangle(0, 0, 0, 0);
Rectangle roiLeft = new Rectangle(0, 0, 0, 0);
Rectangle roiRight = new Rectangle(0, 0, 0, 0);
PImage IMsource, IMnormal, IMyes, IMno; 

int screenWidth = 1240;
int screenHeight = 880;

// translating coordinates to here
int offsetX = 300, offsetY = 440;

// variables
Histogram normalHist, yesHist, sourceHist;
Mat normalMat, yesMat, noMat, sourceMat, Mroi, normalRes, yesRes, noRes;
int selected = 0;

// below for eye camera use (see test_borescope.pde)
// i.e. useWebcam == false
String foundCamera = null;
int camWidth = 160;
int camHeight = 120;// 128;
PImage[] imL;
Mat[] matL;
Mat[] res;

void setup() {

  if ( testing ) {
    testSetup();
    return;
  }

  textlines[0]="";
  /* test new fragments of speech here */
  if ( false  ) {
    textlines[0] = "The quick brown fox jumps over the lazy dog";
    textlines[1] = "Please turn on the TV";
    textlines[2] = "Thank you";
    currentLine = 2;
    readIt();
    if (false) exit();
  }   

  //size(1240, 880);
  //size(screenWidth, screenHeight);
  fullScreen();


  buzzDash = new Buzzer( 1000, 0.1 );
  buzzDot = new Buzzer( 1200, 0.1 ); 
  buzzAlarm = new Buzzer( 1200, 0.8 );  

  if ( debug )  ListCameras();

  if ( useWebcam ) {
    video = new Capture(this, 640/SCALE, 480/SCALE);
    foundCamera = "Laptop's Webcam";
    video.start();
  } else {
    /* old code: hard codes device; now we use selectCamera() in draw()
     //video = new Capture(this, "name=USB2.0_Camera,size="  //U cam webcam
     //video = new Capture(this, "name=USB 2.0 Camera,size="  //webcam
     video = new Capture(this, "name=USB 2.0 PC Cam,size="  // borescope
     //video = new Capture(this, "name=2.0 PC CAMERA,size="  // borescope - 7mm 'Android'
     + camWidth + "x" + camHeight + ",fps=30" ); 
     */
    while ( foundCamera == null) {
      foundCamera = selectCamera ();
      if ( foundCamera != null ) {
        print( "========>FOUND CAMERA: " );
        println( foundCamera );
        video = new Capture( this, foundCamera );
        video.start();
        delay(2000); // don't start right away
      }
    }
  }

  opencv = new OpenCV(this, 640/SCALE, 480/SCALE);
  //opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  opencv.loadCascade( OpenCV.CASCADE_EYE );
  opencv.useGray(); 

  if ( useWebcam == false ) {
    matL = new Mat[10];
    res = new Mat[10];
    imL = new PImage[10];
  }

  // old code kicks starts video here
  //video.start();

  try {
    robot = new Robot();
  } 
  catch (java.awt.AWTException ex) { 
    println("Problem initializing AWT Robot: " + ex.toString());
  }

  doCBInit();

  //launchMail();

  frameRate(FRAME_RATE);
}


void draw() {

  if (testing) {
    testDraw();
    return;
  }

  scale(SCALE);
  // timed operations checked here
  buzzDash.loop();
  buzzDot.loop();
  buzzAlarm.loop();
  checkPause();

  fill(0, 0, 0);
  rect(0, 0, width, height);
  noFill();

  if ( foundCamera == null) { // redundant code - in setup() already
    foundCamera = selectCamera ();
    if ( foundCamera == null ) return;
    print( "========>FOUND CAMERA: " );
    println( foundCamera );
    video = new Capture( this, foundCamera );
    video.start();
    delay(2000); // don't start right away
    return;
  }

  displayText(); // display in the main frame

  pushMatrix(); 
  translate (offsetX, offsetY);  

  switch( phase ) {
  case 0:
    doMail();
    break;
  case 1:
    initPhase1();
    doPhase1();
    break;
  case 2:
    doPhase2();
    break;
  case 3:
    doPhase3();
    break;
  case 4:
    doPhase4();
    break;
  case 5:
    doPhase5();
    break;
  }

  popMatrix();
}

void keyPressed() {

  if ( testing ) return;

  switch( phase ) {
  case 0:
    //switchToAlpine();
    //type(key);
    //doAlpine();
    break;
  case 1:  // in phase 1, therefore '2' is pressed
    stroke(0);

    IMnormal = get( (SCALE*foundROI.x)+ offsetX, (SCALE*foundROI.y) + offsetY, SCALE*foundROI.width, SCALE*foundROI.height);
    if ( useWebcam ) {
      IMsource = trans2( IMnormal );
      IMsource.save("normal.jpg");

      opencv2 = new OpenCV(this, "normal.jpg", useColor);
      opencv2.setGray(opencv2.getR().clone());
      Imgproc.morphologyEx(opencv2.getGray(), opencv2.getGray(), Imgproc.MORPH_GRADIENT, new Mat());
      normalMat = opencv2.getGray();
    } else {
      IMsource = get( SCALE*ROI.x+offsetX, SCALE*ROI.y+offsetY, SCALE*ROI.width, SCALE*ROI.height );
      IMsource.save("normal.jpg");
      process(0, IMsource);
    }
    phase = 2;  
    break;
  case 2:  // in phase 2 therefore '3' is pressed
    stroke(0);
    IMnormal = get( SCALE*foundROI.x+offsetX, SCALE*foundROI.y+offsetY, SCALE*foundROI.width, SCALE*foundROI.height);
    if ( useWebcam ) {
      IMsource = trans2( IMnormal ); 
      IMsource.save("yes.jpg");

      opencv2 = new OpenCV(this, "yes.jpg", useColor);
      opencv2.setGray(opencv2.getR().clone());
      Imgproc.morphologyEx(opencv2.getGray(), opencv2.getGray(), Imgproc.MORPH_GRADIENT, new Mat());
      yesMat = opencv2.getGray();
    } else {
      IMsource = get( SCALE*ROI.x+offsetX, SCALE*ROI.y+offsetY, SCALE*ROI.width, SCALE*ROI.height );
      IMsource.save("yes.jpg");
      process(1, IMsource);
    }
    phase = 3;  
    break;
  case 3:
    stroke(0);
    IMnormal = get( SCALE*foundROI.x+offsetX, SCALE*foundROI.y+offsetY, SCALE*foundROI.width, SCALE*foundROI.height );

    if ( useWebcam) {
      IMsource = trans2( IMnormal ); 
      IMsource.save("no.jpg");

      opencv2 = new OpenCV(this, "no.jpg", useColor);
      opencv2.setGray(opencv2.getR().clone());
      Imgproc.morphologyEx(opencv2.getGray(), opencv2.getGray(), Imgproc.MORPH_GRADIENT, new Mat());
      noMat = opencv2.getGray();

      /* changed
       foundROI.x-=10; 
       foundROI.y-=10; 
       foundROI.width +=20;
       foundROI.height+=20;
       */
    } else {
      IMsource = get( SCALE*ROI.x+offsetX, SCALE*ROI.y+offsetY, SCALE*ROI.width, SCALE*ROI.height );
      IMsource.save("no.jpg");
      process(2, IMsource);
    }
    phase = 4;  
    break;
  case 4:
    // phase = no activity; just loop and wait
    break;
  case 5:  
    // ignore keystrokes if in email
    if ( mode==REGULAR ) { 

      if ( !pause && key == ' ') {
        selected = 1;
        print('*');
        if ( soundon ) buzzDot.on(50);
        if (inputType == REGULAR)
          doCB();
        else doMorse();
      } 
      if (key == 'a' ) announceon = !announceon;    
      if (key == 'p' ) { 
        if ( !pause ) pauseFor(0, false);
        else pause();
      }   
      if (key == 's' ) soundon = !soundon;
      if (key == 'v' ) voiceon = !voiceon;
      if (key == 'k' ) faster();
      if (key == 'j' ) slower();
      if (key == 'R' ) callbellReady = !callbellReady;
      if (key == 'd' ) deleteChar(true);
    }
    break;
  case 6: 
    break;
  }
  switch( key ) {
  case '1':
    phase = 1;
    mode=REGULAR;
    break;
  case '2':
    phase = 2;
    break;
  case '3':
    phase =3;
    break;
  case '4':
    phase =4;
    break;
  case '5':
    phase =5;
    break;
  case '0':
  case 't':
  case 'T':
    // phase = 0;
    break;
  }
}

void doPhase5() {

  showInstruction();
  displayBuffer();

  if ( pause ) {
    textSize(30);
    fill( 255, 0, 0 );
    text( "PAUSED", 260, 40 );
    //if ( prevItem.equals("pause") ) {
    if (showCountDown) {
      text( (pauseFor - (millis() - whenPaused))/1000, 380, 40 );
    }
    return;
  }

  noFill();

  opencv.loadImage(video);
  image(video, 0, 0 );

  fill(0, 0, 0); 
  stroke(0, 0, 0);
  rect(0, 0, screenWidth, ROI.y); // blacken top
  rect(0, ROI.y+ROI.height-20, screenWidth, screenHeight); // blacken bottom

  showInstruction();
  displayBuffer();

  if (useWebcam) {
    noFill();
    strokeWeight(1);
    stroke(0, 255, 0);
    rect(foundROI.x, foundROI.y, foundROI.width, foundROI.height); 

    if ( useOldcode) {

      IMnormal = get(foundROI.x+offsetX, foundROI.y + offsetY, foundROI.width, foundROI.height);
      image( IMnormal, -300, -300 );

      opencv.releaseROI();
      opencv.setROI(foundROI.x, foundROI.y, foundROI.width, foundROI.height);
      debugROI("5old");
      Mroi = opencv.getROI().clone(); 
      opencv.releaseROI();
      //opencv.setGray(Mroi);

      // bad use of morphology
      Imgproc.morphologyEx(Mroi, Mroi, Imgproc.MORPH_GRADIENT, new Mat());

      normalRes = new Mat();  
      //inverted template/image to search
      Imgproc.matchTemplate(Mroi, normalMat, normalRes, Imgproc.TM_CCORR_NORMED);
      yesRes = new Mat();  
      Imgproc.matchTemplate(Mroi, yesMat, yesRes, Imgproc.TM_CCORR_NORMED);
      noRes = new Mat();  
      Imgproc.matchTemplate(Mroi, noMat, noRes, Imgproc.TM_CCORR_NORMED);
    } else {

      // debugROI("5");
      IMnormal = get(foundROI.x+offsetX, foundROI.y+offsetY, foundROI.width, foundROI.height);
      //image( IMnormal, -IMnormal.width, 0);
      IMsource = trans2( IMnormal ); 
      image( IMsource, -IMnormal.width, 0) ; 

      opencv = new OpenCV( this, IMsource );
      opencv.setROI(0, 0, IMsource.width, IMsource.height);
      Mroi = opencv.getROI().clone(); 
      opencv.releaseROI();
      //opencv.setGray(Mroi);
      // DO NOT USE morphology
      //Imgproc.morphologyEx(Mroi, Mroi, Imgproc.MORPH_GRADIENT, new Mat());

      normalRes = new Mat();  
      Imgproc.matchTemplate(normalMat, Mroi, normalRes, Imgproc.TM_CCORR_NORMED);
      yesRes = new Mat();  
      Imgproc.matchTemplate(yesMat, Mroi, yesRes, Imgproc.TM_CCORR_NORMED);
      noRes = new Mat();  
      Imgproc.matchTemplate(noMat, Mroi, noRes, Imgproc.TM_CCORR_NORMED);
    }


    if ( debug ) {
      println( "normal=" + nf((float)Core.minMaxLoc(normalRes).maxVal, 0, 2)
        + " yes=" + nf((float)Core.minMaxLoc(yesRes).maxVal, 0, 2) 
        + " no=" + nf((float)Core.minMaxLoc(noRes).maxVal, 0, 2));
    }
  } else { // use eye cam
    //IMnormal = loadImage( "normal.jpg" );
    image( IMnormal, camWidth, 0 );
    image( imL[0], camWidth, camHeight );
    //IMyes = loadImage( "yes.jpg" );
    image( IMyes, camWidth*2, 0 );
    image( imL[1], camWidth*2, camHeight );
    //IMno = loadImage( "no.jpg" );
    image( IMno, camWidth*3, 0 );
    image( imL[2], camWidth*3, camHeight );

    PImage IMcurrent = get(foundROI.x+offsetX, foundROI.y + offsetY, foundROI.width, foundROI.height);
    PImage procCurrent = process( 3, IMcurrent );
    Mroi = matL[3];
    image( procCurrent, 0, camHeight );

    opencv = new OpenCV( this, procCurrent );
    opencv.setROI(0, 0, IMcurrent.width, IMcurrent.height);
    Mroi = opencv.getROI().clone(); 
    opencv.releaseROI();

    for (int i=0; i<3; i++) { 
      res[i] = new Mat();
      Imgproc.matchTemplate(matL[i], Mroi, res[i], Imgproc.TM_CCORR_NORMED);
      //Imgproc.matchTemplate(matL[i], Mroi, res[i], Imgproc.TM_CCOEFF_NORMED);

      //Imgproc.matchTemplate(matL[i], Mroi, res[i], Imgproc.TM_SQDIFF);

      noFill();
      stroke(0, 255, 0);
      strokeWeight(1);
      rect( OpenCV.pointToPVector(Core.minMaxLoc(res[i]).maxLoc).x + camWidth*(i+1), 
      OpenCV.pointToPVector(Core.minMaxLoc(res[i]).maxLoc).y + camHeight, foundROI.width, 
      foundROI.height );

      fill( 255, 0, 0 );
      text( nf((float)Core.minMaxLoc(res[i]).maxVal, 0, 2), camWidth*(i+1) + 20, camHeight*2 - 15);
    }

    normalRes = res[0];
    yesRes = res[1];
    noRes = res[2];
  }

  /* if using another coefficient
   if ( Core.minMaxLoc(yesRes).minVal < 0.5 && 
   ( Core.minMaxLoc(yesRes).minVal < Core.minMaxLoc(normalRes).minVal ) &&
   ( Core.minMaxLoc(yesRes).minVal < Core.minMaxLoc(noRes).minVal )  ) {
   //*/

  if ( Core.minMaxLoc(yesRes).maxVal > 0.6 && 
    ( Core.minMaxLoc(yesRes).maxVal > Core.minMaxLoc(normalRes).maxVal ) &&
    ( Core.minMaxLoc(yesRes).maxVal > Core.minMaxLoc(noRes).maxVal )  ) {

    if (debug) {
      fill(255, 0, 0);
      textSize(16);
      text( "normal=" + nf((float)Core.minMaxLoc(normalRes).maxVal, 0, 2)
        + " yes=" + nf((float)Core.minMaxLoc(yesRes).maxVal, 0, 2) 
        + " no=" + nf((float)Core.minMaxLoc(noRes).maxVal, 0, 2), -IMnormal.width, -40 );
    }  
    // MARK
    selected = 1;  // yes1
    fill(0, 0, 255);
    rect(0, 0, foundROI.width, foundROI.height); 
    noFill();

    if ( !MARK && ((millis()-firstTimeMorse ) > 2*seconds) ) {
      timeLapse = millis() - lastTransit;
      lastTransit = millis();
      TRANSIT = true;
      MARK = true;
    }

    if ( soundon && inputType==REGULAR ) buzzDot.on(1000);
    if ( callbellReady && ( (millis() - lastTransit) > alarmThreshold )) {
      buzzAlarm.on(5000);
      pauseFor(5000, false);
    }
  } else { 
    // NOT MARK
    if ( Core.minMaxLoc(noRes).maxVal > 0.6 && 
      ( Core.minMaxLoc(noRes).maxVal > Core.minMaxLoc(normalRes).maxVal ) &&
      ( Core.minMaxLoc(noRes).maxVal > Core.minMaxLoc(yesRes).maxVal )  ) {

      // "No" - not used yet
      selected = 0; // no

      //pauseFor( 60000, true );  // 'no' gesture means 60s pause

      /* YLH - use NO to reset morse buffer
       if ( inputType==MORSE ) {
       morseStr="";
       MARK = TRANSIT = false;
       wroteSpace = true; // steady state
       timeLapse = 0;
       lastTransit = millis()-3*seconds;
       }
       */
    } else { // normal

      if ( MARK  && ((millis()-firstTimeMorse ) > 2*seconds) ) {  
        timeLapse = millis() - lastTransit;
        lastTransit = millis();
        TRANSIT = true;
        MARK = false;
      }
    }

    if ( soundon && inputType == REGULAR ) buzzDot.off();
  }

  if (inputType == REGULAR) {
    doCB();
  } else {
    doMorse();
  }
}

void doPhase4() {
  stroke(0, 255, 0);
  image(video, 0, 0 );
  showInstruction();  

  if ( useWebcam) {
    IMnormal = loadImage( "normal.jpg");
    image( IMnormal, - IMnormal.width, 0 ) ; //image( IMnormal, 0, 0);
    IMyes = loadImage( "yes.jpg");
    image( IMyes, - IMnormal.width, IMnormal.height ) ; //image( IMyes, 0, IMnormal.height);
    IMno = loadImage( "no.jpg");
    image( IMno, - IMnormal.width, IMnormal.height+IMyes.height ) ; //image( IMno, 0, IMnormal.height+IMyes.height);
    stroke(0, 255, 0);
    rect(ROI.x, ROI.y, ROI.width, ROI.height);
    stroke( 0, 0, 255);
    rect(  foundROI.x, foundROI.y, foundROI.width, foundROI.height );
  } else {
    IMnormal = loadImage( "normal.jpg");
    image( IMnormal, camWidth, 0 );
    image( imL[0], camWidth, camHeight );
    IMyes = loadImage( "yes.jpg" );
    image( IMyes, camWidth*2, 0 );
    image( imL[1], camWidth*2, camHeight );
    IMno = loadImage( "no.jpg" );
    image( IMno, camWidth*3, 0 );
    image( imL[2], camWidth*3, camHeight );
  }

  lastPresented = millis();
  presented = false;
  selected = 0;
  //phase = 5;
}

void doPhase3() {
  stroke(0, 255, 0);
  image(video, 0, 0 );
  showInstruction();

  IMnormal = loadImage( "normal.jpg");
  if ( useWebcam ) {
    image( IMnormal, - IMnormal.width, 0 ) ; //image( IMnormal, 0, 0);
    IMyes = loadImage( "yes.jpg");
    image( IMyes, - IMnormal.width, IMnormal.height ) ; // image( IMyes, 0, IMnormal.height);
    stroke(0, 255, 0);
    rect(ROI.x, ROI.y, ROI.width, ROI.height);
    stroke( 0, 0, 255);
    rect(  foundROI.x-2, foundROI.y-2, foundROI.width+4, foundROI.height+4 );
  } else {
    image( IMnormal, camWidth, 0 );
    image( imL[0], camWidth, camHeight );
    IMyes = loadImage( "yes.jpg" );
    image( IMyes, camWidth*2, 0 );
    image( imL[1], camWidth*2, camHeight );
  }
}
void doPhase2() {

  image(video, 0, 0 );
  showInstruction();
  IMnormal = loadImage( "normal.jpg");

  if (useWebcam) {
    image( IMnormal, - IMnormal.width, 0 ) ; //image( IMnormal, 0, 0);

    stroke(0, 255, 0);
    rect(ROI.x, ROI.y, ROI.width, ROI.height);

    stroke( 0, 0, 255);
    rect(  foundROI.x-2, foundROI.y-2, foundROI.width+4, foundROI.height+4 );
  } else {
    image( IMnormal, camWidth, 0 );
    image( imL[0], camWidth, camHeight );
  }
  //debugROI("2");
}

void doPhase1() {

  opencv.loadImage(video);
  image(video, 0, 0 );
  showInstruction();

  if ( useWebcam ) {
    ROI.width=120; 
    ROI.height = 240;
    ROI.x = 320/SCALE; // left eye
    ROI.y = 240/SCALE - ROI.height/SCALE/2; 

    boolean found = findEye( ROI );

    if ( found ) {
      if (debug) println( "1: " + foundROI.x + " " + foundROI.y + " " + foundROI.width+ " " +foundROI.height );
    }
  } else {
    ROI.x = 0;
    ROI.y = 0;
    ROI.width = camWidth;
    ROI.height = camHeight;
    foundROI.x = 10;
    foundROI.y = 10;
    foundROI.width = camWidth - 20;
    foundROI.height = camHeight - 20;
  }
}

boolean findEye( Rectangle roi ) {

  noFill();
  strokeWeight(1);
  stroke(0, 255, 0);
  rect(roi.x-roi.width, roi.y, roi.width*2, roi.height);
  line(roi.x, roi.y, roi.x, roi.y+roi.height);

  opencv.setROI(roi.x, roi.y, roi.width, roi.height);
  Rectangle[] eyes = opencv.detect();
  stroke(0, 0, 255);

  for ( int j=0; j<eyes.length; j++ ) {
    rect( eyes[j].x+roi.x-2, eyes[j].y+roi.y-2, eyes[j].width+4, eyes[j].height+4 );
    foundROI = eyes[j];
    foundROI.x += roi.x;
    foundROI.y += roi.y;
  }

  if ( eyes.length==0 ) {
    buzzDash.on(100);
    return false;
  } else {    
    return true;
  }
}

void captureEvent(Capture c) {
  c.read();
}

void displayText() {
  fill(0, 255, 0);
  textSize(30);
  int l=buffer.length();
  if ( currentLine < MaxLines && l > 40 && buffer.charAt(l-1)==' ') {
    textlines[currentLine] = buffer.substring( 0, l-1);
    currentLine++;
    buffer="";
    sayWords("line_stored");
  }
  textlines[currentLine] = buffer;
  for ( int i=0; i<=currentLine; i++ ) {  
    text( textlines[i], offsetX, 30 + i*32);
  }
  noFill();
}

void retrieveLine() {
  if (currentLine <= 0 ) return;
  currentLine--;
  buffer = textlines[currentLine];
  sayWords("line_retrieved");
}

void showInstruction() {
  textSize(14);
  fill(256, 256, 0);
  text( instruction, 10, 360 );
  text( instruction2, 10, 380 );
  noFill();
}

void displayBuffer() {
  int vs = 15, y=bufferY;
  fill(255, 0, 0);
  textSize(30);

  text( buffer.toUpperCase().replaceAll(" ", "_"), 10, -25 );

  textSize(16);
  fill(0, 128, 128);
  if ( inputType == MORSE ) {
    text("speed is " +  Integer.toString(morseSpeed), 10, y );
    displayMorse();
  } else 
    text("speed is " +  Integer.toString(speed), 10, y );

  if ( voiceon) {
    y+=vs;
    fill(0, 128, 128);
    text( "voice feedback on", 10, y);
  }
  if ( soundon) {
    y+=vs;
    fill(0, 128, 128);
    text( "sound on", 10, y);
  }
  if ( !callbellReady) {
    y+=vs;
    fill(255, 0, 0);
    text( "alarm off", 10, y);
  }
  if ( !announceon) {
    y+=vs;
    fill(255, 0, 0);
    text( "NO ANNOUNCEMENT", 10, y);
  }
  fill(0, 128, 128);
}

void displayMorse() {
  int thisx=270, thisy=-60; //thisy=27
  fill(255, 0, 255);
  noStroke();
  if ( morseStr.length() ==0 ) return;
  for ( int i=0; i<morseStr.length (); i++ ) {
    if ( morseStr.charAt(i) == '.') {
      ellipse( thisx, thisy, 15, 15 );
      thisx += 20;
    } else {
      rect( thisx-7, thisy-6, 30, 12 );
      thisx += 40;
    }
  }
}

void checkPause() {
  if ( pause && pauseFor>0 && (millis() - whenPaused) > pauseFor ) {
    pause();
  }
}

// pauseFor = 0 means forever
void pauseFor(int ms, boolean show) {
  pauseFor = ms;
  if ( !pause ) pause();
  showCountDown = show;
}

void pause() {

  pause = !pause;  
  if (pause) { // newly paused
    whenPaused = millis();
    morseStr = ""; 
    wroteSpace = true;
    firstTimeMorse = millis();
    frameRate(1);
  } else {  // newly unpaused

    if ( showCountDown ) sayWords( "waking_up" );
    showCountDown = false;

    morseStr = "";   // ----- Jan 27
    wroteSpace = true;
    lastPresented = millis() + 1000;
    firstTimeMorse = millis();
    lastTransit = millis();
    MARK = TRANSIT = false;
    inDelete = 0;
    timeLapse = 0;
    selected = 0; //============== normal mode
    prevItem = "menu5"; // ----- 2016-01-27
    curItem = "menu5";
    frameRate(FRAME_RATE);
  }
  lastPresented = millis();
}

void initPhase1() {
  frameRate(FRAME_RATE);

  mode = REGULAR;
  inputType = REGULAR;
  curItem = prevItem = "menu5";

  morseStr = "";
  firstTimeMorse = millis();
  wroteSpace = true;

  lastPresented = millis();
  presented = false;
  TRANSIT = false;

  if ( pause ) pause();
}

// CAMERA & IMAGE PROCESSING =============================

void ListCameras() { 
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      print(i); 
      print(": ");
      println(cameras[i]);
    }
  }
}

String selectCamera() { 
  println( "No Camera" );
  fill(0, 0, 0);
  rect(0, 0, width, height);
  fill(200, 50, 50);
  textSize(32);
  text( "Please plug in Eye Scope. Wait 15 seconds ...", offsetX-50, offsetY );
  text( "(Restart program if setup screen does not appear)", offsetX-50, offsetY+40 );

  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    return null;
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      if ( cameras[i].indexOf("USB") > 0 && cameras[i].indexOf(camWidth + "x" + camHeight) > 0 )
        return cameras[i];
    }
  }
  return null;
}


void debugROI(String s) {
  if ( debug) {
    println( s + " ROI:   " + ROI.x + " " + ROI.y + " " + ROI.width+ " " + ROI.height );
    println( s + " found: " + foundROI.x + " " + foundROI.y + " " + foundROI.width+ " " +foundROI.height );
  }
}

PImage trans2( PImage img ) {
  OpenCV newopencv;

  newopencv = new OpenCV(this, img, useColor); // don't use color
  newopencv.blur(1);
  return newopencv.getSnapshot();
}

// process image i
// sets two globals imL[i] and matL[i]
PImage process(int i, PImage inputImg) {
  PImage retImg;
  OpenCV ocv;
  //retImg = get( i*wd, 0, wd, ht);
  ocv = new OpenCV( this, inputImg, false );

  ocv.blur(4);
  ocv.equalizeHistogram();

  ocv.contrast(1.3);

  // experiment with different pre-processing
  //ocv.threshold(128);
  //ocv.dilate();
  //ocv.erode();
  // ocv.findCannyEdges(20,75);

  //ocv.findSobelEdges(0,1);
  //ocv.invert();
  // ocv.blur(1);

  if ( false ) { // testing old code - don't preprocess if using this
    Mat Mroi;
    ocv.setROI(0, 0, inputImg.width, inputImg.height);
    Mroi = ocv.getROI().clone();

    Imgproc.morphologyEx(Mroi, Mroi, Imgproc.MORPH_GRADIENT, new Mat());

    imL[i] = ocv.getSnapshot(); // just to initialize
    ocv.toPImage( Mroi, imL[i] );
    matL[i] = Mroi;
    return imL[i];
  }

  imL[i] = ocv.getSnapshot();

  ocv.setROI(0, 0, imL[i].width, imL[i].height);
  matL[i]= ocv.getROI().clone(); 
  ocv.releaseROI();

  return imL[i];
}