%% PRUEBAS PARA ESTIMAR EL MEJOR MODELO OCULTO DE MARKOV 
clc, clear all, close all,

Codebooks =  load("Codebooks.mat");
Observaciones = load("Observaciones.mat");

K = [64 128 256]; %num centroides
N = [3 4 5 6]; %estados
numeros = [0 1 2 3 4 5 6 7 8 9];
GRAB = fieldnames(Observaciones);
%X = tr1.(GRAB{grab})';
MatricesConfusion = cell(3); %se guardaran las matrices de confusión de todos los modelos generados

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
        % de los vectores de caracterisitcas de todas las muestras
        Pacierto = zeros(1,10); %porcentaje de acierto para cada numero   
        %MatrizConfusion = 
        groundWord = []; predictedWord = []; %para la matriz de confusion
        for ob = 1:10
            observacion = Observaciones.(nombreCLASES{ob});
            % inicializamos y guardamos todas las muestras de un numero
            nombreMuestras = fieldnames(observacion);
            numeroMuestras = length(nombreMuestras);
            estimaciones = zeros(1,numeroMuestras); % para cada grabacion se la estimacion de su modelo más probable
            for muestra = 1:numeroMuestras  
                logsP = zeros(1,10) - Inf;
                    for n = 1:10
                        codebook = Codebooks.("cbook"+(n-1)+"_"+K(k));
                        secuencia = asignarCentroide(observacion.(nombreMuestras{muestra})',codebook);
                        [~, logP] = hmmdecode(secuencia,A{k,n,NUM},B{k,n,NUM});
                        %disp(logP);
                        %if ~isnan(logP)
                            logsP(n) = logP;
                        %end
                    end
                
                [valor,estimaciones(muestra)] = max(logsP);
                groundWord(end+1) = ob -1; %-1 para guardar la clase correspondiente
                predictedWord(end+1) = estimaciones(muestra) - 1; %-1 para guardar la clase correspondiente
               
            end
            %calculamos porcentaje de acierto
            Pacierto(ob) = numel(estimaciones(estimaciones == ob)) /numeroMuestras;
      
        end
        TasaAciertos(NUM,k) = mean(Pacierto);
        disp("____________________________________________")
        disp("Porcentaje de acierto para valores N =  " + N(NUM) + " y K = " + K(k) + " : " + TasaAciertos(NUM,k));
        disp("____________________________________________")
        MatricesConfusion{NUM,k} = confusionmat(groundWord,predictedWord);
    
    end
end


%% elegir modelo en funcion del F1score...
% si tuvieramos en cuenta el ruido deberiamos mirar el peso de este tanto
% en número como en importancia y hacer nuestras predicciones...
% de momento todas las clases son igual de importante y balanceadas, un
% mayor valor del F1 score nos dará una buena estimación del mejor modelo a
% seleccionar
metricas = struct();

for NUM = 1:length(N)
    for k = 1:length(K)

        tp = diag(MatricesConfusion{NUM,k});
        precision = tp./sum(MatricesConfusion{NUM,k},1)';
        recall = tp./sum(MatricesConfusion{NUM,k},2);
        f1 = 2*(precision.*recall)./(precision+recall);

        metricas(NUM,k).precision = mean(precision);
        metricas(NUM,k).recal = mean(recall);
        metricas(NUM,k).f1 = mean(f1);

        figure((NUM-1)*length(N)+k),
        confusionchart(MatricesConfusion{NUM,k},numeros,'RowSummary','row-normalized','ColumnSummary','column-normalized');
        title("N = " + N(NUM) + " K = " + K(k));
    end
end

[~, mejorModelo] = max([metricas.f1]);

[bestN, bestK] = ind2sub(size(metricas), mejorModelo); %convertimos indice
disp("Mejor modelo con N = " + N(bestN) + "y K = " + K(bestK) );
codebookMejor = struct();
modeloMarkovMejor = struct();

for i = 1:length(numeros)
    codebookMejor.("cb"+numeros(i)) = Codebooks.("cbook"+numeros(i)+"_"+K(bestK));
    modeloMarkovMejor.("hmmA"+numeros(i)) = A{bestK,i,bestN};
    modeloMarkovMejor.("hmmB"+numeros(i)) = B{bestK,i,bestN};
end

save("codebook.mat",'-struct',"codebookMejor");
save("modelos.mat",'-struct',"modeloMarkovMejor");

%confusionchart(MatricesConfusion{1,1},numeros)
%cm = confusionchart(MatricesConfusion{1,1},numeros,'RowSummary','row-normalized','ColumnSummary','column-normalized');