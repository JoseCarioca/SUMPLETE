function cuadricula = encuentra_cuadricula_numero(props,tam_im)
%ENCUENTRACUADRICULA 
%encuentra el prop de la cuadricula de la imagen

    cuadricula = NaN;
    
    bboxes = vertcat(props.BoundingBox);
    % Extraer las áreas de las regiones
    areas = bboxes(:, 3) .* bboxes(:, 4);
    
    % Ordenar las áreas de mayor a menor (o menor a mayor)
    [a, ind] = sort(areas, 'descend'); 
    
    % Reordenar las propiedades según el índice ordenado
    props = props(ind);
    
    puntos = vertcat(props.BoundingBox);

    for i = 1 : length(props)
        %compruba que la imagen sea un cuadrado y que tenga un tamaño
        %adecuado
       box = props(i).BoundingBox;
        % rectangle('Position', box, 'EdgeColor', 'r', 'LineWidth', 2);
            % hold on;
             

         if box(3)*box(4) < 0.01*tam_im %si es menor como estan ordenados de mayor a menor se descartan
        
             return
         end

        if abs(box(3)-box(4))<= 0.1*box(3)
           disp("ok")
            ind = (box(1) <= puntos(:,1)) & (puntos(:,1) <= (box(1) + box(3))) & ...  % X dentro de [x, x+width]
                (box(2) <= puntos(:,2)) & (puntos(:,2) <= (box(2) + box(4)));       % Y dentro de [y, y+height]
            
            
             %text(box(1),box(2),num2str(sum(ind)),"Color","r","FontSize",50);
             %pause(2);
            if sum(ind) >= 1 &&  sum (ind) <= 3
               
                cuadricula = props(i);
                return

               
            end

         
            


            
            
            
        end
    end
end