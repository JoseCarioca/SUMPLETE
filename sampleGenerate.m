%% sampleGenerate.m : real time testing and generation of samples
load("combinedHMM.mat");
Codebooks = load("Codebooks.mat");
prueba = false; % want to test with all data?
K = [64 128 256];
N = 3:6;
numeros = 1:9;
Fs = 8000; % Sampling frequency (8 kHz)
audioRecorder = audiorecorder(Fs, 16, 1);

aciertos = zeros(length(K),length(N));
cifraDetectada = zeros(length(K),length(N));
Pestimacion = 0;

%% leer datos
rutaDATA = "DIGITS\";
folders = dir(rutaDATA);
folders = folders([folders.isdir]);

% Eliminar las carpetas '.' y '..' (referencias a actual y padre)
folders = folders(~ismember({folders.name}, {'.', '..'}));

% Guardar las rutas completas de las carpetas
rutasCarpetas ={folders.name};
ITERMAX = 10;

%hasta aqui si quieres probar datos ya recogidos
Pestimacion2 = 0; Pest64K=0; Pest256K=0; %seems cb 256 estimates well, compare with mode
aciertos2 = zeros(length(K),length(N));
for iter = 1:ITERMAX
    
    disp('Hable en 1 segundo...');
    pause(1);
    % Grabar audio
    disp('Grabando...');
    recordblocking(audioRecorder, 1.5); % grabamos 2 segundos
    disp('Fin grabación');
    audioData = getaudiodata(audioRecorder);
    % Preproceso
    caracteristicas = recogerCaracterisitcas(audioData,Fs);
    
    for k = 1:length(K) %por cada numero de centroides
        for NUM = 1:length(N)
            logsP = zeros(1,length(numeros)) - Inf;
            for n = 1:length(numeros)
                codebook = Codebooks.("cbook"+(n)+"_"+K(k));
                secuencia = asignarCentroide(caracteristicas,codebook);
                [~, logP] = hmmdecode(secuencia,A{k,n,NUM},B{k,n,NUM});
                %disp(logP);
                %if ~isnan(logP)
                    logsP(n) = logP;
                %end
            end
        
            notValid = all(isnan(logsP), 'all'); % Returns true if all elements are NaN
            if notValid 
                cifraDetectada(k,NUM) = -1; %not valid
            else
                [valor,cifraDetectada(k,NUM)] = max(logsP);
            end
    
        end
    
    end
    disp("K x N:")
    disp(cifraDetectada);

    estimacion = mode(cifraDetectada(cifraDetectada > 0));
    disp("digit:"+estimacion)
    
    detectada64K = cifraDetectada(1,:);
    est64K = mode(detectada64K(detectada64K > 0));

    detectada256K = cifraDetectada(3,:);
    est256K = mode(detectada256K(detectada256K > 0));
    disp("digit256K:"+est256K)
    real = input('Cual era la palabra? (escriba la cifra): ');
    aciertos2(cifraDetectada == real) = aciertos2(cifraDetectada == real) + 1;

    if estimacion == real
        Pestimacion2 = Pestimacion2 + 1;
    end

    if est64K == real
        Pest64K = Pest64K + 1;
    end

    if est256K == real
        Pest256K = Pest256K + 1;
    end
    
    obj_senal = audioplayer(10*audioData,Fs); % aumento para escuchar mejor
    play(obj_senal);
    pause (1.5);

    %% we can add new sample into the dataset
    
    % Validar entrada
    if isnumeric(real) && real >= 1 && real <= 9
        nombreCarpeta = num2str(real); % Convertir el número a cadena
        
        % Verificar si la carpeta existe, si no, crearla
        if ~exist(nombreCarpeta, 'dir')
            mkdir(nombreCarpeta);
        end
        
        % Generar nombre único para el archivo de audio
        nombreArchivo = ['audio_' datestr(now, 'yyyymmdd_HHMMSS') '.wav']; % Ejemplo: audio_20250108_123456.wav
        
        % Ruta completa del archivo
        rutaArchivo = fullfile(rutaDATA+nombreCarpeta, nombreArchivo);
        
        % Guardar el archivo de audio
        audiowrite(rutaArchivo, audioData, Fs);
        
        disp(['Archivo guardado en: ' rutaArchivo]);
    else
        disp('Entrada no válida. Por favor, introduzca un número entre 1 y 9.');
    end

end

disp("%aciertos modelos por separado:")
disp(aciertos2/iter);

disp("%aciertos MODA:")
disp(Pestimacion2/iter);

disp("%aciertos MODA 64k:")
disp(Pest64K/iter);

disp("%aciertos MODA 256K:")
disp(Pest256K/iter);

