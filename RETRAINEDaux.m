%RETRAINED

%% now we know the best: retrained with all data and save new one...
    vacios = [];
    TRAMAS = struct();


    %% Para cada carpeta (numeros diferentes)
    for i = 1:length(rutasCarpetas) 

        Numeros = dir(rutaDATA+folders(i).name);
        Numeros = Numeros(~[Numeros.isdir]); %quitamos dirs y nos quedamos con archivos
        rutaNumeros = {Numeros.name};
        TRAMAS.("tr"+folders(i).name) = struct();

        %% Para cada numero se genera el codebook 
        vectorCaracteristicas = []; %a partir del vector de caracterisitcas de todos
        for m = 1: length(rutaNumeros) %cada numero se procesara
            [senal,F_old] = audioread (rutaDATA+fullfile(folders(i).name,Numeros(m).name));

            y = senal(:,1)';
            if F_old ~= Fs
                y = resample(y, Fs, F_old); %lo pasamos a 8KHz 
            end
            %figure(1),plot(y);

            y = preenfasis(y,0.95);

            tramas = segmentacion(y,longTrama,longDespTrama); %segmentamos señal
            tramasPalabra = recortaTrama(tramas);
            palabra = invSegmentacion(tramasPalabra,longDespTrama);
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

            TRAMAS.("tr"+folders(i).name).("g"+m) = aux;
            vectorCaracteristicas = [vectorCaracteristicas; aux']; %sino, usar en codebook

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
    save("Codebooks.mat",'-struct','CODEBOOKNum')

    nombreCLASES = fieldnames(Observaciones); %nombre del campo que guarda la estrucutra 
    %inicializamos celdas para guardar A y B 
    A = cell(length(K),length(numeros),length(N)); 
    B = cell(length(K),length(numeros),length(N)); 
    %TasaAciertos = zeros(length(N),length(K));

    for NUM = 1:length(N)

        for k = 1:length(K) %por cada numero de centroides

            for n = 1:length(numeros)
                codebook = Codebooks.("cbook"+numeros(n)+"_"+K(k));
                observacion = Observaciones.("tr"+numeros(n));
                [A{k,n,NUM},B{k,n,NUM}] = HMM(N(NUM),codebook,observacion);

            end
        end
    end

    

    


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



