%% step 0: transformar los samples de audio en vectores de caracteristicas (normalizados)
%% step 1: create codebooks

%% leer datos
folders = dir();
folders = folders([folders.isdir]);

% Eliminar las carpetas '.' y '..' (referencias a actual y padre)
folders = folders(~ismember({folders.name}, {'.', '..'}));

%needed params
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

X = []; Y = []; %data and classes
%% NORMALIZAR?
normalizar = false;

%para codebooks
K = [64 128 256]; %num centroides

% Guardar las rutas completas de las carpetas
rutasCarpetas ={folders.name};
vacios = [];

iniClass = 1;
for i = 1:length(rutasCarpetas)
    clase = str2num(folders(i).name)
    Numeros = dir(folders(i).name);
    Numeros = Numeros(~[Numeros.isdir]); %quitamos dirs y nos quedamos con archivos
    rutaNumeros = {Numeros.name};
    Palabras.("label"+folders(i).name) = struct(); %para luego entrenar los HMM

     for m = 1: length(rutaNumeros) %cada numero se procesara
        [senal,F_old] = audioread (fullfile(folders(i).name,Numeros(m).name));
        
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
        tramasPalabra = enventanar(tramasPalabra,ventana);
        bancoFiltrosMel = generarBancoFiltros(Fs,longTrama);
        coefMel = coeficientesMel(tramasPalabra,bancoFiltrosMel);
        coefMel = liftering (coefMel, numCepstrum);
        deltaCoefMel = MCCDelta (coefMel,longVentanaDelta);
        deltaDeltaCoefMel = MCCDelta (deltaCoefMel,longVentanaDelta);
        energia = logEnergia(tramasPalabra);
        
        %Crear vectores de características
        aux = [energia;coefMel;deltaCoefMel;deltaDeltaCoefMel];
        if sum(any(isnan(aux),1)) > 0
            vacios = [vacios sum(any(isnan(aux),1)) ];
            disp("tramas vacias, se procede a eliminar " + sum(any(isnan(aux),1)) + " vectores");
            aux = aux(:,all(~isnan(aux),1));
        end
        Palabras.("label"+folders(i).name).("record"+m) = aux';
        X = [X; aux']; 
        labelsY = ones(size(aux,2),1) *clase;
        Y = [Y; labelsY] ; %add class label in Y

     end
     if unique(Y(iniClass:end)) ~= clase
         disp("ERROR ENTRENAMIENTO DE X CON DATOS DE OTRO SET");
     end
     
     iniClass = [iniClass size(X,1)];
end

if normalizar
    [Xn, Mean, Std] = normalize(X); %C are the means of each parameter, S ys the std
else
    Xn = X;
end

for k = 1:length(K)
    for c = 1:length(rutasCarpetas)
        disp(['Creando codebook de tamaño K = ', num2str(K(k))]);
        [idx, codebook] = kmeans(Xn(Y == c,:), K(k), ...
        'MaxIter', 1000, ... % Máximo de iteraciones
        'Replicates', 5, ... % Ejecutar k-means 5 veces para evitar mínimos locales
        'Display', 'final'); % Mostrar resultados finales
        CODEBOOKS.("cb"+c+"_"+K(k))= codebook;
     end
end

if normalizar
    % Normalized every record
    labels = fieldnames(Palabras); nlabels = length(labels);
    for n = 1:nlabels %1 a 9
        records = fieldnames(Palabras.(labels{n})); nrecords = length(records);
        for r = 1:nrecords
            Palabras.(labels{n}).(records{r}) = (Palabras.(labels{n}).(records{r}) - Mean) ./ Std; %(c - Mean)./Std;
        end
    end
end

if normalizar 
    save('DATASET.mat', "Xn", "Y","Mean","Std","Palabras")
else
    save('DATASETnotNorm.mat', "Xn", "Y","Palabras")
end
save("newCodeBooks.mat",'-struct','CODEBOOKS');






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



