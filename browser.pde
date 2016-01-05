/* browser - safari 
 mode = BROWSER
 action = 5
 */

void doBrowser() {
  lastPresented = millis()+1000;
  /*
  try {
    //Runtime.getRuntime().exec("open /Applications/Safari.app");
    delay(300);
    println("START_browser");
    
  } 
  catch (IOException ex) {
    println(ex.toString());
  }
  */
}
/*
void quitBrowser() {
   lastPresented = millis()+1000;
   try {
    Runtime.getRuntime().exec("open /Applications/Safari.app");
    commandType("w");
    println("QUIT_browser");
    delay(100);
  } 
  catch (IOException ex) {
    println(ex.toString());
  }
}

*/
