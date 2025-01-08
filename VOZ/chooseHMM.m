%% Step1. Create Codebooks
clc, clear all, close all,

load("DATASETnotNorm.mat");
normalizar = false;
newCodebook = load("newCodeBooks.mat");
clases = unique(Y);
K = [64 128 256]; %num centroides
N = [3 4 5 6]; %estados
disp('Create HMM?');
disp('1. Yes');
disp('0. I already have them, thanks.');
entrenar = input('Choose:');

if entrenar 

numeros = [1 2 3 4 5 6 7 8 9];

%inicializamos celdas para guardar A y B, luego se elegirá el mejor modelo...
A = cell(length(K),length(numeros),length(N)); 
B = cell(length(K),length(numeros),length(N)); 
TasaAciertos = zeros(length(N),length(K));
MatricesConfusion = cell(length(N),length(K));

for NUM = 1:length(N)

    for k = 1:length(K) %por cada numero de centroides
        
        for n = 1:length(numeros)
            codebook = newCodebook.("cb"+numeros(n)+"_"+K(k));
            observacion = Palabras.("label"+numeros(n));
            [A{k,n,NUM},B{k,n,NUM}] = HMM(N(NUM),codebook,observacion);
        
        end

        %% estimar grabacion...
        % de los vectores de caracterisitcas de todas las muestras
        Pacierto = zeros(1,length(numeros)); %porcentaje de acierto para cada numero   
        %MatrizConfusion = 
        groundWord = []; predictedWord = []; %para la matriz de confusion
        for ob = 1:length(numeros)
            % inicializamos y guardamos todas las muestras de un numero
            nombreMuestras = fieldnames(observacion);
            numeroMuestras = length(nombreMuestras);
            estimaciones = zeros(1,numeroMuestras); % para cada grabacion se la estimacion de su modelo más probable
            for muestra = 1:numeroMuestras  
                logsP = zeros(1,9) - Inf;
                    for n = 1:9
                        %codebook = Codebooks.("cbook"+(n)+"_"+K(k));
                        secuencia = asignarCentroide(observacion.(nombreMuestras{muestra}),codebook);
                        [~, logP] = hmmdecode(secuencia,A{k,n,NUM},B{k,n,NUM});
                        %disp(logP);
                        %if ~isnan(logP)
                        logsP(n) = logP;
                        %end
                    end
                
                [valor,estimaciones(muestra)] = max(logsP);
                groundWord(end+1) = ob; %-1 para guardar la clase correspondiente
                predictedWord(end+1) = estimaciones(muestra) ; %-1 para guardar la clase correspondiente
               
            end
            %calculamos porcentaje de acierto
            Pacierto(ob) = numel(estimaciones(estimaciones == ob)) /numeroMuestras;
      
        end

        TasaAciertos(NUM,k) = mean(Pacierto);
        MatricesConfusion{NUM,k} = confusionmat(groundWord,predictedWord);
        disp("____________________________________________")
        disp("Porcentaje de acierto para valores N =  " + N(NUM) + " y K = " + K(k) + " : " + TasaAciertos(NUM,k));
        disp("____________________________________________")
        
    end
    disp("N:"+NUM);
end
order = ["K","labels","N"];
save('HMMs.mat', "A", "B","order")

else
    load ('HMMs.mat');
end

%% probar Modelos
Fs = 8000; % Sampling frequency (8 kHz)
audioRecorder = audiorecorder(Fs, 16, 1);
choice = 0;
% Interactive Loop
aciertos = zeros(length(K),length(N));
palabraDetectada = zeros(length(K),length(N));

iters = 0;
while choice ~=2
    iters = iters + 1;
    disp("____________________________________")
    disp('Reconocedor de Voz (cifras)');
    disp('1. Grabe');
    disp('2. Salir del programa');
    choice = input('Elija una opcion: ', 's');

    if strcmp(choice, '2')
        disp('Cerrando programa...');
        clc,
        break
    elseif strcmp(choice, '1')
        disp('Hable en 1 segundo...');
        pause(1);
        % Grabar audio
        disp('Grabando...');
        recordblocking(audioRecorder, 2); % grabamos 2 segundos
        disp('Fin grabación');
        audioData = getaudiodata(audioRecorder);

        % Preproceso
        caracteristicas = recogerCaracterisitcas(audioData,Fs); %tam L x 40

        if normalizar
            caracteristicas = (caracteristicas - Mean)./Std;
        end
        for n = 1:length(N)

            for k = 1:length(K) %por cada numero de centroides
                palabraDetectada(k,n) = evaluar(A,B,k,n,newCodebook,K(k),caracteristicas);
            end
        end

        % % Deuelve la clase -1, en este caso la palabra que se ha dicho
        % palabraDetectada(1) = evaluar(modelosMarkov,codebook,caracteristicas);
        % %palabraDetectada(2) = evaluar(modelosMarkov6_64,codebook6_64,caracteristicas);
        % palabraDetectada(2) = evaluar(modelosMarkov6_128,codebook6_128,caracteristicas);
        % palabraDetectada(3) = evaluar(modelosMarkov6_256,codebook6_256,caracteristicas);

        % Display the detected word
        disp("Palabra detectada:")
        disp("Moda modelos: " + mode(palabraDetectada,'all'));
        pause(0.5);
        disp(palabraDetectada)
        real = input('Cual era la palabra? (escriba la cifra): ');
        aciertos(palabraDetectada == real) = aciertos(palabraDetectada == real) + 1;
    else
        disp('Selección no válida. Ingrese una de las opciones.');
        pause(1);
    end
end

disp("%acierto del modelo: ");
disp(aciertos/iters);


function clase = evaluarHMM(HMM,CB,V)
%% estimar grabacion...
 
        palabras = length(fieldnames(CB));
        
        logsP = zeros(1,9) - Inf;
            for n = 1:palabras
                secuencia = asignarCentroide(V,CB.("cb"+(n)));
                [~, logP] = hmmdecode(secuencia,HMM.("hmmA"+(n)),HMM.("hmmB"+(n)));
                %disp(logP);
                if ~isnan(logP)
                    logsP(n) = logP;
                end
            end
        [valor,clase] = max(logsP);
        %disp(valor);
        clase = clase;
end

function clase = evaluar(A,B,k,n,CB,K,V)
%% estimar grabacion...
 
        palabras = size(A,2);
        
        logsP = zeros(1,palabras) - Inf;
            for cifra = 1:palabras
                secuencia = asignarCentroide(V,CB.("cb"+(cifra)+"_"+(K)));
                [~, logP] = hmmdecode(secuencia,A{k,cifra,n},B{k,cifra,n});
                %disp(logP);
                %if ~isnan(logP)
                    logsP(n) = logP;
                %end
            end
        [valor,clase] = max(logsP);
        %disp(valor);
end