function trimmed_audio = recortaPalabra(audio,fs)
%RECORTAPALABRA
%   Divide the audio into overlapping frames and compute the energy 
%   of each frame to identify where the energy is above a threshold.

frame_size = 0.03; % 25 ms
frame_shift = 0.01; % 10 ms
frame_length = round(frame_size * fs);
frame_step = round(frame_shift * fs);

% Frame-based processing
num_frames = floor((length(audio) - frame_length) / frame_step) + 1;
energy = zeros(num_frames, 1);

for i = 1:num_frames
    start_idx = (i-1) * frame_step + 1;
    end_idx = start_idx + frame_length - 1;
    frame = audio(start_idx:end_idx);
    energy(i) = sum(frame .^ 2); % Compute energy
end

threshold = 0.01 * max(energy); % Dynamic threshold
voiced_frames = find(energy > threshold);

start_sample = (voiced_frames(1) - 1) * frame_step + 1;
end_sample = (voiced_frames(end) - 1) * frame_step + frame_length;

trimmed_audio = audio(start_sample:end_sample);

end

