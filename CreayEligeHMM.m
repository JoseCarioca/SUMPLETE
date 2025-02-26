%% Recoge los archivos de audio encontrados en el directorio,
%% extrae sus características y crea los codebooks para cada palabra (y diferente K).
%% Parámetros
%% NO USAR SI NO ES NECESARIO (los entrenamientos ya estan guardados)
clc, close all, clear all,
Fs = 8000;
a = 0.95;
ventana = 'hamming';
numTramasRuido = 10; %con 10 va mal
longTrama = 240;
longDespTrama = 120;
tiempoTrama = longTrama/Fs;
tiempoDesplTrama = longDespTrama/Fs;
longVentanaDelta = 5; %Nº de tramas utilizadas para calcular los coeficientes delta y delta-delta
numCepstrum = 13;

tamTest = 0.5; %seprar datos de validacion % de los datos
K_values = [64 128 256];

%% leer datos
rutaDATA = "DIGITS\";
folders = dir(rutaDATA);
folders = folders([folders.isdir]);

% Eliminar las carpetas '.' y '..' (referencias a actual y padre)
folders = folders(~ismember({folders.name}, {'.', '..'}));

% Guardar las rutas completas de las carpetas
rutasCarpetas ={folders.name};
K = [64 128 256]; %num centroides
N = [3 4 5 6]; %estados
numeros = [1 2 3 4 5 6 7 8 9];
RP = 3; %veces que se entrena con randomperm
metricas = struct('precision', cell(length(N), length(K)), ...
                      'recall', cell(length(N), length(K)), ...
                      'f1', cell(length(N), length(K)));
MConfFinal = cell(length(N),length(K));
for NUM = 1:length(N)
    for k = 1:length(K)
        metricas(NUM,k).precision = 0;
        metricas(NUM,k).recall = 0;
        metricas(NUM,k).f1 = 0;
        MConfFinal{NUM,k} = zeros(9,9);
    end
end


for rp = 1:RP %se repite el procedimiento para asegurar una mejor eleccion
    vacios = [];
    TRAMAS = struct();
    

    %% Para cada carpeta (numeros diferentes)
    for i = 1:length(rutasCarpetas) 
        Numeros = dir(rutaDATA+folders(i).name);
        Numeros = Numeros(~[Numeros.isdir]); %quitamos dirs y nos quedamos con archivos
        rutaNumeros = {Numeros.name};
        TRAMAS.("tr"+folders(i).name) = struct();
    
        orden = randperm(length(rutaNumeros));
        datosTest = orden(1:ceil(tamTest*length(rutaNumeros))); %el tamTest% para testear
        %% Para cada numero se genera el codebook 
        vectorCaracteristicas = []; %a partir del vector de caracterisitcas de todos
        for m = 1: length(rutaNumeros) %cada numero se procesara
            [senal,F_old] = audioread (fullfile(rutaDATA+folders(i).name,Numeros(m).name));
            aux = recogerCaracterisitcas(senal,F_old);
            if ismember(m,datosTest) %si es para test guardar para luego
                TRAMAS.("tr"+folders(i).name).("g"+m) = aux';
            else
                vectorCaracteristicas = [vectorCaracteristicas; aux]; %sino, usar en codebook
            end
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
    save("Codebooks.mat",'-struct','CODEBOOKNum');
    
    Codebooks =  load("Codebooks.mat");
    Observaciones = load("Observaciones.mat");

    GRAB = fieldnames(Observaciones);
    MatricesConfusion = cell(4,3); %se guardaran las matrices de confusión de todos los modelos generados
    
    nombreCLASES = fieldnames(Observaciones); %nombre del campo que guarda la estrucutra 
    %inicializamos celdas para guardar A y B, luego se elegirá el mejor modelo...
    A = cell(length(K),length(numeros),length(N)); 
    B = cell(length(K),length(numeros),length(N)); 
    TasaAciertos = zeros(length(N),length(K));
    
    for NUM = 1:length(N)
    
        for k = 1:length(K) %por cada numero de centroides
            
            for n = 1:length(numeros)
                codebook = Codebooks.("cbook"+numeros(n)+"_"+K(k));
                observacion = Observaciones.("tr"+numeros(n));
                [A{k,n,NUM},B{k,n,NUM}] = HMM(N(NUM),codebook,observacion);
            
            end
            
            
            %% estimar grabacion...
            % de los vectores de caracterisitcas de las muestras de
            % entrenamiento
            Pacierto = zeros(1,length(numeros)); %porcentaje de acierto para cada numero   
            %MatrizConfusion = 
            groundWord = []; predictedWord = []; %para la matriz de confusion
            for ob = 1:length(numeros)
                observacion = Observaciones.(nombreCLASES{ob});
                % inicializamos y guardamos todas las muestras de un numero
                nombreMuestras = fieldnames(observacion);
                numeroMuestras = length(nombreMuestras);
                estimaciones = zeros(1,numeroMuestras); % para cada grabacion se la estimacion de su modelo más probable
                for muestra = 1:numeroMuestras  
                    logsP = zeros(1,length(numeros)) - Inf;
                        for n = 1:length(numeros)
                            codebook = Codebooks.("cbook"+(n)+"_"+K(k));
                            secuencia = asignarCentroide(observacion.(nombreMuestras{muestra})',codebook);
                            [~, logP] = hmmdecode(secuencia,A{k,n,NUM},B{k,n,NUM});
                            %disp(logP);
                            %if ~isnan(logP)
                                logsP(n) = logP;
                            %end
                        end
                    notValid = all(isnan(logsP), 'all'); % Returns true if all elements are NaN
                    if notValid 
                        estimaciones(muestra) = -1;
                    else
                        [valor,estimaciones(muestra)] = max(logsP);
                    end
                    groundWord(end+1) = ob ; 
                    predictedWord(end+1) = estimaciones(muestra); 
                   
                end
                %calculamos porcentaje de acierto
                Pacierto(ob) = numel(estimaciones(estimaciones == ob)) /numeroMuestras;
          
            end
            TasaAciertos(NUM,k) = mean(Pacierto);
            %
            MatricesConfusion{NUM,k} = confusionmat(groundWord,predictedWord);
            MConfFinal{NUM,k} = MConfFinal{NUM,k} + MatricesConfusion{NUM,k};
        end
    end
    
    
    %% elegir modelo en funcion del F1score...
    for NUM = 1:length(N)
        for k = 1:length(K)
    
            tp = diag(MatricesConfusion{NUM,k});
            precision = tp./sum(MatricesConfusion{NUM,k},1)';
            recall = tp./sum(MatricesConfusion{NUM,k},2);
            f1 = 2*(precision.*recall)./(precision+recall);
    
            metricas(NUM,k).precision = metricas(NUM,k).precision + mean(precision);
            metricas(NUM,k).recall = metricas(NUM,k).recall + mean(recall);
            metricas(NUM,k).f1 = metricas(NUM,k).f1 + mean(f1);
            %disp("")
            disp("F1Score para N =  " + N(NUM) + " y K = " + K(k) + " : " + metricas(NUM,k).f1/rp);
    
            % figure((NUM-1)*length(N)+k),
            % confusionchart(MatricesConfusion{NUM,k},numeros,'RowSummary','row-normalized','ColumnSummary','column-normalized');
            % title("N = " + N(NUM) + " K = " + K(k));
        end
    end
    disp("____________________________________________")

end

for NUM = 1:length(N)
    for k = 1:length(K)

        metricas(NUM,k).precision = metricas(NUM,k).precision/RP;
        metricas(NUM,k).recall = metricas(NUM,k).recall/RP;
        metricas(NUM,k).f1 = metricas(NUM,k).f1/RP;
    
        figure((NUM-1)*length(N)+k),
        confusionchart(MConfFinal{NUM,k},numeros,'RowSummary','row-normalized','ColumnSummary','column-normalized');
        title("N = " + N(NUM) + " K = " + K(k));
    end
end


[~, mejorModelo] = max([metricas.f1]);

[bestN, bestK] = ind2sub(size(metricas), mejorModelo); %convertimos indice
disp("Mejor modelo con N = " + N(bestN) + " y K = " + K(bestK) );
codebookMejor = struct();
modeloMarkovMejor = struct();

for i = 1:length(numeros)
    codebookMejor.("cb"+numeros(i)) = Codebooks.("cbook"+numeros(i)+"_"+K(bestK));
    modeloMarkovMejor.("hmmA"+numeros(i)) = A{bestK,i,bestN};
    modeloMarkovMejor.("hmmB"+numeros(i)) = B{bestK,i,bestN};
end

save("codebook.mat",'-struct',"codebookMejor");
save("modelos.mat",'-struct',"modeloMarkovMejor");

save("combinedHMM.mat",'A','B');



