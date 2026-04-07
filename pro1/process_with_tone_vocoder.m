function s_processed = process_with_tone_vocoder(s, fs, num_bands, lpf_cutoff, freq_range, filter_type, filter_order)
    % process_with_tone_vocoder: 核心音调声码器处理函数
    % 默认使用 Greenwood 函数进行频带划分
    
    if nargin < 6
        filter_type = 'butter'; % 默认巴特沃斯滤波器
        filter_order = 2;       % 默认 2 阶
    end

    energy_original = sum(s.^2);
    s_processed = zeros(size(s));
    min_freq = freq_range(1);
    max_freq = freq_range(2);
    
    % Greenwood 常数
    A = 165.4;
    a = 0.06;
    d_min = log10((min_freq/A) + 1) / a;
    d_max = log10((max_freq/A) + 1) / a;
    d_values = linspace(d_min, d_max, num_bands+1);
    band_edges = A * (10.^(a*d_values) - 1);
    
    t = (0:length(s)-1)' / fs;
    
    for i = 1:num_bands
        f_low = band_edges(i);
        f_high = band_edges(i+1);
        center_freq = sqrt(f_low * f_high);
        
        % 带通滤波
        [b, a_filter] = butter(4, [f_low f_high]/(fs/2), 'bandpass');
        y = filter(b, a_filter, s);
        y_rect = abs(y); % 全波整流
        
        % 低通滤波提取包络 (支持 Task 2 的多种滤波器类型)
        switch filter_type
            case 'butter'
                [b_lpf, a_lpf] = butter(filter_order, lpf_cutoff/(fs/2), 'low');
            case 'cheby1'
                [b_lpf, a_lpf] = cheby1(filter_order, 1, lpf_cutoff/(fs/2), 'low');
            case 'cheby2'
                [b_lpf, a_lpf] = cheby2(filter_order, 20, lpf_cutoff/(fs/2), 'low');
            case 'ellip'
                [b_lpf, a_lpf] = ellip(filter_order, 1, 20, lpf_cutoff/(fs/2), 'low');
            otherwise
                [b_lpf, a_lpf] = butter(2, lpf_cutoff/(fs/2), 'low');
        end
        
        envelope = filter(b_lpf, a_lpf, y_rect);
        
        % 调制
        sine_wave = sin(2 * pi * center_freq * t);
        modulated_sine = envelope .* sine_wave;
        s_processed = s_processed + modulated_sine;
    end
    
    % 能量归一化与限幅
    energy_processed = sum(s_processed.^2);
    if energy_processed > 0
        s_processed = s_processed * sqrt(energy_original / energy_processed);
    end
    if max(abs(s_processed)) > 1
        s_processed = s_processed / max(abs(s_processed));
    end
end