
function tablero = READ_BOARD()

 cam = webcam;  % Accede a la primera cámara disponible
 resolutions = cam.AvailableResolutions;
 %disp(resolutions);
 cam.Resolution = resolutions{1};




%Im =im2gray(imread('Captura24.PNG'));
%tama_imagen = prod(size(Im));
%max_dist = sqrt(size(Im,1)^2 + size(Im,2)^2);

%coeficientes_numeros = load("coeficientesHU.mat").inv;

figure,

while true




%I = imrotate(Im,rot);
I = im2gray(cam.snapshot());
tama_imagen = prod(size(I));


bw = ~imbinarize(I);
ele = ones(5,5);
% Dilataciónimrotate
bw = imdilate(bw,ele);
bw = bwareaopen(bw,50);

props = regionprops(bw,"BoundingBox","Area");




hold off;
imshow(I,[]);
hold on;
cuadricula = encuentra_cuadriculav2(props,tama_imagen);

if isfield(cuadricula, 'BoundingBox')
    bbox = cuadricula.BoundingBox;
    %plotear rectangulo
    rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
    hold on;

    bbox(3) = floor(1.25*bbox(3) );%añadir margenes para los numeros exteriores
    bbox(4) = floor(1.25*bbox(4));

   
    if bbox(4)+bbox(2) > size(I,1) || bbox(3)+bbox(1) > size(I,2)
        text(30, 30, 'Aleja un poco la camara', 'Color', 'red', 'FontSize', 20);
        hold off;
    elseif bbox(4)+bbox(2) < min(size(I))*0.65 || bbox(3)+bbox(1) < min(size(I))*0.65
        text(30, 30, 'Acerca un poco la camara', 'Color', 'red', 'FontSize', 20);
        hold off;
    else
        text(30, 30, 'Distancia OK', 'Color', 'green', 'FontSize', 20);
    hold off;

    
        imagen = imcrop(I,bbox);%saca la imagen sin editar
        
        
    
        rectangle('Position', cuadricula.BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);%muestra el rectangulo 
        
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
        cuadricula = NaN;
        if ~isempty(lineas)
    
           [~,i] = min(abs([lineas.theta]));
           imagen = imrotate(255-imagen,lineas(i).theta,'nearest','loose');
          
           %ahora que la imagen esta recta debemos volver a recortar el marco
           

        
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%AHORA RECORTAR LA IMAGEN DE NUEVO


        props = regionprops(bwareaopen(imdilate(imbinarize(imagen),ele),50),"BoundingBox","Area");

        [cuadricula,n] = encuentra_cuadriculav2(props,prod(size(imagen))); % n aproxima tam de tablero
        end


        if isfield(cuadricula, 'BoundingBox')
            bbox = cuadricula.BoundingBox;
            tamano_cuadricula = sqrt(n);

       imagen = imcrop(imagen,[bbox(1),bbox(2) ...
             ,bbox(3)+bbox(3)/tamano_cuadricula,bbox(4)+bbox(4)/tamano_cuadricula]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%AHORA LA IMAGEN ESTA BIEN HAY QUE CONTAR LOS NUMEROS DE FUERA Y
        %%DENTRO DEL TABLERO Y GUARDARLO EN LA MATRIZ

       bw = imbinarize(imagen);
       bw = bwareaopen(bw,floor(0.0003 * prod(size(bw))));
            imshow(bw,[]);
            hold on;
            rectangle('Position', [1,1,bbox(3),bbox(4)], 'EdgeColor', 'r', 'LineWidth', 2);
            hold on;
        end
        %ORDENAR SEGUN EL PUNTO X PARA SABER EL ORDEN
        props = regionprops(bw,"BoundingBox");
        bboxes = vertcat(props.BoundingBox);
        [~,inds] = sort(bboxes(:,1),"ascend");
        props = props(inds);
        
        %DETECTAR LOS NUMEROS 
        [numeros_detectados,num_numeros] = detectarNumeros(bw,props,[1,1,bbox(3),bbox(4)]);
         
        %fprintf("numeros dentro de cuadricula = %d\n",num_numeros);

        %COMPROBAR EL TAMAÑO DEL TABLERO
        tamano_tablero = sqrt(num_numeros);
        esCuadradoPerfecto = floor(tamano_tablero)^2 == num_numeros;
        %SI NO ES CUADRADO PERFECTO (TABLERO CUADRADO) VOLVER AL PRINCIPIO
        if esCuadradoPerfecto
            tamano_tablero = round(tamano_tablero);

            tablero = zeros(tamano_tablero+1,tamano_tablero+1);
            %TAMAÑOS DE LAS CASILLAS PARA SABER A QUE CASILLA PERTENECE
            %CADA NUMERO
            casilla_x = bbox(3)/tamano_tablero;
            casilla_y = bbox(4)/tamano_tablero;
            
            for i = 1 : length(props)
                
                
                if numeros_detectados(i) ~= 0 
                    coor = props(i).BoundingBox;
                    
                    x = coor(1)+coor(3)/2;
                    y = coor(2)+coor(4)/2;

                    pos_x = floor(x/casilla_x)+1;
                    pos_y = floor(y/casilla_y)+1;
                    
                    
                    tablero(pos_y,pos_x) = ...%lo convertimos a cadena para añadirlo al final 
                        str2double(strcat(num2str(tablero(pos_y,pos_x)), num2str(numeros_detectados(i)-1)));
                        

                    text(x,y,num2str(numeros_detectados(i)-1),"Color" , "r",fontsize=40);
                    hold on;
                end
                
            end
            %llega aqui si ha leido correctamente
            sound(sin(2*pi*1000*(0:1/44100:0.2)), 44100);
            break;

        end

        end
% 
 end
% 
% 
% 
% 
end
% 
% 
% 
% 

end
