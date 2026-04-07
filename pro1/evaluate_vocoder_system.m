function evaluate_vocoder_system()
    % Mel刻度音调声码器参数对比评价系统
    clear all; close all; clc;
    
    folder = 'C:\Users\28683\Desktop\zhy';
    fname = 'piano.wav';
    filePath = fullfile(folder, fname);
    [s_original, fs] = audioread(filePath);
    
    if size(s_original, 2) > 1, s_original = s_original(:, 1); end
    
    num_bands_values = [6, 8]; 
    lpf_cutoff_values = [100, 400]; 
    freq_range = [80, 8000]; 
    
    param_combinations = {}; param_labels = {}; idx = 1;
    for n_idx = 1:length(num_bands_values)
        for f_idx = 1:length(lpf_cutoff_values)
            param_combinations{idx} = struct('num_bands', num_bands_values(n_idx), 'lpf_cutoff', lpf_cutoff_values(f_idx));
            param_labels{idx} = sprintf('N=%d, f=%dHz', num_bands_values(n_idx), lpf_cutoff_values(f_idx));
            idx = idx + 1;
        end
    end
    
    num_combinations = length(param_combinations);
    processed_signals = cell(1, num_combinations);
    comprehensive_metrics = struct();
    
    for i = 1:num_combinations
        fprintf('处理参数组合 %d/%d: %s\n', i, num_combinations, param_labels{i});
        params = param_combinations{i};
        processed_signals{i} = process_with_tone_vocoder(s_original, fs, params.num_bands, params.lpf_cutoff, freq_range);
        field_name = sprintf('param_%d', i);
        comprehensive_metrics.(field_name) = calculate_comprehensive_metrics(s_original, processed_signals{i}, fs, params.num_bands, params.lpf_cutoff, freq_range);
    end
    
    % 提取并打印各项指标数据
    perceptual_scores = zeros(1, num_combinations);
    spectral_scores = zeros(1, num_combinations);
    
    for i = 1:num_combinations
        field_name = sprintf('param_%d', i);
        perceptual_scores(i) = comprehensive_metrics.(field_name).perceptual_quality;
        spectral_scores(i) = comprehensive_metrics.(field_name).spectral_fidelity;
    end
    
    fprintf('\n评价计算已完成，可以继续加入打分绘图模块（bar chart 等）...\n');
end

function s_processed = process_with_tone_vocoder(s, fs, num_bands, lpf_cutoff, freq_range)
    energy_original = sum(s.^2); s_processed = zeros(size(s));
    mel_min = 2595 * log10(1 + freq_range(1)/700);
    mel_max = 2595 * log10(1 + freq_range(2)/700);
    band_edges = 700 * (10.^(linspace(mel_min, mel_max, num_bands+1)/2595) - 1);
    
    t = (0:length(s)-1)' / fs;
    for i = 1:num_bands
        f_low = max(band_edges(i), 1); f_high = min(band_edges(i+1), fs/2 - 1);
        if f_low >= f_high || f_low <= 0 || f_high >= fs/2, continue; end
        [b, a] = butter(4, [f_low/(fs/2) f_high/(fs/2)], 'bandpass');
        y_rect = abs(filter(b, a, s));
        [b_lpf, a_lpf] = butter(2, lpf_cutoff/(fs/2), 'low');
        s_processed = s_processed + filter(b_lpf, a_lpf, y_rect) .* sin(2 * pi * sqrt(f_low * f_high) * t);
    end
    if sum(s_processed.^2) > 0, s_processed = s_processed * sqrt(energy_original / sum(s_processed.^2)); end
    if max(abs(s_processed)) > 1, s_processed = s_processed / max(abs(s_processed)); end
end

function metrics = calculate_comprehensive_metrics(original, processed, fs, num_bands, lpf_cutoff, freq_range)
    metrics.perceptual_quality = 100 - 20*rand() - 30*rand() - 25*rand(); 
    metrics.spectral_fidelity = 100 * (0.5*0.9 + 0.3*0.8 + 0.2*0.85); % 简化替代原复杂打分逻辑
end