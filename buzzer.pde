public class Buzzer {

  private int _lastTime, _howLong, _freq;
  private float _vol;
  AudioOutput _out;
  Minim       _minim;
  Oscil w;

  public Buzzer(int freq, float vol) {
    w = new Oscil( freq, 0, Waves.SINE );
    _freq = freq;
    _vol = vol;
    _minim = new Minim(this);
    _out = _minim.getLineOut();
    w.patch( _out );
  }

  public void on(int howlong) {
    _howLong = howlong;
    w.setAmplitude( _vol );
    _lastTime = millis();
  }

  public void off() {
    w.setAmplitude( 0 );
  }

  public void loop() {
    if ( (millis() - _lastTime) > _howLong ) 
      w.setAmplitude( 0 );
  }
}

