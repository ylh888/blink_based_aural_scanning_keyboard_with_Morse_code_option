/* morse code decoder: 20150304
 
 Morse:
 - the length a dot is one unit
 - a dash = 3 units
 - space between parts of the same letter is one unit
 - space between letters is 3 units
 - space between words is 10 units (standard==7)
 
 special Morse
 - 6 dots for switching back to scanning mode
 
 inDelete state
 0 - deleted buffer char and current morseStr
 1 - (if more del, then delete previous word)
 */

int inDelete = 0;  
int morseSpeed = 4;
int units = 400;  // morse units

boolean wroteSpace = true; // write only one ' ' letter
int firstTimeMorse = 0;
String morseStr = "";

int lastTransit = 0;
int timeLapse = 0;
boolean TRANSIT = false;

void doMorse() {
  int sinceTransition = (millis() - lastTransit);

  if ( pause ) return;

  // mark =============
  if (MARK) {  
    print("M");
    if (TRANSIT) {  // after transition to mark (uptick) => deal with SPACE here
      //seenTransit = lastTransit;
      println("-T*");
      print(timeLapse); 
      print("* c=");
      print(morseStr); 

      if ( timeLapse > 7*units ) {
        /* 2015-05-12 --- what if we dont add space here
        if ( !wroteSpace) {
          processLetter(); // first process letter, than add space
          if ( buffer.length() > 0 && buffer.charAt( buffer.length()-1) != ' ') {
            buffer += " ";
            //ylh delay(500);
            howmany = buffer.length();

            int i = menuObj.getJSONObject( "space" ).getInt("sound");
            textBySound[howmany-1] = i;
            if ( voiceon ) { 
              sounds[i].play();
              sounds[i].rewind();
            }
          }
          wroteSpace = true;
          
        }
        */
      } else if ( timeLapse > 3*units ) { // space between letters
        processLetter();
        //wroteSpace = false;
      } else {  // very short space - it is part of a letter; dealt with by space
        //
      }
    } else {  // very long mark - short marks are handled by SPACE
      if ( sinceTransition > alarmThreshold ) {   //alarm
        buzzAlarm.on(2000);
        lastTransit = millis(); // reset
        timeLapse = 0;
        pauseFor( 2000, false);
        println("ALARM1");
      }
    }
  } else { 
    print("S");
    // space =============
    if (TRANSIT) {  // after transition to space (downtick) => deal with MARK here

      println("-T*");
      print(timeLapse); 
      print("* c=");
      print(morseStr); 
      if ( timeLapse > alarmThreshold ) {   // alarm - should not see here
        buzzAlarm.on(2000);
        pauseFor(2000, false);
        timeLapse = 0;
        morseStr="";
        println("ALARM2");
      } else if ( timeLapse > 7*units ) {
        processDel();
      } else if ( timeLapse > 3*units  ) {
        morseStr += "-";
        inDelete = 0;  //ylh
        if ( voiceon ) buzzDash.on(200);
      } else {  // if ( yesCount > 0 ) {
        morseStr += ".";
        if ( voiceon ) buzzDot.on(100);
        inDelete = 0;  //ylh
      }
      wroteSpace = false;

      println();
      print("<< C="); 
      print(morseStr); 
      print("| t="); 
      println(buffer);
    } else {  // handle very long SPACE here - short spaces handled by Mark uptick
      if ( sinceTransition > 10*units ) { // was 10 units
        if ( !wroteSpace) {  
          processLetter(); // first process letter, than add space     
          if ( buffer.length() > 0 && buffer.charAt( buffer.length()-1) != ' ') { 
            buffer += " ";
            delay(500);
            howmany = buffer.length();

            int i = menuObj.getJSONObject( "space" ).getInt("sound");
            textBySound[howmany-1] = i;
            if ( voiceon ) { 
              sounds[i].play();
              sounds[i].rewind();
            }
          }
        }
        wroteSpace = true;
      } else if ( sinceTransition > 3*units ) { // space between letters
        processLetter();
        //wroteSpace = false;
      } else {  // very short space - it is part of a letter; dealt with by mark
        //
      }
      
    }
  }
  if ( TRANSIT ) {
    TRANSIT = false;
    lastTransit = millis();
  }
}

void processDel() {
  print("DEL"); 
  print(inDelete); 
  print(" ");

  morseStr = "";

  if ( inDelete == 1 ) { //delete word here
    if (buffer == null || buffer.length() == 0) {
      inDelete = 0;  // no more letters
      return;
    } 
    while (buffer.length ()>0 && buffer.charAt (buffer.length()-1) != ' ') {
      buffer = buffer.substring(0, buffer.length()-1);
      howmany = buffer.length();
    }
    int i=menuObj.getJSONObject( "word_deleted" ).getInt("sound");
    if ( voiceon ) sounds[i].play();
    sounds[i].rewind();
    inDelete = 0;
    return;
  }

  if ( inDelete == 0 ) { //delete char here
    if (buffer == null || buffer.length() == 0) {
      inDelete = 0;  // no more letters
      return;
    } else {
      buffer = buffer.substring(0, buffer.length()-1);
      howmany = buffer.length();
      int i=menuObj.getJSONObject( "letter_deleted" ).getInt("sound");
      if ( voiceon ) sounds[i].play();
      sounds[i].rewind();
    } 
    inDelete = 1;
    return;
  } 

  // inDelete == 0; delete morse letter here, but if no morse then delete char
  // YLH - drop current morseStr and del one char
  /*
  if (morseStr == null || morseStr.length() == 0) {
   inDelete = 1;
   processDel();
   return;
   } else {
   morseStr = morseStr.substring(0, morseStr.length()-1);
   if ( voiceon) buzzAlarm.on(100);
   }
   
   inDelete = 1;
   */
}

void processLetter() {
  if ( morseStr.length() == 0 || morseStr == null ) return;
  procLetter();
}

void procLetter() {
  print("| L-m=|");
  print(morseStr);
  print(" L=");
  String m=toLetter(morseStr);
  if ( m.length() == 0 ) {
    // no match
    print(" NOMATCH ");
    if (voiceon ) {
      int i=menuObj.getJSONObject( "no_match" ).getInt("sound");
      sounds[i].play();
      sounds[i].rewind();
    }
  } else {
    print(m);
    if ( m.equals("use_scanning")) {
      inputType = REGULAR;
      lastPresented = millis(); // + 2*seconds;
      firstTimeMorse = millis();
      MARK = TRANSIT = false;

      pauseFor(1000, false);

      /*int i=menuObj.getJSONObject( "use_scanning" ).getInt("sound");
       if ( voiceon ) sounds[i].play();
       sounds[i].rewind();
       */
      sayWords(m);

      wroteSpace = true;
      morseStr = "";
      return;
    }
    buffer += m; 
    if ( m.equals( "\"" )) {
      m = "quote";
    } else if ( m.equals( "'" )) {
      m = "apostrophe";
    } else if ( m.equals( ":" )) {
      m = "solon";
    } else if ( m.equals( ";" )) {
      m = "semicolon";
    } 
    howmany = buffer.length();
    int i=menuObj.getJSONObject( m ).getInt("sound");
    sayWords( m );

    textBySound[howmany-1] = i;
    /*
    if ( voiceon ) sounds[i].play();
     sounds[i].rewind();
     */
    print(buffer);
    println("<<");
  }
  morseStr="";
}

// https)) {//github.com/chester1000/MorseConverter/blob/master/src/pl/d30/Ex14_6/Morse.java
String toLetter(String s) {        
  if ( s.equals( ".")) { 
    return "e";
  } else if ( s.equals( "..")) { 
    return "i";
  } else if ( s.equals( "...")) { 
    return "s";
  } else if ( s.equals( "....")) { 
    return "h";
  } else if ( s.equals( "...-")) { 
    return "v";
  } else if ( s.equals( "..-")) { 
    return "u";
  } else if ( s.equals( "..-.")) { 
    return "f";
  } else if ( s.equals( ".-")) { 
    return "a";
  } else if ( s.equals( ".-.")) { 
    return "r";
  } else if ( s.equals( ".-..")) { 
    return "l";
  } else if ( s.equals( ".--")) { 
    return "w";
  } else if ( s.equals( ".--.")) { 
    return "p";
  } else if ( s.equals( ".---")) { 
    return "j";
  } else if ( s.equals( "-")) { 
    return "t";
  } else if ( s.equals( "-.")) { 
    return "n";
  } else if ( s.equals( "-..")) { 
    return "d";
  } else if ( s.equals( "-...")) { 
    return "b";
  } else if ( s.equals( "-..-")) { 
    return "x";
  } else if ( s.equals( "-.-")) { 
    return "k";
  } else if ( s.equals( "-.-.")) { 
    return "c";
  } else if ( s.equals( "-.--")) { 
    return "y";
  } else if ( s.equals( "--")) { 
    return "m";
  } else if ( s.equals( "--.")) { 
    return "g";
  } else if ( s.equals( "--..")) { 
    return "z";
  } else if ( s.equals( "--.-")) { 
    return "q";
  } else if ( s.equals( "---")) { 
    return "o";
  } else if ( s.equals( ".....")) {
    return "5";
  } else if ( s.equals( "....-")) {
    return "4";
  } else if ( s.equals( "...--")) {
    return "3";
  } else if ( s.equals( "..--..")) {
    return "?";
  } else if ( s.equals( "..--.-")) {
    return "_";
  } else if ( s.equals( "..---")) {
    return "2";
  } else if ( s.equals( ".-..-.")) {
    return "\"";
  } else if ( s.equals( ".-.-.")) {
    return "+";
  } else if ( s.equals( ".-.-.-")) {
    return ".";
  } else if ( s.equals( ".--.-.")) {
    return "@";
  } else if ( s.equals( ".----")) {
    return "1";
  } else if ( s.equals( ".----.")) {
    return "'";
  } else if ( s.equals( "-....")) {
    return "6";
  } else if ( s.equals( "-....-")) {
    return "-";
  } else if ( s.equals( "-..-.")) {
    return "/";
  } else if ( s.equals( "-.-.-.")) {
    return ";";
  } else if ( s.equals( "-.-.--")) {
    return "!";
  } else if ( s.equals( "--...")) {
    return "7";
  } else if ( s.equals( "--..--")) {
    return ",";
  } else if ( s.equals( "---..")) {
    return "8";
  } else if ( s.equals( "---...")) {
    return ")) {";
  } else if ( s.equals( "----.")) {
    return "9";
  } else if ( s.equals( "-----")) {
    return "0";
  } else if ( s.equals( "......")) { // special - switch back to scanning
    return "use_scanning";
  }
  return "";
}

