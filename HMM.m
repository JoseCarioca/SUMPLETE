function [A,B] = HMM(N,codebook,tramas)
%% Entrenamiento de modelos de Markov a partir de los codebook obtenidos

epsilon = 1e-6; 
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
    B0 = zeros(N, size(codebook,1)) + epsilon; % Valores pequeños para evitar ceros
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

    %Normalizar las filas de B0
    B0 = B0 ./ sum(B0, 2);
    %sum(B0,2)
    
    %[Aaux,Baux,secuencia] = initializeHMM(X, codebook, N);
    %estimacion = hmmviterbi(secuencia,A0,B0);
    [Aaux,Baux] = hmmtrain(secuencia,A0,B0,'Maxiterations',1500,'Tolerance',1e-6);
    A = A + Aaux;
    B = B + Baux;

end

A = A/length(GRAB);
B = B/length(GRAB);
B(B == 0) = epsilon;
B = B ./ sum(B, 2); % Renormalize rows
end




function [A, B,sequence] = initializeHMM(X, codebook, N)
    % Inputs:
    % X         - Feature matrix (M x D), where M is the number of samples
    %             and D is the feature dimension (e.g., MFCCs).
    % codebook  - K x D matrix of centroids from K-means clustering.
    % N         - Number of states in the HMM.
    %
    % Outputs:
    % A         - N x N state transition matrix.
    % B         - N x K emission probability matrix.

    % Step 1: Quantize the data (map features to codebook centroids)
    M = size(X, 1); % Number of feature frames
    sequence = knnsearch(codebook, X); % Map each feature vector to a centroid index (1 to K)
    K = size(codebook, 1); % Number of centroids (emission symbols)

    % Step 2: Initialize the State Transition Matrix (A)
    % Each state has equal probability of self-looping and transitioning to the next state
    A = zeros(N, N);
    for i = 1:N
        if i < N
            A(i, i) = 1 / M; % Self-loop
            A(i, i+1) = 1 / M; % Transition to the next state
        else
            A(i, i) = 1 / M; % Self-loop for the final state
        end
    end
    % Normalize rows
    A = A ./ sum(A, 2);

    % Step 3: Initialize the Emission Probability Matrix (B)
    % Count the occurrences of each centroid for each state
    B = zeros(N, K);

    % Split the sequence into N equal segments (one per state)
    stateBoundaries = round(linspace(1, M+1, N+1)); % N+1 boundaries
    for i = 1:N
        % Extract the segment corresponding to state i
        stateIndices = sequence(stateBoundaries(i):stateBoundaries(i+1)-1);
        % Count emissions (histogram of symbols for this state)
        for k = 1:K
            B(i, k) = sum(stateIndices == k);
        end
    end

    % Normalize rows of B to make them probabilities
    B = B ./ sum(B, 2);

end


% Input: All samples and corresponding codebook
function [trainedA, trainedB] = trainHMM(samples, codebook, N, K)
    % Inputs:
    % samples  - Cell array of feature matrices {X1, X2, ..., Xn}
    % codebook - K x D matrix of centroids from K-means clustering
    % N        - Number of states in the HMM
    % K        - Number of codebook centroids (emission symbols)
    %
    % Outputs:
    % trainedA - Trained state transition matrix
    % trainedB - Trained emission probability matrix

    % Step 1: Quantize all samples
    quantizedSequences = cell(size(samples));
    for i = 1:length(samples)
        % Map each feature vector in the sample to the nearest centroid
        quantizedSequences{i} = knnsearch(codebook, samples{i});
    end

    % Step 2: Initialize A and B
    [A, B] = initializeHMM(samples{1}, codebook, N); % Initialize with first sample

    % Step 3: Aggregate and Train the HMM using hmmtrain
    options = statset('MaxIter', 1000, 'TolFun', 1e-6); % Set training options
    [trainedA, trainedB] = hmmtrain(quantizedSequences, A, B);
end


