%% Programa Principal
%clc, clear all, close all
codebook = load("codebook.mat");
modelosMarkov = load("modelos.mat");

%codebook6_64 = load("codebook6_64.mat");
%modelosMarkov6_64 = load("modelos6_64.mat");

codebook6_128 = load("codebook6_128.mat");
modelosMarkov6_128 = load("modelos6_128.mat");

codebook6_256 = load("codebook6_256.mat");
modelosMarkov6_256 = load("modelos6_256.mat");
%recoger aud
Fs = 8000; % Sampling frequency (8 kHz)
audioRecorder = audiorecorder(Fs, 16, 1);
choice = 0;
% Interactive Loop
aciertos = zeros(1,3);
palabraDetectada = zeros(1,3);
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
        caracteristicas = recogerCaracterisitcas(audioData,Fs);

        % Deuelve la clase -1, en este caso la palabra que se ha dicho
        palabraDetectada(1) = evaluar(modelosMarkov,codebook,caracteristicas);
        %palabraDetectada(2) = evaluar(modelosMarkov6_64,codebook6_64,caracteristicas);
        palabraDetectada(2) = evaluar(modelosMarkov6_128,codebook6_128,caracteristicas);
        palabraDetectada(3) = evaluar(modelosMarkov6_256,codebook6_256,caracteristicas);

        % Display the detected word
        pause(1);
        disp("Palabra detectada:")
        disp("mejor modelo (5, 128): " + palabraDetectada(1));
        disp("por N = 6, K = 128 : " + palabraDetectada(2));
        disp("por N = 6, K = 256 : " + palabraDetectada(3));
        pause(1);
        real = input('Cual era la palabra? (escriba la cifra): ');
        for i = 1:length(aciertos)
            if palabraDetectada(i) == real
                aciertos(i) = aciertos(i) + 1;
            end
        end
    else
        disp('Selección no válida. Ingrese una de las opciones.');
        pause(1);
    end
end

disp("%acierto del modelo: "+aciertos/iters);



function clase = evaluar(HMM,CB,V)
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