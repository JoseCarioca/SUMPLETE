function [numeros_detectados , num_numeros ] = detectarNumeros(bw, props ,box )
    % Función para detectar números basados en correlación con plantillas preguardadas
    % 
    % Inputs:
    %   bw             - Imagen binaria de entrada
    %   props          - Estructura con propiedades (e.g., BoundingBox) de objetos detectados
    %   box es el bounding box de la tabla(tablero)
    %
    % Outputs:
    %   Imprime los números detectados en la consola
    num_numeros = 0;
    tam_imag = size(bw);
    %tam_min = 0.0007 * prod(tam_imag); irrelevante pq se hace en el
    %bwareaopen
    tam_max = 0.007 * prod(tam_imag);
    
    correcto = 0;
    error = 0;
    % Cargar las plantillas desde el archivo .mat
    load('imagenes.mat', 'im');
    numeros_detectados = zeros(1,length(props));
    
   % Validar que las plantillas existan en el archivo
    if ~exist('im', 'var')
        error('El archivo no contiene la variable "im".');
    end

    % Iterar sobre cada propiedad detectada
    for i = 1:length(props)

        if props(i).BoundingBox(3)*props(i).BoundingBox(4) < tam_max
            % Extraer la región correspondiente al número
            num_img = imcrop(bw, props(i).BoundingBox);
    
            % Inicializar los puntajes de correlación
            scores = zeros(1, 9);
    
            % Comparar la imagen con cada plantilla
            for j = 1:10
                scores(j) = corr2(imresize(num_img,size(im{j})), im{j});
            end
            
            [maximo,numero_detectado] = max(scores);

            if maximo > 0.55
                % Determinar el número detectado
                correcto = correcto + 1;
                %primero ver si esta dentro del tablero para contarlo:
                if (props(i).BoundingBox(1) <= box(3)) && (props(i).BoundingBox(2) <= box(4)) 
                    num_numeros = num_numeros + 1;
                end
               


               
                %disp(scores(numero_detectado));
                numeros_detectados(i) = numero_detectado;
                
                
            else
                error = error + 1;
            end

        end
    end

    if abs(correcto)/(correcto+error) < 0.9
        num_numeros = 5;%numero no cuadrado perfecto
        %fprintf("error calculado = %d\n",abs(correcto-error)/(correcto+error));
    end
end