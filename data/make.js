
/**
 * Created by ylh on 14-03-13.
 */

var buttonText=
    [ 
       {"t":"plus", kind:"Alpha"},
       {"t":"equals", kind:"Alpha"},
    ];



for ( var i=0; i< buttonText.length; i++ ) {
  console.log('curl -A "Mozilla" "http://translate.google.com/translate_tts?tl=en&q=' +
  buttonText[i].t +
  '" > en_' +
  buttonText[i].t +
  ".mp3");
}

