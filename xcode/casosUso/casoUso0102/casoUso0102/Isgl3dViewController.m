//
//  Isgl3dViewController.m
//  casoUso0101
//
//  Created by Pablo Flores Guridi on 01/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Isgl3dViewController.h"
#import "isgl3d.h"
#import "claseDibujar.h"


@interface Isgl3dViewController()

@property(nonatomic, retain) AVCaptureSession * session;
@property(nonatomic, retain) AVCaptureDevice * videoDevice;
@property(nonatomic, retain) AVCaptureDeviceInput * videoInput;
@property(nonatomic, retain) AVCaptureVideoDataOutput * frameOutput;
@property(nonatomic, retain) CIContext* context;

//@property(nonatomic, retain) CIImage* ciImage;
//@property(nonatomic, retain) CVPixelBufferRef pb;
//@property(nonatomic, retain) CGImageRef ref;

@end

@implementation Isgl3dViewController

@synthesize session = _session;
@synthesize videoDevice = _videoDevice;
@synthesize videoInput = _videoInput;
@synthesize frameOutput = _frameOutput;
@synthesize context = _context;
@synthesize videoView = _videoView;
@synthesize isgl3DView = _isgl3DView;
@synthesize kalman = _kalman;
@synthesize sensors = _sensors;
@synthesize LSD = _LSD;
@synthesize LSD_original = _LSD_original;
@synthesize segments = _segments;
@synthesize detectedPts = _detectedPts;
@synthesize reproyectedPts = _reproyectedPts;
@synthesize segmentFilterThres = _segmentFilterThres;
@synthesize kalmanErrorGain = _kalmanErrorGain;
@synthesize newRefPose = _newRefPose;

/*para DIBUJAR*/
claseDibujar *cgvista;
float **reproyectados;
float aux[3];
float intrinsecos[3][3] = {{589.141,    0,          240},
                            {0,         580.754,	180},
                            {0,         0,          1	}};

/*Variables para la imagen*/
unsigned char* pixels;
size_t width;
size_t height;
size_t bitsPerComponent;
size_t bitsPerPixel;
float* luminancia;
double* luminancia_double;
int d;
int dProcesamiento;
UIImage *imagen;

/*Variables para el procesamiento*/
float* list;
double* list_double;
float*listFiltrada;
//float** esquinas;

float **imagePoints,**imagePointsCrop;
int listSize;
int listSize_original;
int listFiltradaSize;
float distance_thr=36;
float rotacion[9];
float traslacion[3];
int errorMarkerDetection; //Codigo de error del findPointCorrespondence

/*Variables para el Coplanar*/
int NumberOfPoints=36;
int cantPtosDetectados;
long int i;
float **object, **objectCrop, f=589.141; /*f: focal length en pixels*/
bool PosJuani=true;

//modern coplanar requiere float** en lugar de [][]
float *Tras;
float *TrasPrev;
float **Rot;
float **RotRef;
float **RotRefTras;
float **RotAux;
float center[2]={240, 180};           
bool verbose;
float* angles1;
float* angles2;

/* LSD parameters */
//float scale_inv = 2; /*scale_inv= 1/scale, scale=0.5*/
//float sigma_scale = 0.6; /* Sigma for Gaussian filter is computed as
//                           sigma = sigma_scale/scale.                    */
//float quant = 2.0;       /* Bound to the quantization error on the
//                           gradient norm.                                */
//float ang_th = 22.5;     /* Gradient angle tolerance in degrees.           */
//float log_eps = 0.0;     /* Detection threshold: -log10(NFA) > log_eps     */
//float density_th = 0.0; //0.7  /* Minimal density of region points in rectangle. */
//int n_bins = 1024;        /* Number of bins in pseudo-ordering of gradient
//                           modulus.                                       */
///*Up to here */
//image_float luminancia_sub;
//image_float image;
int cantidad;

/*Kalman variables*/
kalman_state thetaState,psiState,phiState,xState,yState,zState;
//bool kalman=true;
bool init=true;
float** measureNoise;
float** processNoise;
float** stateEvolution;
float** measureMatrix;
float** errorMatrix;
float** kalmanGain;
float* states;
kalman_state_3 state;

int count;
float auxVal=0;


- (CIContext* ) context
{
    if(!_context)
    {
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}

- (void) dealloc {
    [super dealloc];
}


-(void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
  //  NSLog(@"Capture output");
    
    CVPixelBufferRef pb  = CMSampleBufferGetImageBuffer(sampleBuffer);
    //CVPixelBufferRetain(pb);
    CIImage* ciImage = [CIImage imageWithCVPixelBuffer:pb];
    CGImageRef ref = [self.context createCGImage:ciImage fromRect:ciImage.extent];
    
    
    /*Obtengo algunas catacteristicas de la imagen de interes*/
    width = CGImageGetWidth(ref);
    height = CGImageGetHeight(ref);
    bitsPerComponent     = CGImageGetBitsPerComponent(ref);
    bitsPerPixel         = CGImageGetBitsPerPixel(ref);
    d= bitsPerPixel/bitsPerComponent;
    
    
    CVPixelBufferLockBaseAddress(pb, 0);
    pixels = (unsigned char *)CVPixelBufferGetBaseAddress(pb);
    
    if(_LSD_original) [self lsdOriginal];
    else [self procesamiento];
    
    imagen=[[UIImage alloc] initWithCGImage:ref scale:1.0 orientation:UIImageOrientationUp];
    
    
    [self performSelectorOnMainThread:@selector(setImage:) withObject: imagen waitUntilDone:YES];

    CGImageRelease(ref);
    CVPixelBufferUnlockBaseAddress(pb, 0);
    
    [imagen release];
    
    
}

- (void) setImage: (UIImage*) imagen
{
    self.videoView.image = imagen;
 
    
    if (cgvista.dealloc==0)
    {
        [cgvista removeFromSuperview];
        cgvista.dealloc=1;
    }
    /*-------------------------------| Clase dibujar | ----------------------------------*/
    
    if (_LSD_original && listSize_original!=0)
    {
        cgvista.cantidadLsd_original=listSize_original;
        cgvista.lsd_all_original = _LSD_original;
        cgvista.segmentos_lsd_original = list_double;
        
        listSize=0;
        [self.videoView addSubview:cgvista];
        
        cgvista.backgroundColor=[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        
        cgvista.bounds=CGRectMake(0, 0, 1024, 768);
        
        [cgvista setNeedsDisplay];
        
        cgvista.dealloc=0;
        
    }
    else if ((_segments || _detectedPts || _reproyectedPts || _LSD)&&listSize!=0)
    {
        cgvista.lsd_all_original = _LSD_original;
        cgvista.cantidadSegmentos = listFiltradaSize;
        cgvista.cantidadLsd = listSize;
        
        
        cgvista.segments = _segments;
        cgvista.corners = _detectedPts;
        cgvista.reproyected = _reproyectedPts;
        cgvista.lsd_all = _LSD;
        
        listSize_original=0;
        
        if ( _segments ) cgvista.segmentos = listFiltrada;
        if ( _detectedPts ) cgvista.esquinas = imagePoints;
        if ( _LSD ) cgvista.segmentos_lsd = list;
        
        
        //printf("Cantidad de segments en dibujar : %d\n",listSize);
        
        if ( _reproyectedPts )
        {
            for (int i=0;i<NumberOfPoints;i++)
                
            {
                
                
                MAT_DOT_VEC_3X3(aux, Rot, object[i]);
                VEC_SUM(reproyectados[i],aux,Tras);
                MAT_DOT_VEC_3X3(reproyectados[i], intrinsecos, reproyectados[i]);
                
            }
            cgvista.esquinasReproyectadas = reproyectados;
        }
        
    
        
        [self.videoView addSubview:cgvista];
        
        cgvista.backgroundColor=[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
        
        cgvista.bounds=CGRectMake(0, 0, 1024, 768);
        
        [cgvista setNeedsDisplay];
        
        cgvista.dealloc=0;
    
    }
    /*-------------------------------| Clase dibujar | ----------------------------------*/
    
}




- (void) procesamiento
{
    
    if((pixels[0] != INFINITY)&(height!=0))
    {
    if (true||init) {    
        
        if (verbose) NSLog(@"Procesando!\n");
        
           /*-------------------------------------|PROCESAMIENTO|-------------------------------------*/
        //NSLog(@"rgb2gray in\n");
        /*Se pasa la imagen a nivel de grises*/
        
        cantidad =width*height;
        for(int pixelNr=0;pixelNr<cantidad;pixelNr++) luminancia[pixelNr] =0.30*pixels[pixelNr*4+2] + 0.59*pixels[pixelNr*4+1] + 0.11*pixels[pixelNr*4];

        /*Se corre el LSD a la imagen en niveles de grises*/

        
                
        free(list);
        
       // NSLog(@"LSD in\n");
        list = lsd_encuadro(&listSize, luminancia, width, height);
        //NSLog(@"LSD out\n");

        /*-------------------------------------|FILTRADO|-------------------------------------*/
        
        free(listFiltrada);
        listFiltradaSize =0;
//        printf("segmentFilterThresh= %f\n",_segmentFilterThres);
        /*Filtrado de segmentos detectados por el LSD */
        listFiltrada = filterSegments(&listFiltradaSize , &listSize ,list, _segmentFilterThres);
        
        
        /*-------------------------------------|CORRESPONDENCIAS|-------------------------------------*/
        /*Correspondencias entre marcador real y puntos detectados*/
        errorMarkerDetection = findPointCorrespondances(&listFiltradaSize, listFiltrada,imagePoints);
        
        if (verbose){
            printf("Tamano: %d\n", listSize);
            printf("Tamano filtrada: %d\n", listFiltradaSize);
        }
        
        
        if (errorMarkerDetection>=0) {
            
            cantPtosDetectados=getCropLists(imagePoints, object, imagePointsCrop, objectCrop);
            
            /* eleccion de algoritmo de pose*/
            if (PosJuani){
                CoplanarPosit(cantPtosDetectados, imagePointsCrop, objectCrop, f, center, Rot, Tras);
                //                    for(int i=0;i<3;i++){
                //                        for(int j=0;j<3;j++) Rota[i][j]=Rot[i][j];
                //                        Transa[i]=Tras[i];
                //                    }
                
            }
            else {
                for (int k=0;k<36;k++)
                {
                    imagePointsCrop[k][0]=imagePointsCrop[k][0]-center[0];
                    imagePointsCrop[k][1]=imagePointsCrop[k][1]-center[1];
                }
                Composit(cantPtosDetectados,imagePointsCrop,objectCrop,f,Rot,Tras);
            }
            
            if (false){
                printf("\nPARAMETROS DEL COPLANAR:R y T: \n");
                printf("\nRotacion: \n");
                printf("%f\t %f\t %f\n",Rot[0][0],Rot[0][1],Rot[0][2]);
                printf("%f\t %f\t %f\n",Rot[1][0],Rot[1][1],Rot[1][2]);
                printf("%f\t %f\t %f\n",Rot[2][0],Rot[2][1],Rot[2][2]);
            }
            
            if (_sensors) { //Esto es para usar pose de referencia e ir calculando cambios.
                
                /*Agarro refernecia de attitude*/
                if(_newRefPose||init){
                    referenceAttitude = [manager.deviceMotion.attitude retain];
                    for(int i=0;i<3;i++){
                        RotRef[i][0]=Rot[i][0];
                        RotRef[i][1]=Rot[i][1];
                        RotRef[i][2]=Rot[i][2];
                    }
                    Matrix2Euler(RotRef, angles1, angles2);
                    if(false){
                        printf("\nDeviceMotion refAttitude:\n");
                        printf("roll: %g\npitch: %g\nyaw: %g\n",(180.0/MY_PI)*(referenceAttitude.roll),(180.0/MY_PI)*(referenceAttitude.yaw),-(180.0/MY_PI)*(referenceAttitude.pitch));
                        
                        printf("\nDeviceMotion attitude ref rotation matrix:\n");
                        printf("%g\t: %g\t: %g\n",attitude.rotationMatrix.m11,attitude.rotationMatrix.m12,attitude.rotationMatrix.m13);
                        printf("%g\t: %g\t: %g\n",attitude.rotationMatrix.m21,attitude.rotationMatrix.m22,attitude.rotationMatrix.m23);
                        printf("%g\t: %g\t: %g\n",attitude.rotationMatrix.m31,attitude.rotationMatrix.m32,attitude.rotationMatrix.m33);
                    }
                    
                    if(false){
                        printf("\nPosit ref Attitude:\n");
                        printf("roll: %g\npitch: %g\nyaw: %g\n",angles1[0],angles1[1],angles1[2]);
                        
                        printf("\nPosit attitude ref rotation matrix:\n");
                        printf("%g\t: %g\t: %g\n",RotRef[0][0],RotRef[0][1],RotRef[0][2]);
                        printf("%g\t: %g\t: %g\n",RotRef[1][0],RotRef[1][1],RotRef[1][2]);
                        printf("%g\t: %g\t: %g\n",RotRef[2][0],RotRef[2][1],RotRef[2][2]);
                    }
                    
                    _newRefPose=false;
                }
                
                attitude = manager.deviceMotion.attitude;
                [attitude multiplyByInverseOfAttitude:referenceAttitude];
                if(false){
                    printf("\nDeviceMotion attitude change:\n");
                    printf("roll: %g\npitch: %g\nyaw: %g\n",(180.0/MY_PI)*(attitude.roll),(180.0/MY_PI)*(attitude.pitch),(180.0/MY_PI)*(attitude.yaw));
                    
                    printf("\nDeviceMotion attitude change rotation matrix:\n");
                    printf("%g\t: %g\t: %g\n",attitude.rotationMatrix.m11,attitude.rotationMatrix.m12,attitude.rotationMatrix.m13);
                    printf("%g\t: %g\t: %g\n",attitude.rotationMatrix.m21,attitude.rotationMatrix.m22,attitude.rotationMatrix.m23);
                    printf("%g\t: %g\t: %g\n",attitude.rotationMatrix.m31,attitude.rotationMatrix.m32,attitude.rotationMatrix.m33);
                }
                TRANSPOSE_MATRIX_3X3(RotRefTras, RotRef);
                MATRIX_PRODUCT_3X3(RotAux,RotRefTras,Rot);
                Matrix2Euler(RotAux, angles1, angles2);
                
                
                if(false){
                    printf("\nPosit attitude change:\n");
                    printf("roll: %g\npitch: %g\nyaw: %g\n",angles1[0],angles1[1],angles1[2]);
                    
                    
                    printf("\nPosit attitude change rotation matrix:\n");
                    printf("%g\t: %g\t: %g\n",RotAux[0][0],RotAux[0][1],RotAux[0][2]);
                    printf("%g\t: %g\t: %g\n",RotAux[1][0],RotAux[1][1],RotAux[1][2]);
                    printf("%g\t: %g\t: %g\n",RotAux[2][0],RotAux[2][1],RotAux[2][2]);
                }
                
                
                angles2[0]=(180.0/MY_PI)*attitude.roll;
                angles2[1]=(180.0/MY_PI)*attitude.pitch;
                angles2[2]=(180.0/MY_PI)*attitude.yaw;
                
                for (int i=0; i<3; i++) angles1[i]=1.0*angles2[i]+0.0*angles1[i];
                Euler2Matrix(angles1, RotAux);
                
                
                MATRIX_PRODUCT_3X3(Rot, RotRef, RotAux);
                
                if(false){
                    printf("\nPosit attitude change rotation matrix:\n");
                    printf("%g\t: %g\t: %g\n",Rot[0][0],Rot[0][1],Rot[0][2]);
                    printf("%g\t: %g\t: %g\n",Rot[1][0],Rot[1][1],Rot[1][2]);
                    printf("%g\t: %g\t: %g\n",Rot[2][0],Rot[2][1],Rot[2][2]);
                }
            }
            if (_kalman){
                Matrix2Euler(Rot, angles1, angles2);
                if(false){
                    if(init){
                        thetaState = kalman_init(1, 4, 1, angles1[0]);
                        psiState = kalman_init(1, 7, 1, angles1[1]);
                        phiState = kalman_init(1, 0.1, 1, angles1[2]);
//                        xState = kalman_init(1, 8, 1, Tras[0]);
//                        yState = kalman_init(1, 8, 1, Tras[1]);
//                        zState = kalman_init(1, 8, 1, Tras[2]);
                        init=false;
                     }
                     kalman_update(&thetaState, angles1[0]);
                     kalman_update(&psiState, angles1[1]);
                     kalman_update(&phiState, angles1[2]);
//                     kalman_update(&xState, Tras[0]);
//                     kalman_update(&yState, Tras[1]);
//                     kalman_update(&zState, Tras[2]);
                
                     angles1[0]=thetaState.x;
                     angles1[1]=psiState.x;
                     angles1[2]=phiState.x;
//                     Tras[0]=xState.x;
//                     Tras[1]=yState.x;
//                     Tras[2]=zState.x;
                
                     
                
                }
                else{
                    if(init){
                        
                        /* kalman correlacionado */
                        IDENTITY_MATRIX_3X3(stateEvolution);
                        IDENTITY_MATRIX_3X3(measureMatrix);
                        IDENTITY_MATRIX_3X3(processNoise);
                        IDENTITY_MATRIX_3X3(errorMatrix);
                        SCALE_MATRIX_3X3(errorMatrix, 1, errorMatrix);
                        
                        measureNoise[0][0] =4.96249572803608;
                        measureNoise[0][1]=4.31450588099769;
                        measureNoise[0][2]=-0.0459669868120827;
                        measureNoise[1][0]=4.31450588099769;
                        measureNoise[1][1]=7.02354899298729;
                        measureNoise[1][2]=-0.0748919339531972;
                        measureNoise[2][0]=-0.0459669868120827;
                        measureNoise[2][1]=-0.0748919339531972;
                        measureNoise[2][2]=0.00106230567668207;
//                        measureNoise[0][0]=1;
//                        measureNoise[0][1]=0;
//                        measureNoise[0][2]=0;
//                        measureNoise[1][0]=0;
//                        measureNoise[1][1]=1;
//                        measureNoise[1][2]=0;
//                        measureNoise[2][0]=0;
//                        measureNoise[2][1]=0;
//                        measureNoise[2][2]=1;
                       
                        
                        state = kalman_init_3x3(processNoise,measureNoise, errorMatrix,kalmanGain,angles1);
                        
                        xState = kalman_init(1, 0.2, 1, Tras[0]);
                        yState = kalman_init(1, 0.2, 1, Tras[1]);
                        zState = kalman_init(1, 0.2, 1, Tras[2]);

                        
                        init=false;
                    }
                    
//                    printf("kalmanErrorGain= %f\n",_kalmanErrorGain);
                    SCALE_MATRIX_3X3(measureNoise, _kalmanErrorGain, measureNoise);
                    
                    /* kalman correlacionado */
                    kalman_update_3x3(&state, angles1, stateEvolution, measureMatrix);

                    kalman_update(&xState, Tras[0]);
                    kalman_update(&yState, Tras[1]);
                    kalman_update(&zState, Tras[2]);
                    
                    Tras[0]=xState.x;
                    Tras[1]=yState.x;
                    Tras[2]=zState.x;
                    
//                    VEC_PRINT(angles1);
//                    VEC_PRINT(Tras);
                
                }
                Euler2Matrix(angles1, Rot);
                count=0;
                
                
            }
            
        }
        
    }
        
        
        if (verbose){
            printf("\nPARAMETROS DEL COPLANAR:R y T: \n");
            printf("\nRotacion: \n");
            printf("%f\t %f\t %f\n",Rot[0][0],Rot[0][1],Rot[0][2]);
            printf("%f\t %f\t %f\n",Rot[1][0],Rot[1][1],Rot[1][2]);
            printf("%f\t %f\t %f\n",Rot[2][0],Rot[2][1],Rot[2][2]);
            printf("Traslacion: \n");
            printf("%f\t %f\t %f\n",Tras[0],Tras[1],Tras[2]);
        }
    
        if (verbose){
            printf("\nPrimera solucion\n");
            printf("psi1: %g\ntheta1: %g\nphi1: %g\n",angles1[0],angles1[1],angles1[2]);
            printf("\nSegunda solicion\n");
            printf("psi2: %g\ntheta2: %g\nphi2: %g\n",angles2[0],angles2[1],angles2[2]);
        }
        self.isgl3DView.Rotacion=Rot;
        if(false){
            printf("%f\t %f\t %f\n",TrasPrev[0]-Tras[0],TrasPrev[1]-Tras[1],TrasPrev[2]-Tras[2]);
            float thresTras = 0.2;
            if (auxVal<thresTras){
                for (int i=0; i<3; i++) TrasPrev[i]=Tras[i];
                self.isgl3DView.traslacion=TrasPrev;
            }
            auxVal = sqrtf((Tras[0]-TrasPrev[0])*(Tras[0]-TrasPrev[0])+(Tras[1]-TrasPrev[1])*(Tras[1]-TrasPrev[1]));
        }
        else{
            self.isgl3DView.traslacion=Tras;
        }
        
        
        /*-------------------------------------|FIN DEL PROCESAMIENTO|-------------------------------------*/
        
    }
    
}

- (void) lsdOriginal{
    
    cantidad =width*height;
    for(int pixelNr=0;pixelNr<cantidad;pixelNr++) luminancia_double[pixelNr] =0.30*pixels[pixelNr*4+2] + 0.59*pixels[pixelNr*4+1] + 0.11*pixels[pixelNr*4];
    
    free(list_double);
   // NSLog(@"LSD original in\n");
    list_double = lsd(&listSize_original, luminancia_double, width, height);
   // NSLog(@"LSD original out\n");
    
}

- (void) reservarMemoria {
    
    if (verbose) printf("Reservamos memoria");
    
//    free(pixels);
    
    /*Reservamos memoria*/
    Rot=(float**)malloc(3*sizeof(float*));
    for (i=0; i<3;i++) Rot[i]=(float*)malloc(3*sizeof(float));
    
    RotRefTras=(float**)malloc(3*sizeof(float*));
    for (i=0; i<3;i++) RotRefTras[i]=(float*)malloc(3*sizeof(float));
    
    RotRef=(float**)malloc(3*sizeof(float*));
    for (i=0; i<3;i++) RotRef[i]=(float*)malloc(3*sizeof(float));
    
    RotAux=(float**)malloc(3*sizeof(float*));
    for (i=0; i<3;i++) RotAux[i]=(float*)malloc(3*sizeof(float));
    
    Tras=(float*)malloc(3*sizeof(float));
    
    TrasPrev=(float*)malloc(3*sizeof(float));

    angles1=(float*)malloc(3*sizeof(float));
    angles2=(float*)malloc(3*sizeof(float));

    object=(float **)malloc(NumberOfPoints * sizeof(float *));
    for (i=0;i<NumberOfPoints;i++) object[i]=(float *)malloc(3 * sizeof(float));
    
    reproyectados=(float **)malloc(NumberOfPoints * sizeof(float *));
    for (i=0;i<NumberOfPoints;i++) reproyectados[i]=(float *)malloc(3 * sizeof(float));

    objectCrop=(float **)malloc(NumberOfPoints * sizeof(float *));
    for (i=0;i<NumberOfPoints;i++) objectCrop[i]=(float *)malloc(3 * sizeof(float));
    
    imagePointsCrop=(float **)malloc(NumberOfPoints * sizeof(float *));
    for (i=0;i<NumberOfPoints;i++) imagePointsCrop[i]=(float *)malloc(2 * sizeof(float));
  
    imagePoints=(float **)malloc(NumberOfPoints * sizeof(float *));
    for (i=0;i<NumberOfPoints;i++) imagePoints[i]=(float *)malloc(2 * sizeof(float));
    
    //    coplMatrix=(float **)malloc(3 * sizeof(float *));
    //    for (i=0;i<3;i++) coplMatrix[i]=(float *)malloc(NumberOfPoints * sizeof(float));

    pixels = (unsigned char*) malloc(360*480*4*sizeof(unsigned char));
    for (int i=0;i<360*480*4;i++)
    {
        pixels[i]= INFINITY;
    }

    luminancia = (float *) malloc(360*480*sizeof(float));
    luminancia_double = (double *) malloc(360*480*sizeof(double));
    cgvista=[[claseDibujar alloc] initWithFrame:self.videoView.frame]; 
    
    /* READ MARKER MODEL */
   
    
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MarkerQR" ofType:@"txt"];
    
    FILE *filePuntos;
    
    filePuntos=fopen(filePath.UTF8String, "r");
    
    if (filePuntos==NULL)
    {
        printf("Could not open file!");
    }
    else {
        
        for(int i=0; i<36; i++)fscanf(filePuntos,"%f %f %f\n",&object[i][0],&object[i][1],&object[i][2]);
    }
    fclose(filePuntos);
    
    /* END MARKER */
    
//    self.isgl3DView.distanciaMarcador = (float*) malloc(2*sizeof(float));
//    
//    self.isgl3DView.distanciaMarcador[0] = object[0][0] - object[12][0];
//    self.isgl3DView.distanciaMarcador[1] = object[0][1] - object[24][1];
//    /* END MARKER */
    
    /*Reservo memoria para kalman*/
    
    measureNoise=(float **)malloc(3 * sizeof(float *));
    for (int k=0;k<3;k++) measureNoise[k]=(float *)malloc(3 * sizeof(float));
    
    processNoise=(float **)malloc(3 * sizeof(float *));
    for (int k=0;k<3;k++) processNoise[k]=(float *)malloc(3 * sizeof(float));
    
    stateEvolution=(float **)malloc(3 * sizeof(float *));
    for (int k=0;k<3;k++) stateEvolution[k]=(float *)malloc(3 * sizeof(float));
    
    measureMatrix=(float **)malloc(3 * sizeof(float *));
    for (int k=0;k<3;k++) measureMatrix[k]=(float *)malloc(3 * sizeof(float));
    
    errorMatrix=(float **)malloc(3 * sizeof(float *));
    for (int k=0;k<3;k++) errorMatrix[k]=(float *)malloc(3 * sizeof(float));
    
    kalmanGain=(float **)malloc(3 * sizeof(float *));
    for (int k=0;k<3;k++) kalmanGain[k]=(float *)malloc(3 * sizeof(float));
    
    states=(float *)malloc(3 * sizeof(float));
    
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
	isgl3dAllowedAutoRotations allowedAutoRotations = [Isgl3dDirector sharedInstance].allowedAutoRotations;
	if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationNone) {
		return NO;
        
	} else if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationByIsgl3dDirector) {
		
		if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft && allowedAutoRotations != Isgl3dAllowedAutoRotationsPortraitOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationLandscapeRight;
            
		} else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight && allowedAutoRotations != Isgl3dAllowedAutoRotationsPortraitOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationLandscapeLeft;
            
		} else if (interfaceOrientation == UIInterfaceOrientationPortrait && allowedAutoRotations != Isgl3dAllowedAutoRotationsLandscapeOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationPortrait;
            
		} else if (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown && allowedAutoRotations != Isgl3dAllowedAutoRotationsLandscapeOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationPortraitUpsideDown;
		}
        
		// Return true only for portrait
		return  (interfaceOrientation == UIInterfaceOrientationPortrait);
        
	} else if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationByUIViewController) {
		if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && allowedAutoRotations != Isgl3dAllowedAutoRotationsPortraitOnly) {
			return YES;
			
		} else if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && allowedAutoRotations != Isgl3dAllowedAutoRotationsLandscapeOnly) {
			return YES;
			
		} else {
			return NO;
		}
		
	} else {
		NSLog(@"Isgl3dViewController:: ERROR : Unknown auto rotation strategy of Isgl3dDirector.");
		return NO;
	}
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationByUIViewController) {
		CGRect screenRect = [[UIScreen mainScreen] bounds];
		CGRect rect = CGRectZero;
		
		if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			rect = screenRect;
            
		} else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
			rect.size = CGSizeMake( screenRect.size.height, screenRect.size.width );
		}
		
		UIView * glView = [Isgl3dDirector sharedInstance].openGLView;
		float contentScaleFactor = [Isgl3dDirector sharedInstance].contentScaleFactor;
        
		if (contentScaleFactor != 1) {
			rect.size.width *= contentScaleFactor;
			rect.size.height *= contentScaleFactor;
		}
		glView.frame = rect;
	}
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


-(void)createVideo{
    
    casoUso0102AppDelegate *appDelegate = (casoUso0102AppDelegate *)[[UIApplication sharedApplication] delegate];
    ///self.viewController=(Isgl3dViewController*)appDelegate.viewController;
    
    UIImageView* vistaImg = [[UIImageView alloc] init];
    //  vistaImg.image = [UIImage imageNamed:@"Calibrar10.jpeg"];
    
    
    //vistaImg.transform =CGAffineTransformMake(0, 1, -1, 0, 0, 0);
    /* Se ajusta la pantalla*/
    
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullScreenRect = screen.bounds;
    
    printf("%f \t %f\n",fullScreenRect.size.width, fullScreenRect.size.height);
    [vistaImg setCenter:CGPointMake(fullScreenRect.size.width/2, fullScreenRect.size.height/2)];
    [vistaImg setBounds:fullScreenRect];
    
    
    
    //    [vistaImg setNeedsDisplay];
    
    
    [appDelegate.window addSubview:vistaImg];
	[appDelegate.window sendSubviewToBack:vistaImg];
    
    
    self.videoView = vistaImg;
    
    
	// Make the opengl view transparent
	[Isgl3dDirector sharedInstance].openGLView.backgroundColor = [UIColor clearColor];
	[Isgl3dDirector sharedInstance].openGLView.opaque = NO;
    
    
    
    
}




- (void) viewDidLoad{
    
    if (true) printf("viewDidLoad\n");
    
   // [self createVideo];
    [super viewDidLoad];
    
    /*Creamos y seteamos la captureSession*/
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
//    AVCaptureConnection *captureConnection = [self.frameOutput connectionWithMediaType:AVMediaTypeVideo];
//    
//    oneFrame = CMTimeMake(1, 10);
//    captureConnection.videoMinFrameDuration=oneFrame;
//    
//    printf("%d\n",captureConnection.supportsVideoMaxFrameDuration);
//    printf("%d\n",captureConnection.supportsVideoMinFrameDuration);

    /*Creamos al videoDevice*/
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /*Creamos al videoInput*/
    self.videoInput  = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
    
    /*Creamos y seteamos al frameOutpt*/
    self.frameOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    
    self.frameOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id) kCVPixelBufferPixelFormatTypeKey];
    
    
    /*Ahora conectamos todos los objetos*/
    /*Primero le agregamos a la sesion el videoInput y el videoOutput*/
    
    [self.session addInput: self.videoInput];
    [self.session addOutput: self.frameOutput];
    
    /*Le decimos al método que nuestro sampleBufferDelegate (al que se le pasan los pixeles por el metodo captureOutput) es el mismo*/
    dispatch_queue_t processQueue = dispatch_queue_create("procesador", NULL);
   [self.frameOutput setSampleBufferDelegate:self queue:processQueue];
   dispatch_release(processQueue);
//   [self.frameOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    /*Sin esta linea de codigo el context apunta siempre a nil*/
    self.context =  [CIContext contextWithOptions:nil];

    [self.session startRunning];
    
    /* inicializo del motion manager*/
    manager = [[CMMotionManager alloc] init];
    referenceAttitude = nil;
    
    manager.deviceMotionUpdateInterval = 1.0/60.0;
    [manager startDeviceMotionUpdates];
    
    _newRefPose=true;
    _kalman=true;
    _sensors=true;
    _LSD=false;
    _LSD_original = false;
    _segments=false;
    _detectedPts=false;
    _reproyectedPts=false;
    
    listSize_original = 0;
}

//- (void) viewDidUnload {
//	[super viewDidUnload];
//}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end


