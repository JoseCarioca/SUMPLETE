%% RETRAINED

%% leer datos
rutaDATA = "DIGITS\";
folders = dir(rutaDATA);
folders = folders([folders.isdir]);

% Eliminar las carpetas '.' y '..' (referencias a actual y padre)
folders = folders(~ismember({folders.name}, {'.', '..'}));

% Guardar las rutas completas de las carpetas
rutasCarpetas ={folders.name};

vacios = [];
TRAMAS = struct();
numeros = 1:9;
N = 3:6;
prueba = false; % want to test with all data?
K = [64 128 256];
Fs = 8000; % Sampling frequency (8 kHz)


%% Para cada carpeta (numeros diferentes)
for i = 1:length(rutasCarpetas) 

    Numeros = dir(rutaDATA+folders(i).name);
    Numeros = Numeros(~[Numeros.isdir]); %quitamos dirs y nos quedamos con archivos
    rutaNumeros = {Numeros.name};
    TRAMAS.("tr"+folders(i).name) = struct();

    %% Para cada numero se genera el codebook 
    vectorCaracteristicas = []; %a partir del vector de caracterisitcas de todos
    for m = 1: length(rutaNumeros) %cada numero se procesara
        [senal,F_old] = audioread (rutaDATA+fullfile(folders(i).name,Numeros(m).name));
        vector = recogerCaracterisitcas(senal,F_old);
       
        
        TRAMAS.("tr"+folders(i).name).("g"+m) = vector';
        vectorCaracteristicas = [vectorCaracteristicas; vector]; %sino, usar en codebook

    end

    %% crear codebook
    for k = 1:length(K)
        [idx, codebook] = kmeans(vectorCaracteristicas, K(k), ...
        'MaxIter', 1000, ... % Máximo de iteraciones
        'Replicates', 5, ... % Ejecutar k-means 5 veces para evitar mínimos locales
        'Display','off');
        CODEBOOKNum.("cbook"+folders(i).name+"_"+K(k))= codebook;
    end

end
save("Observaciones.mat",'-struct',"TRAMAS")
save("Codebooks.mat",'-struct','CODEBOOKNum')

nombreCLASES = fieldnames(Observaciones); %nombre del campo que guarda la estrucutra 
%inicializamos celdas para guardar A y B 
A = cell(length(K),length(numeros),length(N)); 
B = cell(length(K),length(numeros),length(N)); 
%TasaAciertos = zeros(length(N),length(K));

for NUM = 1:length(N)

    for k = 1:length(K) %por cada numero de centroides

        for n = 1:length(numeros)
            codebook = Codebooks.("cbook"+numeros(n)+"_"+K(k));
            observacion = Observaciones.("tr"+numeros(n));
            [A{k,n,NUM},B{k,n,NUM}] = HMM(N(NUM),codebook,observacion);

        end
    end
end

save("combinedHMM.mat",'A','B');

