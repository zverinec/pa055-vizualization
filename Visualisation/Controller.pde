/** @file Controller.pde
 * @author Jan Drabek, Martin Ukrop
 * @brief controller object, adjusts settings and manages control panel drawing
 */
 
import java.awt.event.KeyEvent;

class Controller {
  
  // slider change if RIGHT/LEFT arrows are presed
  float keySliderShift = 0.1;
  // minutes passed if UP/DOWN arrows are pressed 
  int keyTimeShift = 1;
  
  // height of the slider bar
  int sliderHeight = 20;
  // part of the bar occupied by actual slider (its relative width)
  float sliderMoverRatio = 0.1;
  // pixel space between slider and bar border
  int sliderOffset = 4;
  
  // tick-box size constant
  int boxSide = 16;
  // y position of top bounding box for button choosers
  int topYbuttons = screenHeight-controlPanelHeight+70-12;
  // margin applied for time and velocity slider
  int sliderMargin = 30;
  // x position of center of the first play/pause button
  int buttonsXbegin = 350+130+boxSide/2;
  // y position of center of the top of speed slider
  int speedSliderY = screenHeight-controlPanelHeight+sliderHeight+80;
  // length between play/pause button centers
  int buttonSpacing = (int)(1.5*boxSide);
  
  // button constants
  static final int BUTTON_PLAY = 0;
  static final int BUTTON_PAUSE = 1;
  static final int BUTTON_HOME = 2;
  static final int BUTTON_END = 3;
  static final int BUTTON_NEXT = 4;
  static final int BUTTON_PREV = 5;

  /** Controller constructor
   * adjusts screen settings
   * loads images and fonts to global variables
   * displays control panel
   */
  Controller() {
    size(screenWidth, screenHeight);
    frameRate(25);
    smooth();
    noStroke();
    // load background
    bgImage = loadImage(bgImagePath);
    // load fonts
    fonts = new PFont[4];
    for (int i = 0; i < 4; i++) {
      fonts[i] = loadFont(fontPaths[i]);
    }
    // load logos
    logoImages = new PImage[3];
    for (int i = 0; i < 3; i++) {
      logoImages[i] = loadImage(logoImagePaths[i]);
    }
    // draw control panel and data
    drawControlPanel();
    redrawData = true;
  }
  
  /** method for switching years */
  void handleYearChange(boolean toNextYear) {
    currentTeamLeft = -1;
    currentTeamRight = -1;
    selectedYear = (toNextYear) ? years.getNext(selectedYear) : years.getPrev(selectedYear);
  }

  /** general method for mouse clicking the control panel
   * calls appropriate subrutine
   * changing settings redraws the control panel and data
   * assumtion: click was placed somewhere in the control area
   */
  void changeSettingsViaClick(int x, int y) {
    boolean clickMeaningful = false;
    // help button click
    if (isIn(x, screenWidth-210, screenWidth-210+180) &&
        isIn(y, screenHeight-60, screenHeight-60+30)) {
          clickMeaningful = true;
      helpDisplayed = !helpDisplayed;
    }
    if (helpDisplayed) {
      return;
    }
    // data slider click
    if (y < screenHeight-controlPanelHeight+sliderHeight) {
      clickMeaningful = true;
      dataSliderPosition = changeSliderPosition(x, screenWidth, dataSliderPosition);
    }
    // year buttons click
    int yearTopBox = (int) (screenHeight-controlPanelHeight+70);
    if ((isIn(x, 20, 40) && isIn(y, topYbuttons, topYbuttons+16)) ||
        (isIn(x, 130, 150) && isIn(y, topYbuttons, topYbuttons+16))) {
       clickMeaningful = true;
       handleYearChange((isIn(x, 130, 150) && isIn(y, topYbuttons, topYbuttons+16)));
     }
    // category selector click
    if (isIn(x, 180, 180+140) && 
        isIn(y, topYbuttons, topYbuttons+24.9*3)) {
      clickMeaningful = true;
      selectedCategories[(y-topYbuttons)/25] = !selectedCategories[(y-topYbuttons)/25];
    }
    // time slider click
    int sliderTopPos = screenHeight-controlPanelHeight+sliderHeight+sliderMargin/2;
    if (isIn(x, 350+sliderMargin, screenWidth-sliderMargin) && 
        isIn(y, sliderTopPos, sliderTopPos+sliderHeight)) {
      clickMeaningful = true;
      int relativeX = x-(350+sliderMargin);
      int barWidth = screenWidth-350-2*sliderMargin;
      currentTimePoint = (int)(301*changeSliderPosition(relativeX, barWidth, (float)currentTimePoint/301));
    }
    // speed slider click
    if (isIn(x, screenWidth-300+sliderMargin, screenWidth-sliderMargin) && 
        isIn(y, speedSliderY, speedSliderY+sliderHeight)) {
      clickMeaningful = true;
      int relativeX = x-(screenWidth-300+sliderMargin);
      globalAnimationSpeed = changeSliderPosition(relativeX, 300-2*sliderMargin, globalAnimationSpeed);
    }
    // animation start/stop/home/end click
    if (isIn(x, buttonsXbegin-buttonSpacing/2, buttonsXbegin+5*buttonSpacing/2) &&
        isIn(y, speedSliderY, speedSliderY+buttonSpacing) ) {
      clickMeaningful = true;
      switch ((int)((x-buttonsXbegin+buttonSpacing/2)/buttonSpacing)) {
        case 0: currentTimePoint = 0; break;
        case 1: animate = !animate; animateCounter = 0; break;
        case 2:
        case 3: currentTimePoint = 301; break;
        default: break;
      }
    }
    // stop at animation end click
    if (isIn(x, buttonsXbegin + 3.5*buttonSpacing, buttonsXbegin+7*buttonSpacing) &&
        isIn(y, speedSliderY, speedSliderY+buttonSpacing) ) {
      clickMeaningful = true;
      stopAtAnimationEnd = !stopAtAnimationEnd;
    }
    // if we clicked something meaningfull, redraw everything
    if (clickMeaningful) {
      drawControlPanel();
      redrawData = true;
    }
  }

  /** general method for keys pressed
   */
  void changeSettingsViaKey() {
    if (helpDisplayed) {
      if (keyCode == KeyEvent.VK_H) {
        helpDisplayed = false;
        // redraw everything
        drawControlPanel();
        redrawData = true;
      }
      return;
    }
    switch (keyCode) {
      case KeyEvent.VK_PAGE_DOWN:
      dataSliderPosition = min(dataSliderPosition+keySliderShift,1); break;
      case KeyEvent.VK_PAGE_UP:
      dataSliderPosition = max(dataSliderPosition-keySliderShift,0); break;
      case KeyEvent.VK_HOME:
      dataSliderPosition = 0; break;
      case KeyEvent.VK_END:
      dataSliderPosition = 1; break;
      case UP:
      currentTimePoint = min(currentTimePoint+keyTimeShift, 301); break;
      case DOWN:
      currentTimePoint = max(currentTimePoint-keyTimeShift, 0); break;
      case ENTER:
      case KeyEvent.VK_SPACE:
      animate = !animate; animateCounter = 0; break;
      case LEFT:
      currentTimePoint = 0; break;
      case RIGHT:
      currentTimePoint = 301; break;
      case KeyEvent.VK_N:
      handleYearChange(true);
      break;
      case KeyEvent.VK_P:
      handleYearChange(false);
      break;
      case KeyEvent.VK_S:
      globalAnimationSpeed = max(0, globalAnimationSpeed - 0.02);
      break;
      case KeyEvent.VK_F:
      globalAnimationSpeed = min(1, globalAnimationSpeed + 0.02);
      break;
      case KeyEvent.VK_E:
      stopAtAnimationEnd = !stopAtAnimationEnd;
      break;
      case KeyEvent.VK_H:
      helpDisplayed = !helpDisplayed;
      break;
      case KeyEvent.VK_1:
      selectedCategories[0] = !selectedCategories[0]; 
      break;
      case KeyEvent.VK_2:
      selectedCategories[1] = !selectedCategories[1]; 
      break;
      case KeyEvent.VK_3:
      selectedCategories[2] = !selectedCategories[2]; 
      break;
      default: return; // not meaningful, do not redraw
    }
    // redraw everything
    drawControlPanel();
    redrawData = true;
  }

  /** draw the control panel including data slider
   */
  void drawControlPanel() {
    // draw background
    int numImagesWidth = ceil((float)screenWidth/bgImage.width);
    for (int i = 0; i < numImagesWidth; i++) {
      image(bgImage, i*bgImage.width, screenHeight-controlPanelHeight);
    }

    // draw data slider
    drawSlider(0, screenHeight-controlPanelHeight, screenWidth, dataSliderPosition);
    
    // draw year chooser (0-150 pixels from left)
    fill(brownDark);
    textFont(fonts[1]);
    String text = "ročník";
    text(text, 85-textWidth(text)/2, screenHeight-controlPanelHeight+sliderHeight+20+textAscent()/2);
    textFont(fonts[0]);
    text = years.get(selectedYear).name;
    int yearTopBox = (int) (screenHeight-controlPanelHeight+70);
    text(text, 65, yearTopBox);
    drawButton(30, yearTopBox - 5, BUTTON_PREV);
    drawButton(140, yearTopBox - 5, BUTTON_NEXT);
    
    // draw categories chooser (150-350 pixels from left)
    fill(brownDark);
    textFont(fonts[1]);
    text = "kategorie";
    text(text, 250-textWidth(text)/2, screenHeight-controlPanelHeight+sliderHeight+20+textAscent()/2);
    textFont(fonts[0]);
    for (int i = 0; i < 3; i++) {
      drawBox(195, screenHeight-controlPanelHeight+70+i*25, selectedCategories[i]);
      switch (i) {
        case 0: text = "středoškoláci"; break;
        case 1: text = "vysokoškoláci"; break;
        case 2: text = "ostatní"; break;
      }
      text(text, 215, screenHeight-controlPanelHeight+70+i*25+textAscent()/2);
    }
    
    // draw time slider (350-screenWidth pixels from left)
    drawSlider(350+sliderMargin, screenHeight-controlPanelHeight+sliderHeight+sliderMargin/2, 
               screenWidth-350-2*sliderMargin, (float)currentTimePoint/301);
    fill(brownDark);
    textFont(fonts[0]);
    for(int hour = 0; hour <= 5; hour++) {
      text = "" + (hour+15) + ":00";
      int position = (int)map(hour, 0, 5, 350+sliderMargin, screenWidth-sliderMargin-textWidth(text));
      text(text, position, screenHeight-controlPanelHeight+2*sliderHeight+3*sliderMargin/4+textAscent());
    } 
    
    // draw speed slider ((screenWidth-300)-screenWidth pixels from left)
    fill(brownDark);
    textFont(fonts[1]);
    text = "rychlost";
    text(text, screenWidth-300+sliderMargin/2-textWidth(text), speedSliderY+textAscent());
    drawSlider(screenWidth-300+sliderMargin, speedSliderY, 300-2*sliderMargin, globalAnimationSpeed);
    
    // draw animation buttons
    fill(brownDark);
    textFont(fonts[1]);
    text = "časová osa";
    text(text, 350+sliderMargin, speedSliderY+textAscent());
    drawButton(buttonsXbegin, speedSliderY+boxSide/2, BUTTON_HOME);
    drawButton(buttonsXbegin + 2*buttonSpacing, speedSliderY+boxSide/2, BUTTON_END);
    if (animate) {
      drawButton(buttonsXbegin+buttonSpacing, speedSliderY+boxSide/2, BUTTON_PAUSE);
    } else {
      drawButton(buttonsXbegin+buttonSpacing, speedSliderY+boxSide/2, BUTTON_PLAY);
    }
    
    drawBox(buttonsXbegin + 4*buttonSpacing, speedSliderY+boxSide/2, stopAtAnimationEnd);
    String stopAtAnimationEnd = "skončit";
    text(stopAtAnimationEnd, buttonsXbegin + 5*buttonSpacing, speedSliderY+textAscent());
    
    stroke(brownMedium);
    rect(screenWidth-210, screenHeight-60, 180, 30);
    text("nápověda & zásluhy", screenWidth-195, screenHeight-52+textAscent());
  }
  
  /** general method for slider drawing
   * @param x              x of the upper left corner of the entire bar
   * @param y              y of the upper left corner of the entire bar
   * @param barWidth       width of the entire bar
   * @param position       slider position given in [0,1] including
   */
  void drawSlider(int x, int y, int barWidth, float position) {
    // draw bar
    noStroke();
    fill(red(brownLight), green(brownLight), blue(brownLight), 64);
    rect(x, y, barWidth, sliderHeight);
    // compute relative x slider position
    fill(red(brownLight), green(brownLight), blue(brownLight), 128);
    int sliderWidth = (int)(barWidth*sliderMoverRatio);
    float sliderCenter = map(position, 0, 1, sliderWidth/2, barWidth-sliderWidth/2);
    rect(x+sliderCenter-sliderWidth/2+sliderOffset, y+sliderOffset, 
         sliderWidth-2*sliderOffset, sliderHeight-2*sliderOffset);
  }
  
  /** general method for slider position changing
   * enables dragging if needed
   * @param relativeX      position of the click from the left side of slider bar
   * @param barWidth       width of the entire bar
   * @param position       original slider position given in [0,1] including
   * @return               new slider position in [0,1] including
   */
  float changeSliderPosition(int relativeX, int barWidth, float position) {
    int sliderWidth = (int)(barWidth*sliderMoverRatio);
    int currentSliderPosition = (int)map(position, 0, 1, sliderWidth/2, barWidth-sliderWidth/2);
    // enable dragging if necessary
    if (!dragging 
        && relativeX > currentSliderPosition-sliderWidth/2 
        && relativeX < currentSliderPosition+sliderWidth/2 ) {
      dragging = true;
      dragXOffset = relativeX - currentSliderPosition;
      return position;
    }
    // if clicked outside if the slider, reposition
    relativeX = constrain(relativeX, sliderWidth/2, barWidth-sliderWidth/2);
    return map(relativeX, sliderWidth/2, barWidth-sliderWidth/2, 0, 1);
  }
  
  /** general method for tick-box drawing
   * @param x         x coordinate of box center
   * @param y         y coordinate of box center
   * @param ticked    should tick be placed inside?
   */
  void drawBox(int x, int y, boolean ticked) {
    strokeWeight(2);
    stroke(brownDark);
    noFill();
    rect(x-boxSide/2, y-boxSide/2, boxSide, boxSide);
    strokeWeight(5);
    if (ticked) {
      line(x-boxSide/2, y, x-boxSide/8, y+boxSide/3);
      line(x+boxSide/2, y-boxSide/2, x-boxSide/8, y+boxSide/3);
    }
    noStroke();
  }
  
  /** general method for function circle drawing
   * @param x      x coordinate of top left corner  
   * @param y      y coordinate of top left corner
   * @param type   should the circle should be "ticked"
   */
  void drawCircle(int x, int y, boolean selected) {
    int strokeWeight = 2;
    strokeWeight(strokeWeight);
    stroke(brownDark);
    noFill();
    float radius = sqrt(pow(boxSide,2)+pow(boxSide,2))/2;
    ellipse(x-boxSide/2+radius-strokeWeight*3/2, y-boxSide/2+radius-strokeWeight*3/2, boxSide, boxSide);
    if (selected) {
      strokeWeight(3);
      fill(brownDark);
      ellipse(x-boxSide/2+radius-strokeWeight*3/2, y-boxSide/2+radius-strokeWeight*3/2, boxSide*2/5, boxSide*2/5);
    }
    noStroke();
  }
  
  /** general method for function button drawing
   * @param x      x coordinate of button center
   * @param y      y coordinate of button center
   * @param type   button type (see constants at top)
   */
  void drawButton(int x, int y, int type) {
    strokeWeight(2);
    stroke(brownDark);
    noFill();
    rect(x-boxSide/2, y-boxSide/2, boxSide, boxSide);
    fill(brownDark);
    noStroke();
    switch (type) {
      case BUTTON_PLAY: 
      triangle(x-boxSide/4,y-2*boxSide/6, x-boxSide/4,y+2*boxSide/6, x+2*boxSide/6,y); break;
      case BUTTON_PAUSE:
      rect(x-boxSide/4, y-2*boxSide/6, boxSide/4, 2*boxSide/3);
      rect(x+boxSide/8, y-2*boxSide/6, boxSide/4, 2*boxSide/3);
      break;
      case BUTTON_HOME:
      triangle(x+2*boxSide/6,y-2*boxSide/6, x+2*boxSide/6,y+2*boxSide/6, x-boxSide/6,y);
      rect(x-boxSide/6-boxSide/6, y-2*boxSide/6, boxSide/6, 2*boxSide/3);
      break;
      case BUTTON_END:
      triangle(x-2*boxSide/6,y-2*boxSide/6, x-2*boxSide/6,y+2*boxSide/6, x+boxSide/6,y);
      rect(x+boxSide/6, y-2*boxSide/6, boxSide/6, 2*boxSide/3);
      break;
      case BUTTON_NEXT:
      triangle(x-2*boxSide/6,y-2*boxSide/6, x-2*boxSide/6,y+2*boxSide/6, x+2*boxSide/6,y);
      break;
      case BUTTON_PREV:
      triangle(x+2*boxSide/6,y-2*boxSide/6, x+2*boxSide/6,y+2*boxSide/6, x-2*boxSide/6,y);
      break;
      default: break;
    }
    noFill();
  }
}

