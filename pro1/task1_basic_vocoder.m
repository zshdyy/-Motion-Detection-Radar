function task1_basic_vocoder()
    % Task 1: 基础加权Greenwood音调声码器测试
    disp('=== 运行 Task 1: 基础音调声码器 ===');
    % 这里可以加入调用 process_with_tone_vocoder 的测试代码
    % 例如读取音频并调用下方的函数
end

function s_processed = process_with_tone_vocoder(s, fs, num_bands, lpf_cutoff, freq_range)
    % 使用加权Greenwood音调声码器处理语音信号
    energy_original = sum(s.^2);
    s_processed = zeros(size(s));
    
    A = 165.4;
    a = 0.06;
    min_f = freq_range(1);
    max_f = freq_range(2);
    
    d_min = log10((min_f/A) + 1) / a;
    d_max = log10((max_f/A) + 1) / a;
    d_values = linspace(d_min, d_max, num_bands+1);
    
    % 物理段长度（耳蜗位置差）作为加权因子
    segment_lengths = diff(d_values); % 每段在D轴上的长度
    weights = segment_lengths / mean(segment_lengths); % 标准化权重
    
    band_edges = A * (10.^(a * d_values) - 1);
    t = (0:length(s)-1)'/fs;
    
    for i = 1:num_bands
        f_low = band_edges(i);
        f_high = band_edges(i+1);
        center_freq = sqrt(f_low * f_high);
        
        [b_bp, a_bp] = butter(4, [f_low f_high]/(fs/2), 'bandpass');
        y = filter(b_bp, a_bp, s);
        y_rect = abs(y);
        
        [b_lp, a_lp] = butter(2, lpf_cutoff/(fs/2), 'low');
        envelope = filter(b_lp, a_lp, y_rect);
        
        sine_wave = sin(2*pi*center_freq * t);
        modulated = envelope .* sine_wave;
        
        s_processed = s_processed + weights(i) * modulated;
    end
    
    energy_processed = sum(s_processed.^2);
    if energy_processed > 0
        s_processed = s_processed * sqrt(energy_original / energy_processed);
    end
    if max(abs(s_processed)) > 1
        s_processed = s_processed / max(abs(s_processed));
    end
end