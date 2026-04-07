function task4_noise_lpf_analysis()
    num_bands = 6;
    lpf_cutoffs = [20, 50, 100, 400];
    freq_range = [200, 7000];
    snr_db = -5; 
    folder = 'C:\Users\j7805\Desktop\信号Project1\音频（bb）';
    
    [s1, ~] = audioread(fullfile(folder, 'C_01_01(1).wav'));
    [s2, fs] = audioread(fullfile(folder, 'C_01_02(1).wav'));
    
    s1_noisy = add_noise(s1, snr_db);
    s2_noisy = add_noise(s2, snr_db);
    
    s1_processed_all = cell(length(lpf_cutoffs), 1);
    s2_processed_all = cell(length(lpf_cutoffs), 1);
    for i = 1:length(lpf_cutoffs)
        lpf = lpf_cutoffs(i);
        s1_processed = process_with_tone_vocoder(s1_noisy, fs, num_bands, lpf, freq_range);
        s2_processed = process_with_tone_vocoder(s2_noisy, fs, num_bands, lpf, freq_range);
        s1_processed_all{i} = s1_processed;
        s2_processed_all{i} = s2_processed;
        audiowrite(fullfile(folder, sprintf('C_01_01_noisy_Lpf%d_SNR%ddB.wav', lpf, snr_db)), s1_processed, fs);
        audiowrite(fullfile(folder, sprintf('C_01_02_noisy_Lpf%d_SNR%ddB.wav', lpf, snr_db)), s2_processed, fs);
    end
    
    create_spectrograms(s1, s1_processed_all, fs, lpf_cutoffs, 'C_01_01');
    create_spectrograms(s2, s2_processed_all, fs, lpf_cutoffs, 'C_01_02');
end

function noisy_signal = add_noise(clean_signal, snr_db)
    noise_power = mean(clean_signal.^2) / (10^(snr_db/10));
    noisy_signal = clean_signal + sqrt(noise_power) * randn(size(clean_signal));
end

function create_spectrograms(original_signal, processed_signals, fs, lpf_cutoffs, title_prefix)
    figure('Position', [100, 100, 1000, 800], 'Color', 'white');
    subplot(length(lpf_cutoffs) + 1, 1, 1);
    spectrogram(original_signal, 256, 128, 256, fs, 'yaxis');
    title(['Original signal - ', title_prefix]); ylim([0 16]);
    for i = 1:length(lpf_cutoffs)
        subplot(length(lpf_cutoffs) + 1, 1, i + 1);
        spectrogram(processed_signals{i}, 256, 128, 256, fs, 'yaxis');
        title(sprintf('signal (fc=%dHz)', lpf_cutoffs(i))); ylim([0 16]); colorbar; caxis([-150 0]);
    end
    sgtitle(['语谱图比较 - ', title_prefix]);
end

function s_processed = process_with_tone_vocoder(s, fs, num_bands, lpf_cutoff, freq_range)
    energy_original = sum(s.^2); s_processed = zeros(size(s));
    A = 165.4; a = 0.06;
    d_min = log10((freq_range(1)/A) + 1) / a;
    d_max = log10((freq_range(2)/A) + 1) / a;
    band_edges = A * (10.^(a * linspace(d_min, d_max, num_bands+1)) - 1);
    t = (0:length(s)-1)' / fs;
    for i = 1:num_bands
        f_low = band_edges(i); f_high = band_edges(i+1);
        [b, a_filter] = butter(4, [f_low f_high]/(fs/2), 'bandpass');
        y_rect = abs(filter(b, a_filter, s));
        [b_lpf, a_lpf] = butter(2, lpf_cutoff/(fs/2), 'low');
        s_processed = s_processed + filter(b_lpf, a_lpf, y_rect) .* sin(2 * pi * sqrt(f_low * f_high) * t);
    end
    if sum(s_processed.^2) > 0, s_processed = s_processed * sqrt(energy_original / sum(s_processed.^2)); end
    if max(abs(s_processed)) > 1, s_processed = s_processed / max(abs(s_processed)); end
end