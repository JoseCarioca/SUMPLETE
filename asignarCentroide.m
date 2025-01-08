function centroides = asignarCentroide(vector, matriz)
    % Asigna un vector al centroide más cercano en una matriz de centroides.
    % vector: Vector de características (M x D).
    % matriz: Matriz de centroides (K x D), donde K es el número de centroides.
    % idxMin: Índice del centroide más cercano.
    centroides = zeros(1,size(vector,1));
    for i = 1:size(vector,1)
        [~, centroides(i)] = min(sqrt(sum((matriz - vector(i,:)).^2, 2)));
    end
    
end
