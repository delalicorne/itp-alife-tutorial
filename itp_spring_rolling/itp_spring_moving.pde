int numPoints = 3;
boolean showSprings = false;

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
   
   void addPoint(Point point) { points = (Point[]) append(points, point); }
   void addNewPoint(float x, float y) { addPoint(new Point(x, y)); }
   void addNewPoint(float x, float y, float vx, float vy) { addPoint(new Point(x, y, vx, vy)); }
   
   void addSpring(Spring spring) { springs = (Spring[]) append(springs, spring); }
   void addNewSpring(Point p1, Point p2, float restLength) { addSpring(new Spring(p1, p2, restLength)); }
   
   void evo() {
     for (var spring : springs) spring.evo();
     for (var point : points) point.evo();
   }
   
   void draw() {
     if (showSprings) for (var spring : springs) spring.draw();
     for (var point : points) point.draw();
   }
}

World world = new World();



void initWorld() {
    int oldNumPoints = world.points.length;  
    for (int i = oldNumPoints; i < numPoints; i++) {
     world.addNewPoint(random(1) + width / 2, random(1) + height / 2); 
    }
    /*for (int j = 0; j < 20; j++) {
       int i1 = (int) random(world.points.length);
       int i2 = (int) random(world.points.length);
       if (i1 == i2) continue;
       world.addNewSpring(world.points[i1], world.points[i2], 200);
    }*/
    
    for (int i1 = oldNumPoints; i1 < world.points.length; i1++) {
       for (int i2 = 0; i2 < world.points.length; i2++) {
          if (i1 == i2) continue;
          world.addNewSpring(world.points[i1], world.points[i2], width / 3); 
       }
    }
}

void setup() {
    size(1000, 1000);
    initWorld();
}

void draw() {
    background(0);
    world.evo();
    world.draw();
}

void keyPressed() {
   if (keyCode == ENTER) {
        numPoints++;
        println(numPoints);
        initWorld();
   }
   if (keyCode == 32) {
     showSprings ^= true;
   }
}
