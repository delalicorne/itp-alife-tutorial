/* 
  A first creature that moves using springs
*/

boolean showSprings = true;
float oscCounter = 0.0;


class Point {
   float x, y, vx, vy;
   float frictionCoeff = 0.98;
   Point(float x, float y) { this(x, y, 0.0, 0.0); }
   Point(float x, float y, float vx, float vy) { this.x = x; this.y = y; this.vx = vx; this.vy = vy; }
   
   void evo() {
       x += vx;
       y += vy;
       vx *= frictionCoeff;
       vy *= frictionCoeff;
   }
   
   void draw() {
       fill(0); stroke(255, 0, 0); strokeWeight(2);
       ellipse(x, y, 4, 4);
   }
}

class Spring {
    Point p1, p2; 
    float restLength;
    float coeff = 0.01;
    Spring(Point p1, Point p2, float restLength) { this.p1 = p1; this.p2 = p2; this.restLength = restLength; }
    
    void evo() {
       float dx12 = p2.x - p1.x; float dy12 = p2.y - p1.y; float dx21 = -dx12, dy21 = -dy12;
       float d = sqrt(sq(dx12) + sq(dy12));
       if (d == 0.0) return; // shouldn't happen, but to be on the safe side
       float ndx12 = dx12 / d, ndy12 = dy12 / d, ndx21 = dx21 / d, ndy21 = dy21 / d;
       float dd = (d - restLength) * coeff; // if dd > 0, must contract, if dd < 0 must expand
       p1.vx += dd * ndx12; p1.vy += dd * ndy12;
       p2.vx += dd * ndx21; p2.vy += dd * ndy21;
    }
    
    void draw() {
       stroke(255); strokeWeight(2);
       line(p1.x, p1.y, p2.x, p2.y);
    }
}




class World {
   Point[] points = new Point[0];
   Spring[] springs = new Spring[0];
   
   World() { }
   
   Point addPoint(Point point) { points = (Point[]) append(points, point); return point; }
   Point addNewPoint(float x, float y) { return addPoint(new Point(x, y)); }
   Point addNewPoint(float x, float y, float vx, float vy) { return addPoint(new Point(x, y, vx, vy)); }
   
   Spring addSpring(Spring spring) { springs = (Spring[]) append(springs, spring); return spring; }
   Spring addNewSpring(Point p1, Point p2, float restLength) { return addSpring(new Spring(p1, p2, restLength)); }
   
   void evo() {
     for (var spring : springs) {
       spring.evo();
     }
     if (frameCount % 100 < 50) springs[0].restLength = 100; else springs[0].restLength = 200;

     for (var point : points) {
       point.evo();
     }
     if (frameCount % 100 < 50) { points[0].frictionCoeff = 0.1; points[1].frictionCoeff = 0.9; } 
     if (frameCount % 100 > 50) { points[1].frictionCoeff = 0.1; points[0].frictionCoeff = 0.9; } 

   }
   
   void draw() {
     if (showSprings) for (var spring : springs) spring.draw();
     for (var point : points) point.draw();
   }
}

World world = new World();



void initWorld() {
   float x = random(width / 2), y = random(height / 2);
   Point p1 = world.addNewPoint(x + 100, y + 100), p2 = world.addNewPoint(x + 200, y + 100), p3 = world.addNewPoint(x + 150, y + 188);
   Spring s = world.addNewSpring(p1, p2, 100);
   Spring s2 = world.addNewSpring(p2, p3, 100);
   Spring s3 = world.addNewSpring(p1, p3, 100);


}

void setup() {
    size(1200, 1200);
    initWorld();
}

void draw() {
    background(0);
    world.evo();
    world.draw();
}

void keyPressed() {
   if (keyCode == ENTER) {
        initWorld();
   }
   if (keyCode == 32) {
     showSprings ^= true;
   }
}
