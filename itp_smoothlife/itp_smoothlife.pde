// Based on by Stephan Rafler

class Uni {
  
  float[][] mat; // the matrix; the universe
  float[][] bufmat; // the buffer matrix
  int w; int h;
  int innerRad, outerRad;
  float birthOne, birthTwo, deathOne, deathTwo;
  float innerSmoothness, outerSmoothness;
  
  Uni(int w, int h) {
     this.w = w; this.h = h;
     mat = new float[w][h];
     bufmat = new float[w][h];
     for (int x = 0; x < w; x++) {
        for (int y = 0; y < h; y++) {
           if (sq(x - w / 2) + sq(y - h / 2) > 400) continue;
           mat[x][y] = random(1.0); 
        }
     }
     fixParams();
  }
  
  void fixParams() {
     innerRad = 8; outerRad = innerRad * 3;
     birthOne = 0.278; birthTwo = 0.365;
     deathOne = 0.267; deathTwo = 0.445;
     innerSmoothness = 0.028;
     outerSmoothness = 0.147;
     
     /*{
       int inrad = 7; int outrad = 21;
       float alpha_n = 0.028; float alpha_m = 0.147; 
       float b_1 = 0.25; float b_2 = 0.325; float d_1 = 0.2; float d_2 = 0.325;
     }*/
     
    /* innerRad = 7; outerRad = innerRad * 3;
     birthOne = 0.25; birthTwo = 0.325;
     deathOne = 0.2; deathTwo = 0.325;
     innerSmoothness = 0.028;
     outerSmoothness = 0.147; */
  }
  
  int f2c(float f) {
     return color(int(constrain(f, 0, 1) * 255)); 
  }
  
  float logistic(float x, float threshold, float smoothness) {
      return 1.0 / (1.0 + exp(-(4.0 / smoothness) * (x - threshold)));
  }
  
  float smoothIndicator(float x, float lowerEnd, float higherEnd, float smoothness) {
     return logistic(x, lowerEnd, smoothness) * (1.0 - logistic(x, higherEnd, smoothness)); 
  }
  
  float smoothSelector(float x, float y, float input, float smoothness) {
    return x * logistic(input, 0.5, smoothness) + y * (1.0 - logistic(input, 0.5, smoothness));
  }
  
  float getVal(int x, int y) {
     if (x < 0) x += w; if (x >= w) x -= w; if (y < 0) y += h; if (y >= h) y -= h; return mat[x][y]; 
  }
  
  float compInnerAverage(int cx, int cy) {
     int numPoints = 0; float sum = 0.0;
     for (int x = cx - innerRad; x <= cx + innerRad; x++) {
        for (int y = cy - innerRad; y <= cy + innerRad; y++) {
           float squareRad = sq(x - cx) + sq(y - cy); if (squareRad > innerRad) continue;
           sum += getVal(x, y); numPoints++;
        } 
     }
     return sum / numPoints;
  }
  
  float compOuterAverage(int cx, int cy) {
     int numPoints = 0; float sum = 0.0;
     for (int x = cx - outerRad; x <= cx + outerRad; x++) {
        for (int y = cy - outerRad; y <= cy + outerRad; y++) {
           float squareRad = sq(x - cx) + sq(y - cy); if (squareRad < innerRad || squareRad > outerRad) continue;
           sum += getVal(x, y); numPoints++;
        } 
     }
     return sum / numPoints;
  }
  
  float nextVal(int x, int y) {
     float innerAverage = compInnerAverage(x, y), outerAverage = compOuterAverage(x, y);
     return smoothIndicator(outerAverage, smoothSelector(birthOne, deathOne, innerAverage, innerSmoothness), smoothSelector(birthTwo, deathTwo, innerAverage, innerSmoothness), outerSmoothness);
  }
  

  void draw() {
     loadPixels();
     for (int x = 0; x < w; x++) for (int y = 0; y < h; y++) pixels[x + y * width] = f2c(mat[x][y]);
     updatePixels();
  }
  
  void evo() {
      for (int x = 0; x < w; x++) {
         for (int y = 0; y < h; y++) {
            bufmat[x][y] = nextVal(x, y);
         }
      }
      for (int x = 0; x < w; x++) {
         for (int y = 0; y < h; y++) {
            mat[x][y] = bufmat[x][y];
         }
      }
  }
  void smoothEvo() {
      for (int x = 0; x < w; x++) {
         for (int y = 0; y < h; y++) {
            bufmat[x][y] = nextVal(x, y);
         }
      }
      for (int x = 0; x < w; x++) {
         for (int y = 0; y < h; y++) {
            mat[x][y]  = constrain(mat[x][y] + (2 * bufmat[x][y] - 1.0) * mat[x][y] * 0.05, 0, 1);
         }
      }
  }
}

Uni uni;

void setup() {
  size(300, 300);
  uni = new Uni(width, height);
}

void draw() {
  background(0);  
  uni.draw();
  uni.evo();
}
