function number = READ_BOARD()

 cam = webcam;  % Accede a la primera cámara disponible
 resolutions = cam.AvailableResolutions;
 %disp(resolutions);
 cam.Resolution = resolutions{1};






figure,

while true





I = im2gray(cam.snapshot());
tama_imagen = prod(size(I));


bw = ~imbinarize(I);
bw = bwareaopen(bw,50);
ele = ones(5,5);
% Dilataciónimrotate
bw = imdilate(bw,ele);


props = regionprops(bw,"BoundingBox","Area");




hold off;
imshow(bw,[]);
hold on;
cuadricula = encuentra_cuadricula_numero(props,tama_imagen);

if isfield(cuadricula, 'BoundingBox')
    bbox = cuadricula.BoundingBox;
    %plotear rectangulo
    rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
    hold on;

    

    
        imagen = imcrop(I,bbox);%saca la imagen sin editar
        
        
    
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %ROTAR LA IMAGEN
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         E = edge(imagen, 'canny', [], 2); % Más robusto contra ruido con sigma=2
    
        
    
        % Calcula la transformada de Hough sobre una imagen binaria
        [H, theta, rho] =hough(E);
        % Obtenemos líneas
        peaks = houghpeaks(H,81);
        max_dist = sqrt(size(imagen,1)^2 + size(imagen,2)^2);
    
        lineas = houghlines(E, theta, rho,peaks,'FillGap',max_dist);
      
        
    
           [~,i] = min(abs([lineas.theta]));
           imagen = imrotate(255-imagen,lineas(i).theta,'nearest','loose');
          
           %ahora que la imagen esta recta debemos volver a recortar el marco
           
        bw = bwareaopen((imbinarize(imagen)),50);
        imshow(bw);
        hold on;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%AHORA RECORTAR LA IMAGEN DE NUEVO


        props = regionprops(bw,"BoundingBox","Area");

        
        numero_detectado = detectar_numero(bw,props);
         
       
          
            
            
                
                
        if numero_detectado ~= 0 
          number = numero_detectado-1;
          sound(sin(2*pi*1000*(0:1/44100:0.2)), 44100);
         return
        
        end
           
      end
            
        hold off;
 end

     
% 
 end
% 
% 
% 
% 

% 
% 
% 
% 


