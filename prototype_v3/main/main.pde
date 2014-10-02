/*  Pratik Parija & Raymond Chu
    Media in Game Design
    Assignment 3: Team-Based Prototype
    Welcome to Poly, Enjoy Your Stay!
*/

// DISCLAMER: My code is very sloppy, as usual... QQ

/*===== CONSTANTS =====*/
int WIDTH = 1080;
int HEIGHT = 720;

PFont font;
PImage player;

PImage relationship;
PImage intelligence;
boolean wentToClass = false;

BufferedReader map;
int TILES_NUM = 6;
PImage floor[]  = new PImage[TILES_NUM];
String floorPaths[] = {"floor.png", "table.png", "chair-1.png", "door-front.png", "Table-long.png", "door-front2.png"};

int NPCS_NUM = 5;
PImage npc[] = new PImage[NPCS_NUM];
String npcPaths[] = {"npc_01.png", "npc_02.png", "npc_03.png", "npc_04.png", "npc_05.png"};
BufferedReader stories[] = new BufferedReader[NPCS_NUM+1];
String storyPaths[] = {"npc1.txt", "npc2.txt", "npc3.txt", "npc4.txt", "npc5.txt", "edu.txt"};
int talkingNum = -1; // who the player is talking to

int TILE_ROWS = 50;
int TILE_COLUMNS = 50;
int tiles[][] = new int[TILE_ROWS][TILE_COLUMNS];

String playerStrings[] = {
"chars_01.png", "chars_02.png", "chars_03.png", "chars_04.png", 
"chars_05.png", "chars_06.png", "chars_07.png", "chars_08.png", 
"chars_09.png", "chars_10.png", "chars_11.png", "chars_12.png", 
"chars_13.png", "chars_14.png", "chars_15.png", "chars_16.png"};
int player_direction = 0; // down = 0, left = 1, right = 2, up = 3
int playerRoll = 0;
int PLAYER_SPRITECHANGE = 3;
int sprite_counter = 0;
int playerStartX;
int playerStartY;

float X_START = WIDTH*0.5;
float Y_START = HEIGHT*0.5;
float x_tilt = 0;
float y_tilt = 0;
float rollingX = 6;
float rollingY = 6;

String rollingText = ""; // text to roll
String rolling_buffer = ""; // a buffer displaying the characters already rolled out
int TEXTROLL_INTERVAL = 1; // how many frames it takes for a letter to roll
int textroll_count; // used for keeping track of the interval
boolean isPrompt = false; // prompt messages do not get rolling text
boolean readyNext = true;

int response = -1; // -1 is NORMAL, 0 is WAITING, 1 is UP, 2 is DOWN

int finishTalking = 0;
int FLASH_INTERVAL = 30;
int FLASH_HEIGHT = 30;
boolean isRelationship = true;

void setup() {
  size(WIDTH, HEIGHT);
  
  font = createFont("EightBit.tff", 28);
  textFont(font, 28);
  
  relationship = loadImage("relationship.png");
  intelligence = loadImage("intelligence.png");
 
  
  for (int i = 0; i < TILES_NUM; ++i) {
    floor[i] = loadImage(floorPaths[i]);
  }
  for (int i = 0; i < NPCS_NUM+1; ++i) {
    if (i != NPCS_NUM) npc[i] = loadImage(npcPaths[i]);
    stories[i] = createReader(storyPaths[i]);
  }
  
  map = createReader("map.txt");
  String line;
  for (int i = 0; i < TILE_ROWS; ++i) {
    try {
      line = map.readLine();
    } catch (IOException e) {
      e.printStackTrace();
      line = null;
      return;
    }
    
    for (int j = 0; j < TILE_COLUMNS; ++j) {
      char s = line.charAt(j);
      if (s == 'X') {
        tiles[i][j] = -1;
      } else if (s == ' ') {
        tiles[i][j] = 0;
      } else if (s == 'T') {
        tiles[i][j] = 1;
      } else if (s == 'C') {
        tiles[i][j] = 2;
      } else if (s == '^') {
        tiles[i][j] = 3;
      } else if (s == 'P') {
        tiles[i][j] = 4;
      } else if (s == 'E') {
        tiles[i][j] = 5;
      } else if (s == 'M') {
        playerStartX = i;
        playerStartY = j;
        tiles[i][j] = 0;
      }
      
      else if (s == '0') {
        tiles[i][j] = 10;
      } else if (s == '1') {
        tiles[i][j] = 11;
      } else if (s == '2') {
        tiles[i][j] = 12;
      } else if (s == '3') {
        tiles[i][j] = 13;
      } else if (s == '4') {
        tiles[i][j] = 14;
      }
    }
  }
}

void draw() {
  background(175, 255, 106);
  displayFloor();
  
  player = loadImage(playerStrings[4*player_direction+playerRoll]);
  image(player, X_START-5, Y_START-10, 40, 40);
  
  drawTextBox();
  
  stroke(50);
  fill(0);
  handleNpcTalk();
  rollText();
  
  statusShower();
}

void statusShower() {
  if (finishTalking == 0) return;
  if (finishTalking == FLASH_INTERVAL && !isRelationship && !wentToClass) {
    finishTalking = 0;
  }
  float fraction = ((float) finishTalking)/FLASH_INTERVAL;
  int alpha = (int) (fraction * 255);
  tint(255, alpha);
  if (isRelationship) {
    image(relationship, width*0.5-10, height*0.5-25 + (int)fraction*FLASH_HEIGHT, 48, 20);
  } else {
    image(intelligence, width*0.5-10, height*0.5-25 + (int)fraction*FLASH_HEIGHT, 48, 20);
  }
  noTint();
  
  --finishTalking;
  wentToClass = false;
}

void displayFloor() {
  float tables[][] = {{-1, -1, -1}, {-1, -1, -1}};
  float npcs[][] = new float[NPCS_NUM][3];
  for (int i = 0; i < NPCS_NUM; ++i) {
    for (int j = 0; j < 3; ++j) {
      npcs[i][j] = -1;
    }
  }
  
  
  for (int row = 0; row < TILE_ROWS; ++row) {
   float yCor = Y_START + (row - playerStartX) * 30;
   yCor += y_tilt;
   if (yCor+30 < 0 || yCor > HEIGHT) continue;
   for (int column = 0; column < TILE_COLUMNS; ++column) {
     if (tiles[row][column] < 0) continue;
     
     float xCor = X_START + (column - playerStartY) * 30;
     xCor += x_tilt;
     if (xCor+30 < 0 || xCor > WIDTH) continue;
     
     int index = tiles[row][column];
     if (index == 1) {
       tables[0][0] = xCor; tables[0][1] = yCor; tables[0][2] = 1;
     } else if (index == 4) {
       tables[1][0] = xCor; tables[1][1] = yCor; tables[1][2] = 4;
       image(floor[0], xCor, yCor, 30, 30);
     } else if (index >= 10 && index < 10 + NPCS_NUM) {
       npcs[index-10][0] = xCor; npcs[index-10][1] = yCor; npcs[index-10][2] = index-10;
       image(floor[0], xCor, yCor, 30, 30);
     } else {
       image(floor[0], xCor, yCor, 30, 30);
       if (index != 0) image(floor[index], xCor, yCor, 30, 30);
     }
   }
  }
  
  for (int i = 0; i < 2; ++i) {
    if (tables[i][0] != -1) image(floor[(int)tables[i][2]], tables[i][0], tables[i][1], 30*3, 30*6);
  }
  for (int i = 0; i < NPCS_NUM; ++i) {
    if (npcs[i][0] != -1) image(npc[(int)npcs[i][2]], npcs[i][0]+2, npcs[i][1]-10, 26, 40);
  }
}

void drawTextBox() {
  stroke(50);
  strokeWeight(4);
  fill(255);
  rect(width*0.01, height*0.90, width*0.98, height*0.09);
}

void keyPressed() {
  if (talkingNum < 0) {
    if (keyCode == UP) {
      rollScreen(0, rollingY);
      spriteRoller(3);
    } else if (keyCode == DOWN) {
      rollScreen(0, -rollingY);
      spriteRoller(0);
    } else if (keyCode == RIGHT) {
      rollScreen(-rollingX, 0);
      spriteRoller(2);
    } else if (keyCode == LEFT) {
      rollScreen(rollingX, 0);
      spriteRoller(1);
    } else if (key == ' ') {
      talk();
    }
    return;
  }
  
  if (response == 0) {
    if (keyCode == UP) {
      response = 1;
      wentToClass = true;
    } else if (keyCode == DOWN) {
      response = 2;
      wentToClass = false;
    }
    return;
  }
  
  if (key == ' ') readyNext = true;
}

void spriteRoller(int dir) {
  if (dir != player_direction) {
    player_direction = dir;
    playerRoll = 0;
    sprite_counter = 0;
    return;
  }
  if (++sprite_counter % PLAYER_SPRITECHANGE == 0) {
    playerRoll = (playerRoll + 1) % 4;
  }
}

void rollScreen(float x, float y) {
  int new_y = (int) -(x_tilt + x)/30;
  new_y += playerStartY;
  int new_x = (int) -(y_tilt + y)/30;
  new_x += playerStartX;
  if (tiles[new_x][new_y] != 0) return;
  x_tilt += x;
  y_tilt += y;
}

void setText(String text) {
  rolling_buffer = (isPrompt) ? text : "";
  textroll_count = 0;
  rollingText = text;
}

void rollText() {
  if (isPrompt) {
    text(rollingText, width*0.03, height*0.96);
    return;
  }
  
  if (rollingText == "") return;
  
  if (rolling_buffer == rollingText) {
    
  } else if (++textroll_count % TEXTROLL_INTERVAL == 0) {
    rolling_buffer = rollingText.substring(0, rolling_buffer.length()+1);
  }
  
  text(rolling_buffer, width*0.03, height*0.96);
}

boolean textReady() {
  return (rollingText == "" || rolling_buffer == rollingText);
}

int getCurrentTileX() {
  int new_x = (int) -y_tilt/30;
  return new_x + playerStartX;
}

int getCurrentTileY() {
  int new_y = (int) -x_tilt/30;
  return new_y + playerStartY;
}

void talk() {
 int x = getCurrentTileX();
 if (player_direction == 0) ++x; else if (player_direction == 3) --x;
 int y = getCurrentTileY();
 if (player_direction == 1) --y; else if (player_direction == 2) ++y;
 
 int target = tiles[x][y];
 if (target == 5) {
   talkingNum = NPCS_NUM;
 }
 if (target < 10 || target >= 10+NPCS_NUM) return;
 
 talkingNum = target-10;
}

void handleNpcTalk() {
 if (talkingNum < 0) return;
 if (!textReady()) return;
 if (!readyNext) return;
 if (response == 0) return;
 
 isPrompt = false;
 
 String line;
 try {
   line = stories[talkingNum].readLine();
 } catch (IOException e) {
   e.printStackTrace();
   line = null;
 }
 
 if (line == null) {
   stories[talkingNum] = createReader(storyPaths[talkingNum]);
   isRelationship = (talkingNum == NPCS_NUM) ? false : true;
   talkingNum = -1;
   setText(" ");
   finishTalking = FLASH_INTERVAL;
   return;
 }
 
 char s = line.charAt(0);
 if (s == '>') {
   String accum = line.substring(1) + "     ";
   try {
    line = stories[talkingNum].readLine();
   } catch (IOException e) {
    e.printStackTrace();
    line = null;
   }
   accum += line.substring(1);
  
   response = 0;
   textSize(20);
   isPrompt = true;
   setText(accum);
   textSize(28);
   return;
 } else if (s == '!' && response > 0) {
   if (response == 2) {
     try {
       line = stories[talkingNum].readLine();
     } catch (IOException e) {
       e.printStackTrace();
       line = null;
     }
   } else if (response == 1) {
     try {
       stories[talkingNum].readLine();
     } catch (IOException e) {
       e.printStackTrace();
       line = null;
     }
   }
   
   line = line.substring(1);
 }
 
 readyNext = false;
 setText(line);
}
