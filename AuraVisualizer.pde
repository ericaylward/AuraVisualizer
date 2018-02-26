/*
RESOURCES USED

Base for background: http://openprocessing.org/sketch/28089
Base for circles: https://processing.org/examples/softbody.html
Kinect PV2 Library: http://codigogenerativo.com/works/kinectpv2/
Beat Listener: http://code.compartmental.net/minim/beatdetect_method_iskick.html

*/

//FOR CIRCLES
import KinectPV2.KJoint;
import KinectPV2.*;

//music
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

//bg vars
float angle, spin;
int dotCnt, gap;
int halfW, halfH;

//circle obj creation
circleX[] myCircle;
circleX[] myCircle2;

//circle pulse vars
long lastTime = 0;
int count = 3;
int timer; 

//this is center distance for users 1 and 2
double centerDistance;

//left arm to right arm dist
float wingSpan;

//face vars
int st;
int type;

int smileState;
int smileFeature;

int faceArraySize;
int faceID;

//colors (COLOR ID - same for F and S in same for loop == good)
//Fcol is user 1, Scol is user 2

color Fcol = color(255, 255, 255);
color Scol = color(255, 255, 255);

int fcolCountH = 0;
int fcolCountS = 0;
int fcolCountA = 0;

int scolCountH = 0;
int scolCountS = 0;
int scolCountA = 0;

//triggers to initiate colour gradual change
boolean setColHappy = false; 
boolean setColHappy2 = false; 
boolean setColSad = false;
boolean setColSad2 = false;
boolean setColAngry = false; 
boolean setColAngry2 = false;

//proximity colour change --- this triggers when users are within 250 px of eachother + one is dominant
boolean u1ProximityDom = false;
boolean u2ProximityDom = false;

//eye bools for Angry emotion
boolean leftEyeClosed = false; 
boolean rightEyeClosed = false;

boolean leftEyeClosed2 = false; 
boolean rightEyeClosed2 = false;

//gradual colour change if iniators
boolean u1ColGradBool = false;
boolean u2ColGradBool = false;

int u1ColGradR = 255;
int u1ColGradG = 255;
int u1ColGradB = 255;

int u2ColGradR = 255;
int u2ColGradG = 255;
int u2ColGradB = 255;

int u1ColOrigR = 255;
int u1ColOrigG = 255;
int u1ColOrigB = 255;

int u2ColOrigR = 255;
int u2ColOrigG = 255;
int u2ColOrigB = 255;

//these vars act as target values for u1ColGrad/u2ColGrad when they change.
int idealSadR = 10;
int idealSadG = 55;
int idealSadB = 255;

int idealHappyR = 255;
int idealHappyG = 235;
int idealHappyB = 50;

int idealAngryR = 255;
int idealAngryG = 10;
int idealAngryB = 20;

//when u#ColGrad reaches the ideal colour value, these get triggered, then initiate music.
boolean u1HappyReached = false;
boolean u2HappyReached = false;

boolean u1SadReached = false;
boolean u2SadReached = false;

boolean u1AngryReached = false;
boolean u2AngryReached = false;

//count for head pos for circles
int headPosArrayCount;

//count for background and music
int userCount = 0;
boolean cohesive = false;

//music setup
Minim minim;

AudioPlayer sad;
AudioPlayer happy;
AudioPlayer angry;
AudioPlayer neutral;
AudioPlayer clap;

BeatDetect beat;
BeatListener bl;

//music gradual fade vars
float neutralFade = 0;
float neutralGain = 0;
boolean neutralFadeBool = false;
boolean neutralGainBool = false;

float sadGain = -100;
float sadFade = sadGain;
boolean sadFadeBool = false;
boolean sadGainBool = false;

float happyGain = -100;
float happyFade = happyGain;
boolean happyFadeBool = false;
boolean happyGainBool = false;

float angryGain = -100;
float angryFade = angryGain;
boolean angryFadeBool = false;
boolean angryGainBool = false;

//for music - whether or not both circles are same colour
boolean sameColour;

int counter = 0;

int userId;

//create the kinect object
KinectPV2 kinect;

//Face data array
FaceData [] faceData;

color col;
void setup()
{
  //background
  angle = 0.0; //main counter
  spin = PI/25; // the amount our counter changes per draw cycle
  halfW = width/2; // for translating to center of screen
  halfH = height/2; // for translating to center of screen
  dotCnt = 30; // number of dots accross and down in one quadrant
  gap = 25; //size of gap between dots
  
  timer = 0;

  fullScreen(P3D);
  //size(1280,800,P3D);

  lastTime = millis();

  myCircle = new circleX[count];
  myCircle2 = new circleX[count];

  for (int i = 0; i < count; i++)
  {
    myCircle[i] = new circleX();
    myCircle2[i] = new circleX();
  }

  //define kinect object
  kinect = new KinectPV2(this);

  kinect.enableSkeletonColorMap(true);

  //for face detection based on the color Img
  kinect.enableColorImg(true);

  //for face detection base on the infrared Img
  kinect.enableInfraredImg(true);

  //enable face detection
  kinect.enableFaceDetection(true);

  kinect.init();

  //music setup
  minim = new Minim(this);

  neutral = minim.loadFile("Neutral.mp3");
  neutral.play(); 
  
  angry = minim.loadFile("Angry.mp3");
  angry.play();
  angry.setGain(-100);
  
  sad = minim.loadFile("Sad.mp3");
  sad.play();
  sad.setGain(-100);

  happy = minim.loadFile("Happy.mp3");
  happy.play();
  happy.setGain(-100);
  
  //beat listener setup
  beat = new BeatDetect(neutral.bufferSize(), neutral.sampleRate()); 
  beat.setSensitivity(0);
  bl = new BeatListener(beat, neutral);

  frameRate(60);
}

void draw()
{
  
  if((myCircle[0].happyBool == true && myCircle2[0].happyBool == true) || (myCircle[0].sadBool == true && myCircle2[0].sadBool == true) || (myCircle[0].angryBool == true && myCircle2[0].angryBool == true))
  {
    cohesive = true;
  }
  
  else
  {
    cohesive = false;
  }
  
  timer++;
  
  centerDistance = Math.sqrt(Math.pow((myCircle2[0].centerX - myCircle[0].centerX), 2) + Math.pow((myCircle2[0].centerY - myCircle[0].centerY), 2));

  angle -= spin; //main counter
  background(0);
  pushMatrix();
    translate(halfW, halfH); //set origin to center of screen and out a little bit
    //rotateX(radians(angle*2)); //the "tilt" of the view is based on the mouse's up/down movement 49.8 1.5
    //rotateY(radians(angle*2)); //slowly spins around the origin just for fun
    float magn = abs(neutral.mix.level() * 800); //the quasi-magnitude is based on the mouse's horizontal position
    for (int z=0; z < dotCnt; z++) {
      for (int x=0; x < dotCnt; x++) {
        //we're only figuring 1/4 of the grid, so 0=origin and dotCnt=edge
        float dotX = x*gap; //expand x by the gap amount
        float dotZ = z*gap; //same for z
        float dotDist = sqrt(sq(x) + sq(z)); //get this dot's distance from the origin
        float dotY = sin(angle+dotDist)*magn/dotDist; //this is where the magic happens
        //dotHue = col; //hue is based simply on the dot's distance from the origin
        float dotSat = abs(neutral.mix.level()*1000); //saturation is maxed out
        float dotBrt = (dotY + 15)/(dotDist*0.10) ; // brightness is based on dots height, giving us the bright peaks/dark troughs, and dims with distance from origin
        
        strokeWeight(2.5);
        
        //changes background colour
        if(myCircle[0].dominant == true && myCircle2[0].dominant == false)
        {
          stroke(u1ColGradR, u1ColGradG, u1ColGradB, dotBrt * 5); //color
        }
        else if (myCircle2[0].dominant == true && myCircle[0].dominant == false)
        {
          stroke(u2ColGradR, u2ColGradG, u2ColGradB, dotBrt * 5); //color
        }
        
        else
        {
          stroke(255,255,255, dotBrt * 5);
        }
        
        //translate( 0.0, -height/2);
        // four dots - one for each quadrant
        point(dotX, dotZ);//, dotZ + 100);
        point(-dotX, -dotZ);//, dotZ +100);
        point(dotX, -dotZ);//, -dotZ+100);
        point(-dotX, dotZ);//, -dotZ+100););
      }
    }  
  popMatrix();
  
  //start face capture
  kinect.generateFaceData();

  //skeleton tracking
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();
  //face tracking
  ArrayList<FaceData> faceData = kinect.getFaceData();
  
  //count for background and music
  userCount = skeletonArray.size();
  
  //User 1 Switching Happy Bool
  if (fcolCountH == 0) {
    setColHappy = false;
  } else {
    fcolCountH--;
  }

  //User 1 Switching Sad Bool
  if (fcolCountS == 0) {
    setColSad = false;
  } else {
    fcolCountS--;
  }

  ////User 1 Switching Angry Bool
  if (fcolCountA == 0) {
   setColAngry = false;
  } else {
   fcolCountA--;
  }

  //User 2 Switching Happy Bool
  if (scolCountH == 0) {
    setColHappy2 = false;
  } else {
    scolCountH--;
  }

  //User 2 Switching Sad Bool
  if (scolCountS == 0) {
    setColSad2 = false;
  } else {
    scolCountS--;
  }

  //User 2 Switching Angry Bool
  if (scolCountA == 0) {
   setColAngry2 = false;
  } else {
   scolCountA--;
  }
  
  
  //setting dom and prox bool -- dominant in case of 1v1
  if(myCircle[0].dominant == true && centerDistance <= 250)
  {
    u1ProximityDom = true;
    u2ProximityDom = false;
  }
  
  else if((myCircle[0].dominant == true && centerDistance > 250) || myCircle[0].dominant == false)
  {
    u1ProximityDom = false;
  }
  
  
  if(myCircle2[0].dominant == true && centerDistance <= 250)
  {
    u1ProximityDom = false;
    u2ProximityDom = true;
  }
  
  else if((myCircle2[0].dominant == true && centerDistance > 250) || myCircle2[0].dominant == false)
  {
    u2ProximityDom = false;
  }
  

  //Reading all the bodies within capture zone
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);

    //If User 1
    if (i == 0) {
      //start / orig color
      Fcol = color(u1ColGradR, u1ColGradG, u1ColGradB);


      //User 1 Emotion Color Change
      if (setColHappy == true && setColSad == false && setColAngry == false)
      {           
        Fcol = color(u1ColGradR, u1ColGradG, u1ColGradB);

        //circle sets - these bools don't do much yet
        myCircle[0].happyBool = true;
        myCircle[1].happyBool = true;
        myCircle[2].happyBool = true;

        myCircle[0].sadBool = false;
        myCircle[1].sadBool = false;
        myCircle[2].sadBool = false;
        
        myCircle[0].angryBool = false;
        myCircle[1].angryBool = false;
        myCircle[2].angryBool = false;
      }

      if (setColSad == true && setColHappy == false && setColAngry == false)
      {
        Fcol = color(u1ColGradR, u1ColGradG, u1ColGradB);

        myCircle[0].happyBool = false;
        myCircle[1].happyBool = false;
        myCircle[2].happyBool = false;

        myCircle[0].sadBool = true;
        myCircle[1].sadBool = true;
        myCircle[2].sadBool = true;
        
        myCircle[0].angryBool = false;
        myCircle[1].angryBool = false;
        myCircle[2].angryBool = false;
      }

      if (setColAngry == true && setColHappy == false && setColSad == false)
      {
        Fcol = color(u1ColGradR, u1ColGradG, u1ColGradB);

        myCircle[0].happyBool = false;
        myCircle[1].happyBool = false;
        myCircle[2].happyBool = false;
        
        myCircle[0].sadBool = false;
        myCircle[1].sadBool = false;
        myCircle[2].sadBool = false;

        myCircle[0].angryBool = true;
        myCircle[1].angryBool = true;
        myCircle[2].angryBool = true;
      }
    }

    //If User 2
    if (i == 1) {
      //start / orig color
      Scol = color(u2ColGradR, u2ColGradG, u2ColGradB);

      //User 2 Emotion Color Change
      if (setColHappy2 == true && setColSad2 == false && setColAngry2 == false) {
        Scol = color(u2ColGradR, u2ColGradG, u2ColGradB);
        myCircle2[0].happyBool = true;
        myCircle2[1].happyBool = true;
        myCircle2[2].happyBool = true;

        myCircle2[0].sadBool = false;
        myCircle2[1].sadBool = false;
        myCircle2[2].sadBool = false;
        
        myCircle2[0].angryBool = false;
        myCircle2[1].angryBool = false;
        myCircle2[2].angryBool = false;

      }
      if (setColSad2 == true && setColHappy2 == false && setColAngry2 ==false) {
        Scol = color(u2ColGradR, u2ColGradG, u2ColGradB);
        myCircle2[0].happyBool = false;
        myCircle2[1].happyBool = false;
        myCircle2[2].happyBool = false;

        myCircle2[0].sadBool = true;
        myCircle2[1].sadBool = true;
        myCircle2[2].sadBool = true;
        
        myCircle2[0].angryBool = false;
        myCircle2[1].angryBool = false;
        myCircle2[2].angryBool = false;
      }

      if (setColAngry2 == true && setColHappy2 == false && setColSad2 == false)
      {
        Scol = color(u2ColGradR, u2ColGradG, u2ColGradB);

        myCircle2[0].happyBool = false;
        myCircle2[1].happyBool = false;
        myCircle2[2].happyBool = false;
        
        myCircle2[0].sadBool = false;
        myCircle2[1].sadBool = false;
        myCircle2[2].sadBool = false;

        myCircle2[0].angryBool = true;
        myCircle2[1].angryBool = true;
        myCircle2[2].angryBool = true;
      }
    }


    if (skeleton.isTracked()) {
      KJoint[] joints = skeleton.getJoints();

      if (faceData.size() == skeletonArray.size())
      {
        FaceData faceD = faceData.get(i);

        if (faceD.isFaceTracked()) {

          FaceFeatures [] faceFeatures = faceD.getFaceFeatures();

          //Feature detection of the user

          for (int j = 0; j < 8; j++) {
            st   = faceFeatures[j].getState();

            smileState = faceFeatures[0].getState();

            type = faceFeatures[j].getFeatureType();

            smileFeature = faceFeatures[0].getFeatureType();
            
            //if we're checking User 1...
            if(i == 0){
              //////checking user eyes
              /////left eye
              if ((type == 2) && (st == 1))
              {
                  leftEyeClosed = true;
              }
              
              else if ((type == 2) && (st == 0))
              {
                 leftEyeClosed = false;
              }
              
              ///right eye
              if ((type == 3) && (st == 1))
              {
                rightEyeClosed = true;
              }
              
              else if ((type == 3) && (st == 0))
              {
                 rightEyeClosed = false;
              }
            }
            
            //if we're checking User 2...
            if(i == 1){   
              //////checking user eyes
              /////left eye
              if ((type == 2) && (st == 1))
              {
                leftEyeClosed2 = true;
              }
              
              else if ((type == 2) && (st == 0))
              {
                 leftEyeClosed2 = false;
              }
              ///right eye
              if ((type == 3) && (st == 1))
              {
                rightEyeClosed2 = true;
              }
              
              else if ((type == 3) && (st == 0))
              {
                 rightEyeClosed2 = false;
              }
            }

            //Switching Bool Variables if User 1 changes emotion
            if ((type == 0)&& (st == 1))
            {
              if(u2ProximityDom != true)
              {
                //setColHappy = true;
                if (i == 0 && leftEyeClosed == false && rightEyeClosed == false) {
                  fcolCountH = 10;
                  setColHappy = true;
                }
              }
              
              if(u1ProximityDom != true)
              {
                if (i == 1 && leftEyeClosed2 == false && rightEyeClosed2 == false) {
                  scolCountH = 10;
                  setColHappy2 = true;
                }
              }
            }
            
            //Switching Bool Variables if User 2 changes emotion
            else if ((type == 0)&& (st == 0)) {
              
              if(u2ProximityDom != true)
              {
                if (i == 0 && leftEyeClosed == false && rightEyeClosed == false) {
                  fcolCountS = 10;
                  setColSad = true;
                }
              }
              
              if(u1ProximityDom != true){
                if (i == 1 && leftEyeClosed2 == false && rightEyeClosed2 == false) {
                  scolCountS = 10;
                  setColSad2 = true;
                }
              }
            }

            //'unknown' handler (when state isn't 1 or 0)
            else if ((type == 0)&& (st == -1)) {
              //first user
              
              if(u2ProximityDom != true)
              {
                if (i == 0)
                {
                  fcolCountH = 10;
  
                  if (setColHappy == true)
                  {
                    setColHappy = true;
                    setColSad = false;
                  } else if (setColSad == true )
                  {
                    setColSad = true;
                    setColHappy = false;
                  }
                }
              }
              
              //second user
              if(u1ProximityDom != true){
                if (i == 1) {
                  scolCountH = 10;
    
                  if (setColHappy2 == true)
                  {
                    setColHappy2 = true;
                    setColSad2 = false;
                  } else if (setColSad2 == true )
                  {
                    setColSad2 = true;
                    setColHappy2 = false;
                  }
                }
              }
            }        
            
            //Anger switch for user 1
            if ((type == 6) && (st == 1)) {
              
              if(u2ProximityDom != true){
                if (i == 0 && leftEyeClosed == true && rightEyeClosed == true) {
                  
                  fcolCountA = 10;
                  
                  if (setColHappy == true)
                  {
                    setColHappy = false;
                    setColSad = false;
                    setColAngry = true;
                  } else if (setColSad == true )
                  {
                    setColSad = false;
                    setColHappy = false;
                    setColAngry = true;
                  }
                }
              }
              
              //Anger switch for user 2
              if(u1ProximityDom != true){
                if (i == 1 && leftEyeClosed2 == true && rightEyeClosed2 == true) {
                  //setColAngry = true;
                  scolCountA = 10;
                  
                  if (setColHappy2 == true)
                  {
                    setColHappy2 = false;
                    setColSad2 = false;
                    setColAngry2 = true;
                  } else if (setColSad2 == true )
                  {
                    setColSad2 = false;
                    setColHappy2 = false;
                    setColAngry2 = true;
                  }
                }
              }
            }
          }
        }
      }
      
      //splits head positions and colors
      dataHandler(joints, KinectPV2.JointType_Head, i, skeletonArray.size());
    }
  }

  ////////////////////////////////////
  //user 1 happy gradual change xxxx
  if (myCircle[0].happyBool == true && myCircle[1].happyBool == true && myCircle[2].happyBool == true)
  {
    u1SadReached = false;
    u1AngryReached = false;
    
    u1ColGradBool = true;

    myCircle[0].sadBool = false;
    myCircle[1].sadBool = false;
    myCircle[2].sadBool = false;

    myCircle[0].angryBool = false;
    myCircle[1].angryBool = false;
    myCircle[2].angryBool = false;


    if (u1ColGradBool == true)
    {
      if (u1ColGradR < idealHappyR)
      {
        u1ColGradR += 5.0;
      }
      
      else if(u1ColGradR > idealHappyR)
      {
        u1ColGradR -= 5.0;
      }

      if (u1ColGradG > idealHappyG || u1ColGradG == u1ColOrigG)
      {
        u1ColGradG -= 5.0;
      }

      //handler for sad to happy transition
      else if (u1ColGradG < idealHappyG)
      {
        u1ColGradG += 5.0;
      }

      if (u1ColGradB > idealHappyB || u1ColGradB == u1ColOrigB)
      {
        u1ColGradB -= 5.0;
      }
      
      else if (u1ColGradB < idealHappyB)
      {
        u1ColGradB +=5.0;
      }

      if (u1ColGradR == idealHappyR && u1ColGradG == idealHappyG && u1ColGradB == idealHappyB)
      {
        u1ColGradBool = false;

        u1SadReached = false;
        u1AngryReached = false;
        u1HappyReached = true;
      }
    }
  }


  //user 1 sad gradual change xxxx
  if (myCircle[0].sadBool == true && myCircle[1].sadBool == true && myCircle[2].sadBool == true)
  {
    u1HappyReached = false;
    u1AngryReached = false;
    u1ColGradBool = true;

    myCircle[0].happyBool = false;
    myCircle[1].happyBool = false;
    myCircle[2].happyBool = false;

    myCircle[0].angryBool = false;
    myCircle[1].angryBool = false;
    myCircle[2].angryBool = false;

    //neutral to sad trans
    if (u1ColGradBool == true)
    {
      if (u1ColGradR > idealSadR || u1ColGradR == u1ColOrigR)
      {
        u1ColGradR -= 5.0;
      }
      
      else if (u1ColGradR < idealSadR)
      {
        u1ColGradR += 5.0;
      }

      if (u1ColGradG > idealSadG || u1ColGradG == u1ColOrigG)
      {
        u1ColGradG -= 5.0;
      }
      
      else if (u1ColGradG < idealSadG)
      {
        u1ColGradG += 5.0;
      }
      
      if (u1ColGradB < idealSadB) //note - doesnt have or because it needs max blue
      {
        u1ColGradB += 5.0;
      }
      
      else if (u1ColGradB > idealSadB)
      {
        u1ColGradB -= 5.0;
      }

      if (u1ColGradR == idealSadR && u1ColGradG == idealSadG && u1ColGradB == idealSadB)
      {
        u1ColGradBool = false;

        u1SadReached = true;
        u1AngryReached = false;
        u1HappyReached = false;
      }
    }
  }

  //user 1 Angry gradual change xxxx
  if (myCircle[0].angryBool == true && myCircle[1].angryBool == true && myCircle[2].angryBool == true)
  {
    u1HappyReached = false;
    u1SadReached = false;
    u1ColGradBool = true;

    myCircle[0].happyBool = false;
    myCircle[1].happyBool = false;
    myCircle[2].happyBool = false; 
    
    myCircle[0].sadBool = false;
    myCircle[1].sadBool = false;
    myCircle[2].sadBool = false; 

    if (u1ColGradBool == true)
    {
      if (u1ColGradR < idealAngryR)
      {
        u1ColGradR += 5.0;
      }
      
      else if(u1ColGradR > idealAngryR)
      {
        u1ColGradR -= 5.0;
      }

      if (u1ColGradG > idealAngryG || u1ColGradG == u1ColOrigG)
      {
        u1ColGradG -= 5.0;
      }
      
      else if (u1ColGradG < idealAngryG)
      {
        u1ColGradG += 5.0;
      }

      //handler for sad to Angry transition
      else if (u1ColGradG < idealAngryG)
      {
        u1ColGradG += 5.0;
      }

      if (u1ColGradB > idealAngryB || u1ColGradB == u1ColOrigB)
      {
        u1ColGradB -= 5.0;
      }

      if (u1ColGradR == idealAngryR && u1ColGradG == idealAngryG && u1ColGradB == idealAngryB)
      {
        u1ColGradBool = false;

        u1HappyReached = false;
        u1SadReached = false;
        u1AngryReached = true;
      }
    }
  }
  
  /////////////////////////////
  //user 2 happy gradual change
  if (myCircle2[0].happyBool == true && myCircle2[1].happyBool == true && myCircle2[2].happyBool == true)
  {
    u2SadReached = false;
    u2AngryReached = false;
    u2ColGradBool = true;

    myCircle2[0].sadBool = false;
    myCircle2[1].sadBool = false;
    myCircle2[2].sadBool = false;
    
    myCircle2[0].angryBool = false;
    myCircle2[1].angryBool = false;
    myCircle2[2].angryBool = false;


    if (u2ColGradBool == true)
    {
      if (u2ColGradR < idealHappyR)
      {
        u2ColGradR += 5.0;
      }
      
      else if(u2ColGradR > idealHappyR)
      {
        u2ColGradR -= 5.0;
      }

      if (u2ColGradG > idealHappyG || u2ColGradG == u2ColOrigG)
      {
        u2ColGradG -= 5.0;
      }
      
      else if(u2ColGradG < idealHappyG)
      {
        u2ColGradG += 5.0;
      }

      //handler for sad to happy transition
      else if (u2ColGradG < idealHappyG)
      {
        u2ColGradG += 5.0;
      }

      if (u2ColGradB > idealHappyB || u2ColGradB == u2ColOrigB)
      {
        u2ColGradB -= 5.0;
      }

      if (u2ColGradR == idealHappyR && u2ColGradG == idealHappyG && u2ColGradB == idealHappyB)
      {
        u2ColGradBool = false;

        u2SadReached = false;
        u2AngryReached = false;
        u2HappyReached = true;
      }
    }
  }


  //user 2 sad gradual change xxxx
  if (myCircle2[0].sadBool == true && myCircle2[1].sadBool == true && myCircle2[2].sadBool == true)
  {
    u2HappyReached = false;
    u2AngryReached = false;
    u2ColGradBool = true;

    myCircle2[0].happyBool = false;
    myCircle2[1].happyBool = false;
    myCircle2[2].happyBool = false;
    
    myCircle2[0].angryBool = false;
    myCircle2[1].angryBool = false;
    myCircle2[2].angryBool = false;

    //neutral to sad trans
    if (u2ColGradBool == true)
    {
      if (u2ColGradR > idealSadR || u2ColGradR == u2ColOrigR)
      {
        u2ColGradR -= 5.0;
      }
      
      else if (u2ColGradR < idealSadR)
      {
        u2ColGradR += 5.0;
      }

      if (u2ColGradG > idealSadG || u2ColGradG == u2ColOrigG)
      {
        u2ColGradG -= 5.0;
      }
      
      else if(u2ColGradG < idealSadG)
      {
        u2ColGradG += 5.0;
      }

      if (u2ColGradB < idealSadB) //note - doesnt have or because it needs max blue
      {
        u2ColGradB += 5.0;
      }
      
      else if(u2ColGradB > idealSadB)
      {
        u2ColGradB += 5.0;
      }

      if (u2ColGradR == idealSadR && u2ColGradG == idealSadG && u2ColGradB == idealSadB)
      {
        u2ColGradBool = false;

        u2SadReached = true;
        u2HappyReached = false;
        u2AngryReached = false;
      }
    }
  }
  
   ////user 2 Angry gradual change xxxx
  if (myCircle2[0].angryBool == true && myCircle2[1].angryBool == true && myCircle2[2].angryBool == true)
  {
   u2HappyReached = false;
   u2SadReached = false;
   u2ColGradBool = true;

   myCircle2[0].happyBool = false;
   myCircle2[1].happyBool = false;
   myCircle2[2].happyBool = false;
   
   myCircle2[0].sadBool = false;
   myCircle2[1].sadBool = false;
   myCircle2[2].sadBool = false;

   if (u2ColGradBool == true)
   {
     if (u2ColGradR < idealAngryR)
     {
       u2ColGradR += 5.0;
     }
     
     else if (u2ColGradR > idealAngryR)
     {
       u2ColGradR -= 5.0;
     }

     if (u2ColGradG > idealAngryG || u2ColGradG == u2ColOrigG)
     {
       u2ColGradG -= 5.0;
     }

     else if (u2ColGradG < idealAngryG)
     {
       u2ColGradG += 5.0;
     }

     if (u2ColGradB > idealAngryB || u2ColGradB == u2ColOrigB)
     {
       u2ColGradB -= 5.0;
     }
     
     else if(u2ColGradB < idealAngryB)
     {
       u2ColGradB += 5.0;
     }

     if (u2ColGradR == idealAngryR && u2ColGradG == idealAngryG && u2ColGradB == idealAngryB)
     {
       u2ColGradBool = false;

       u2HappyReached = false;
       u2SadReached = false;
       u2AngryReached = true;
     }
   }
  }
  

  //dominance check
  if (skeletonArray.size() == 2)
  {
    if (myCircle[0].wingSpan > myCircle2[0].wingSpan)
    {
      myCircle[0].dominant = true;
      myCircle2[0].dominant = false;
    } else if (myCircle2[0].wingSpan > myCircle[0].wingSpan)
    {
      myCircle2[0].dominant = true;
      myCircle[0].dominant = false;
    }
  }
  
  //User 1 emotion influence based on proximity + dominance
  if(u1ProximityDom == true && u2ProximityDom == false)
  {
    if(myCircle[0].angryBool == true && myCircle[0].sadBool == false && myCircle[0].happyBool == false)
    {
      setColHappy2 = false; 
      setColSad2 = false;
      setColAngry2 = true;
      
      myCircle2[0].happyBool = false;
      myCircle2[1].happyBool = false;
      myCircle2[2].happyBool = false;
      
      myCircle2[0].sadBool = false;
      myCircle2[1].sadBool = false;
      myCircle2[2].sadBool = false;
      
      myCircle2[0].angryBool = true;
      myCircle2[1].angryBool = true;
      myCircle2[2].angryBool = true;
      
      u2HappyReached = false;
      u2SadReached = false;
    }
    else if(myCircle[0].angryBool == false && myCircle[0].sadBool == true && myCircle[0].happyBool == false)
    {
      setColHappy2 = false; 
      setColSad2 = true;
      setColAngry2 = false;
      
      myCircle2[0].happyBool = false;
      myCircle2[1].happyBool = false;
      myCircle2[2].happyBool = false;
      
      myCircle2[0].sadBool = true;
      myCircle2[1].sadBool = true;
      myCircle2[2].sadBool = true;
      
      myCircle2[0].angryBool = false;
      myCircle2[1].angryBool = false;
      myCircle2[2].angryBool = false;
      
      u2HappyReached = false;
      u2AngryReached = false;
    }
    else if(myCircle[0].angryBool == false && myCircle[0].sadBool == false && myCircle[0].happyBool == true)
    {
      setColHappy2 = true; 
      setColSad2 = false;
      setColAngry2 = false;
      
      myCircle2[0].happyBool = true;
      myCircle2[1].happyBool = true;
      myCircle2[2].happyBool = true;
      
      myCircle2[0].sadBool = false;
      myCircle2[1].sadBool = false;
      myCircle2[2].sadBool = false;
      
      myCircle2[0].angryBool = false;
      myCircle2[1].angryBool = false;
      myCircle2[2].angryBool = false;
      
      u2SadReached = false;
      u2AngryReached = false;
    }
  }
  
  //User 2 emotion influence based on proximity + dominance
  if(u2ProximityDom == true && u1ProximityDom == false)
  {
    if(myCircle2[0].angryBool == true && myCircle2[0].sadBool == false && myCircle2[0].happyBool == false)
    {
      setColHappy = false; 
      setColSad = false;
      setColAngry = true;
      
      myCircle[0].happyBool = false;
      myCircle[1].happyBool = false;
      myCircle[2].happyBool = false;
      
      myCircle[0].sadBool = false;
      myCircle[1].sadBool = false;
      myCircle[2].sadBool = false;
      
      myCircle[0].angryBool = true;
      myCircle[1].angryBool = true;
      myCircle[2].angryBool = true;
      
      u1HappyReached = false;
      u1SadReached = false;
    }
    else if(myCircle2[0].angryBool == false && myCircle2[0].sadBool == true && myCircle2[0].happyBool == false)
    {
      setColHappy = false; 
      setColSad = true;
      setColAngry = false;
      
      myCircle[0].happyBool = false;
      myCircle[1].happyBool = false;
      myCircle[2].happyBool = false;
      
      myCircle[0].sadBool = true;
      myCircle[1].sadBool = true;
      myCircle[2].sadBool = true;
      
      myCircle[0].angryBool = false;
      myCircle[1].angryBool = false;
      myCircle[2].angryBool = false;
      
      u1HappyReached = false;
      u1AngryReached = false;
    }
    else if(myCircle2[0].angryBool == false && myCircle2[0].sadBool == false && myCircle2[0].happyBool == true)
    {
      setColHappy = true; 
      setColSad = false;
      setColAngry = false;
      
      myCircle[0].happyBool = true;
      myCircle[1].happyBool = true;
      myCircle[2].happyBool = true;
      
      myCircle[0].sadBool = false;
      myCircle[1].sadBool = false;
      myCircle[2].sadBool = false;
      
      myCircle[0].angryBool = false;
      myCircle[1].angryBool = false;
      myCircle[2].angryBool = false;
      
      u1SadReached = false;
      u1AngryReached = false;
    }
  }
  

  //this loop speeds up how fast the circles pulse
  for (int i =0; i <2; i++)
  {
    myCircle2[1].drawShape();
    myCircle2[2].drawShape();
    myCircle[1].drawShape();
    myCircle[2].drawShape();
  }

    //call for music
    musicPlayer(skeletonArray.size());
}

//handles data before split
void dataHandler(KJoint[] joints, int jointType, int userID, int skeletonArraySize) {
  float headX = joints[jointType].getX();
  float headY = joints[jointType].getY();
  float headZ = joints[jointType].getZ();

  //getting the position of all left hands
  float leftHandX = joints[KinectPV2.JointType_HandLeft].getX();   
  float leftHandY = joints[KinectPV2.JointType_HandLeft].getY(); 

  //getting the position of all right hands
  float rightHandX = joints[KinectPV2.JointType_HandRight].getX();   
  float rightHandY = joints[KinectPV2.JointType_HandRight].getY(); 


  tint(0, 0, 0, 255);
  //FOR CIRCLES
  if (skeletonArraySize == 1) {
    myCircle[0].go = true;
  }

  if (skeletonArraySize == 2)
  {
    myCircle2[0].go = true;
  }
  /////////
  if (myCircle[0].RoC <= 0.666) {
    myCircle[1].go = true;
  }

  if (myCircle[0].RoC <= 1.333 ) {
    myCircle[2].go = true;
  }
  ////////////
  if (myCircle2[0].RoC <= 0.666) {
    myCircle2[1].go = true;
  }

  if (myCircle2[0].RoC <= 1.333 ) {
    myCircle2[2].go = true;
  }

  //calling seperate for each circle in object (3 circles) - for loop doesn't work here
  seperate(headX, headY, headZ, userID, 0, rightHandX, rightHandY, leftHandX, leftHandY, Fcol, Scol);
  seperate(headX, headY, headZ, userID, 1, rightHandX, rightHandY, leftHandX, leftHandY, Fcol, Scol);
  seperate(headX, headY, headZ, userID, 2, rightHandX, rightHandY, leftHandX, leftHandY, Fcol, Scol);

  //physics collisions
  for (int x = 0; x < count; x++)
  {
    //Circle 2 affects circle 1
    if (myCircle[0].dominant == false && myCircle2[0].dominant == true)
    {
      //Right Side Collision
      if (myCircle[x].nodeX[7] < myCircle2[x].nodeX[5] + 20 && myCircle[x].nodeX[7] > myCircle2[x].nodeX[7] && myCircle[x].nodeY[7] < myCircle2[x].nodeY[5]+50 && myCircle[x].nodeY[7] > myCircle2[x].nodeY[7]-50)
      {
        myCircle[x].nodeX[7] = myCircle2[x].nodeX[5] + 20;
        myCircle[x].nodeY[7] = myCircle2[x].nodeY[5];
      }

      if (myCircle[x].nodeX[9] < myCircle2[x].nodeX[3] + 20 && myCircle[x].nodeX[9] > myCircle2[x].nodeX[9] && myCircle[x].nodeY[9] < myCircle2[x].nodeY[3]+50 && myCircle[x].nodeY[9] > myCircle2[x].nodeY[9]-50)
      {
        myCircle[x].nodeX[9] = myCircle2[x].nodeX[3] + 20;
        myCircle[x].nodeY[9] = myCircle2[x].nodeY[3];
      }

      if (myCircle[x].nodeX[8] < myCircle2[x].nodeX[4] + 20 && myCircle[x].nodeX[8] > myCircle2[x].nodeX[8] && myCircle[x].nodeY[8] < myCircle2[x].nodeY[4]+50 && myCircle[x].nodeY[8] > myCircle2[x].nodeY[4]-50)
      {
        myCircle[x].nodeX[8] = myCircle2[x].nodeX[4] + 20;
        myCircle[x].nodeY[8] = myCircle2[x].nodeY[4];
      }

      if (myCircle[x].nodeX[10] < myCircle2[x].nodeX[2] + 20 && myCircle[x].nodeX[10] > myCircle2[x].nodeX[10] && myCircle[x].nodeY[10] < myCircle2[x].nodeY[2]+50 && myCircle[x].nodeY[10] > myCircle2[x].nodeY[2]-50)
      {
        myCircle[x].nodeX[10] = myCircle2[x].nodeX[2] + 20;
        myCircle[x].nodeY[10] = myCircle2[x].nodeY[2];
      }

      if (myCircle[x].nodeX[11] < myCircle2[x].nodeX[1] + 20 && myCircle[x].nodeX[11] > myCircle2[x].nodeX[11] && myCircle[x].nodeY[11] < myCircle2[x].nodeY[1]+50 && myCircle[x].nodeY[11] > myCircle2[x].nodeY[1]-50)
      {
        myCircle[x].nodeX[11] = myCircle2[x].nodeX[1] + 20;
        myCircle[x].nodeY[11] = myCircle2[x].nodeY[1];
      }


      //Bottom Collision
      if (myCircle[x].nodeX[0] < myCircle2[x].nodeX[6]+50 && myCircle[x].nodeX[0] > myCircle2[x].nodeX[6]-50 && myCircle[x].nodeY[0] > myCircle2[x].nodeY[0] && myCircle[x].nodeY[0] < myCircle2[x].nodeY[6] + 20)
      {
        myCircle[x].nodeX[0] = myCircle2[x].nodeX[6];
        myCircle[x].nodeY[0] = myCircle2[x].nodeY[6] + 20;
      }

      if (myCircle[x].nodeX[11] < myCircle2[x].nodeX[7]+50 && myCircle[x].nodeX[11] > myCircle2[x].nodeX[7]-50 && myCircle[x].nodeY[11] > myCircle2[x].nodeY[11] && myCircle[x].nodeY[11] < myCircle2[x].nodeY[7] + 20)
      {
        myCircle[x].nodeX[11] = myCircle2[x].nodeX[7];
        myCircle[x].nodeY[11] = myCircle2[x].nodeY[7] + 20;
      }

      if (myCircle[x].nodeX[1] < myCircle2[x].nodeX[5]+50 && myCircle[x].nodeX[1] > myCircle2[x].nodeX[5]-50 && myCircle[x].nodeY[1] > myCircle2[x].nodeY[1] && myCircle[x].nodeY[1] < myCircle2[x].nodeY[5] + 20)
      {
        myCircle[x].nodeX[1] = myCircle2[x].nodeX[5];
        myCircle[x].nodeY[1] = myCircle2[x].nodeY[5] + 20;
      }

      if (myCircle[x].nodeX[10] < myCircle2[x].nodeX[8]+50 && myCircle[x].nodeX[10] > myCircle2[x].nodeX[8]-50 && myCircle[x].nodeY[10] > myCircle2[x].nodeY[10] && myCircle[x].nodeY[10] < myCircle2[x].nodeY[8] + 20)
      {
        myCircle[x].nodeX[10] = myCircle2[x].nodeX[8];
        myCircle[x].nodeY[10] = myCircle2[x].nodeY[8] + 20;
      }

      if (myCircle[x].nodeX[2] < myCircle2[x].nodeX[4]+50 && myCircle[x].nodeX[2] > myCircle2[x].nodeX[4]-50 && myCircle[x].nodeY[2] > myCircle2[x].nodeY[2] && myCircle[x].nodeY[2] < myCircle2[x].nodeY[4] + 20)
      {
        myCircle[x].nodeX[2] = myCircle2[x].nodeX[4];
        myCircle[x].nodeY[2] = myCircle2[x].nodeY[4] + 20;
      }

      //Top Collision
      if (myCircle[x].nodeX[6] < myCircle2[x].nodeX[0]+50 && myCircle[x].nodeX[6] > myCircle2[x].nodeX[0]-50 && myCircle[x].nodeY[6] < myCircle2[x].nodeY[6] && myCircle[x].nodeY[6] > myCircle2[x].nodeY[0] - 20)
      {
        myCircle[x].nodeX[6] = myCircle2[x].nodeX[0];
        myCircle[x].nodeY[6] = myCircle2[x].nodeY[0] - 20;
      }

      if (myCircle[x].nodeX[7] < myCircle2[x].nodeX[11]+50 && myCircle[x].nodeX[7] > myCircle2[x].nodeX[11]-50 && myCircle[x].nodeY[7] < myCircle2[x].nodeY[7] && myCircle[x].nodeY[7] > myCircle2[x].nodeY[11] - 20)
      {
        myCircle[x].nodeX[7] = myCircle2[x].nodeX[11];
        myCircle[x].nodeY[7] = myCircle2[x].nodeY[11] - 20;
      }

      if (myCircle[x].nodeX[5] < myCircle2[x].nodeX[1]+50 && myCircle[x].nodeX[5] > myCircle2[x].nodeX[1]-50 && myCircle[x].nodeY[5] < myCircle2[x].nodeY[5] && myCircle[x].nodeY[5] > myCircle2[x].nodeY[1] - 20)
      {
        myCircle[x].nodeX[5] = myCircle2[x].nodeX[1];
        myCircle[x].nodeY[5] = myCircle2[x].nodeY[1] - 20;
      }

      if (myCircle[x].nodeX[4] < myCircle2[x].nodeX[2]+50 && myCircle[x].nodeX[4] > myCircle2[x].nodeX[2]-50 && myCircle[x].nodeY[4] < myCircle2[x].nodeY[4] && myCircle[x].nodeY[4] > myCircle2[x].nodeY[2] - 20)
      {
        myCircle[x].nodeX[4] = myCircle2[x].nodeX[2];
        myCircle[x].nodeY[4] = myCircle2[x].nodeY[2] - 20;
      }

      if (myCircle[x].nodeX[8] < myCircle2[x].nodeX[10]+50 && myCircle[x].nodeX[8] > myCircle2[x].nodeX[10]-50 && myCircle[x].nodeY[8] < myCircle2[x].nodeY[8] && myCircle[x].nodeY[8] > myCircle2[x].nodeY[10] - 20)
      {
        myCircle[x].nodeX[8] = myCircle2[x].nodeX[10];
        myCircle[x].nodeY[8] = myCircle2[x].nodeY[10] - 20;
      }


      //Left Side Collision
      if (myCircle[x].nodeX[3] > myCircle2[x].nodeX[9] - 20 && myCircle[x].nodeX[3] < myCircle2[x].nodeX[3] && myCircle[x].nodeY[3] < myCircle2[x].nodeY[9]+50 && myCircle[x].nodeY[3] > myCircle2[x].nodeY[9]-50)
      {
        myCircle[x].nodeX[3] = myCircle2[x].nodeX[9] - 20;
        myCircle[x].nodeY[3] = myCircle2[x].nodeY[9];
      }

      if (myCircle[x].nodeX[4] > myCircle2[x].nodeX[8] - 20 && myCircle[x].nodeX[4] < myCircle2[x].nodeX[4] && myCircle[x].nodeY[4] < myCircle2[x].nodeY[8]+50 && myCircle[x].nodeY[4] > myCircle2[x].nodeY[8]-50)
      {
        myCircle[x].nodeX[4] = myCircle2[x].nodeX[8] - 20;
        myCircle[x].nodeY[4] = myCircle2[x].nodeY[8];
      }

      if (myCircle[x].nodeX[2] > myCircle2[x].nodeX[10] - 20 && myCircle[x].nodeX[2] < myCircle2[x].nodeX[2] && myCircle[x].nodeY[2] < myCircle2[x].nodeY[10]+50 && myCircle[x].nodeY[2] > myCircle2[x].nodeY[10]-50)
      {
        myCircle[x].nodeX[2] = myCircle2[x].nodeX[10] - 20;
        myCircle[x].nodeY[2] = myCircle2[x].nodeY[10];
      }

      if (myCircle[x].nodeX[1] > myCircle2[x].nodeX[11] - 20 && myCircle[x].nodeX[1] < myCircle2[x].nodeX[1] && myCircle[x].nodeY[1] < myCircle2[x].nodeY[11]+50 && myCircle[x].nodeY[1] > myCircle2[x].nodeY[11]-50)
      {
        myCircle[x].nodeX[1] = myCircle2[x].nodeX[11] - 20;
        myCircle[x].nodeY[1] = myCircle2[x].nodeY[11];
      }

      if (myCircle[x].nodeX[5] > myCircle2[x].nodeX[7] - 20 && myCircle[x].nodeX[5] < myCircle2[x].nodeX[5] && myCircle[x].nodeY[5] < myCircle2[x].nodeY[7]+50 && myCircle[x].nodeY[5] > myCircle2[x].nodeY[7]-50)
      {
        myCircle[x].nodeX[5] = myCircle2[x].nodeX[7] - 20;
        myCircle[x].nodeY[5] = myCircle2[x].nodeY[7];
      }


      //Bottom Right Diagonal
      if (myCircle[x].nodeX[11] < myCircle2[x].nodeX[4] + 20 && myCircle[x].nodeY[11] < myCircle2[x].nodeY[4] + 20 && myCircle[x].nodeX[11] > myCircle2[x].nodeX[7] && myCircle[x].nodeY[11] > myCircle2[x].nodeY[2])
      {
        myCircle[x].nodeX[11] = myCircle2[x].nodeX[4] + 20;
        myCircle[x].nodeY[11] = myCircle2[x].nodeY[4] + 20;
      }

      if (myCircle[x].nodeX[10] < myCircle2[x].nodeX[5] + 20 && myCircle[x].nodeY[10] < myCircle2[x].nodeY[5] + 20 && myCircle[x].nodeX[10] > myCircle2[x].nodeX[7] && myCircle[x].nodeY[10] > myCircle2[x].nodeY[2])
      {
        myCircle[x].nodeX[10] = myCircle2[x].nodeX[5] + 20;
        myCircle[x].nodeY[10] = myCircle2[x].nodeY[5] + 20;
      }

      if (myCircle[x].nodeX[9] < myCircle2[x].nodeX[6] + 20 && myCircle[x].nodeY[9] < myCircle2[x].nodeY[6] + 20 && myCircle[x].nodeX[9] > myCircle2[x].nodeX[7] && myCircle[x].nodeY[9] > myCircle2[x].nodeY[2])
      {
        myCircle[x].nodeX[9] = myCircle2[x].nodeX[6] + 20;
        myCircle[x].nodeY[9] = myCircle2[x].nodeY[6] + 20;
      }

      if (myCircle[x].nodeX[0] < myCircle2[x].nodeX[3] + 20 && myCircle[x].nodeY[0] < myCircle2[x].nodeY[3] + 20 && myCircle[x].nodeX[0] > myCircle2[x].nodeX[7] && myCircle[x].nodeY[0] > myCircle2[x].nodeY[2])
      {
        myCircle[x].nodeX[0] = myCircle2[x].nodeX[3] + 20;
        myCircle[x].nodeY[0] = myCircle2[x].nodeY[3] + 20;
      }


      //Bottom Left Diagonal
      if (myCircle[x].nodeX[2] > myCircle2[x].nodeX[7] - 20 && myCircle[x].nodeY[2] < myCircle2[x].nodeY[7] + 20 && myCircle[x].nodeX[2] < myCircle2[x].nodeX[5] && myCircle[x].nodeY[2] > myCircle2[x].nodeY[10])
      {
        myCircle[x].nodeX[2] = myCircle2[x].nodeX[7] - 20;
        myCircle[x].nodeY[2] = myCircle2[x].nodeY[7] + 20;
      }

      if (myCircle[x].nodeX[1] > myCircle2[x].nodeX[8] - 20 && myCircle[x].nodeY[1] < myCircle2[x].nodeY[8] + 20 && myCircle[x].nodeX[1] < myCircle2[x].nodeX[5] && myCircle[x].nodeY[1] > myCircle2[x].nodeY[10])
      {
        myCircle[x].nodeX[1] = myCircle2[x].nodeX[8] - 20;
        myCircle[x].nodeY[1] = myCircle2[x].nodeY[8] + 20;
      }

      if (myCircle[x].nodeX[3] > myCircle2[x].nodeX[6] - 20 && myCircle[x].nodeY[3] < myCircle2[x].nodeY[6] + 20 && myCircle[x].nodeX[3] < myCircle2[x].nodeX[5] && myCircle[x].nodeY[3] > myCircle2[x].nodeY[10])
      {
        myCircle[x].nodeX[3] = myCircle2[x].nodeX[6] - 20;
        myCircle[x].nodeY[3] = myCircle2[x].nodeY[6] + 20;
      }

      if (myCircle[x].nodeX[0] > myCircle2[x].nodeX[9] - 20 && myCircle[x].nodeY[0] < myCircle2[x].nodeY[9] + 20 && myCircle[x].nodeX[0] < myCircle2[x].nodeX[5] && myCircle[x].nodeY[0] > myCircle2[x].nodeY[10])
      {
        myCircle[x].nodeX[0] = myCircle2[x].nodeX[9] - 20;
        myCircle[x].nodeY[0] = myCircle2[x].nodeY[9] + 20;
      }


      //Top Left Diagonal
      if (myCircle[x].nodeX[4] > myCircle2[x].nodeX[11] - 20 && myCircle[x].nodeY[4] > myCircle2[x].nodeY[11] - 20 && myCircle[x].nodeX[4] < myCircle2[x].nodeX[1] && myCircle[x].nodeY[4] < myCircle2[x].nodeY[8])
      {
        myCircle[x].nodeX[4] = myCircle2[x].nodeX[11] - 20;
        myCircle[x].nodeY[4] = myCircle2[x].nodeY[11] - 20;
      }

      if (myCircle[x].nodeX[5] > myCircle2[x].nodeX[10] - 20 && myCircle[x].nodeY[5] > myCircle2[x].nodeY[10] - 20 && myCircle[x].nodeX[5] < myCircle2[x].nodeX[1] && myCircle[x].nodeY[5] < myCircle2[x].nodeY[8])
      {
        myCircle[x].nodeX[5] = myCircle2[x].nodeX[10] - 20;
        myCircle[x].nodeY[5] = myCircle2[x].nodeY[10] - 20;
      }

      if (myCircle[x].nodeX[3] > myCircle2[x].nodeX[0] - 20 && myCircle[x].nodeY[3] > myCircle2[x].nodeY[0] - 20 && myCircle[x].nodeX[3] < myCircle2[x].nodeX[1] && myCircle[x].nodeY[3] < myCircle2[x].nodeY[8])
      {
        myCircle[x].nodeX[3] = myCircle2[x].nodeX[0] - 20;
        myCircle[x].nodeY[3] = myCircle2[x].nodeY[0] - 20;
      }

      if (myCircle[x].nodeX[6] > myCircle2[x].nodeX[9] - 20 && myCircle[x].nodeY[6] > myCircle2[x].nodeY[9] - 20 && myCircle[x].nodeX[6] < myCircle2[x].nodeX[1] && myCircle[x].nodeY[6] < myCircle2[x].nodeY[8])
      {
        myCircle[x].nodeX[6] = myCircle2[x].nodeX[9] - 20;
        myCircle[x].nodeY[6] = myCircle2[x].nodeY[9] - 20;
      }


      //Top Right Diagonal
      if (myCircle[x].nodeX[8] < myCircle2[x].nodeX[1] + 20 && myCircle[x].nodeY[8] > myCircle2[x].nodeY[1] - 20&& myCircle[x].nodeX[8] > myCircle2[x].nodeX[11] && myCircle[x].nodeY[8] < myCircle2[x].nodeY[4])
      {
        myCircle[x].nodeX[8] = myCircle2[x].nodeX[1] + 20;
        myCircle[x].nodeY[8] = myCircle2[x].nodeY[1] - 20;
      }

      if (myCircle[x].nodeX[7] < myCircle2[x].nodeX[2] + 20 && myCircle[x].nodeY[7] > myCircle2[x].nodeY[2] - 20 && myCircle[x].nodeX[7] > myCircle2[x].nodeX[11] && myCircle[x].nodeY[7] < myCircle2[x].nodeY[4])
      {
        myCircle[x].nodeX[7] = myCircle2[x].nodeX[2] + 20;
        myCircle[x].nodeY[7] = myCircle2[x].nodeY[2] - 20;
      }

      if (myCircle[x].nodeX[9] < myCircle2[x].nodeX[0] + 20 && myCircle[x].nodeY[9] > myCircle2[x].nodeY[0] - 20 && myCircle[x].nodeX[9] > myCircle2[x].nodeX[11] && myCircle[x].nodeY[9] < myCircle2[x].nodeY[4])
      {
        myCircle[x].nodeX[9] = myCircle2[x].nodeX[0] + 20;
        myCircle[x].nodeY[9] = myCircle2[x].nodeY[0] - 20;
      }

      if (myCircle[x].nodeX[6] < myCircle2[x].nodeX[3] + 20 && myCircle[x].nodeY[6] > myCircle2[x].nodeY[3] - 20 && myCircle[x].nodeX[6] > myCircle2[x].nodeX[11] && myCircle[x].nodeY[6] < myCircle2[x].nodeY[4])
      {
        myCircle[x].nodeX[6] = myCircle2[x].nodeX[3] + 20;
        myCircle[x].nodeY[6] = myCircle2[x].nodeY[3] - 20;
      }
    }
    else
    {
      //Right Side Collision
      if (myCircle2[x].nodeX[7] < myCircle[x].nodeX[5] + 20 && myCircle2[x].nodeX[7] > myCircle[x].nodeX[7] && myCircle2[x].nodeY[7] < myCircle[x].nodeY[5]+50 && myCircle2[x].nodeY[7] > myCircle[x].nodeY[7]-50)
      {
        myCircle2[x].nodeX[7] = myCircle[x].nodeX[5] + 20;
        myCircle2[x].nodeY[7] = myCircle[x].nodeY[5];
      }

      if (myCircle2[x].nodeX[9] < myCircle[x].nodeX[3] + 20 && myCircle2[x].nodeX[9] > myCircle[x].nodeX[9] && myCircle2[x].nodeY[9] < myCircle[x].nodeY[3]+50 && myCircle2[x].nodeY[9] > myCircle[x].nodeY[9]-50)
      {
        myCircle2[x].nodeX[9] = myCircle[x].nodeX[3] + 20;
        myCircle2[x].nodeY[9] = myCircle[x].nodeY[3];
      }

      if (myCircle2[x].nodeX[8] < myCircle[x].nodeX[4] + 20 && myCircle2[x].nodeX[8] > myCircle[x].nodeX[8] && myCircle2[x].nodeY[8] < myCircle[x].nodeY[4]+50 && myCircle2[x].nodeY[8] > myCircle[x].nodeY[4]-50)
      {
        myCircle2[x].nodeX[8] = myCircle[x].nodeX[4] + 20;
        myCircle2[x].nodeY[8] = myCircle[x].nodeY[4];
      }

      if (myCircle2[x].nodeX[10] < myCircle[x].nodeX[2] + 20 && myCircle2[x].nodeX[10] > myCircle[x].nodeX[10] && myCircle2[x].nodeY[10] < myCircle[x].nodeY[2]+50 && myCircle2[x].nodeY[10] > myCircle[x].nodeY[2]-50)
      {
        myCircle2[x].nodeX[10] = myCircle[x].nodeX[2] + 20;
        myCircle2[x].nodeY[10] = myCircle[x].nodeY[2];
      }

      if (myCircle2[x].nodeX[11] < myCircle[x].nodeX[1] + 20 && myCircle2[x].nodeX[11] > myCircle[x].nodeX[11] && myCircle2[x].nodeY[11] < myCircle[x].nodeY[1]+50 && myCircle2[x].nodeY[11] > myCircle[x].nodeY[1]-50)
      {
        myCircle2[x].nodeX[11] = myCircle[x].nodeX[1] + 20;
        myCircle2[x].nodeY[11] = myCircle[x].nodeY[1];
      }


      //Bottom Collision
      if (myCircle2[x].nodeX[0] < myCircle[x].nodeX[6]+50 && myCircle2[x].nodeX[0] > myCircle[x].nodeX[6]-50 && myCircle2[x].nodeY[0] > myCircle[x].nodeY[0] && myCircle2[x].nodeY[0] < myCircle[x].nodeY[6] + 20)
      {
        myCircle2[x].nodeX[0] = myCircle[x].nodeX[6];
        myCircle2[x].nodeY[0] = myCircle[x].nodeY[6] + 20;
      }

      if (myCircle2[x].nodeX[11] < myCircle[x].nodeX[7]+50 && myCircle2[x].nodeX[11] > myCircle[x].nodeX[7]-50 && myCircle2[x].nodeY[11] > myCircle[x].nodeY[11] && myCircle2[x].nodeY[11] < myCircle[x].nodeY[7] + 20)
      {
        myCircle2[x].nodeX[11] = myCircle[x].nodeX[7];
        myCircle2[x].nodeY[11] = myCircle[x].nodeY[7] + 20;
      }

      if (myCircle2[x].nodeX[1] < myCircle[x].nodeX[5]+50 && myCircle2[x].nodeX[1] > myCircle[x].nodeX[5]-50 && myCircle2[x].nodeY[1] > myCircle[x].nodeY[1] && myCircle2[x].nodeY[1] < myCircle[x].nodeY[5] + 20)
      {
        myCircle2[x].nodeX[1] = myCircle[x].nodeX[5];
        myCircle2[x].nodeY[1] = myCircle[x].nodeY[5] + 20;
      }

      if (myCircle2[x].nodeX[10] < myCircle[x].nodeX[8]+50 && myCircle2[x].nodeX[10] > myCircle[x].nodeX[8]-50 && myCircle2[x].nodeY[10] > myCircle[x].nodeY[10] && myCircle2[x].nodeY[10] < myCircle[x].nodeY[8] + 20)
      {
        myCircle2[x].nodeX[10] = myCircle[x].nodeX[8];
        myCircle2[x].nodeY[10] = myCircle[x].nodeY[8] + 20;
      }

      if (myCircle2[x].nodeX[2] < myCircle[x].nodeX[4]+50 && myCircle2[x].nodeX[2] > myCircle[x].nodeX[4]-50 && myCircle2[x].nodeY[2] > myCircle[x].nodeY[2] && myCircle2[x].nodeY[2] < myCircle[x].nodeY[4] + 20)
      {
        myCircle2[x].nodeX[2] = myCircle[x].nodeX[4];
        myCircle2[x].nodeY[2] = myCircle[x].nodeY[4] + 20;
      }

      //Top Collision
      if (myCircle2[x].nodeX[6] < myCircle[x].nodeX[0]+50 && myCircle2[x].nodeX[6] > myCircle[x].nodeX[0]-50 && myCircle2[x].nodeY[6] < myCircle[x].nodeY[6] && myCircle2[x].nodeY[6] > myCircle[x].nodeY[0] - 20)
      {
        myCircle2[x].nodeX[6] = myCircle[x].nodeX[0];
        myCircle2[x].nodeY[6] = myCircle[x].nodeY[0] - 20;
      }

      if (myCircle2[x].nodeX[7] < myCircle[x].nodeX[11]+50 && myCircle2[x].nodeX[7] > myCircle[x].nodeX[11]-50 && myCircle2[x].nodeY[7] < myCircle[x].nodeY[7] && myCircle2[x].nodeY[7] > myCircle[x].nodeY[11] - 20)
      {
        myCircle2[x].nodeX[7] = myCircle[x].nodeX[11];
        myCircle2[x].nodeY[7] = myCircle[x].nodeY[11] - 20;
      }

      if (myCircle2[x].nodeX[5] < myCircle[x].nodeX[1]+50 && myCircle2[x].nodeX[5] > myCircle[x].nodeX[1]-50 && myCircle2[x].nodeY[5] < myCircle[x].nodeY[5] && myCircle2[x].nodeY[5] > myCircle[x].nodeY[1] - 20)
      {
        myCircle2[x].nodeX[5] = myCircle[x].nodeX[1];
        myCircle2[x].nodeY[5] = myCircle[x].nodeY[1] - 20;
      }

      if (myCircle2[x].nodeX[4] < myCircle[x].nodeX[2]+50 && myCircle2[x].nodeX[4] > myCircle[x].nodeX[2]-50 && myCircle2[x].nodeY[4] < myCircle[x].nodeY[4] && myCircle2[x].nodeY[4] > myCircle[x].nodeY[2] - 20)
      {
        myCircle2[x].nodeX[4] = myCircle[x].nodeX[2];
        myCircle2[x].nodeY[4] = myCircle[x].nodeY[2] - 20;
      }

      if (myCircle2[x].nodeX[8] < myCircle[x].nodeX[10]+50 && myCircle2[x].nodeX[8] > myCircle[x].nodeX[10]-50 && myCircle2[x].nodeY[8] < myCircle[x].nodeY[8] && myCircle2[x].nodeY[8] > myCircle[x].nodeY[10] - 20)
      {
        myCircle2[x].nodeX[8] = myCircle[x].nodeX[10];
        myCircle2[x].nodeY[8] = myCircle[x].nodeY[10] - 20;
      }

      //Left Side Collision
      if (myCircle2[x].nodeX[3] > myCircle[x].nodeX[9] - 20 && myCircle2[x].nodeX[3] < myCircle[x].nodeX[3] && myCircle2[x].nodeY[3] < myCircle[x].nodeY[9]+50 && myCircle2[x].nodeY[3] > myCircle[x].nodeY[9]-50)
      {
        myCircle2[x].nodeX[3] = myCircle[x].nodeX[9] - 20;
        myCircle2[x].nodeY[3] = myCircle[x].nodeY[9];
      }

      if (myCircle2[x].nodeX[4] > myCircle[x].nodeX[8] - 20 && myCircle2[x].nodeX[4] < myCircle[x].nodeX[4] && myCircle2[x].nodeY[4] < myCircle[x].nodeY[8]+50 && myCircle2[x].nodeY[4] > myCircle[x].nodeY[8]-50)
      {
        myCircle2[x].nodeX[4] = myCircle[x].nodeX[8] - 20;
        myCircle2[x].nodeY[4] = myCircle[x].nodeY[8];
      }

      if (myCircle2[x].nodeX[2] > myCircle[x].nodeX[10] - 20 && myCircle2[x].nodeX[2] < myCircle[x].nodeX[2] && myCircle2[x].nodeY[2] < myCircle[x].nodeY[10]+50 && myCircle2[x].nodeY[2] > myCircle[x].nodeY[10]-50)
      {
        myCircle2[x].nodeX[2] = myCircle[x].nodeX[10] - 20;
        myCircle2[x].nodeY[2] = myCircle[x].nodeY[10];
      }

      if (myCircle2[x].nodeX[1] > myCircle[x].nodeX[11] - 20 && myCircle2[x].nodeX[1] < myCircle[x].nodeX[1] && myCircle2[x].nodeY[1] < myCircle[x].nodeY[11]+50 && myCircle2[x].nodeY[1] > myCircle[x].nodeY[11]-50)
      {
        myCircle2[x].nodeX[1] = myCircle[x].nodeX[11] - 20;
        myCircle2[x].nodeY[1] = myCircle[x].nodeY[11];
      }

      if (myCircle2[x].nodeX[5] > myCircle[x].nodeX[7] - 20 && myCircle2[x].nodeX[5] < myCircle[x].nodeX[5] && myCircle2[x].nodeY[5] < myCircle[x].nodeY[7]+50 && myCircle2[x].nodeY[5] > myCircle[x].nodeY[7]-50)
      {
        myCircle2[x].nodeX[5] = myCircle[x].nodeX[7] - 20;
        myCircle2[x].nodeY[5] = myCircle[x].nodeY[7];
      }

      //Bottom Right Diagonal
      if (myCircle2[x].nodeX[11] < myCircle[x].nodeX[4] + 20 && myCircle2[x].nodeY[11] < myCircle[x].nodeY[4] + 20 && myCircle2[x].nodeX[11] > myCircle[x].nodeX[7] && myCircle2[x].nodeY[11] > myCircle[x].nodeY[2])
      {
        myCircle2[x].nodeX[11] = myCircle[x].nodeX[4] + 20;
        myCircle2[x].nodeY[11] = myCircle[x].nodeY[4] + 20;
      }

      if (myCircle2[x].nodeX[10] < myCircle[x].nodeX[5] + 20 && myCircle2[x].nodeY[10] < myCircle[x].nodeY[5] + 20 && myCircle2[x].nodeX[10] > myCircle[x].nodeX[7] && myCircle2[x].nodeY[10] > myCircle[x].nodeY[2])
      {
        myCircle2[x].nodeX[10] = myCircle[x].nodeX[5] + 20;
        myCircle2[x].nodeY[10] = myCircle[x].nodeY[5] + 20;
      }

      if (myCircle2[x].nodeX[9] < myCircle[x].nodeX[6] + 20 && myCircle2[x].nodeY[9] < myCircle[x].nodeY[6] + 20 && myCircle2[x].nodeX[9] > myCircle[x].nodeX[7] && myCircle2[x].nodeY[9] > myCircle[x].nodeY[2])
      {
        myCircle2[x].nodeX[9] = myCircle[x].nodeX[6] + 20;
        myCircle2[x].nodeY[9] = myCircle[x].nodeY[6] + 20;
      }

      if (myCircle2[x].nodeX[0] < myCircle[x].nodeX[3] + 20 && myCircle2[x].nodeY[0] < myCircle[x].nodeY[3] + 20 && myCircle2[x].nodeX[0] > myCircle[x].nodeX[7] && myCircle2[x].nodeY[0] > myCircle[x].nodeY[2])
      {
        myCircle2[x].nodeX[0] = myCircle[x].nodeX[3] + 20;
        myCircle2[x].nodeY[0] = myCircle[x].nodeY[3] + 20;
      }

      //Bottom Left Diagonal
      if (myCircle2[x].nodeX[2] > myCircle[x].nodeX[7] - 20 && myCircle2[x].nodeY[2] < myCircle[x].nodeY[7] + 20 && myCircle2[x].nodeX[2] < myCircle[x].nodeX[5] && myCircle2[x].nodeY[2] > myCircle[x].nodeY[10])
      {
        myCircle2[x].nodeX[2] = myCircle[x].nodeX[7] - 20;
        myCircle2[x].nodeY[2] = myCircle[x].nodeY[7] + 20;
      }

      if (myCircle2[x].nodeX[1] > myCircle[x].nodeX[8] - 20 && myCircle2[x].nodeY[1] < myCircle[x].nodeY[8] + 20 && myCircle2[x].nodeX[1] < myCircle[x].nodeX[5] && myCircle2[x].nodeY[1] > myCircle[x].nodeY[10])
      {
        myCircle2[x].nodeX[1] = myCircle[x].nodeX[8] - 20;
        myCircle2[x].nodeY[1] = myCircle[x].nodeY[8] + 20;
      }

      if (myCircle2[x].nodeX[3] > myCircle[x].nodeX[6] - 20 && myCircle2[x].nodeY[3] < myCircle[x].nodeY[6] + 20 && myCircle2[x].nodeX[3] < myCircle[x].nodeX[5] && myCircle2[x].nodeY[3] > myCircle[x].nodeY[10])
      {
        myCircle2[x].nodeX[3] = myCircle[x].nodeX[6] - 20;
        myCircle2[x].nodeY[3] = myCircle[x].nodeY[6] + 20;
      }

      if (myCircle2[x].nodeX[0] > myCircle[x].nodeX[9] - 20 && myCircle2[x].nodeY[0] < myCircle[x].nodeY[9] + 20 && myCircle2[x].nodeX[0] < myCircle[x].nodeX[5] && myCircle2[x].nodeY[0] > myCircle[x].nodeY[10])
      {
        myCircle2[x].nodeX[0] = myCircle[x].nodeX[9] - 20;
        myCircle2[x].nodeY[0] = myCircle[x].nodeY[9] + 20;
      }

      //Top Left Diagonal
      if (myCircle2[x].nodeX[4] > myCircle[x].nodeX[11] - 20 && myCircle2[x].nodeY[4] > myCircle[x].nodeY[11] - 20 && myCircle2[x].nodeX[4] < myCircle[x].nodeX[1] && myCircle2[x].nodeY[4] < myCircle[x].nodeY[8])
      {
        myCircle2[x].nodeX[4] = myCircle[x].nodeX[11] - 20;
        myCircle2[x].nodeY[4] = myCircle[x].nodeY[11] - 20;
      }

      if (myCircle2[x].nodeX[5] > myCircle[x].nodeX[10] - 20 && myCircle2[x].nodeY[5] > myCircle[x].nodeY[10] - 20 && myCircle2[x].nodeX[5] < myCircle[x].nodeX[1] && myCircle2[x].nodeY[5] < myCircle[x].nodeY[8])
      {
        myCircle2[x].nodeX[5] = myCircle[x].nodeX[10] - 20;
        myCircle2[x].nodeY[5] = myCircle[x].nodeY[10] - 20;
      }

      if (myCircle2[x].nodeX[3] > myCircle[x].nodeX[0] - 20 && myCircle2[x].nodeY[3] > myCircle[x].nodeY[0] - 20 && myCircle2[x].nodeX[3] < myCircle[x].nodeX[1] && myCircle2[x].nodeY[3] < myCircle[x].nodeY[8])
      {
        myCircle2[x].nodeX[3] = myCircle[x].nodeX[0] - 20;
        myCircle2[x].nodeY[3] = myCircle[x].nodeY[0] - 20;
      }

      if (myCircle2[x].nodeX[6] > myCircle[x].nodeX[9] - 20 && myCircle2[x].nodeY[6] > myCircle[x].nodeY[9] - 20 && myCircle2[x].nodeX[6] < myCircle[x].nodeX[1] && myCircle2[x].nodeY[6] < myCircle[x].nodeY[8])
      {
        myCircle2[x].nodeX[6] = myCircle[x].nodeX[9] - 20;
        myCircle2[x].nodeY[6] = myCircle[x].nodeY[9] - 20;
      }

      //Top Right Diagonal
      if (myCircle2[x].nodeX[8] < myCircle[x].nodeX[1] + 20 && myCircle2[x].nodeY[8] > myCircle[x].nodeY[1] - 20&& myCircle2[x].nodeX[8] > myCircle[x].nodeX[11] && myCircle2[x].nodeY[8] < myCircle[x].nodeY[4])
      {
        myCircle2[x].nodeX[8] = myCircle[x].nodeX[1] + 20;
        myCircle2[x].nodeY[8] = myCircle[x].nodeY[1] - 20;
      }

      if (myCircle2[x].nodeX[7] < myCircle[x].nodeX[2] + 20 && myCircle2[x].nodeY[7] > myCircle[x].nodeY[2] - 20 && myCircle2[x].nodeX[7] > myCircle[x].nodeX[11] && myCircle2[x].nodeY[7] < myCircle[x].nodeY[4])
      {
        myCircle2[x].nodeX[7] = myCircle[x].nodeX[2] + 20;
        myCircle2[x].nodeY[7] = myCircle[x].nodeY[2] - 20;
      }

      if (myCircle2[x].nodeX[9] < myCircle[x].nodeX[0] + 20 && myCircle2[x].nodeY[9] > myCircle[x].nodeY[0] - 20 && myCircle2[x].nodeX[9] > myCircle[x].nodeX[11] && myCircle2[x].nodeY[9] < myCircle[x].nodeY[4])
      {
        myCircle2[x].nodeX[9] = myCircle[x].nodeX[0] + 20;
        myCircle2[x].nodeY[9] = myCircle[x].nodeY[0] - 20;
      }

      if (myCircle2[x].nodeX[6] < myCircle[x].nodeX[3] + 20 && myCircle2[x].nodeY[6] > myCircle[x].nodeY[3] - 20 && myCircle2[x].nodeX[6] > myCircle[x].nodeX[11] && myCircle2[x].nodeY[6] < myCircle[x].nodeY[4])
      {
        myCircle2[x].nodeX[6] = myCircle[x].nodeX[3] + 20;
        myCircle2[x].nodeY[6] = myCircle[x].nodeY[3] - 20;
      }
    }
  }
}

//function which seperates values depending on skeleton array #/position
void seperate(float headPosX, float headPosY, float headPosZ, int userNumber, int forCount, float rightHandX, float rightHandY, float leftHandX, float leftHandY, color FState, color SState)
{
  if (userNumber == 0)
  {
    wingSpan = dist(rightHandX, rightHandY, leftHandX, leftHandY);
    myCircle[0].wingSpan = wingSpan;
    myCircle[1].wingSpan = wingSpan;
    myCircle[2].wingSpan = wingSpan;

    myCircle[0].sadR = red(FState);
    myCircle[0].sadG = green(FState);
    myCircle[0].sadB = blue(FState);

    myCircle[0].drawShape();
    myCircle[0].moveShape(headPosX, headPosY);

    myCircle[0].RoC = 0;
    myCircle[0].stroke_alpha = 255;

    myCircle[0].stroke_Weight = wingSpan*0.2;

    myCircle[1].sadR = red(FState);
    myCircle[1].sadG = green(FState);
    myCircle[1].sadB = blue(FState);
    myCircle[1].moveShape(headPosX, headPosY);

    myCircle[2].sadR = red(FState);
    myCircle[2].sadG = green(FState);
    myCircle[2].sadB = blue(FState);

    //myCircle[2].drawShape();
    myCircle[2].moveShape(headPosX, headPosY);
  }
  else if (userNumber == 1 )
  {
    wingSpan = dist(rightHandX, rightHandY, leftHandX, leftHandY);
    myCircle2[0].wingSpan = wingSpan;
    myCircle2[1].wingSpan = wingSpan;
    myCircle2[2].wingSpan = wingSpan;

    myCircle2[0].sadR = red(SState);
    myCircle2[0].sadG = green(SState);
    myCircle2[0].sadB = blue(SState);

    myCircle2[0].RoC = 0;
    myCircle2[0].stroke_alpha = 255;
    myCircle2[0].stroke_Weight = wingSpan*0.2;

    myCircle2[0].drawShape();
    myCircle2[0].moveShape(headPosX, headPosY);
    println("head2", headPosX, ",", headPosY);
    
    myCircle2[1].sadR = red(SState);
    myCircle2[1].sadG = green(SState);
    myCircle2[1].sadB = blue(SState);
    myCircle2[1].RoC = myCircle[1].RoC; 
    myCircle2[1].moveShape(headPosX, headPosY);

    myCircle2[2].sadR = red(SState);
    myCircle2[2].sadG = green(SState);
    myCircle2[2].sadB = blue(SState);

    myCircle2[2].moveShape(headPosX, headPosY);
  }
}


//music player - skeleton array passed through for a second dom check
void musicPlayer(int skeletonArraySize)
{
  //dominance check
  if (skeletonArraySize == 2)
  {
    if (myCircle[0].wingSpan > myCircle2[0].wingSpan)
    {
      myCircle[0].dominant = true;
      myCircle2[0].dominant = false;
    } else if (myCircle2[0].wingSpan > myCircle[0].wingSpan)
    {
      myCircle2[0].dominant = true;
      myCircle[0].dominant = false;
    }
  } else if (skeletonArraySize == 1)
  {
    myCircle[0].dominant = true;
  }

  if (skeletonArraySize == 0);

  //condition for sad play
  if ( key == 'a' || key == 'A' || (u1SadReached == true && u2SadReached == true && userCount == 2))
  {
    if (myCircle[0].sadBool == true && myCircle2[0].sadBool == true) {
      sadFadeBool = false;
      
      neutralGainBool = false;
      happyGainBool = false;
      angryGainBool = false;

      if (sadGain == (-100) || sadGain <= (-25))
      {
        sadGain = -16;
        sad.setGain(sadGain);
        sadGainBool = true;
      }

      if (neutralFade>(-8))
      {
        neutralFadeBool = true;
      }
    }
  }

  //condition for happy play
  if (key == 'b' || key == 'B' || (u1HappyReached == true && u2HappyReached==true && userCount == 2))
  {
    if (myCircle[0].happyBool == true && myCircle2[0].happyBool == true) {
      happyFadeBool = false;
      
      neutralGainBool = false;
      sadGainBool = false;
      angryGainBool = false;
      
      if (happyGain == (-100) || happyGain <= (-25))
      {
        happyGain = -25;
        happy.setGain(happyGain);
        happyGainBool = true;
      }

      if (neutralFade>(-8))
      {
        neutralFadeBool = true;
      }
    }
  }
  
  //condition for angry play
  if ( key == 'c' || key == 'C' || (u1AngryReached == true && u2AngryReached == true && userCount == 2))
  {
    if (myCircle[0].angryBool == true && myCircle2[0].angryBool == true) {
      angryFadeBool = false;
      
      neutralGainBool = false;
      happyGainBool = false;
      sadGainBool = false;

      if (angryGain == (-100) || angryGain <= (-25))
      {
        angryGain = -16;
        angry.setGain(sadGain);
        angryGainBool = true;
      }

      if (neutralFade>(-8))
      {
        neutralFadeBool = true;
      }
    }
  }

  //condition for return to neutral
  if (skeletonArraySize == 0)
  { 
    neutralFadeBool = false;
    
    happyGainBool = false;
    sadGainBool = false;
    angryGainBool = false;
    
    if (neutralGain<0)
    {
      neutralGainBool = true;
    }
  }

  //neutral fade out
  if (neutralFadeBool == true)
  {
    if (neutralFade>(-8))
    {
      neutralFade-=0.6;
      neutral.setGain(neutralFade);
    }

    if (neutralFade<(-8))
    {
      neutralGain = neutralFade;
      neutralFadeBool = false;
    }
  }

  //Neutral Gain Fade in
  if (neutralGainBool == true)
  {
    neutralFadeBool = false;
    
    sadFadeBool = true;
    happyFadeBool = true;
    angryFadeBool = true;
    
    if (neutralGain<(0))
    {
      neutralGain+=0.6;
      neutral.setGain(neutralGain);
    }

    if (neutralGain>=(0))
    {
      neutralFade = neutralGain;
      neutralGainBool = false;
    }
  }

  //sad fade out complete
  if (sadFadeBool == true)
  {
    if (sadFade>(-25))
    {
      sadFade-=0.3;
      sad.setGain(sadFade);

    }

    if (sadFade<=(-25))
    {
      sadGain = sadFade;
      sadFadeBool = false;
    }
  }

  //Sad Gain Fade in
  if (sadGainBool == true)
  {
    sadFadeBool = false;
    
    happyFadeBool = true;
    neutralFadeBool = true;
    angryFadeBool = true;
    
    if (sadGain<(0))
    {
      sadGain+=0.6;
      sad.setGain(sadGain);
    }

    if (sadGain>=(0))
    {
      sadFade = sadGain;
      sadGainBool = false;
    }
  }

  //happy fade out
  if (happyFadeBool == true)
  {
    // happyGainBool = false;
    if (happyFade>(-50))
    {
      happyFade-=0.6;
      happy.setGain(happyFade);
    }

    if (happyFade<=(-50))
    {
      happyGain = happyFade;
      happyFadeBool = false;
    }
  }

  //happy Gain Fade in
  if (happyGainBool == true)
  {
    happyFadeBool = false;
    
    sadFadeBool = true;
    neutralFadeBool = true;
    angryFadeBool = true;
    
    if (happyGain<(0))
    {
      happyGain+=0.6;
      happy.setGain(happyGain);
    }

    if (happyGain>=(0))
    {
      happyFade = happyGain;
      happyGainBool = false;
    }
  }
  
  //angry fade out complete
  if (angryFadeBool == true)
  {
    if (angryFade>(-25))
    {
      angryFade-=0.6;
      angry.setGain(angryFade);

    }

    if (angryFade<=(-25))
    {
      angryGain = angryFade;
      angryFadeBool = false;
    }
  }

  //angry Gain Fade in
  if (angryGainBool == true)
  {
    angryFadeBool = false;
    
    happyFadeBool = true;
    neutralFadeBool = true;
    sadFadeBool = true;
    
    if (angryGain<(0))
    {
      angryGain+=0.6;
      angry.setGain(angryGain);
    }

    if (angryGain>=(0))
    {
      angryFade = angryGain;
      angryGainBool = false;
    }
  }

  if (!happy.isPlaying() || !neutral.isPlaying() || !sad.isPlaying() || !angry.isPlaying())
  {
    happy.loop();
    neutral.loop();
    sad.loop();
    angry.loop();
  }
}

//beat listener
class BeatListener implements AudioListener
{
  private BeatDetect beat;
  private AudioPlayer source;
 
  BeatListener(BeatDetect beat, AudioPlayer source)
  {
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
  }
 
  void samples(float[] samps)
  {
    beat.detect(source.mix);
  }
 
  void samples(float[] sampsL, float[] sampsR)
  {
    beat.detect(source.mix);
  }
}