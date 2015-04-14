import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim       minim;
AudioOutput out;
Oscil       wave1, wave2;

Capture video;
OpenCV opencv;

int lastTime, iters = 0;

void setup() {
  size(640, 480);
  
  minim = new Minim(this);
  
  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();
  
  // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
  wave1 = new Oscil( 440, 0, Waves.SINE );
  wave2 = new Oscil( 660, 0, Waves.SINE );
  // patch the Oscil to the output
  wave1.patch( out );
  wave2.patch( out );
  
  video = new Capture(this, 640/2, 480/2);
  opencv = new OpenCV(this, 640/2, 480/2);
  //opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  opencv.loadCascade( OpenCV.CASCADE_EYE );
  opencv.useGray(); 

  video.start();
}

void draw() {
  scale(2);
  opencv.loadImage(video);
  image(video, 0, 0 );
  stroke( 255, 0, 0 );
  rect( 100, 120, 120, 80);
  opencv.setROI( 100, 120, 120, 80);


  noFill();
  stroke(0, 255, 0);
  strokeWeight(1);

  /* do not need face detection
   opencv.releaseROI();
   opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
   Rectangle[] faces = opencv.detect();
   println(faces.length);
   for (int i = 0; i < faces.length; i++) {
   println(i, ": ", faces[i].x + "," + faces[i].y);
   rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
   opencv.setROI(faces[i].x, faces[i].y, faces[i].width, faces[i].height*2/3); 
   
   
   opencv.loadCascade( OpenCV.CASCADE_EYE );
   */

  Rectangle[] eyes = opencv.detect();
  stroke(0, 0, 255);
  //fill(0);
  for ( int j=0; j<eyes.length; j++ ) {
    //rect( eyes[j].x+faces[i].x, eyes[j].y+faces[i].y, eyes[j].width, eyes[j].height );
    rect( eyes[j].x+100, eyes[j].y+120, eyes[j].width, eyes[j].height );
  }
  switch (eyes.length ) {
    case 0:  wave1.setAmplitude(0.5); wave2.setAmplitude(.5); break;
    case 1:  wave1.setAmplitude(0.5f); wave2.setAmplitude(0); break;
    case 2:  wave1.setAmplitude(0); wave2.setAmplitude(0); break;
    default:  wave1.setAmplitude(0); wave2.setAmplitude(0); break;
  }
  
  iters++;
  if( (millis() - lastTime) > 1000 ) {
    lastTime = millis();
    println( iters );
    iters = 0;
  }
  
  /*
  } 
   */
}

void captureEvent(Capture c) {
  c.read();
}


