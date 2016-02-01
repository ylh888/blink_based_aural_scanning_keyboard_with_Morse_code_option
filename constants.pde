// UI variables
// when announceon = false, no announcement is made, used with sound on to practice blink
boolean announceon = true;  
// soundon - beeps on "Yes"
boolean soundon = false;
// voiceon - voice feedback on select
boolean voiceon = true;
// pause operations
boolean pause = false;
boolean callbellReady = true;

// MODE variables
// enum for the variable 'mode'
final int REGULAR = 0;  
final int BROWSER = 1;
final int EMAIL = 2;
int mode = REGULAR; // 0=regular aural keyboard; 1=browser; 2=emailpp

// enum for the variable 'inputType'
final int MORSE = 1; 
int inputType = REGULAR;

// morse - is current scene MARK or Space?
boolean MARK = false;

// MESSAGE BUFFER
// message store
final int MaxLines = 12;
String[] textlines = new String[MaxLines+1];
int currentLine = 0;
final int bufferY = 285;


final int FRAME_RATE = 15; // normal running frame rate to return to, from slower resting state

