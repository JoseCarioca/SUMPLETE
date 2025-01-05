%% Programa Principal
%clc, clear all, close all
codebook = load("codebook.mat");
modelosMarkov = load("modelos.mat");

%recoger aud
Fs = 8000; % Sampling frequency (8 kHz)
audioRecorder = audiorecorder(Fs, 16, 1);
choice = 0;
% Interactive Loop
while choice ~=2
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
        recordblocking(audioRecorder, 1.5); % grabamos 2 segundos
        disp('Fin grabación');
        audioData = getaudiodata(audioRecorder);

        % Preproceso
        caracteristicas = recogerCaracterisitcas(audioData,Fs);

        % Deuelve la clase -1, en este caso la palabra que se ha dicho
        palabraDetectada = evaluar(modelosMarkov,codebook,caracteristicas);

        % Display the detected word
        pause(1);
        disp("Palabra detectada: "+ palabraDetectada);
        pause(1);
    else
        disp('Selección no válida. Ingrese una de las opciones.');
        pause(1);
    end
end



function clase = evaluar(HMM,CB,V)
%% estimar grabacion...
 
        palabras = length(fieldnames(CB));
        
        logsP = zeros(1,10) - Inf;
            for n = 1:palabras
                secuencia = asignarCentroide(V,CB.("cb"+(n-1)));
                [~, logP] = hmmdecode(secuencia,HMM.("hmmA"+(n-1)),HMM.("hmmB"+(n-1)));
                %disp(logP);
                if ~isnan(logP)
                    logsP(n) = logP;
                end
            end
        
        [valor,clase] = max(logsP);
        %disp(valor);
        clase = clase -1;
end