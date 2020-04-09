
class FluidGrid2D {
  
  private double[][][] data;
  private double[][][] back;
  
  public static final int LAGRANGE = -3;
  public static final int CURL = -2;
  public static final int NONE = -1;
  public static final int PRESSURE = 0;
  public static final int PX = 1; // momentum x
  public static final int PY = 2; // momentum y
  
  public FluidGrid2D(int w, int h, int p) {
    p += 3; // required properties
    data = new double[p][w][h];
    back = new double[p][w][h];
  }
  
  public double[][][] getData() {
    return data;
  }
  
  public int getWidth() {
    return data[0].length;
  }
  
  public int getHeight() {
    return data[0][0].length;
  }
  
  public int propertyCount() {
    return data.length;
  }
  
  public void clear() {
    for(int p=0;p<propertyCount();p++) {
      for(int x=0;x<getWidth();x++) {
      for(int y=0;y<getHeight();y++) {
        data[p][x][y] = 0;
      }
      }
    }
  }
  
  public void swapBuffers() {
    double[][][] temp = back;
    back = data;
    data = temp;
  }
  
  public double getLagrangian(int p, int x, int y) {
    
    double lagrangian = 0;
    
    for(int i=-1;i<=1;i++) {
    for(int j=-1;j<=1;j++) {
      
      int u = wrap(x+i,getWidth());
      int v = wrap(y+j,getHeight());
      
      double factor = -1;
      if(i!=0 || j!=0) {
        if(i!=0 && j!=0) {
          factor = 0.05;
        } else {
          factor = 0.2;
        }
      } else {
        // factor = -1;
      }
      
      lagrangian += data[p][u][v]*factor;
    }
    }
    
    return lagrangian;
  }
  
  public void advect(double dt) {
    
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      for(int p=1;p<propertyCount();p++) {
        back[p][x][y] = 0;
      }
    }
    }
    
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      
      if(data[3][x][y]!=0) {
        
        double mass = 0;
        for(int p=3;p<=4;p++) {
          mass += data[p][x][y];
        }
        
        double xn = x+data[PX][x][y]/mass*dt;
        double yn = y+data[PY][x][y]/mass*dt;
        double ix0 = xn-(int)Math.floor(xn);
        double iy0 = yn-(int)Math.floor(yn);
        double ix1 = 1-ix0;
        double iy1 = 1-iy0;
        
        int x0 = wrap((int)Math.floor(xn),getWidth());
        int y0 = wrap((int)Math.floor(yn),getHeight());
        int x1 = wrap(x0+1,getWidth());
        int y1 = wrap(y0+1,getHeight());
        
        for(int p=1;p<propertyCount();p++) {
          back[p][x0][y0] += ix1*iy1*data[p][x][y];
          back[p][x1][y0] += ix0*iy1*data[p][x][y];
          back[p][x0][y1] += ix1*iy0*data[p][x][y];
          back[p][x1][y1] += ix0*iy0*data[p][x][y];
        }
        
      } else {
        data[PX][x][y] = 0;
        data[PY][x][y] = 0;
      }
    }
    }
    
    swapBuffers();
  }
  
  public void diffuse(double dt) {
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      for(int p=1;p<propertyCount();p++) {
        back[p][x][y] = data[p][x][y]+getLagrangian(p,x,y)*dt;
      }
    }
    }
    swapBuffers();
  }
  
  public void updatePressure(double factor) {
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      if(data[3][x][y]!=0) {
        int x0 = wrap(x-1,getWidth());
        int y0 = wrap(y-1,getHeight());
        int x1 = wrap(x+1,getWidth());
        int y1 = wrap(y+1,getHeight());
        data[PRESSURE][x][y] =
           ((data[PX][x0][y]-data[PX][x1][y])+
            (data[PY][x][y0]-data[PY][x][y1]))*factor;
      } else {
        data[PRESSURE][x][y] = 0;
      }
    }
    }
  }
  
  public void subtractPressureGradient(double factor) {
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      int x0 = wrap(x-1,getWidth());
      int y0 = wrap(y-1,getHeight());
      int x1 = wrap(x+1,getWidth());
      int y1 = wrap(y+1,getHeight());
      data[PX][x][y] += (data[PRESSURE][x0][y]-data[PRESSURE][x1][y])*factor;
      data[PY][x][y] += (data[PRESSURE][x][y0]-data[PRESSURE][x][y1])*factor;
    }
    }
  }
  
  public double get(int p, int x, int y) {
    switch(p) {
      case NONE:
        return 0;
      case LAGRANGE:
        return getLagrangian(3,x,y); // assume the existence of at least one custom property
      case CURL:
        return getCurl(x,y);
      default:
        return Math.abs(data[p][x][y]);
    }
  }
  
  public void draw(PImage canvas,
      int rp, float rb, // red index & red brightness
      int gp, float gb, // etc...
      int bp, float bb) {
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      canvas.pixels[x+y*canvas.width] = color(
          (float)get(rp,x,y)*rb,
          (float)get(gp,x,y)*gb,
          (float)get(bp,x,y)*bb);
    }
    }
  }
  
  public void draw(PImage canvas, int p, float b) {
    draw(canvas,p,b,p,b,p,b);
  }
  
  public void paint(int p, int x, int y, float radius, double value) {
    // paint a circle
    for(int i=max(floor(x-radius),0);i<=min(ceil(x+radius),getWidth()-1);i++) {
    for(int j=max(floor(y-radius),0);j<=min(ceil(y+radius),getHeight()-1);j++) {
      if(pow(i-x,2)+pow(j-y,2)<=radius*radius) {
        data[p][i][j] = value;
      }
    }
    }
  }
  
  public double getCurl(int x, int y) {
    int x0 = wrap(x-1,getWidth());
    int y0 = wrap(y-1,getHeight());
    int x1 = wrap(x+1,getWidth());
    int y1 = wrap(y+1,getHeight());
    return
        (data[PX][x][y0]-data[PX][x][y1])-
        (data[PY][x0][y]-data[PY][x1][y]);
  }
  
  public void clearBorder() {
    for(int i=0;i<getWidth();i++) {
    for(int p=1;p<=2;p++) {
      data[p][i][0] = 0;
      data[p][i][getHeight()-1] = 0;
    }
    }
    for(int i=0;i<getHeight();i++) {
    for(int p=1;p<=2;p++) {
      data[p][0][i] = 0;
      data[p][getWidth()-1][i] = 0;
    }
    }
  }
  
  public void fixThatShit() {
    for(int x=0;x<getWidth();x++) {
    for(int y=0;y<getHeight();y++) {
      for(int p=1;p<propertyCount();p++) {
        if(Double.isNaN(data[p][x][y])) {
          data[p][x][y] = 0;
        }
      }
    }
    }
  }
  
}
