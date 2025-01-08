%% estimateDigitVoice

function estimacion = estimateDigitVoice(A,B,Codebooks,audioData,Fs)
[nk, nNums, nN] = size(A);
cifraDetectada = zeros(nk, nN);
K = [64 128 256];

% Preproceso
    caracteristicas = recogerCaracterisitcas(audioData,Fs);
    
    for k = 1:nk %por cada numero de centroides
        for NUM = 1:nN
            logsP = zeros(1,nNums) - Inf;
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

     % disp("K x N:");
     % disp(cifraDetectada);
    estimacion = mode(cifraDetectada(cifraDetectada > 0));

end