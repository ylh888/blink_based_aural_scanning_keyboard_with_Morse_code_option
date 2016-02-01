/* CommBoard - aural 
 action
 0 means do nothing; go to next cell
 1 means pick the letter, either key itself or "substitute"; play sound
 2 means read the text back
 3 means erase text buffer
 4 means delete last char
 -- next 2 not implemented
 5 means in browser cycle
 6 means in email cycle
 --
 9 means pause for 3 minutes
 
 */
// present, wait for cbPeriod before moving to next item
int cbPeriod = 1450;   
int speed = 5;

//pause
int PAUSE_TIME = 60;

// if selected within debounce, consider it is intended for the previous item
int cbDebounce = 100; 
// right after an action, if not yet presented, then present it after this cbPresentLead period
int cbPresentLead = 1600;

// introduce a delay following 'select' action, to give pause
int afterSelectDelay = 800;

int lastPresented = 0;
int whenPaused = 0;

String buffer = new String();  // current buffer
int[] textBySound = new int[4000];
int howmany = 0; // this is dodgy way of tracking current buffer's length - YLH to fix

boolean presented=false;

JSONObject menuObj;
String curItem = "menu5", prevItem = "menu5";

void doCB() {
  int i;
  if ( pause ) return;

  if ( curItem.equals( "menu5" ) ) {  // re-assigning "menu5"
    if ( mode == REGULAR ) {
    } else if (mode == BROWSER) {
      curItem = "browsermenu";
      lastPresented = millis();
    } else if (mode == EMAIL) {
      curItem = "emailmenu";
      lastPresented = millis();
    }
  }

  if ( presented==false ) {
    if ( (millis() - lastPresented) > cbPresentLead ) {

      i=menuObj.getJSONObject( curItem ).getInt("sound");
      if ( announceon ) sounds[i].play();
      sounds[i].rewind();

      print(' '); 
      print(curItem);

      lastPresented = millis();
      presented = true;      
      selected = 0;
    }
    return;
  }

  if ( selected == 0 || selected == 2 ) { // go to next item
    if ( (millis() - lastPresented) > cbPeriod ) {
      lastPresented = millis();
      prevItem = curItem;
      curItem = menuObj.getJSONObject( curItem ).getString("Skip");
      i=menuObj.getJSONObject( curItem ).getInt("sound");
      if ( announceon ) sounds[i].play();
      sounds[i].rewind();

      print(' '); 
      //print(curItem);
    }
  } else { // selected
    selected = 0;  // unset it so the next round doesn't interfere
    if ( (millis() - lastPresented) < cbDebounce ) {
      // rewind to last pos
      curItem = prevItem;
    }
    lastPresented = millis();

    /*print("\nseleced in MODE "); 
     print(mode); 
     print(" item ");
     println(curItem);
     */
    //println(menuObj.getJSONObject( curItem ));

    switch (menuObj.getJSONObject( curItem ).getInt("action") ) { 
    case 0: // skip to next
      break;
    case 1: // pick this letter, add to text buffer
      if (voiceon) { // feedback
        i=menuObj.getJSONObject( curItem ).getInt("sound");
        sounds[i].play();
        sounds[i].rewind();
      }
      pick(); 
      break;
    case 2: // read text from buffer
      readIt(); 
      //readBuffer();
      //readByGoogle();
      // readByEspeak();
      break;
    case 3: // retrieve last line from textlines, store in buffer
      retrieveLine();
      break;
    case 4: // delete char
      deleteChar(true);
      break;
    case 44: // delete word
      deleteWord();
      break;
    case 444: // erase text buffer
      eraseBuffer();
      break;
    case 5:
       /*// go to browser
      if (voiceon) { // feedback
        i=menuObj.getJSONObject( curItem ).getInt("sound");
        sounds[i].play();
        sounds[i].rewind();
      }
      doBrowser();
      mode = BROWSER;
      */
      break;
    case 6: // go to email
      if (voiceon) { // feedback
        i=menuObj.getJSONObject( curItem ).getInt("sound");
        sounds[i].play();
        sounds[i].rewind();
      }
      /*
      doMail();
      mode = EMAIL;
      */
      break;
    case 8:
      inputType = MORSE;
      firstTimeMorse = millis();
      morseStr="";

      MARK = TRANSIT = false;
      wroteSpace = true; // steady state
      timeLapse = 0;
      lastTransit = millis()+ 1*seconds;
      i=menuObj.getJSONObject( "use_morse" ).getInt("sound");
      if ( announceon ) sounds[i].play();
      sounds[i].rewind();

      break;
    case 9:
      prevItem = "pause";
      pauseFor( PAUSE_TIME*seconds, true );    

      break;
    case 99:
      buzzAlarm.on(5000);
      pauseFor(5000, false);
      println("ALARM0"); 
      break;
    } 
    // regular CB funcitons
    // go to next item - but do not present
    /* if ( !inEmail) {
     //curItem = menuObj.getJSONObject( curItem ).getString("doNext");
     }
     */
    if ( 0 == menuObj.getJSONObject( curItem ).getInt("action")) { // 'no action' done
      lastPresented = millis() ;
    } else { // slow down after select
      lastPresented = millis() + afterSelectDelay;
    }
    curItem = menuObj.getJSONObject( curItem ).getString("doNext");

    presented = false;
    //lastPresented = millis() + afterSelectDelay;

    selected = 0;
  }
}

void pick() {

  switch (mode) {
  case REGULAR:
    // pick up the substitue text, or, if it does not exist, the key itself as literal
    buffer += menuObj.getJSONObject( curItem ).getString("substitute", curItem);
    textBySound[howmany] = menuObj.getJSONObject( curItem ).getInt("sound");
    howmany++;
    //println( buffer );
    break;
  case BROWSER:
    //print("X");
    if ( curItem.equals("return") ) {

    } else if (curItem.equals("pagedown") ) {
      robot.keyPress(KeyEvent.VK_SPACE);
      robot.keyRelease(KeyEvent.VK_SPACE);
    } else if ( curItem.equals("pageup") ) {
      robot.keyPress(KeyEvent.VK_SHIFT);
      robot.keyPress(KeyEvent.VK_SPACE);
      robot.keyRelease(KeyEvent.VK_SPACE);
      robot.keyRelease(KeyEvent.VK_SHIFT);
    } else if ( curItem.equals("pageback") ) {
      commandType("[[");
    } else if ( curItem.equals("pageforward") ) {
      commandType("]]");
    } else if ( curItem.equals("url") ) {
      robot.keyPress(KeyEvent.VK_META);
      robot.keyPress(KeyEvent.VK_L);
      robot.keyRelease(KeyEvent.VK_L);
      robot.keyRelease(KeyEvent.VK_META);
    } else if ( curItem.equals("tab") ) {
      robot.keyPress(KeyEvent.VK_TAB);
      robot.keyRelease(KeyEvent.VK_TAB);
    } else if ( curItem.equals("endbrowser") ) {
      robot.keyPress(KeyEvent.VK_META);
      robot.keyPress(KeyEvent.VK_W);
      robot.keyRelease(KeyEvent.VK_W);
      robot.keyRelease(KeyEvent.VK_META);
      mode = REGULAR;
      //curItem = prevItem = "menu5";
    } else {
      type(menuObj.getJSONObject( curItem ).getString("substitute", curItem));
    }
    delay(20);
    break;
  case EMAIL:
    break;
  }
}

// not used!!!
void readBuffer() {
  int wait = 800;
  int lastSaid = 0;
  lastPresented = millis();
  int i = 0;
  buzzDot.off();

  while (true) {
    if (i== howmany) break;
    while ( (millis ()-lastSaid) < wait ) {
      lastPresented = millis();
    }
    if ( announceon ) sounds[textBySound[i]].play(); 
    sounds[textBySound[i]].rewind();

    lastSaid = millis();
    i++;
  }
}

void eraseBuffer() {
  buffer = "";
  howmany = 0;
}
void deleteWord() {
  howmany = buffer.length();
  if ( howmany == 0 ) return;
  do {
    deleteChar(false);
    //howmany--;
  } 
  while ( howmany>0 && buffer.charAt (howmany-1) != ' ' );
  /*
  int i=menuObj.getJSONObject( "word_deleted" ).getInt("sound");
   if ( announceon ) sounds[i].play();
   sounds[i].rewind();
   */
  sayWords("word_deleted");
}

void deleteChar(boolean on) {  // voice feedback?
  //howmany = buffer.length()-1;
  howmany = buffer.length();
  if (howmany<=0) {
    howmany=0;
    return;
  }

  buffer = buffer.substring( 0, --howmany);
  if ( on ) sayWords("letter_deleted");
}

void doCBInit() {

  menuObj = loadJSONObject("menu.json");

  java.util.Iterator itr = menuObj.keyIterator();

  int nItems=1;
  while (itr.hasNext ()) {
    itr.next();
    nItems++;
  }

  gMinim = new Minim( this );
  sounds = new AudioPlayer[nItems];

  int idx = 0;
  String ky;
  itr = menuObj.keyIterator();
  while (itr.hasNext ()) {
    ky = (String) itr.next();
    print(ky); 
    print(": ");
    JSONObject item = menuObj.getJSONObject(ky);
    sounds[idx] = gMinim.loadFile("en_" + ky + ".mp3");
    item.setInt("sound", idx);
    menuObj.setJSONObject(ky, item);

    idx++;
  }

  saveJSONObject( menuObj, "data/menu1.json");
}

void slower() {
  if ( inputType == MORSE ) {
    units +=50;
    if ( units > 600 ) units = 600;
    morseSpeed = (600 - units)/50;
    return;
  }

  // adjust all other input types here
  cbPeriod +=150;
  if ( cbPeriod > 2200 ) cbPeriod = 2200;
  speed = (2200 - cbPeriod)/150;
}

void faster() {
  if ( inputType == MORSE ) {
    units -=50;
    if ( units < 100 ) units = 100;
    morseSpeed = (600 - units)/50;
    return;
  }
  // adjust all other input types here
  cbPeriod -=150;
  if ( cbPeriod < 700 ) cbPeriod = 700;
  speed = (2200 - cbPeriod)/150;
}

