/**
 * Paper Reverbs 
 * @author: Indira Ardolic (@indirawrs) 
 * Using MultipleColorTracking by Jordi Tost (@jorditost)
 * @url: https://github.com/jorditost/ImageFiltering/tree/master/MultipleColorTracking
 */

import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;
import processing.sound.*;
SoundFile[] files;

SoundFile grass, uke; 
Reverb reverb;
Delay delay;
int x = 300;
int w = 10;
Capture video;
OpenCV opencv;
PImage src, colorFilteredImage;
ArrayList<Contour> contours;

// <1> Set the range of Hue values for our filter
//ArrayList<Integer> colors;
int maxColors = 4;
int[] hues;
int[] colors;
int rangeWidth = 10;

PImage[] outputs;

int colorToChange = -1;
int rangeLow = 20;
int rangeHigh = 35;

void setup() {
  background(w);
  video = new Capture(this, 640, 480);
  opencv = new OpenCV(this, video.width, video.height);
  contours = new ArrayList<Contour>();
  size(1712, 960);
  files = new SoundFile[4];
  for (int i = 0; i < files.length; i++) {
    files[i] = new SoundFile(this, (i+1) + ".aif");
  }

  //fullScreen();
  //AUDIO


  uke = new SoundFile(this, "uke.aif");

  grass = new SoundFile(this, "grass.aif");
  grass.loop();
  reverb = new Reverb(this);
  reverb.process(grass);

  uke.loop();
  delay = new Delay(this);
  delay.process(uke, 5);



  // Array for detection colors
  colors = new int[maxColors];
  hues = new int[maxColors];

  outputs = new PImage[maxColors];

  video.start();
}

void draw() {
  //textSize(random(30, 40));
  //text("wasn't it funny", 1230, 200);
  //text("when i had nothing to laugh about", 630, 200);
  //text("not really", 300, 200);



  delay.time(map(mouseY, 0, height, 0.001, 2.0));
  delay.feedback(map(mouseX, 0, width, 0.0, 0.8));
  println("mousex " + mouseX);
  println("mousey " + mouseY);

  if (video.available()) {
    video.read();
  }

  // <2> Load the new frame of our movie in to OpenCV
  opencv.loadImage(video);

  // Tell OpenCV to use color information
  opencv.useColor();
  src = opencv.getSnapshot();

  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);

  detectColors();

  // Show images //
  //pushStyle();
  //blendMode(LIGHTEST); //or darkest, try this out? like actually... go... and... rehearse... 
  //image(src, 0, 0);
  //popStyle(); 

  for (int i=0; i<outputs.length; i++) {
    if (outputs[i] != null) {
      image(outputs[i], width-src.width/4, i*src.height/4, src.width/4, src.height/4);

      noStroke();
      fill(colors[i]);
      rect(src.width, i*src.height/4, 30, src.height/4);
    }
  }

  // Print text if new color expected
  textSize(20);
  stroke(255);
  fill(255);

  if (colorToChange > -1) {
    //text("click to change color " + colorToChange, 10, 25);
  } else {
    //text("press key [1-4] to select color", 10, 25);
  }

  displayContoursBoundingBoxes();
  vidOverlap();
  // reverbTrash();
  colorHSVTrack();
}

//////////////////////
// Detect Functions
//////////////////////

void detectColors() {

  for (int i=0; i<hues.length; i++) {

    if (hues[i] <= 0) continue;

    opencv.loadImage(src);
    opencv.useColor(HSB);
    opencv.setGray(opencv.getH().clone());
    int hueToDetect = hues[i];
    //println("index " + i + " - hue to detect: " + hueToDetect);
    opencv.inRange(hueToDetect-rangeWidth/2, hueToDetect+rangeWidth/2);
    opencv.erode();
    outputs[i] = opencv.getSnapshot();
  }
  if (outputs[0] != null) {

    opencv.loadImage(outputs[0]);
    contours = opencv.findContours(true, true);
  }
}

void displayContoursBoundingBoxes() {

  for (int i=0; i<contours.size(); i++) {

    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();

    if (r.width < 20 || r.height < 20)
      continue;

    noStroke();
    noFill();
    //    strokeWeight(.2);
    rect(0, r.y, r.width, r.height);
  }
}

//////////////////////
// Keyboard / Mouse
//////////////////////

void mousePressed() {

  if (colorToChange > -1) {

    color c = get(mouseX, mouseY);
    println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));

    int hue = int(map(hue(c), 0, 255, 0, 180));

    colors[colorToChange-1] = c;
    hues[colorToChange-1] = hue;

    println("color index " + (colorToChange-1) + ", value: " + hue);
  }
}


void keyReleased() {
  colorToChange = -1;
}

void vidOverlap() {
  if (keyCode == UP) {
    pushStyle();
    blendMode(DARKEST);
    image(src, width/3, height/3, width/2, height/2);
    image(src, 600, 0, width/3, height/3);
    image(src, 600, 800, width/3, height/3);
    popStyle();
  } else if (keyCode == DOWN) {
    pushStyle();
    blendMode(LIGHTEST);
    image(src, width/3, height/3, width/2, height/2);
    image(src, 600, 0, width/3, height/3);
    image(src, width/3, 800, width/3, height/3);
    image(src, 1200, 700, width/3, height/3); //botom RIGHT
    blendMode(EXCLUSION);
    image(src, 1200, 0, width/3, height/3);

    popStyle();
  } else if (keyCode == LEFT) {
    pushStyle();
    blendMode(DIFFERENCE);
    image(src, 0, 300, width/3, height/3);
    image(src, width/3, height/3, width/2, height/2);
    blendMode(DARKEST);
    image(src, 0, 0, width/3, height/3);
    image(src, 600, 800, width/3, height/3);
    blendMode(EXCLUSION);
    image(src, 1200, 700, width/3, height/3); //botom right
    blendMode(REPLACE);
    image(src, 1200, 0, width/3, height/3); //top right

    // image(src, mouseX, mouseY, 200, 300);
    // println("left// blend mode exclusion");
    popStyle();
  } else if (keyCode == RIGHT) {
    pushStyle();
    blendMode(MULTIPLY);
    image(src, width/3, height/3, width/2, height/2);
    image(src, 0, 0, width/3, height/3);
    image(src, 1200, 0, width/3, height/3);
    blendMode(LIGHTEST);
    image(src, 0, 0, width/3, height/3);
    image(src, 600, 0, width/3, height/3);
    blendMode(DARKEST);
    image(src, 1200, 700, width/3, height/3); //botom right

    popStyle();
  } else {
    blendMode(REPLACE);
    image(src, 0, 0, width, height);
    image(src, 1200, 700, width/3, height/3);
    image(src, width/3, height/3, width/2, height/2);
    image(src, 0, 800, width/3, height/3); //botom left
  }
}
void keyPressed() {
  switch(key) {
  case 'w':
    files[0].loop(0.5, 2.0);
    break;
  case 'a':
    files[1].play(0.3, 0.4);
    break;
  case 's':
    files[2].play(0.5, 1.0);
    break;
  case 'd':
    files[3].play(0.5, 1.0);
    break;
  case 'f':
    files[4].play(0.5, 1.0);

    break;
  case 'g':
    files[0].play(0.2, 1.0);
    break;
  }
}

//////////////////////
//   AUDIO ~ BITS
//////////////////////
//making a physical circuit might be fun. experiment with makey makey after creating a canvas to project on


void reverbTrash() {
  // change the roomsize of the reverb
  reverb.room(map(mouseX, 0, width, 0, 1.0));
  // change the high frequency dampening parameter
  reverb.damp(map(mouseX, 0, width, 0, 1.0));    
  // change the wet/dry relation of the effect
  reverb.wet(map(mouseY, 0, height, 0, 1.0));
}

void colorHSVTrack() {
  // Read last captured frame
  if (video.available()) {
    video.read();
  }

  opencv.loadImage(video);
  opencv.useColor();
  src = opencv.getSnapshot();
  opencv.useColor(HSB);
  opencv.setGray(opencv.getH().clone());
  opencv.inRange(rangeLow, rangeHigh);
  colorFilteredImage = opencv.getSnapshot();
  contours = opencv.findContours(true, true);
  //Display background images
  //image(src, 0, 0);
  // image(colorFilteredImage, src.width, 0);
  //DRAW A HUGE RECTANGLE
  if (contours.size() > 0) {
    Contour biggestContour = contours.get(0);
    Rectangle r = biggestContour.getBoundingBox();
    pushStyle();
    noFill(); 
    strokeWeight(.2); 
    noStroke();
    rect(r.x, r.y, r.width, r.height);
    popStyle();
    // <12> Draw a dot in the middle of the bounding box, on the object.
    pushStyle();
    blendMode(EXCLUSION);
    noStroke(); 
    fill(205, 200, 0);
    ellipse(r.x + r.width/2, r.y + r.height/2, 1, 1);
    popStyle();

    // MAP AUDIO BASED ON TRACKED COLOR POSITION
    reverb.room(map(r.x, 0, width, 0, 1.0));
    // change the high frequency dampening parameter
    reverb.damp(map(r.y, 0, width, 0, 1.0));    
    // change the wet/dry relation of the effect
    reverb.wet(map(r.x, 0, height, 0, 1.0));
    println("r.x " + r.x + "|| r.y " + r.y);
  }
}