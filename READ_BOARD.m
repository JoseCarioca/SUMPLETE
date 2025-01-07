function tablero = READ_BOARD()

    cam = webcam;  % Accede a la primera cámara disponible
    resolutions = cam.AvailableResolutions; % Obtiene las resoluciones disponibles de la cámara
    %disp(resolutions); % Descomentar para ver las resoluciones
    cam.Resolution = resolutions{1}; % Establece la resolución de la cámara

    figure, % Prepara la ventana para mostrar la imagen

    while true

        I = im2gray(cam.snapshot()); % Captura la imagen en escala de grises
        tama_imagen = prod(size(I)); % Calcula el tamaño total de la imagen

        bw = ~imbinarize(I); % Convierte la imagen a blanco y negro (invertida)
        ele = ones(5,5); % Define un elemento estructurante para operaciones morfológicas

        % Dilatación de la imagen para mejorar la detección de objetos
        bw = imdilate(bw, ele);
        bw = bwareaopen(bw, 50); % Elimina objetos pequeños (menos de 50 píxeles)

        % Obtiene propiedades de las regiones detectadas (como el BoundingBox)
        props = regionprops(bw, "BoundingBox", "Area");

        hold off;
        imshow(I, []); % Muestra la imagen original
        hold on;
        
        % Detecta la cuadrícula del tablero
        cuadricula = encuentra_cuadriculav2(props, tama_imagen);

        % Si se detecta una cuadrícula
        if isfield(cuadricula, 'BoundingBox')
            bbox = cuadricula.BoundingBox; % Obtiene el BoundingBox de la cuadrícula
            % Dibuja el rectángulo que marca la cuadrícula
            rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
            hold on;

            % Ajusta los márgenes del BoundingBox
            bbox(3) = floor(1.25*bbox(3)); 
            bbox(4) = floor(1.25*bbox(4));

            % Verifica si el tamaño del BoundingBox es adecuado
            if bbox(4) + bbox(2) > size(I, 1) || bbox(3) + bbox(1) > size(I, 2)
                text(30, 30, 'Aleja un poco la camara', 'Color', 'red', 'FontSize', 20);
                hold off;
            elseif bbox(4) + bbox(2) < min(size(I)) * 0.65 || bbox(3) + bbox(1) < min(size(I)) * 0.65
                text(30, 30, 'Acerca un poco la camara', 'Color', 'red', 'FontSize', 20);
                hold off;
            else
                text(30, 30, 'Distancia OK', 'Color', 'green', 'FontSize', 20);
                hold off;

                % Recorta la imagen para centrarse en el tablero
                imagen = imcrop(I, bbox);

                rectangle('Position', cuadricula.BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2); % Muestra el rectángulo de la cuadrícula

                % Rotación de la imagen para corregir la inclinación
                E = edge(imagen, 'canny', [], 2); % Detecta los bordes en la imagen
                [H, theta, rho] = hough(E); % Calcula la transformada de Hough
                peaks = houghpeaks(H, 81); % Detecta los picos en la transformada de Hough
                max_dist = sqrt(size(imagen, 1)^2 + size(imagen, 2)^2); % Calcula la distancia máxima en la imagen
                lineas = houghlines(E, theta, rho, peaks, 'FillGap', max_dist); % Extrae las líneas de la transformada de Hough

                if ~isempty(lineas)
                    [~, i] = min(abs([lineas.theta])); % Encuentra la línea más recta
                    imagen = imrotate(255 - imagen, lineas(i).theta, 'nearest', 'loose'); % Rota la imagen para alinearla

                    % Vuelve a recortar el área de la cuadrícula
                    props = regionprops(bwareaopen(imdilate(imbinarize(imagen), ele), 50), "BoundingBox", "Area");
                    [cuadricula, n] = encuentra_cuadriculav2(props, prod(size(imagen))); % Recalcula la cuadrícula
                end

                % Recorta la imagen después de la corrección de la inclinación
                if isfield(cuadricula, 'BoundingBox')
                    bbox = cuadricula.BoundingBox;
                    tamano_cuadricula = sqrt(n); % Calcula el tamaño aproximado de la cuadrícula
                    imagen = imcrop(imagen, [bbox(1), bbox(2), bbox(3) + bbox(3)/tamano_cuadricula, bbox(4) + bbox(4)/tamano_cuadricula]);
                end

                % Procesa la imagen para detectar los números
                bw = imbinarize(imagen); % Convierte la imagen recortada en una imagen binaria
                bw = bwareaopen(bw, floor(0.0003 * prod(size(bw)))); % Elimina el ruido pequeño
                imshow(bw, []); % Muestra la imagen binaria
                hold on;
                rectangle('Position', [1, 1, bbox(3), bbox(4)], 'EdgeColor', 'r', 'LineWidth', 2); % Dibuja el rectángulo de la cuadrícula

                % Ordena los números según su coordenada X
                props = regionprops(bw, "BoundingBox");
                bboxes = vertcat(props.BoundingBox);
                [~, inds] = sort(bboxes(:,1), "ascend"); % Ordena los objetos por su posición en X
                props = props(inds);

                % Detecta los números en la imagen
                [numeros_detectados, num_numeros] = detectarNumeros(bw, props, [1, 1, bbox(3), bbox(4)]);

                % Verifica si el número de celdas detectadas forma un cuadrado perfecto
                tamano_tablero = sqrt(num_numeros);
                esCuadradoPerfecto = (floor(tamano_tablero)^2 == num_numeros && num_numeros >= 9);
                if esCuadradoPerfecto
                    tamano_tablero = round(tamano_tablero); % Redondea el tamaño del tablero
                    tablero = zeros(tamano_tablero + 1, tamano_tablero + 1); % Crea la matriz del tablero

                    % Calcula el tamaño de las casillas en X e Y
                    casilla_x = bbox(3) / tamano_tablero;
                    casilla_y = bbox(4) / tamano_tablero;

                    for i = 1:length(props)
                        if numeros_detectados(i) ~= 0
                            coor = props(i).BoundingBox;
                            x = coor(1) + coor(3) / 2; % Calcula el centro de la casilla en X
                            y = coor(2) + coor(4) / 2; % Calcula el centro de la casilla en Y

                            % Determina la posición de la casilla en el tablero
                            pos_x = floor(x / casilla_x) + 1;
                            pos_y = floor(y / casilla_y) + 1;

                            % Actualiza el tablero con el número detectado
                            tablero(pos_y, pos_x) = str2double(strcat(num2str(tablero(pos_y, pos_x)), num2str(numeros_detectados(i) - 1)));
                            text(x, y, num2str(numeros_detectados(i) - 1), "Color", "r", 'FontSize', 40); % Muestra el número en la imagen
                            hold on;
                        end
                    end

                    if ~any(tablero(1:end-1,1:end-1) > 9)

                        sound(sin(2 * pi * 1000 * (0:1 / 44100:0.2)), 44100); % Emite un sonido si la lectura fue exitosa
                       break; % Termina el bucle cuando se ha leído correctamente el tablero
                    end

                end

            end
        end
    end
end
