import java.awt.AWTException;
import java.awt.Rectangle;
import java.awt.Robot;
import java.util.ArrayList;
import java.util.Collections;
import processing.core.PApplet;
import processing.sound.*; // Import Sound library

//when in doubt, consult the Processsing reference: https://processing.org/reference/

int margin = 200; //set the margin around the squares
final int padding = 50; // padding between buttons and also their width/height
final int buttonSize = 40; // padding between buttons and also their width/height
ArrayList<Integer> trials = new ArrayList<Integer>(); //contains the order of buttons that activate in the test
int trialNum = 0; //the current trial number (indexes into trials array above)
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
int hits = 0; //number of successful clicks
int misses = 0; //number of missed clicks
Robot robot; //initialized in setup 

int numRepeats = 1; //sets the number of times each button repeats in the test

// Animation variables
float animationOffset = 0;
float pulsePhase = 0;
float warningPulse = 0;

// Sound variables
SoundFile hitSound;
SoundFile missSound;

// Tutorial variables
boolean inTutorial = true;
int tutorialStep = 0;
int tutorialTargetButton = 5; // Button to click in tutorial
boolean tutorialComplete = false;
int tutorialHits = 0;
int tutorialMisses = 0;
final int TUTORIAL_TARGETS = 3; // Number of practice targets

void setup()
{
  size(700, 700); // set the size of the window
  //noCursor(); //hides the system cursor if you want
  noStroke(); //turn off all strokes, we're just using fills here (can change this if you want)
  textFont(createFont("Arial", 16)); //sets the font to Arial size 16
  textAlign(CENTER);
  frameRate(60);
  ellipseMode(CENTER); //ellipses are drawn from the center (BUT RECTANGLES ARE NOT!)
  //rectMode(CENTER); //enabling will break the scaffold code, but you might find it easier to work with centered rects

  // Load sound files
  hitSound = new SoundFile(this, "c-371145.mp3");
  missSound = new SoundFile(this, "incorrect-293358.mp3");

  try {
    robot = new Robot(); //create a "Java Robot" class that can move the system cursor
  } 
  catch (AWTException e) {
    e.printStackTrace();
  }

  //===DON'T MODIFY THIS RANDOM ORDERING CODE==
  for (int i = 0; i < 16; i++) //generate list of targets and randomize the order
      // number of buttons in 4x4 grid
    for (int k = 0; k < numRepeats; k++)
      // number of times each button repeats
      trials.add(i);

  Collections.shuffle(trials); // randomize the order of the buttons
  System.out.println("trial order: " + trials);
  
  surface.setLocation(0,0);// put window in top left corner of screen (doesn't always work)
}


void draw()
{
  background(0); //set background to black

  if (inTutorial) {
    drawTutorial();
    return;
  }

  if (trialNum >= trials.size()) //check to see if test is over
  {
    float timeTaken = (finishTime-startTime) / 1000f;
    float penalty = constrain(((95f-((float)hits*100f/(float)(hits+misses)))*.2f),0,100);
    fill(255); //set fill color to white
    //write to screen (not console)
    text("Finished!", width / 2, height / 2); 
    text("Hits: " + hits, width / 2, height / 2 + 20);
    text("Misses: " + misses, width / 2, height / 2 + 40);
    text("Accuracy: " + (float)hits*100f/(float)(hits+misses) +"%", width / 2, height / 2 + 60);
    text("Total time taken: " + timeTaken + " sec", width / 2, height / 2 + 80);
    text("Average time for each button: " + nf((timeTaken)/(float)(hits+misses),0,3) + " sec", width / 2, height / 2 + 100);
    text("Average time for each button + penalty: " + nf(((timeTaken)/(float)(hits+misses) + penalty),0,3) + " sec", width / 2, height / 2 + 140);
    return; //return, nothing else to do now test is over
  }

  fill(255); //set fill color to white
  text((trialNum + 1) + " of " + trials.size(), 40, 20); //display what trial the user is on

  // Update animation
  animationOffset -= 0.5; // Speed of flowing animation (negative for reverse)
  pulsePhase += 0.1; // Speed of pulsing
  warningPulse += 0.15; // Speed of warning pulse for incorrect hovers

  for (int i = 0; i < 16; i++)// for all button
    drawButton(i); //draw button

  drawDottedLines();

  // Draw cursor (green when in target, red otherwise)
  Rectangle currentBounds = getButtonLocation(trials.get(trialNum));
  boolean isInTarget = (mouseX > currentBounds.x && mouseX < currentBounds.x + currentBounds.width) && 
                       (mouseY > currentBounds.y && mouseY < currentBounds.y + currentBounds.height);
  
  if (isInTarget) {
    fill(50, 255, 50, 200); // Green when in target
  } else {
    fill(255, 0, 0, 200); // Red otherwise
  }
  ellipse(mouseX, mouseY, 20, 20); //draw user cursor as a circle with a diameter of 20
  
  drawClicksRemaining();
  drawStreak();
}

void drawTutorial() {
  // Update animation for tutorial
  animationOffset -= 0.5;
  pulsePhase += 0.1;
  warningPulse += 0.15;
  
  // Draw title
  fill(255);
  textFont(createFont("Arial", 24));
  text("TUTORIAL", width/2, 50);
  textFont(createFont("Arial", 16));
  
  // Draw tutorial instructions based on step
  fill(200);
  if (tutorialStep == 0) {
    text("Welcome to the Clicking Test!", width/2, 100);
    text("This tutorial will teach you the basics.", width/2, 120);
    text("", width/2, 140);
    text("Your goal: Click the CYAN colored buttons as fast as possible", width/2, 160);
    text("", width/2, 180);
    fill(0, 255, 255);
    text("CYAN = Current Target", width/2, 200);
    fill(0, 80, 80);
    text("DARK CYAN = Next Target", width/2, 220);
    fill(200);
    text("", width/2, 240);
    text("Click anywhere or press any key to continue...", width/2, 280);
  } 
  else if (tutorialStep == 1) {
    text("Visual Feedback System:", width/2, 100);
    text("", width/2, 120);
    text("• Your cursor turns GREEN when over the target", width/2, 140);
    text("• Your cursor turns RED when not over the target", width/2, 160);
    text("", width/2, 180);
    text("• A flowing line shows the path to your target", width/2, 200);
    text("• The line is GREEN when you're over the target", width/2, 220);
    text("• The line is YELLOW when you need to move to the target", width/2, 240);
    text("", width/2, 260);
    text("Click anywhere or press any key to continue...", width/2, 300);
  }
  else if (tutorialStep == 2) {
    text("Tips for Success:", width/2, 100);
    text("", width/2, 120);
    text("• Speed matters, but accuracy matters MORE", width/2, 140);
    text("• Missing clicks adds a time penalty to your score", width/2, 160);
    text("• Aim carefully before clicking", width/2, 180);
    text("", width/2, 200);
    text("• Follow the flowing line to find targets quickly", width/2, 220);
    text("• Use the next target preview (dark cyan) to plan ahead", width/2, 240);
    text("", width/2, 260);
    text("Click anywhere or press any key to continue...", width/2, 300);
  }
  else if (tutorialStep == 3) {
    text("Now it's your turn! Click the " + TUTORIAL_TARGETS + " cyan targets to practice", width/2, 100);
    text("Targets clicked: " + tutorialHits + "/" + TUTORIAL_TARGETS, width/2, 120);
    
    if (tutorialMisses > 0) {
      fill(255, 100, 100);
      text("Misses: " + tutorialMisses + " (Try to click accurately!)", width/2, 140);
      fill(200);
    }
    
    // Draw practice grid
    for (int i = 0; i < 16; i++) {
      drawTutorialButton(i);
    }
    
    // Draw tutorial dotted line
    drawTutorialDottedLine();
    
    // Draw cursor
    Rectangle currentBounds = getButtonLocation(tutorialTargetButton);
    boolean isInTarget = (mouseX > currentBounds.x && mouseX < currentBounds.x + currentBounds.width) && 
                         (mouseY > currentBounds.y && mouseY < currentBounds.y + currentBounds.height);
    
    if (isInTarget) {
      fill(50, 255, 50, 200);
    } else {
      fill(255, 0, 0, 200);
    }
    ellipse(mouseX, mouseY, 20, 20);
    
    if (tutorialHits >= TUTORIAL_TARGETS) {
      fill(50, 255, 50);
      text("Perfect! You're ready!", width/2, height - 100);
      text("Press any key or click to begin the real test...", width/2, height - 60);
      tutorialComplete = true;
    }
  }
}

void drawTutorialButton(int i) {
  Rectangle bounds = getButtonLocation(i);
  strokeWeight(0);
  
  boolean isMouseOver = (mouseX > bounds.x && mouseX < bounds.x + bounds.width) && 
                        (mouseY > bounds.y && mouseY < bounds.y + bounds.height);

  if (tutorialTargetButton == i && tutorialStep == 3 && !tutorialComplete) {
    if (isMouseOver) {
      fill(50, 255, 50); // Green when hovering
    } else {
      fill(0, 255, 255); // Cyan for target
    }
  }
  else {
    if (isMouseOver && tutorialStep == 3 && !tutorialComplete) {
      float pulse = sin(warningPulse) * 0.5 + 0.5;
      stroke(255, 0, 0, 150 + pulse * 105);
      strokeWeight(3 + pulse * 2);
      fill(80 + pulse * 60, 0, 0);
    } else {
      stroke(20);
      strokeWeight(2);
      fill(0);
    }
  }
  
  rect(bounds.x, bounds.y, bounds.width, bounds.height);
}

void drawTutorialDottedLine() {
  if (tutorialStep != 3 || tutorialComplete) return;
  
  Rectangle currentBounds = getButtonLocation(tutorialTargetButton);
  float currentCenterX = currentBounds.x + currentBounds.width / 2.0;
  float currentCenterY = currentBounds.y + currentBounds.height / 2.0;
  
  boolean isInTarget = (mouseX > currentBounds.x && mouseX < currentBounds.x + currentBounds.width) && 
                       (mouseY > currentBounds.y && mouseY < currentBounds.y + currentBounds.height);
  
  drawAnimatedLine(mouseX, mouseY, currentCenterX, currentCenterY, true, isInTarget);
  noStroke();
}

int currentStreak = 0;

void drawStreak() {
  textAlign(LEFT);
  
  if (currentStreak > 0) {
    fill(255, 215, 0); // Gold color
    textFont(createFont("Arial", 24));
    text("STREAK: " + currentStreak, 400, 180);
  }
  
  textFont(createFont("Arial", 16));
  textAlign(CENTER);
  noStroke();
}

void drawClicksRemaining() {
  int remaining = trials.size() - trialNum;
  textAlign(RIGHT);
  fill(255);
  textFont(createFont("Arial", 20));
  text("Clicks left: " + remaining, width - 20, 30);
  textFont(createFont("Arial", 16));
  textAlign(CENTER);
}

void drawDottedLines() {
   if (trialNum >= trials.size()) return; // Don't draw lines if test is over
  
  // Get current target button center
  Rectangle currentBounds = getButtonLocation(trials.get(trialNum));
  float currentCenterX = currentBounds.x + currentBounds.width / 2.0;
  float currentCenterY = currentBounds.y + currentBounds.height / 2.0;
  
  // Check if mouse is within the target bounds
  boolean isInTarget = (mouseX > currentBounds.x && mouseX < currentBounds.x + currentBounds.width) && 
                       (mouseY > currentBounds.y && mouseY < currentBounds.y + currentBounds.height);
  
  // Draw animated line from mouse to current target (more prominent)
  drawAnimatedLine(mouseX, mouseY, currentCenterX, currentCenterY, true, isInTarget);
  
  // Draw line from current target to next target (if there is a next target) - more subtle
  if (trialNum + 1 < trials.size()) {
    Rectangle nextBounds = getButtonLocation(trials.get(trialNum + 1));
    float nextCenterX = nextBounds.x + nextBounds.width / 2.0;
    float nextCenterY = nextBounds.y + nextBounds.height / 2.0;
    
    drawAnimatedLine(currentCenterX, currentCenterY, nextCenterX, nextCenterY, false, false);
  }
  
  noStroke(); // Turn off stroke for other drawing operations
}

void drawAnimatedLine(float x1, float y1, float x2, float y2, boolean isPrimary, boolean isInTarget) {
  float distance = dist(x1, y1, x2, y2);
  float dashLength = isPrimary ? 12 : 8;
  float gapLength = isPrimary ? 8 : 6;
  float totalDashGap = dashLength + gapLength;
  
  // Calculate the direction vector
  float dx = (x2 - x1) / distance;
  float dy = (y2 - y1) / distance;
  
  // Draw dashes along the line with animation
  for (float i = 0; i < distance; i += totalDashGap) {
    // Animated offset creates flowing effect
    float offsetI = (i + animationOffset) % totalDashGap;
    float adjustedI = i - (animationOffset % totalDashGap);
    
    if (adjustedI < 0) adjustedI += totalDashGap;
    
    float startX = x1 + dx * adjustedI;
    float startY = y1 + dy * adjustedI;
    float endX = x1 + dx * min(adjustedI + dashLength, distance);
    float endY = y1 + dy * min(adjustedI + dashLength, distance);
    
    // Calculate progress along line (0 to 1)
    float progress = adjustedI / distance;
    
    // Only draw if within bounds
    if (adjustedI >= 0 && adjustedI < distance) {
      if (isPrimary) {
        // Primary line: gradient from cursor to target with pulsing
        float pulseValue = sin(pulsePhase + progress * PI * 2) * 0.3 + 0.7; // Pulse effect
        
        if (isInTarget) {
          // GREEN when in target
          // Draw green glow layers
          stroke(100, 255, 0, 40 * pulseValue);
          strokeWeight(lerp(8, 12, progress) * pulseValue);
          line(startX, startY, endX, endY);
          
          stroke(120, 255, 0, 60 * pulseValue);
          strokeWeight(lerp(6, 9, progress) * pulseValue);
          line(startX, startY, endX, endY);
          
          stroke(150, 255, 0, 80 * pulseValue);
          strokeWeight(lerp(5, 7, progress) * pulseValue);
          line(startX, startY, endX, endY);
          
          // Main green line
          stroke(50, 255, 50, lerp(200, 255, progress));
          strokeWeight(lerp(3, 5, progress) * pulseValue);
          line(startX, startY, endX, endY);
        } else {
          // YELLOW when not in target
          // Draw yellow glow layers
          stroke(255, 220, 0, 30 * pulseValue);
          strokeWeight(lerp(8, 12, progress) * pulseValue);
          line(startX, startY, endX, endY);
          
          stroke(255, 230, 0, 50 * pulseValue);
          strokeWeight(lerp(6, 9, progress) * pulseValue);
          line(startX, startY, endX, endY);
          
          stroke(255, 240, 0, 70 * pulseValue);
          strokeWeight(lerp(5, 7, progress) * pulseValue);
          line(startX, startY, endX, endY);
          
          // Main yellow line
          stroke(255, 255, 0, lerp(200, 255, progress));
          strokeWeight(lerp(3, 5, progress) * pulseValue);
          line(startX, startY, endX, endY);
        }
      } else {
        // Secondary line: more subtle
        stroke(0, 80, 80, 100);
        strokeWeight(2);
        line(startX, startY, endX, endY);
      }
      
      // Add arrowheads along the line for primary line
      if (isPrimary && (int)adjustedI % 60 == 0 && adjustedI > 0) {
        drawArrow(startX, startY, dx, dy, isInTarget);
      }
    }
  }
  
  noStroke();
}

void drawArrow(float x, float y, float dx, float dy, boolean isInTarget) {
  pushMatrix();
  translate(x, y);
  rotate(atan2(dy, dx));
  
  // Draw small arrow
  float arrowSize = 6;
  if (isInTarget) {
    fill(50, 255, 50, 200); // Green when in target
  } else {
    fill(255, 255, 0, 200); // Yellow otherwise
  }
  noStroke();
  triangle(0, 0, -arrowSize, -arrowSize/2, -arrowSize, arrowSize/2);
  
  popMatrix();
}

void checkMouse() {
  // Handle tutorial clicks
  if (inTutorial) {
    if (tutorialStep < 3) {
      tutorialStep++;
    } else if (tutorialStep == 3) {
      if (tutorialComplete) {
        inTutorial = false;
        tutorialStep = 0;
      } else {
        // Check if clicked on tutorial target
        Rectangle bounds = getButtonLocation(tutorialTargetButton);
        if ((mouseX > bounds.x && mouseX < bounds.width + bounds.x) && 
            (mouseY > bounds.y && mouseY < bounds.height + bounds.y)) {
          tutorialHits++;
          hitSound.play();
          // Generate new random target for next practice
          if (tutorialHits < TUTORIAL_TARGETS) {
            tutorialTargetButton = (int)random(16);
          }
        } else {
          tutorialMisses++;
          missSound.play();
        }
      }
    }
    return;
  }

  if (trialNum >= trials.size()) //if task is over, just return
    return;

  if (trialNum == 0) //check if first click, if so, start timer
    startTime = millis();

  if (trialNum == trials.size() - 1) //check if final click
  {
    finishTime = millis();
    //write to terminal some output. Useful for debugging too.
    println("we're done!");
  }

  Rectangle bounds = getButtonLocation(trials.get(trialNum));

 //check to see if mouse cursor is inside button 
  if ((mouseX > bounds.x && mouseX < bounds.width + bounds.x) && (mouseY > bounds.y && mouseY < bounds.height + bounds.y)) // test to see if hit was within bounds
  {
    System.out.println("HIT! " + trialNum + " " + (millis() - startTime)); // success
    hits++; 
    currentStreak++;
    hitSound.play(); // Play hit sound
  } 
  else
  {
    System.out.println("MISSED! " + trialNum + " " + (millis() - startTime)); // fail
    misses++;
    currentStreak = 0;
    missSound.play(); // Play miss sound
  }

  trialNum++; //Increment trial number

  //in this example code, we move the mouse back to the middle
  // robot.mouseMove(width/2, (height)/2); //on click, move cursor to roughly center of window!
}

void mousePressed() // test to see if hit was in target!
{
  checkMouse();
}  

//probably shouldn't have to edit this method
Rectangle getButtonLocation(int i) //for a given button ID, what is its location and size
{
   int x = (i % 4) * (padding + buttonSize) + margin;
   int y = (i / 4) * (padding + buttonSize) + margin;
   return new Rectangle(x, y, buttonSize, buttonSize);
}

//you can edit this method to change how buttons appear
void drawButton(int i)
{
  Rectangle bounds = getButtonLocation(i);
  strokeWeight(0);
  
  // Check if mouse is over this button
  boolean isMouseOver = (mouseX > bounds.x && mouseX < bounds.x + bounds.width) && 
                        (mouseY > bounds.y && mouseY < bounds.y + bounds.height);

  if (trials.get(trialNum) == i) { // see if current button is the target
    if (isMouseOver) {
      fill(50, 255, 50); // Green when hovering over target
    } else {
      fill(0, 255, 255); // Cyan otherwise
    }
  }
  else if (trialNum+1 < trials.size() && trials.get(trialNum+1) == i) { // see if current button is the next target
    if (isMouseOver) {
      // Warning animation for hovering over next target (not current)
      float pulse = sin(warningPulse) * 0.5 + 0.5;
      fill(60 + pulse * 40, 40, 40); // Subtle red pulse
    } else {
      fill(0, 80, 80);
    }
  }
  else { 
    if (isMouseOver) {
      // Warning animation for hovering over incorrect button
      float pulse = sin(warningPulse) * 0.5 + 0.5;
      stroke(255, 0, 0, 150 + pulse * 105); // Red pulsing outline
      strokeWeight(3 + pulse * 2); // Pulsing thickness
      fill(80 + pulse * 60, 0, 0); // Red pulsing fill
    } else {
      stroke(20);
      strokeWeight(2);
      fill(0); // if not, fill black
    }
  }

  rect(bounds.x, bounds.y, bounds.width, bounds.height); //draw button
}

void mouseMoved()
{
   //can do stuff everytime the mouse is moved (i.e., not clicked)
   //https://processing.org/reference/mouseMoved_.html
}

void mouseDragged()
{
  //can do stuff everytime the mouse is dragged
  //https://processing.org/reference/mouseDragged_.html
}

void keyPressed() 
{
  //can use the keyboard if you wish
  //https://processing.org/reference/keyTyped_.html
  //https://processing.org/reference/keyCode.html
  checkMouse();
  System.out.println("clicked");
}

//ALL IDEAS GENERATED INDEPENDENTLY, SOME IMPLEMENTATION WAS AIDED BY LLM TOOLS