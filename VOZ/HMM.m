function [A,B] = HMM(N,codebook,tramas)
%% Entrenamiento de modelos de Markov a partir de los codebook obtenidos

epsilon = 1e-10; 
GRAB = fieldnames(tramas);
A = zeros(N);
B = zeros(N, size(codebook,1));
for grab = 1:length(GRAB)
    X = tramas.(GRAB{grab})'; %queremos una muestra por fila
    %centroides = zeros(size(X,1));
    secuencia = asignarCentroide(X,codebook);
    
    
    numObservaciones = size(secuencia,2);
    % Inicializar la matriz de transición A0
    A0 = zeros(N);
    pasosPorEstado = ceil(size(secuencia,2) / N); % Timesteps por estado
    for i = 1:N-1
        A0(i, i) = 1 - 1/pasosPorEstado;
        A0(i, i+1) = 1/pasosPorEstado;
    end
    A0(N, N) = 1; % Estado final es absorbente
    
    % Inicializar la matriz de observaciones B0
    B0 = zeros(N, size(codebook,1)) + 1e-6; % Valores pequeños para evitar ceros
    for i = 1:N
        inicio = (i-1) * pasosPorEstado + 1;
        fin = min(i * pasosPorEstado, size(secuencia,2));
        if inicio <= size(secuencia,2)
            observaciones = secuencia(inicio:fin);
            for obs = observaciones
                B0(i, obs) = B0(i, obs) + 1;
            end
        end
    end
    
    % Normalizar las filas de B0
    B0 = B0 ./ sum(B0, 2);
    
    
    %estimacion = hmmviterbi(secuencia,A0,B0);
    [Aaux,Baux] = hmmtrain(secuencia,A0,B0,"Maxiterations",1000);
    A = A + Aaux;
    B = B + Baux;

end

A = A/length(GRAB);
B = B/length(GRAB);
B(B == 0) = epsilon;
B = B ./ sum(B, 2); % Renormalize rows
end
