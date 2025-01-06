function cuadricula = encuentra_cuadricula_numero(props,tam_im)
%ENCUENTRACUADRICULA 
%encuentra el prop de la cuadricula de la imagen

    cuadricula = NaN;
    
    bboxes = vertcat(props.BoundingBox);
    % Extraer las áreas de las regiones
    areas = bboxes(:, 3) .* bboxes(:, 4);

    % Ordenar las áreas de mayor a menor (o menor a mayor)
    [~, ind] = sort(areas, 'descend'); 
    
    % Reordenar las propiedades según el índice ordenado
    props = props(ind);
    
    puntos = vertcat(props.BoundingBox);

    for i = 1 : length(props)
        %compruba que la imagen sea un cuadrado y que tenga un tamaño
        %adecuado
       box = props(i).BoundingBox;


         if box(3)*box(4) < 0.005*tam_im %si es menor como estan ordenados de mayor a menor se descartan
        
             return
         end

        if abs(box(3)-box(4))<= 0.05*box(3)
           
            ind = (box(1) <= puntos(:,1)) & (puntos(:,1) <= (box(1) + box(3))) & ...  % X dentro de [x, x+width]
                (box(2) <= puntos(:,2)) & (puntos(:,2) <= (box(2) + box(4)));       % Y dentro de [y, y+height]
            

            if sum(ind) >= 1 &&  sum (ind) <= 3
               
                cuadricula = props(i);
                return

               
            end

         
            


            
            
            
        end
    end
end

