float[][] medium; // we'll think of the cells as being 1pix wide and high
float[][] derivativeMedium; // the evolution of the medium
int w, h;

void initializeMedium() {
  w = width; // cells are 1 pix big
    h = height; 
    medium = new float[w][h];
    derivativeMedium = new float[w][h];
    int numCenters = 10;
    float[] xRandom = new float[numCenters], yRandom = new float[numCenters];
    float[] values = new float[numCenters]; // values at the (xRandom, yRandom) centers
    for (int i = 0; i < numCenters; i++) {
       xRandom[i] = 0.3 * w + random(0.4 * w); // we are a random number in [0.3*w, 0.7*w]
       yRandom[i] = 0.3 * h + random(0.4 * h); // same
       values[i] = random(1.0) * 2.0 - 1.0; // random number in [-1,1]
    }
    for (int x = 0; x < w; x++) {
       for (int y = 0; y < h; y++) {
           for (int i = 0; i < numCenters; i++) {
             float dx = xRandom[i] - x, dy = yRandom[i] - y; // vectors between centers and (x,y)
             float dSquared = sq(dx) + sq(dy); float d = sqrt(dSquared);
             float decayFactor = 1.0 / (1.0 + 0.02 * d); 
             medium[x][y] += values[i] * decayFactor;
           }
       }
    }
}
void setup() {
    size(1200, 1200, P2D);
    initializeMedium();
}

int f2c(float f) {
   float clipVal = 0.5;
   f = constrain(f, -clipVal, clipVal); // clips the values of f to [-1, 1]
   if (f >= 0) return color((int) (f * 255 / clipVal), 0, 0);
   else return color(0, 0, (int) (-f * 255 / clipVal)); // f < 0
}

void drawMedium() {
 loadPixels(); // gives us raw access to the pixels
 for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
       int i = x + y * width; 
       pixels[i] = f2c(medium[x][y]);
    }
 }
 updatePixels();
}

void draw() {
  drawMedium();
  evoMedium();
}


void keyPressed(KeyEvent kev) {
   if (keyCode == 32) { // spacebar ascii code
       initializeMedium();
   }
}

float laplacian(int x, int y) {
   int xp = (x + 1) % w, xm = (x - 1 + w) % w, yp = (y + 1) % h, ym = (y - 1 + h) % h;
   float neighborAverage = (medium[xp][y] + medium[xm][y] + medium[x][yp] + medium[x][ym]) / 4.0;
   // how the field at (x, y) is in deficit/exceess wrt neighbors
   return neighborAverage - medium[x][y]; 
}

void evoMedium() {
  
  for (int x = 0; x < w; x++) {
      for (int y = 0; y < h; y++) {
        float refractiveIndex = 1.0; if (x < w / 2) refractiveIndex = 1.333;
        derivativeMedium[x][y] += laplacian(x, y) / refractiveIndex; 
      }
  }
  
  // d_t u = Laplacian(u)
  for (int x = 0; x < w; x++) {
     for (int y = 0; y < h; y++) {
         medium[x][y] += derivativeMedium[x][y];
     } 
  }
}
