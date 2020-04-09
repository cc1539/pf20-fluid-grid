                                                
FluidGrid2D fg;
PImage canvas;

float advect_dt = 0.01;

int wrap(int n, int l) {
  
  //n%=l;if(n<0){n+=l;} // actually wrap around
  n = min(max(0,n),l-1); // wall
  
  return n;
}

void setup() {
  
  size(640,640);
  noSmooth();
  
  fg = new FluidGrid2D(width/4,height/4,2);
  canvas = createImage(fg.getWidth(),fg.getHeight(),ARGB);
}

void keyPressed() {
  switch(key) {
    case 'c': {
      fg.clear();
    } break;
    case 'e': {
      fg.clear();
      for(int x=0;x<fg.getWidth();x++) {
      for(int y=0;y<fg.getHeight();y++) {
        double[][][] data = fg.getData();
        data[3][x][y] = 0.2;
      }
      }
    } break;
  }
}

void draw() {
  
  if(keyPressed && key=='a') {
    advect_dt = (float)mouseX/width;
  }
  
  if(mousePressed) {
    int x = mouseX*canvas.width/width;
    int y = mouseY*canvas.height/height;
    if(mouseButton==LEFT) {
      if(keyPressed && key=='1') {
        fg.paint(4,x,y,10,10);
      } else {
        fg.paint(3,x,y,10,1);
      }
    } else {
      fg.paint(FluidGrid2D.PX,x,y,10,(mouseX-pmouseX)*3);
      fg.paint(FluidGrid2D.PY,x,y,10,(mouseY-pmouseY)*3);
    }
  }
  
  for(int t=0;t<8;t++) {
    //fg.clearBorder();
    
    fg.advect(advect_dt);
    fg.diffuse(1);
    
    fg.fixThatShit(); // doesn't fix shit
    /*
    for(int i=0;i<20;i++) {
      fg.updatePressure(0.25);
      fg.subtractPressureGradient(1);
    }
    */
    
    // apply custom physics (surface tension)
    for(int x=0;x<fg.getWidth();x++) {
    for(int y=0;y<fg.getHeight();y++) {
      double[][][] data = fg.getData();
      
      // gravity to the center of the grid
      /*
      float dx = x - fg.getWidth()/2;
      float dy = y - fg.getHeight()/2;
      float force = -10/(dx*dx+dy*dy+1);
      
      data[FluidGrid2D.PX][x][y] += data[3][x][y]*dx*force;
      data[FluidGrid2D.PY][x][y] += data[3][x][y]*dy*force;
      */
      
      // gravity downwards
      data[FluidGrid2D.PY][x][y] += data[3][x][y]*data[3][x][y]/4*((keyPressed && key=='g')?10:1);
      
      // surface tension
      int x0 = wrap(x-1,fg.getWidth());
      int y0 = wrap(y-1,fg.getHeight());
      int x1 = wrap(x+1,fg.getWidth());
      int y1 = wrap(y+1,fg.getHeight());
      
      {
        int prop = 3;
        double factor = Math.min(Math.max((data[prop][x][y]-0.5)*200,-200),20);
        data[FluidGrid2D.PX][x][y] += (data[prop][x0][y]-data[prop][x1][y])*factor*data[prop][x][y];
        data[FluidGrid2D.PY][x][y] += (data[prop][x][y0]-data[prop][x][y1])*factor*data[prop][x][y];
      }
      
      {
        int prop = 4;
        double factor = Math.min(Math.max((data[prop][x][y]-0.5)*200,-200),20)*-1e-3;
        double ax = (data[prop][x0][y]-data[prop][x1][y])*factor*data[prop][x][y];
        double ay = (data[prop][x][y0]-data[prop][x][y1])*factor*data[prop][x][y];
        data[FluidGrid2D.PX][x][y] += ax;
        data[FluidGrid2D.PY][x][y] += ay;
      }
      
    }
    }
    
  }
  
  if(keyPressed && key==' ') {
    fg.draw(canvas,
        FluidGrid2D.PX,8,
        FluidGrid2D.NONE,0,
        FluidGrid2D.PY,8);
  } else if(keyPressed && key=='s') {
    fg.draw(canvas,
        FluidGrid2D.CURL,32,
        FluidGrid2D.NONE,0,
        FluidGrid2D.CURL,-32);
  } else {
    fg.draw(canvas,
        4,255,
        3,128,
        3,255);
  }
  
  canvas.updatePixels();
  image(canvas,0,0,width,height);
}
