/* 
  All right, so we have some basic mechanisms to make move creatures... Now, what do we want a creature to be? A collection of
  legs with springs
*/


boolean showSprings = true;
int tick = 0;

void setup() {
    fullScreen();
  
    // world.addCreature(new BasicBiped(100, 100, 100));
   // world.addCreature(new BasicTriped(200, 200, 100));
  
    makeNewGeneration();
}



void draw() {
    background(0);
    world.evo();
    world.draw();

   
}

class Actionable {
   float action; // the action is supposed to be between 0.0 and 1.0 (0.0: minimal action, 1.0: maximal action)
   Actionable() {
      action = 0.0; 
   }
}


// For the leg, the action is the friction coefficient
class Leg extends Actionable {
   float x, y, vx, vy;
   Leg(float x, float y) { this(x, y, 0.0, 0.0); action = 0.02; }
   Leg(float x, float y, float vx, float vy) { this.x = x; this.y = y; this.vx = vx; this.vy = vy; }
   
   void evo() {
       float frictionCoefficient = 1.0 - constrain(action, 0.0, 1.0);
       x += vx;
       y += vy;
       vx *= frictionCoefficient;
       vy *= frictionCoefficient;
   }
   
   void draw() {
       fill(0); stroke(255, 0, 0); strokeWeight(2);
       ellipse(x, y, 4, 4);
   }
}

class Spring extends Actionable {
    Leg p1, p2; 
    float coeff = 0.01;
    float defRestLength;
    Spring(Leg p1, Leg p2, float defRestLength) { this.p1 = p1; this.p2 = p2; this.defRestLength = defRestLength; }
    
    void evo() {
       float restLength = defRestLength - defRestLength * constrain(action, 0.0, 1.0);

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


// A sensor whose value is always on the unit circle
class Sensor {
   float xVal;
   float yVal;
   Sensor() { xVal = 1.0; yVal = 0.0; }
   
   void evo() {
     
   }
}

class Iclock extends Sensor {
    float frequency; // roughly speaking how many beats we want per minute
    Iclock(float frequency) {
      this.frequency = frequency;
    }
    
    void evo() {
      xVal = cos((TWO_PI * frequency * tick) / 1500);
      yVal = sin((TWO_PI * frequency * tick) / 1500);
    }
}

// A gene consists of an activation pattern; when the pattern is activated, it tries to bring the target closer to the target value
class Gene {
    Creature creature;
    int numSensors;

    int tid; // (actionable) target id
    float tarval; // the target value that we aim for in case we match the pattern
    int[] sids = new int[0]; 
    float[] xPatVals = new float[0];
    float[] yPatVals = new float[0];

    Actionable target;
    Sensor[] sensors = new Sensor[0]; 
    
    Gene(Creature creature, int tid, float tarval) {
       this.creature = creature;
       setTarget(tid, tarval);
       numSensors = 0;
    }
    
    Gene(Creature creature, Gene gene) {
       this.creature = creature;
       setTarget(gene.tid, gene.tarval);
       for (int i = 0; i < gene.numSensors; i++) {
          int sid = gene.sids[i]; float xPatVal = gene.xPatVals[i], yPatVal = gene.yPatVals[i]; addNewSap(sid, xPatVal, yPatVal);
       }
    }
    
    void setTarget(int tid, float tarval) { this.tid = tid; target = creature.actionables[tid]; this.tarval = tarval; }
    
    void addNewSap(int sid, float xPatVal, float yPatVal) {
       Sensor sensor = creature.sensors[sid];

       sids = append(sids, sid);
       xPatVals = append(xPatVals, xPatVal);
       yPatVals = append(yPatVals, yPatVal);
       sensors = (Sensor[]) append(sensors, sensor);
       
       numSensors = sensors.length;
    }
    
    float compSapMse() {
       float mse = 0.0;
       for (int i = 0; i < numSensors; i++) {
          int sid = sids[i];
          float xPatVal = xPatVals[i], yPatVal = yPatVals[i];
          Sensor sensor = creature.sensors[sid];
          float xVal = sensor.xVal, yVal = sensor.yVal;
          mse += (sq(xPatVal - xVal) + sq(yPatVal - yVal)) / sqrt(numSensors);
       }
       return mse;
    }
    

    // We compute how far we are from the pattern, and the adjustment force depends on the pattern value
    void evo() {
       float mse = compSapMse();
       float actionStrength = 1.0 / (1.0 + mse);
       float dTar = tarval - target.action;
       target.action += 0.1 * (dTar * actionStrength);
    }
    
    void randomMutation() {
       float tidFlipProb = 0.033 * 1000.0 / (1000.0 + genNumber); 
       if (random(1.0) < tidFlipProb ) setTarget((int) random(creature.actionables.length), tarval);
       float tarvalNoiseSigma = 0.24 * 1000.0 / (1000.0 + genNumber); 
       tarval = constrain(tarval + tarvalNoiseSigma * randomGaussian(), 0.0, 1.0);
       float sidFlipProb = 0.015 * 1000.0 / (1000.0 + genNumber); float xyNoiseSigma = 0.25 * 1000.0 / (1000.0 + genNumber);
       for (int i = 0; i < numSensors; i++) {
          if (random(1.0) < sidFlipProb) { 
            int newSid = (int) random(creature.sensors.length); sids[i] = newSid; sensors[i] = creature.sensors[newSid]; 
          }
          xPatVals[i] += randomGaussian() * xyNoiseSigma;
          yPatVals[i] += randomGaussian() * xyNoiseSigma;
          float norm = sqrt(sq(xPatVals[i]) + sq(yPatVals[i]));
          xPatVals[i] /= norm; yPatVals[i] /= norm;
       }
    }
    
    JSONObject toJson() {
       var json = new JSONObject(); 
       json.setInt("tid", tid);
       json.setFloat("tarval", tarval);
       var sidsJson = new JSONArray(); 
       var xPatValsJson = new JSONArray(); 
       var yPatValsJson = new JSONArray();
       for (int i = 0; i < sids.length; i++) {
         sidsJson.setInt(i, sids[i]);
         xPatValsJson.setFloat(i, xPatVals[i]);
         yPatValsJson.setFloat(i, yPatVals[i]);
       }
       json.setJSONArray("sids", sidsJson);
       json.setJSONArray("xPatVals", xPatValsJson);
       json.setJSONArray("yPatVals", yPatValsJson);


       return json;
    }
}

// Guides a creature to its target
class Guide extends Sensor {
   Creature creature;
   float xTarget;
   float yTarget;
   
   Guide(Creature creature, float xTarget, float yTarget) {
     this.creature = creature;
     this.xTarget = xTarget;
     this.yTarget = yTarget;
   }
   
   void evo() {
      float dx = xTarget - creature.xCog; float dy = yTarget - creature.yCog; float d = sqrt(sq(dx) + sq(dy));
      if (d == 0.0) return; xVal = dx / d; yVal = dy / d;
   }
}




class Creature {
   Iclock primaryClock;
   Iclock secondaryClock;
   
   boolean isRed = false;
   
   Leg[] legs = new Leg[0];
   float xCog, yCog;
   Actionable[] actionables = new Actionable[0];
   Spring[] springs = new Spring[0];
   Sensor[] sensors = new Sensor[0];
   Gene[] genes = new Gene[0];
   
   
   Creature() { 
     primaryClock = addNewClock(10); secondaryClock = addNewClock(30);
   }
   
   Actionable addActionable(Actionable actionable) { actionables = (Actionable[]) append(actionables, actionable); return actionable; }

   Leg addLeg(Leg leg) { legs = (Leg[]) append(legs, leg); addActionable(leg); return leg; }
   Leg addNewLeg(float x, float y) { return addLeg(new Leg(x, y)); }
   Leg addNewLeg(float x, float y, float vx, float vy) { return addLeg(new Leg(x, y, vx, vy)); }
   
   Spring addSpring(Spring spring) { springs = (Spring[]) append(springs, spring); addActionable(spring); return spring; }
   Spring addNewSpring(Leg p1, Leg p2, float restLength) { return addSpring(new Spring(p1, p2, restLength)); }
   
   Sensor addSensor(Sensor sensor) { sensors = (Sensor[]) append(sensors, sensor); return sensor; }
   Iclock addNewClock(float frequency) { Iclock iclock = new Iclock(frequency); addSensor(iclock); return iclock; }
   Guide addNewGuide(float xTarget, float yTarget) { Guide guide = new Guide(this, xTarget, yTarget); addSensor(guide); return guide; }
   
   Gene addGene(Gene gene) { genes = (Gene[]) append(genes, gene); return gene; }
   Gene addNewGene(int tid, float tarval) { return addGene(new Gene(this, tid, tarval)); }
   Gene addNewGene(Gene gene) { return addGene(new Gene(this, gene)); } // Copies the genetic material of the gene to make a new gene
   
   Gene addRandomGene(int numSaps) {
      int tid = (int) random(actionables.length); float tarval = random(1.0); 
      Gene gene = addNewGene(tid, tarval);
      for (int i = 0; i < numSaps; i++) {
          int sid = (int) random(sensors.length);
          float angle = random(TWO_PI); float xPatVal = cos(angle), yPatVal = sin(angle);
          gene.addNewSap(sid, xPatVal, yPatVal);
      }
      return gene;
   }
   
   
   void evo() {
     for (var spring : springs) spring.evo();
     for (var leg : legs) leg.evo();
     for (var sensor : sensors) sensor.evo();
     for (var gene : genes) gene.evo();
     xCog = yCog = 0.0; for (var leg : legs) { xCog += leg.x / legs.length; yCog += leg.y / legs.length; }
   }
   
   void draw() {
     
     if (showSprings) for (var spring : springs) spring.draw();
     for (var leg : legs) leg.draw();
     strokeWeight(4); stroke(255, 255, 0); if (isRed) stroke(255, 0, 0);
     ellipse(xCog, yCog, 20, 20);
     strokeWeight(2);
     stroke(0, 255, 0);
     
     // line(xCog, yCog, xCog + primaryClock.xVal * 10, yCog + primaryClock.yVal * 10);
     // line(cog.x, cog.y, cog.x + secondaryClock.xVal * 20, cog.y + secondaryClock.yVal * 20);
     noFill();
   }
   
   JSONArray getGenesJson() {
      var genesJson = new JSONArray();
      for (int i = 0; i < genes.length; i++) {
         genesJson.setJSONObject(i, genes[i].toJson()); 
      }
      return genesJson;
   }
}


class BasicBiped extends Creature {
    Leg p1, p2;
    Spring s;
    float len;
    BasicBiped(float x, float y, float len) {
        p1 = addNewLeg(x, y); 
        p2 = addNewLeg(x + len, y);
        s = addNewSpring(p1, p2, len);
        this.len = len;
    }
    
    void evo() {
       s.action = primaryClock.xVal * 0.5 + 0.5;
       p1.action = 0.6 + primaryClock.xVal * 0.2;
       p2.action = 1.0;
       super.evo();
    }
}

class BasicTriped extends Creature {
   Leg p1, p2, p3;
   Spring s12, s13, s23;
   float len;
   BasicTriped(float x, float y, float len) {
       this.len = len;
       p1 = addNewLeg(x, y);
       p2 = addNewLeg(x + len, y);
       p3 = addNewLeg(x + len * 0.5, y + len * 0.87);
       s12 = addNewSpring(p1, p2, len);
       s13 = addNewSpring(p1, p3, len);
       s23 = addNewSpring(p2, p3, len);
   }
   
   void evo() {
       s12.action = max(primaryClock.xVal, 0.0) * 0.5;
       s23.action = 0.0;
       s13.action = max(-primaryClock.xVal, 0.0) * 0.5;
       p1.action = max( primaryClock.xVal, 0.0) * 0.8;
       p3.action = max(-primaryClock.xVal, 0.0) * 0.8;
       super.evo(); 
   }
}

// A simple creature that aims to go 100 pixels down and 100 pixels right
class Sapiens extends Creature {
    float xTarget; float yTarget; int numLegs; float rad;
    float oricx, oricy;
        
    Sapiens(int numLegs, int numGenes, int numSaps, float cx, float cy, float rad) {
      initLegsAndSprings(numLegs, cx, cy, rad);
      addNewGuide(cx + 100, cy + 100);
      initRandomGenes(numGenes, numSaps);
      oricx = cx; oricy = cy;
    }
    
    
    // A sapiens that inherits the genes of another sapiens
    Sapiens(Sapiens sapiens, float cx, float cy) {
       initLegsAndSprings(sapiens.numLegs, cx, cy, sapiens.rad);
       addNewGuide(cx + 100, cy + 100);
       copyGenes(sapiens);
        oricx = cx; oricy = cy;
      }
    
    void initLegsAndSprings(int numLegs, float cx, float cy, float rad) {
      this.numLegs = numLegs;
      this.rad = rad;
      for (int i = 0; i < numLegs; i++) {
          float x = cx + rad * cos((TWO_PI * i) / numLegs); float y = cy + rad * sin((TWO_PI * i) / numLegs);
          addNewLeg(x, y);
      }
          
      for (int i = 0; i < numLegs; i++) {
          for (int j = i + 1; j < numLegs; j++) {
            addNewSpring(legs[i], legs[j], rad);
          } 
      }
    }
    
    void initRandomGenes(int numGenes, int numSaps) {
      for (int i = 0; i < numGenes; i++) addRandomGene(numSaps); 
    }
    
    void copyGenes(Sapiens sapiens) {
      for (Gene gene : sapiens.genes) addNewGene(gene);
    }
    
    float compScore() {
       return 0.7 * (sq(xCog - oricx) + sq(yCog - oricy)) + 0.3 * (sq(max(xCog - oricx, 0)) + sq(max(yCog - oricy, 0)));
    }
    
    void draw() {
       stroke(0, 0, 255); strokeWeight(4); line(oricx, oricy, xCog, yCog);
       super.draw(); 
    }
}




class World {
  Creature[] creatures = new Creature[0];
  Sapiens[] sapienses = new Sapiens[0];

  Creature addCreature(Creature creature) { creatures = (Creature[]) append(creatures, creature); return creature; }
  Creature addNewCreature() { return addCreature(new Creature()); }
  void addSapiens(Sapiens sapiens) { addCreature(sapiens); sapienses = (Sapiens[]) append(sapienses, sapiens); }
  
  void removeCreature(Creature creature) {
     Creature[] oldCreatures = creatures; creatures = new Creature[0]; 
     for (Creature oldCreature : oldCreatures) if (oldCreature != creature) addCreature(oldCreature);
  }
  
  void evo() {
    for (int i = 0; i < 100; i++) {
      tick++;
      for (var creature : creatures) creature.evo();
    }
  }
  
  void draw() {
    for (var creature : creatures) creature.draw();
   // if (frameCount % 5 == 0) {
       markLeaderInRed(); 
       saveFrame("evo-####.png");
       
    //}
    if (frameCount % 50 == 0) {
      nextGen();
    }
  }
}

World world;
int genNumber = 0;

void nextGen() {
  genNumber++;
  float maxScore = -1000000000.0; Sapiens maxSapiens = null;
  for (Sapiens sapiens : world.sapienses) {
     float score = sapiens.compScore();
     if (score >= maxScore) {
       maxScore = score; maxSapiens = sapiens;
     }
  }
  if (maxSapiens != null) {
    var maxSapiensJson = new JSONObject();
    maxSapiensJson.setJSONArray("genes", maxSapiens.getGenesJson());
    maxSapiensJson.setFloat("score", maxScore);
    saveJSONObject(maxSapiensJson, "max-gen-" + genNumber + ".json");
    makeNewGenerationFromSapiens(maxSapiens);
  }
  else {
     makeNewGeneration();
  }
  println(genNumber, " maxScore=", maxScore);
}


void keyPressed(KeyEvent kev) {
    

    if ((keyCode == RETURN || keyCode == ENTER) && (kev.isControlDown() || kev.isMetaDown())) {
      

    }
}

int numCreaturePerGen = 96;
int numCreaturePerLine = 12;


void makeNewGeneration() {
    world = new World();
    int numGenes = 20;
    int numLegs = 5;
    int numSapvals = 3;
    for (int i = 0; i < numCreaturePerGen; i++) {
       int k = i % numCreaturePerLine; int l = i / numCreaturePerLine;
       int x = 100 + 150 * k;
       int y = 100 + l * 150;
       int rad = 100;
       
       Sapiens sapiens = new Sapiens(numLegs, numGenes, numSapvals, x, y, rad);
       world.addSapiens(sapiens); 
       
    }
}

void markLeaderInRed() {
  float maxScore = 0.0; Sapiens maxSapiens = null;
  for (Sapiens sapiens : world.sapienses) {
     sapiens.isRed = false;
     float score = sapiens.compScore();
     if (score >= maxScore) {
       maxScore = score; maxSapiens = sapiens;
     } 
  }
  if (maxSapiens != null) maxSapiens.isRed = true;
}

void makeNewGenerationFromSapiens(Sapiens originalSapiens) {
    int numGenes = 20;
    int numLegs = 5;
    int numSapvals = 3;
    world = new World();
    for (int i = 0; i < numCreaturePerGen; i++) {
       int k = i % numCreaturePerLine; int l = i / numCreaturePerLine;
       int x = 100 + 150 * k;
       int y = 100 + l * 150;
       int rad = 100;
       Sapiens sapiens = new Sapiens(originalSapiens, x, y);
       if (i > 0) {
         for (Gene gene : sapiens.genes) {
             gene.randomMutation();
         }
       }
       world.addSapiens(sapiens); 
    }
}  


// To make it possible to inherit, we should encode the genes by putting sensor ids and activable ids rather than the actual pointers
// Ok done. 
