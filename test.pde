
byte[] buff = new byte[1024];

 Runtime r;

void testSetup() {

  try {
    robot = new Robot();
  } 
  catch (java.awt.AWTException ex) { 
    println("Problem initializing AWT Robot: " + ex.toString());
  }

  launchEmail();
  delay( 200 );
  //type("ipp");

 //if (true) return;

  try {
    String[] args1 = {
      "open", "/usr/local/bin/alpine"
      //"open /Applications/Safari.app"
      //"open", "/Applications/iterm.app", "alpine"
    };
    r = Runtime.getRuntime();
    mailProcess = r.exec(args1);

    
    //Runtime.getRuntime().exec("open /Applications/Safari.app");
     //http://www.ask-coder.com/1527922/java-file-redirection-both-ways-within-runtime-exec
     //   Process proc = Runtime.getRuntime().exec("...");
     toMail = mailProcess.getOutputStream();
     
     buff[0] = 'a';
     buff[1] = 'l';
     buff[2] = 'p';
     buff[3] = 'i';
     buff[4] = 'n';
     buff[5] = 'e';
     buff[6] = '\n';
     
     delay(1000);
     buff = "ippnn".getBytes();
     /*
     //type("wq");
     println( buff );
     
     toMail.write(buff, 0, 10);
     toMail.flush();
     */
     delay(500);
     
  }
  catch (IOException ex) {
    println(ex.toString());
  }

  println( "Robot initialized; Alpine launched");
}

int iter =0;
void testDraw() {

  //if(true) return;

  delay(1000);
  switch (iter) {
  case 0:
    switchToEmail("i");
    //type("i");
    break;
  case 1:
  case 2:
        switchToEmail("p");
    //type("p");
    break;
  case 3:
  case 4:
       switchToEmail("n");
    // type("n");
    break;
  case 5:
    println("revert");
    iter = 0;
    break;
  }
  iter++;
}


void testKeyPressed() {
  switchToEmail("p");
  //type("p");
  println("keypres");

  if (true) return;

  buff = String.valueOf(key).getBytes();
  robot.keyPress(KeyEvent.VK_ENTER);
  robot.keyRelease(KeyEvent.VK_ENTER);
  /*
  try {
   toMail.write(buff, 0, 1);
   }
   catch (IOException ex) {
   println(ex.toString());
   }
   */

  switch( key) {
  }
}

void switchToEmail(String str) {
  try {

    Runtime.getRuntime().exec( "/usr/bin/osascript -e 'tell application \"Terminal\" to activate'");
    //toMail.write(buff, iter, 1);
    //toMail.flush();
    
    type( str );
    delay(100);
  } 
  catch (IOException ex) {
    println(ex.toString());
  }
  println("to email");
}

void launchEmail() {
  switchToEmail(" ");

  try {
    Runtime.getRuntime().exec("open /usr/local/bin/alpine");
    delay(100);
  } 
  catch (IOException ex) {
    println(ex.toString());
  }
}

