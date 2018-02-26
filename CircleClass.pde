class circleX
{
  static final int NUM_AURA = 10;
  static final int DIST = 20;
  
  boolean happyBool;
  boolean sadBool;
  boolean angryBool;
  boolean dominant;
  
  float wingSpan;
  
  //colour stuff
  float sadR = 50.0f;
  float sadG = 70.0f;
  float sadB = 200.0f;
  
  float origR;
  float origG;
  float origB;
  
  //these lines were originally in circleClass2
  float madR = 255;
  float madG = 10;
  float madB = 20;
 
  float howClose;
  
  // center point
  float centerX = 0, centerY = 0;
  
  float radius = 10;
  float rotAngle = -90;
  
  float accelX;
  float accelY;
  
  float springing = .0009;
  float damping = .98;
  
  
  //50 nodes can be used to achieve "sad" effect
  //Corner Nodes
  int nodes = 12;
  
  float nodeStartX[] = new float[nodes];
  float nodeStartY[] = new float[nodes];
  
  float[]nodeX = new float[nodes];
  float[]nodeY = new float[nodes];
  
  float[]angle = new float[nodes];
  float[]frequency = new float[nodes];
  
  // Soft-Body Dynamics, not in use
  //float organicConstant = 10;
  
  // Stroke Variables
  float stroke_Weight = 10;
  float stroke_alpha = 255;
  float stroke_balance = 255;
  float stroke_hue = 60;
  float stroke_sat = 255;
  
  // Rate of Change, or how fast the circle increases
  float RoC = 2; 
  
  boolean go;
  boolean change;
  circleX()
  {
    centerX = width/2;
    centerY = height/2;
    // Initialize frequencies for corner nodes
    for (int i=0; i<nodes; i++)
    {
      frequency[i] = random(5, 12);
    }
    go = false;
    change = false;
    noStroke();
  }
  
  void drawShape()
  {
  //origR = 50.0f;
  //origG = 70.0f;
  //origB = 200.0f;
    

    if(RoC <= 0.001)
    {
      radius = 10;
      //stroke_alpha = 255;
      //stroke_Weight = 10;
      RoC = 2;
      go = true;
      change = true;
    }
    
    if(radius > 15 && change == true)
    {
      stroke_alpha = 255;
      //stroke_balance = 255;
      stroke_Weight = 10;
      change = false;
    }
    
    //calculate node starting locations
    for(int i=0; i<nodes; i++)
    {
      //nodeStartX[i] = centerX+cos(radians(rotAngle))*(radius + (wingSpan*0.25));
      //nodeStartY[i] = centerY+sin(radians(rotAngle))*(radius+ (wingSpan*0.25));
      
      nodeStartX[i] = centerX+cos(radians(rotAngle))*(radius);
      nodeStartY[i] = centerY+sin(radians(rotAngle))*(radius);
      rotAngle += 360.0/nodes;
    }
  
    // draw polygon
  // colorMode(HSB);
    
     
    curveTightness(0);
    noFill();
    
    pushMatrix();
    stroke(sadR, sadG, sadB, stroke_alpha);
    strokeWeight(stroke_Weight);
    popMatrix();
    
     
      beginShape();
      
      for(int i=0; i<nodes; i++)
      {
        curveVertex(nodeX[i], nodeY[i]);
      }
      for(int i=0; i<nodes-1; i++)
      {
        curveVertex(nodeX[i], nodeY[i]);
      }

      if(stroke_Weight <= 1)
      {
       stroke_Weight = 1; 
      }

      radius += RoC;
      RoC -= 0.01;
      
      if(RoC <= 0.001)
      {
       RoC = 0.001; 
      }
      
      //stroke_balance -= 2.275;
      stroke_alpha -= 2.275;
      stroke_Weight -= 0.05;
      
      
      
      endShape();
  }
  
  void moveShape(float x1, float y1)
  {
    float deltaX = x1-centerX;
    float deltaY = y1-centerY;
  
    // create springing effect
    deltaX *= springing;
    deltaY *= springing;
    accelX += deltaX;
    accelY += deltaY;
  
    // move predator's center
    centerX += accelX;
    centerY += accelY;
  
    // slow down springing
    accelX *= damping;
    accelY *= damping;
  
    for (int i=0; i<nodes; i++){
      nodeX[i] = nodeStartX[i]+sin(radians(angle[i]));
      nodeY[i] = nodeStartY[i]+sin(radians(angle[i]));
      angle[i]+=frequency[i];
    }
  }
  
}