%% estimateDigitVoice

function estimacion = estimateDigitVoice(A,B,Codebooks,audioData,Fs)
[nk, nNums, nN] = size(A);
cifraDetectada = zeros(nk, nN);

% Preproceso
    caracteristicas = recogerCaracterisitcas(audioData,Fs);
    
    for k = 1:nk %por cada numero de centroides
        for NUM = 1:nN
            logsP = zeros(1,length(numeros)) - Inf;
            for n = 1:nNums
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

    estimacion = mode(cifraDetectada(cifraDetectada > 0));

end