%% collect audio
% Función para capturar una muestra de audio usando un objeto de grabación.
% Entrada:
% - audioRecorder: Objeto de tipo audiorecorder, configurado previamente.
% - seconds: Duración de la grabación en segundos.
% Salida:
% - audioData: Vector que contiene los datos de la señal de audio grabada.

function [audioData] = collectAudio(audioRecorder, seconds)

    % Mostrar mensaje al usuario indicando que hable en 1 segundo.
    disp('Hable en 1 segundo...');
    pause(1); % Pausa para permitir al usuario prepararse.

    % Grabar audio
    disp('Grabando...'); % Mensaje de inicio de grabación.
    recordblocking(audioRecorder, seconds); % Graba durante el tiempo especificado (seconds).
    disp('Fin grabación'); % Mensaje indicando el fin de la grabación.

    % Extraer los datos de la grabación
    audioData = getaudiodata(audioRecorder); % Obtiene la señal de audio grabada como un vector.

    % Nota: La variable 'caracteristicas' y la función 'recogerCaracteristicas'
    % no se utilizan en esta función. Es posible que sea un residuo o algo
    % que deba eliminarse o moverse a otro lugar del código.

end