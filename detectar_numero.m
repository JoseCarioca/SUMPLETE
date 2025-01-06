function numero = detectarNumeros(bw, props)
    % Función para detectar números basados en correlación con plantillas preguardadas
    % 
    % Inputs:
    %   bw             - Imagen binaria de entrada
    %   props          - Estructura con propiedades (e.g., BoundingBox) de objetos detectados
    %   box es el bounding box de la tabla(tablero)
    %
    % Outputs:
    %   Imprime los números detectados en la consola
   
    % Cargar las plantillas desde el archivo .mat
    load('imagenes.mat', 'im');
    
    numero = 0;
   
    
   % Validar que las plantillas existan en el archivo
    if ~exist('im', 'var')
        error('El archivo no contiene la variable "im".');
    end

    % Iterar sobre cada propiedad detectada
    for i = 1:length(props)

       
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
                numero = numero_detectado;
                return;
                
            end

     end
end

