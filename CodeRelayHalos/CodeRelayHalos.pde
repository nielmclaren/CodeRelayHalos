import ddf.minim.*;
import ddf.minim.analysis.*;

ddf.minim.Minim minim;
ddf.minim.AudioInput in;
FFT fft;

int numCols = 12;
int numRows = 6;

FastBlurrer blurrer;

void setup() {
  size(1440, 900);

  minim = new Minim(this);
  in = minim.getLineIn();
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(10, 1);
  println(fft.avgSize());
  
  int blurRadius = 16;
  blurrer = new FastBlurrer(width, height, blurRadius);
  
  colorMode(HSB);
}


void draw() {
  background(0);
  fft.forward(in.mix);
  drawFft(fft);
  drawHalos(16, 255);
  blur();
  drawHalos(8, 196);
  drawFps();
}

void drawFft(FFT fft) {
  noStroke();
  fill(4);
  float bandWidth = (float)width / fft.avgSize();
  for (int i = 0; i < fft.avgSize(); i++) {
    // draw the line for frequency band i, scaling it up so we can see it a bit better
    float h = fft.getAvg(i) * 8;
    rect(i * bandWidth, height - h, bandWidth, h);
  }
}

void drawHalos(int thickness, int brightness) {
  for (int col = 0; col < numCols; col++) {
    for (int row = 0; row < numRows; row++) {
      drawHalo(col, row, thickness, brightness);
    }
  }
}

void drawHalo(int col, int row, int thickness, int brightness) {
  stroke(getHaloColor(col, row, brightness));
  strokeWeight(thickness);
  noFill();
  
  float spacing = 40;
  float tileSize = min(width / numCols, height / numRows);
  float diameter = tileSize - spacing;
  float centeringOffsetX = (width - tileSize * numCols) / 2;
  float centeringOffsetY = (height - tileSize * numRows) / 2;
  
  ellipse(
    centeringOffsetX + (col + 0.5) * tileSize,
    centeringOffsetY + (row + 0.5) * tileSize,
    diameter, diameter);
}

color getHaloColor(int col, int row, int brightness) {
  float delta = abs(col - numCols/2 + 0.5) + abs(row - numRows/2 + 0.5);
  delta = 1 - delta * 0.1;
  println(delta);
  float level;
  if (col < 6) {
    level = in.left.level();
  } else {
    level = in.right.level();
  }
  float t = (modTime(8000) + delta) % 1.0 + level * 0.3;
  t = t % 1.0;
  t = sine(t);
  
  return color(
    map(t, 0, 1, 196, 270) % 255,
    196,
    brightness);
}

void blur() {
  loadPixels();
  blurrer.blur(pixels);
  updatePixels();
}

float modTime(long period) {
  return (float)(millis() % period) / period;
}

float sine(float t) {
  return sin(t * PI) / 2 + 0.5;
}

float upAndDown(float t) {
  if (t > 0.5) {
    return 2 * (1 - t);
  }
  return t * 2;
}

void drawFps() {
  text("FPS:"+ frameRate, 5, 15);
}