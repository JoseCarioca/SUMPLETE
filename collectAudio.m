%% collect audio 

function [audioData] = collectData(audioRecorder,seconds)

    caracteristicas = recogerCaracterisitcas(senal,F_old);

    disp('Hable en 1 segundo...');
    pause(1);
    % Grabar audio
    disp('Grabando...');
    recordblocking(audioRecorder, seconds);
    disp('Fin grabación');
    audioData = getaudiodata(audioRecorder);

end