## Blink-based Aural Scanning Keyboard with Morse Code option


Using a simple template matching technique, this Processing-based app makes it possible to type text using blinks only. The app distinguishes 3 types of eye patterns that are registered at initialization: normal, action, extra-action (corresponding, typically, to a normal eye gaze, eye rolled-up, and eye shut).

An earlier version uses webcam, and is demonstarted here: 
https://www.youtube.com/watch?v=1--6nZVQz3c

The latest version uses closely mounted USB borescope that looks at the eye. No video demo yet.

The user is prompted with the **row** number (row of letters) and, on blink ("action" pattern), then individual letters within that row. 

Row 5 is used for additional letters/functions (see Manual).

Optionally, the user may enter into Morse mode where she could blink the letters using Morse Code convention. To get back to normal aural scanning mode, a 6-dot blink should be used.

The entered text is stored in a buffer of 20 lines. The current line is automatically stored when it is more than a number of letters (the last being a 'space' letter). The stored lines maybe pulled back (last-in first-out) into the current line for editing.

The app has option for sounding a bell.

### Installation

1. You need the [Processing environment](https://processing.org/)
2. Within Processing, add the following libraries: **OpenCV**, **minim**
3. Install [eSpeak](http://espeak.sourceforge.net/) for speech (text reading).

It is also possible to get a pre-compiled version for OSX and Windows 64.

### Menu layout

The menu interface is maintained in code/menu.json. The behaviour of the app could be entirely changed by re-designing *menu.json*.

### Future developments

Interface with a browser and email programs.


#### Caveats

The code works well but needs refactoring to be more easily maintained. Some actions, for instance switching from Morse to scanning mode, maybe slightly delayed.

Once initialized, the eye is scanned within a fixed window. If the camera is moved, then one needs to re-initialize the app (by typing the '1' key).

Use under MIT license. The code writer assumes no liability for the program's use.

(C) [Ability Spectrum](http://abilityspectrum.com), 2015.



