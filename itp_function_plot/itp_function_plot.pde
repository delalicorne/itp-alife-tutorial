

void setup() {
  size(700, 700);    
}

float threshold = 0.0;
float alpha = 0.01;

float f(float x) {
  return 1.0 / (1.0 + exp(-4.0 * (x - threshold) / alpha));
}

float res = 800.0;
void draw() {
  background(0);
  noStroke();
  fill(255);
  for (float x = 0.0; x <= 1.0; x += 1.0 / res) {
     float y = f(x);
     ellipse(x * width, (1 - y) * height, 4, 4);
  }
}

void mouseMoved() {
   threshold = float(mouseX) / width; 
   alpha = sqrt(height) / (mouseY + 10.0);
}
