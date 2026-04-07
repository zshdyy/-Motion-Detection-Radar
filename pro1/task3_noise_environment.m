function task3_noise_environment()
    lpf_cutoff = 50; 
    band_numbers = [2, 4, 6, 8, 16]; 
    freq_range = [200, 7000]; 
    snr_db = -5; 
    folder = 'C:\Users\j7805\Desktop\信号Project1\音频（bb）';
    
    [s1, fs] = audioread(fullfile(folder, 'C_01_01(1).wav'));
    [s2, fs] = audioread(fullfile(folder, 'C_01_02(1).wav'));
    
    fprintf('生成SNR = %.1f dB的噪声信号...\n', snr_db);
    s1_noisy = add_noise(s1, snr_db);
    s2_noisy = add_noise(s2, snr_db);
    
    audiowrite(fullfile(folder, sprintf('C_01_01_noisy_SNR%ddB.wav', snr_db)), s1_noisy, fs);
    audiowrite(fullfile(folder, sprintf('C_01_02_noisy_SNR%ddB.wav', snr_db)), s2_noisy, fs);
    
    for i = 1:length(band_numbers)
        n = band_numbers(i);
        fprintf('处理 %d 个频带（噪声环境）...\n', n);
        s1_processed = process_with_tone_vocoder(s1_noisy, fs, n, lpf_cutoff, freq_range);
        s2_processed = process_with_tone_vocoder(s2_noisy, fs, n, lpf_cutoff, freq_range);
        
        audiowrite(fullfile(folder, sprintf('C_01_01_noisy_N%d_SNR%ddB.wav', n, snr_db)), s1_processed, fs);
        audiowrite(fullfile(folder, sprintf('C_01_02_noisy_N%d_SNR%ddB.wav', n, snr_db)), s2_processed, fs);
    end
    
    create_noisy_combined_figure(s1, s1_noisy, fs, band_numbers, folder, 'C_01_01', [0, 4], snr_db);
    create_noisy_combined_figure(s2, s2_noisy, fs, band_numbers, folder, 'C_01_02', [0, 2], snr_db);
    plot_greenwood_bands_task3(band_numbers, freq_range);
    fprintf('\n=== Task 3 处理完成 ===\n');
end

function noisy_signal = add_noise(clean_signal, snr_db)
    signal_power = mean(clean_signal.^2);
    snr_linear = 10^(snr_db/10);
    noise_power = signal_power / snr_linear;
    noise = sqrt(noise_power) * randn(size(clean_signal));
    noisy_signal = clean_signal + noise;
end

function create_noisy_combined_figure(clean_signal, noisy_signal, fs, band_numbers, folder, file_prefix, xlim_time, snr_db)
    figure('Position', [50, 50, 1400, 1200]);
    N_clean = length(clean_signal);
    Y_clean_shifted = fftshift(abs(fft(clean_signal)/N_clean));
    f_clean = (-N_clean/2:(N_clean/2-1))*fs/N_clean;
    
    N_noisy = length(noisy_signal);
    Y_noisy_shifted = fftshift(abs(fft(noisy_signal)/N_noisy));
    f_noisy = (-N_noisy/2:(N_noisy/2-1))*fs/N_noisy;
    
    subplot(length(band_numbers)+2, 2, 1);
    plot(f_clean, Y_clean_shifted, 'b-', 'LineWidth', 1.5);
    title(['频域图: 原始干净信号 - ', file_prefix]); xlim([-8000 8000]); grid on;
    
    subplot(length(band_numbers)+2, 2, 2);
    t_clean = (0:length(clean_signal)-1)/fs;
    plot(t_clean, clean_signal, 'b-', 'LineWidth', 1.5);
    title(['时域图: 原始干净信号 - ', file_prefix]); ylim([-0.5 0.5]); xlim(xlim_time); grid on;
    
    subplot(length(band_numbers)+2, 2, 3);
    plot(f_noisy, Y_noisy_shifted, 'b-', 'LineWidth', 1.5);
    title(sprintf('频域图: 噪声信号 (SNR=%.1fdB) - %s', snr_db, file_prefix)); xlim([-8000 8000]); grid on;
    
    subplot(length(band_numbers)+2, 2, 4);
    t_noisy = (0:length(noisy_signal)-1)/fs;
    plot(t_noisy, noisy_signal, 'b-', 'LineWidth', 1.5);
    title(sprintf('时域图: 噪声信号 (SNR=%.1fdB) - %s', snr_db, file_prefix)); ylim([-0.5 0.5]); xlim(xlim_time); grid on;
    
    for i = 1:length(band_numbers)
        n = band_numbers(i);
        [audio, ~] = audioread(fullfile(folder, sprintf('%s_noisy_N%d_SNR%ddB.wav', file_prefix, n, snr_db)));
        N = length(audio);
        Y_shifted = fftshift(abs(fft(audio)/N));
        f = (-N/2:(N/2-1))*fs/N;
        
        subplot(length(band_numbers)+2, 2, 2*(i+1)+1);
        plot(f, Y_shifted, 'b-', 'LineWidth', 1.5);
        title(sprintf('%s N=%d 频域图', file_prefix, n)); xlim([-8000 8000]); grid on;
        
        subplot(length(band_numbers)+2, 2, 2*(i+1)+2);
        plot((0:length(audio)-1)/fs, audio, 'b-', 'LineWidth', 1.5);
        title(sprintf('%s N=%d 时域图', file_prefix, n)); ylim([-0.5 0.5]); xlim(xlim_time); grid on;
    end
    sgtitle(sprintf('Task 3: 噪声环境下的分析 - %s', file_prefix), 'FontSize', 14);
end

function plot_greenwood_bands_task3(band_numbers, freq_range)
    A = 165.4; a = 0.06;
    d_min = log10((freq_range(1)/A) + 1) / a;
    d_max = log10((freq_range(2)/A) + 1) / a;
    figure('Position', [200, 200, 1200, 1000]);
    for b = 1:length(band_numbers)
        num_bands = band_numbers(b);
        d_values = linspace(d_min, d_max, num_bands+1);
        band_edges = A * (10.^(a*d_values) - 1);
        subplot(length(band_numbers), 1, b); hold on;
        for i = 1:num_bands
            x_band = [band_edges(i), band_edges(i+1), band_edges(i+1), band_edges(i)];
            y_band = [0, 0, 1, 1];
            fill(x_band, y_band, 'b', 'EdgeColor', 'k', 'FaceAlpha', 0.6);
        end
        xlim([0, freq_range(2)*1.1]); ylim([0, 1.2]); grid on;
        title(sprintf('N=%d Greenwood频带划分', num_bands));
    end
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
        envelope = filter(b_lpf, a_lpf, y_rect);
        s_processed = s_processed + envelope .* sin(2 * pi * sqrt(f_low * f_high) * t);
    end
    if sum(s_processed.^2) > 0, s_processed = s_processed * sqrt(energy_original / sum(s_processed.^2)); end
    if max(abs(s_processed)) > 1, s_processed = s_processed / max(abs(s_processed)); end
end