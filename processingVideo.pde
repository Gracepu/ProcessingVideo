import processing.sound.*;
import processing.video.*;
import cvimage.*;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;

//Detectores
import org.opencv.objdetect.CascadeClassifier;
import org.opencv.objdetect.Objdetect;

// Cámara e imagen
Capture cam;
CVImage img;

// Cascadas para detección
CascadeClassifier face,leye,reye;

// Modelos
String faceFile, leyeFile,reyeFile;
boolean leyeClosed,reyeClosed;
SoundFile alarm;

public void setup() {
  size(640, 480);
  
  //Cámara
  cam = new Capture(this, width , height);
  cam.start(); 
  
  text("Try blocking your eyes to the camera!",width/2,15);
  //OpenCV
  //Carga biblioteca core de OpenCV
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  println(Core.VERSION);
  
  //Crea imágenes
  img = new CVImage(cam.width, cam.height);
  
  //Detectores
  faceFile = "haarcascade_frontalface_default.xml";
  leyeFile = "haarcascade_mcs_lefteye.xml";
  reyeFile = "haarcascade_mcs_righteye.xml";
  face = new CascadeClassifier(dataPath(faceFile));
  leye = new CascadeClassifier(dataPath(leyeFile));
  reye = new CascadeClassifier(dataPath(reyeFile));
  
  leyeClosed = false;
  reyeClosed = false;
  
  alarm = new SoundFile(this,"Wecker-sound.wav");
}

public void draw() {
  if (cam.available()) {
    background(0);
    cam.read();
    
    //Obtiene la imagen de la cámara
    img.copy(cam, 0, 0, cam.width, cam.height, 
    0, 0, img.width, img.height);
    img.copyTo();
    
    //Imagen de grises
    Mat gris = img.getGrey();
    
    if(leyeClosed && reyeClosed) {
      // Imagen de entrada
      if(!alarm.isPlaying()) alarm.play();
      image(img,random(-5,5),random(-5,5));
    } else {
      if(alarm.isPlaying()) alarm.stop();
      if(leyeClosed || reyeClosed) {
        //Copia de Mat a CVImage
        cpMat2CVImage(gris,img);
      }
      // Imagen de entrada
      image(img,0,0);
    }
    //Detección y pintado de contenedores
    FaceDetect(gris);
    
    gris.release();
  }
}

void FaceDetect(Mat grey) {
  Mat auxroi;
  
  //Detección de rostros
  MatOfRect faces = new MatOfRect();
  face.detectMultiScale(grey, faces, 1.15, 3, 
    Objdetect.CASCADE_SCALE_IMAGE, 
    new Size(60, 60), new Size(200, 200));
  Rect [] facesArr = faces.toArray();
  
   //Dibuja contenedores de los ojos. Sin relleno
  noFill();
  
  //Búsqueda de ojos
  MatOfRect leyes,reyes;
  for (Rect r : facesArr) {    
    //Izquierdo (en la imagen)
    leyes = new MatOfRect();
    Rect roi=new Rect(r.x,r.y,(int)(r.width*0.7),(int)(r.height*0.6));
    auxroi= new Mat(grey, roi);
    
    //Detecta
    leye.detectMultiScale(auxroi, leyes, 1.15, 3, 
    Objdetect.CASCADE_SCALE_IMAGE, 
    new Size(30, 30), new Size(200, 200));
    Rect [] leyesArr = leyes.toArray();
    
    // Comprobamos si el ojo está visible
    if(leyesArr.length == 0) leyeClosed = true;
    else leyeClosed = false;
    
    //Dibuja
    stroke(0,255,0);
    for (Rect rl : leyesArr) {
      rect(rl.x+r.x, rl.y+r.y, rl.height, rl.width);   //Strange dimenions change
    }
    leyes.release();
    auxroi.release(); 
     
    //Derecho (en la imagen)
    reyes = new MatOfRect();
    roi=new Rect(r.x+(int)(r.width*0.3),r.y,(int)(r.width*0.7),(int)(r.height*0.6));
    auxroi= new Mat(grey, roi);
    
    //Detecta
    reye.detectMultiScale(auxroi, reyes, 1.15, 3, 
    Objdetect.CASCADE_SCALE_IMAGE, 
    new Size(30, 30), new Size(200, 200));
    Rect [] reyesArr = reyes.toArray();
    
    // Comprobamos si el ojo está visible
    if(reyesArr.length == 0) reyeClosed = true;
    else reyeClosed = false;
    
    //Dibuja
    stroke(0,0,255);
    for (Rect rl : reyesArr) {    
      rect(rl.x+r.x+(int)(r.width*0.3), rl.y+r.y, rl.height, rl.width);   //Strange dimenions change
    }
    reyes.release();
    auxroi.release(); 
  }
  
  faces.release();
}

//Copia unsigned byte Mat a color CVImage
void  cpMat2CVImage(Mat in_mat,CVImage out_img) {    
  byte[] data8 = new byte[cam.width*cam.height];
  
  out_img.loadPixels();
  in_mat.get(0, 0, data8);
  
  // Cada columna
  for (int x = 0; x < cam.width; x++) {
    // Cada fila
    for (int y = 0; y < cam.height; y++) {
      // Posición en el vector 1D
      int loc = x + y * cam.width;
      //Conversión del valor a unsigned basado en 
      //https://stackoverflow.com/questions/4266756/can-we-make-unsigned-byte-in-java
      int val = data8[loc] & 0xFF;
      //Copia a CVImage
      out_img.pixels[loc] = color(val);
    }
  }
  out_img.updatePixels();
}
