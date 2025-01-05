function trimmed_audio = recortaTrama(tramas)
%RECORTAPALABRA
%   Divide the audio into overlapping frames and compute the energy 
%   of each frame to identify where the energy is above a threshold.

% Frame-based processing
E = sum(tramas.^2);

threshold = 0.01 * max(E); % Dynamic threshold
voiced_frames = find(E > threshold);

start_sample = voiced_frames(1);
end_sample = voiced_frames(end);
if start_sample > 1
    start_sample = start_sample-1;
end
if end_sample < length(E)
    end_sample = end_sample + 1;
end

trimmed_audio = tramas(:,start_sample:end_sample);

end


