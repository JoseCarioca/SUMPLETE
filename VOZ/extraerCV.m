%% Recoge los archivos de audio encontrados en el directorio,
%% extrae sus características y crea los codebooks para cada palabra (y diferente K).
%% Parámetros
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

tamTest = 0.15; %seprar datos de validacion % de los datos

%% leer datos
folders = dir();
folders = folders([folders.isdir]);

% Eliminar las carpetas '.' y '..' (referencias a actual y padre)
folders = folders(~ismember({folders.name}, {'.', '..'}));

% Guardar las rutas completas de las carpetas
rutasCarpetas ={folders.name};
vacios = [];
TRAMAS = struct();
%% Para cada carpeta (numeros diferentes)
for i = 1:length(rutasCarpetas) 
    Numeros = dir(folders(i).name);
    Numeros = Numeros(~[Numeros.isdir]); %quitamos dirs y nos quedamos con archivos
    rutaNumeros = {Numeros.name};
    TRAMAS.("tr"+folders(i).name) = struct();

    orden = randperm(length(rutaNumeros));
    datosTest = orden(1:ceil(tamTest*length(rutaNumeros))); %el tamTest% para testear
    %% Para cada numero se genera el codebook 
    vectorCaracteristicas = []; %a partir del vector de caracterisitcas de todos
    for m = 1: length(rutaNumeros) %cada numero se procesara
        [senal,F_old] = audioread (fullfile(folders(i).name,Numeros(m).name));
        %[senal,F_old] = audioread ("1\Uno.opus");
        %pasamos a 8KHz
        y = senal(:,1)';
        if F_old ~= Fs
            y = resample(y, Fs, F_old); %lo pasamos a 8KHz 
        end
        %figure(1),plot(y);
        
        y = preenfasis(y,0.95);

        tramas = segmentacion(y,longTrama,longDespTrama); %segmentamos señal
        %tramasPalabra = inicioFin(tramas,numTramasRuido); %nos quedamos con las tramas de la palabra
        %palabra = recortaPalabra(y,Fs);
        tramasPalabra = recortaTrama(tramas);
        palabra = invSegmentacion(tramasPalabra,longDespTrama);
        
        %figure(2), plot(palabra); title("palabra"); % para comprobar

         % obj_senal = audioplayer(10*palabra,Fs); % aumento para escuchar mejor
         % play(obj_senal);
         % pause (1.5);
        %Obtención de las ventana enventanadas
        tramasPalabra = enventanar(tramasPalabra,ventana);
        %Obtención de los coeficientes cepstrales en la escala de Mel
        bancoFiltrosMel = generarBancoFiltros(Fs,longTrama);
        coefMel = coeficientesMel(tramasPalabra,bancoFiltrosMel);
        
        %Liftering
        coefMel = liftering (coefMel, numCepstrum);
        
        %Obtención de los coeficientes delta cepstrum
        %La entrada a la función audioDelta debe ser la matriz de
        %coeficientes MelCepstrum traspuesta
        deltaCoefMel = MCCDelta (coefMel,longVentanaDelta);
        
        %Obtención de los coeficientes delta-delta cepstrum
        deltaDeltaCoefMel = MCCDelta (deltaCoefMel,longVentanaDelta);
        %Obtención del logaritmo de la Energía de cada trama
        energia = logEnergia(tramasPalabra);
        %Crear vectores de características
        aux = [energia;coefMel;deltaCoefMel;deltaDeltaCoefMel];
        if sum(any(isnan(aux),1)) > 0
            vacios = [vacios sum(any(isnan(aux),1)) ];
            disp("tramas vacias, se procede a eliminar " + sum(any(isnan(aux),1)) + " vectores");
            aux = aux(:,all(~isnan(aux),1));
        end
        if ismember(m,datosTest) %si es para test guardar para luego
            TRAMAS.("tr"+folders(i).name).("g"+m) = aux;
        else
            vectorCaracteristicas = [vectorCaracteristicas; aux']; %sino, usar en codebook
        end
    end

    %save("tramas"+folders)
    %% crear codebook
    K_values = [64, 128, 256];
    for k = 1:length(K_values)
        K = K_values(k);
        disp(['Creando codebook de tamaño K = ', num2str(K)]);
        [idx, codebook] = kmeans(vectorCaracteristicas, K, ...
        'MaxIter', 1000, ... % Máximo de iteraciones
        'Replicates', 5, ... % Ejecutar k-means 5 veces para evitar mínimos locales
        'Display', 'final'); % Mostrar resultados finales
        disp(['Codebook de tamaño ', num2str(K), ' creado con éxito.']);
        CODEBOOKNum.("cbook"+folders(i).name+"_"+K_values(k))= codebook;
    end

    
   
end
save("Observaciones.mat",'-struct',"TRAMAS")
save("Codebooks.mat",'-struct','CODEBOOKNum');
%%


%% funciones
function tramasEnventanadas = enventanar(tramas, tipoVentana)
    [longTrama,numtramas] = size(tramas);
    switch tipoVentana
        case 'rectangular'
            ventana = ones(1, longTrama);
        case 'hamming'
            ventana = hamming(longTrama)';
        case 'hanning'
            ventana = hanning(longTrama)';
        otherwise
            error('Tipo de ventana no reconocido');
    end
    tramasEnventanadas = tramas' .* ventana;
    tramasEnventanadas = tramasEnventanadas';
end

function bancoFiltros = generarBancoFiltros(Fs, longTrama)
    bancoFiltros = designAuditoryFilterBank(Fs, 'FFTLength', longTrama);
end

function coefMel = coeficientesMel(tramasPalabra,bancoFiltrosMel)
    F = fft(tramasPalabra);
    F = bancoFiltrosMel * abs(F(1:size(bancoFiltrosMel,2),:));
    coefMel = dct(log10(F));
end

function coefMel = liftering (coefMel, numCepstrum)
    coefMel = coefMel(1:numCepstrum,:); 
end

function deltaCoefMel = MCCDelta(coefMel, longVentanaDelta)
    deltaCoefMel = audioDelta(coefMel', longVentanaDelta)';
end

function energia = logEnergia(tramas)
    energia = log10(sum(tramas.^2));
end

function palabra = invSegmentacion (conjTramas, L)
    palabra = reshape(conjTramas(end-L:end,:),1,[]);
end

function Y = preenfasis(y,a)
    Y = filter((1-a),a, y);
    %figure(1), plot(Y); title("señal con preenfasis");
end

function conjunto = segmentacion(muestra, longitud, desp)
    conjunto = buffer(muestra, longitud, longitud - desp);
end



