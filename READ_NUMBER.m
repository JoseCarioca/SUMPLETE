function number = READ_NUMBER()

    cam = webcam;  % Accede a la primera cámara disponible
    resolutions = cam.AvailableResolutions;  % Obtiene las resoluciones disponibles
    %disp(resolutions);
    cam.Resolution = resolutions{1};  % Establece la resolución más baja disponible
    global stopExecution;
    stopExecution = false;
    figure,  % Crea una figura para mostrar las imágenes procesadas

    while true  % Comienza un bucle infinito
        if stopExecution
            stopExecution = false;
            close;
            return;

        end
        I = im2gray(cam.snapshot());  % Captura una imagen de la cámara y la convierte a escala de grises
        tama_imagen = prod(size(I));  % Calcula el tamaño total de la imagen

        bw = ~imbinarize(I);  % Binariza la imagen y la invierte
        bw = bwareaopen(bw, 50);  % Elimina pequeñas áreas (menores a 50 píxeles)
        ele = ones(10, 10);  % Define un elemento estructurante 5x5 para la dilatación
        bw = imdilate(bw, ele);  % Aplica la dilatación para resaltar las características

        props = regionprops(bw, "BoundingBox", "Area");  % Obtiene las propiedades de las regiones

        hold off;
        imshow(I, []);  % Muestra la imagen binarizada
        hold on;
        cuadricula = encuentra_cuadricula_numero(props, tama_imagen);  % Busca la cuadrícula que contiene el número

        if isfield(cuadricula, 'BoundingBox')  % Si se encuentra una cuadrícula
            bbox = cuadricula.BoundingBox;  % Obtiene las coordenadas del recuadro que rodea la cuadrícula
            rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);  % Dibuja un rectángulo alrededor de la cuadrícula
            hold on;

            imagen = imcrop(I, bbox);  % Recorta la imagen original según el BoundingBox encontrado

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ROTAR LA IMAGEN
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            E = edge(imagen, 'canny', [], 2);  % Aplica el detector de bordes Canny con un sigma de 2 (robusto al ruido)

            % Calcula la transformada de Hough sobre la imagen binaria
            [H, theta, rho] = hough(E);
            % Obtiene las líneas de la transformada de Hough
            peaks = houghpeaks(H, 81);
            max_dist = sqrt(size(imagen, 1)^2 + size(imagen, 2)^2);  % Calcula la distancia máxima en la imagen

            lineas = houghlines(E, theta, rho, peaks, 'FillGap', max_dist);  % Extrae las líneas detectadas

            [~, i] = min(abs([lineas.theta]));  % Encuentra la línea con el ángulo más cercano a 0
            imagen = imrotate(255 - imagen, lineas(i).theta, 'nearest', 'loose');  % Rota la imagen para corregir la inclinación

            % Recorta de nuevo la imagen para eliminar el margen después de la rotación
            bw = bwareaopen(imbinarize(imagen), 50);
            %imshow(bw);  % Muestra la imagen binarizada después de la corrección de orientación
            %hold on;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % AHORA RECORTAR LA IMAGEN DE NUEVO
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            props = regionprops(bw, "BoundingBox", "Area");  % Vuelve a obtener las propiedades de las regiones detectadas

            numero_detectado = detectar_numero(bw, props);  % Detecta el número en la imagen procesada

            % Si el número detectado es diferente de 0, se termina el proceso
            if numero_detectado ~= 0 
                number = numero_detectado - 1;  % Ajusta el número detectado (resta 1)
                sound(sin(2 * pi * 1000 * (0:1 / 44100:0.2)), 44100);  % Reproduce un sonido de confirmación
                close;
                return  % Retorna el número detectado
            end
        end
    %hold off;  % Finaliza la visualización
    end

    
end



