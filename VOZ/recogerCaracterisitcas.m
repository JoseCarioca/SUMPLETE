function vectorCaracteristicas = recogerCaracterisitcas(senal,F_old)
%Devuelve el vector de caracterisitcas de un registro de audio

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
    
    %pasamos a 8KHz
    y = senal(:,1)';
    if F_old ~= Fs
        y = resample(y, Fs, F_old); %lo pasamos a 8KHz 
    end
    
    y = filter((1-a),a, y);

    tramas = segmentacion(y,longTrama,longDespTrama); %segmentamos señal
    tramasPalabra = recortaTrama(tramas); %nos quedamos con las tramas de la palabra
    
    palabra = invSegmentacion(tramasPalabra,longDespTrama);
    
    figure(1), plot(palabra); title("palabra recogida"); % para comprobar

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
    vectorCaracteristicas = aux';

end

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

function conjunto = segmentacion(muestra, longitud, desp)
    conjunto = buffer(muestra, longitud, longitud - desp);
end

