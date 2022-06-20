float[][] f;
float[][] df;
float[][] ddf;

int cellSize = 1;
int w, h; 

void setup() {
  size(800, 800);
  initField();
}

int getFieldColor(int x, int y) {
   float v = constrain(f[x][y], -1, 1);
   if (v < 0) return color(0, 0, (int) (-v * 255));
   else return color(int(v * 255), 0, 0);
}

void initField() {
  w = width / cellSize; h = height / cellSize; // we will assume the pixel size to be 
  f = new float[w][h];
  df = new float[w][h];
  ddf = new float[w][h];
  
  int numCenters = 10;
  int[] cx = new int[numCenters];
  int[] cy = new int[numCenters];
  float[] centerPeakVal = new float[numCenters];
  for (int i = 0; i < numCenters; i++) {
     cx[i] = (int) random(w);
     cy[i] = (int) random(h);
     centerPeakVal[i] = random(-1, 1);
  }
  
  for (int x = 0; x < w; x++) {
     for (int y = 0; y < h; y++) {
         for (int i = 0; i < numCenters; i++) {
             float dx = x - cx[i]; float dy = y - cy[i]; float d = sqrt(sq(dx) + sq(dy));
             f[x][y] += centerPeakVal[i] / (1.0 + d / (w / 10));
         }
     }
  }
}

void draw() {
  evoField();
  drawField();
}

float fieldLaplacian(int x, int y) {
   int xp = (x + 1) % w; int xm = (x - 1 + w) % w; int yp = (y + 1) % h; int ym = (y - 1 + h) % h; 
   return 0.25 * (f[xp][y] + f[xm][y] + f[x][yp] + f[x][ym]) - f[x][y];
}

void evoField() {
   for (int x = 0; x < w; x++) {
      for (int y = 0; y < h; y++) {
          
      }
   }
}

void drawField() {
   if (cellSize > 1) {
     noStroke();
     for (int x = 0; x < w; x++) {
        for (int y = 0; y < h; y++) {
           fill(getFieldColor(x, y)); rect(x * cellSize, y * cellSize, cellSize, cellSize); 
        }
     }
   }
   else {
      loadPixels();
      for (int x = 0; x < w; x++) {
         for (int y = 0; y < h; y++) {
            pixels[x + y * width] = getFieldColor(x, y); 
         }
      }
      updatePixels();
   }
}

void keyPressed(KeyEvent kev) {
   if (keyCode == 32) initField(); 
}
