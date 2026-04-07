function task2_filter_analysis()
    num_bands = 4;
    lpf_cutoffs = [20, 50, 100, 400];
    freq_range = [200, 7000];
    folder = 'D:\大二下\信号matlab'; % 请确保此路径在实际运行时正确
    
    fname1 = 'C_01_01.wav';
    filePath1 = fullfile(folder, fname1);
    [s1, fs] = audioread(filePath1);
    
    fname2 = 'C_01_02.wav';
    filePath2 = fullfile(folder, fname2);
    [s2, fs] = audioread(filePath2);
    
    filter_types = {'butter', 'cheby1', 'cheby2', 'ellip'}; 
    filter_orders = [2, 4]; 
    
    s1_processed_all = cell(length(lpf_cutoffs), length(filter_types), length(filter_orders));
    s2_processed_all = cell(length(lpf_cutoffs), length(filter_types), length(filter_orders));
    
    for i = 1:length(lpf_cutoffs)
        lpf = lpf_cutoffs(i);
        for t = 1:length(filter_types)
            filter_type = filter_types{t};
            for o = 1:length(filter_orders)
                filter_order = filter_orders(o);
                fprintf('处理 LPF=%d Hz, 滤波器=%s, 阶数=%d...\n', lpf, filter_type, filter_order);
                
                s1_processed = process_with_tone_vocoder(s1, fs, num_bands, lpf, freq_range, filter_type, filter_order);
                s2_processed = process_with_tone_vocoder(s2, fs, num_bands, lpf, freq_range, filter_type, filter_order);
                
                out_filename1 = sprintf('C_01_01_N4_LPF%d_%s_O%d.wav', lpf, filter_type, filter_order);
                out_filename2 = sprintf('C_01_02_N4_LPF%d_%s_O%d.wav', lpf, filter_type, filter_order);
                audiowrite(fullfile(folder, out_filename1), s1_processed, fs);
                audiowrite(fullfile(folder, out_filename2), s2_processed, fs);
                
                s1_processed_all{i, t, o} = s1_processed;
                s2_processed_all{i, t, o} = s2_processed;
            end
        end
    end
    
    fprintf('s1_processed_all维度: %d x %d x %d\n', size(s1_processed_all));
    fprintf('s2_processed_all维度: %d x %d x %d\n', size(s2_processed_all));
    
    create_filter_comparison_plots(s1, s1_processed_all, fs, lpf_cutoffs, filter_types, filter_orders, 'C_01_01');
    create_filter_comparison_plots(s2, s2_processed_all, fs, lpf_cutoffs, filter_types, filter_orders, 'C_01_02');
    
    create_filter_type_comparison_plots(s1, s1_processed_all, fs, lpf_cutoffs, filter_types, filter_orders, 'C_01_01');
    create_filter_type_comparison_plots(s2, s2_processed_all, fs, lpf_cutoffs, filter_types, filter_orders, 'C_01_02');
end

function s_processed = process_with_tone_vocoder(s, fs, num_bands, lpf_cutoff, freq_range, filter_type, filter_order)
    energy_original = sum(s.^2);
    s_processed = zeros(size(s));
    min_freq = freq_range(1);
    max_freq = freq_range(2);
    A = 165.4;
    a = 0.06;
    d_min = log10((min_freq/A) + 1) / a;
    d_max = log10((max_freq/A) + 1) / a;
    d_values = linspace(d_min, d_max, num_bands+1);
    band_edges = A * (10.^(a*d_values) - 1);
    
    for i = 1:num_bands
        f_low = band_edges(i);
        f_high = band_edges(i+1);
        center_freq = sqrt(f_low * f_high);
        [b, a] = butter(4, [f_low f_high]/(fs/2), 'bandpass');
        y = filter(b, a, s);
        y_rect = abs(y);
        
        switch filter_type
            case 'butter'
                [b_lpf, a_lpf] = butter(filter_order, lpf_cutoff/(fs/2), 'low');
            case 'cheby1'
                [b_lpf, a_lpf] = cheby1(filter_order, 1, lpf_cutoff/(fs/2), 'low');
            case 'cheby2'
                [b_lpf, a_lpf] = cheby2(filter_order, 20, lpf_cutoff/(fs/2), 'low');
            case 'ellip'
                [b_lpf, a_lpf] = ellip(filter_order, 1, 20, lpf_cutoff/(fs/2), 'low');
        end
        
        envelope = filter(b_lpf, a_lpf, y_rect);
        t = (0:length(s)-1)' / fs;
        sine_wave = sin(2 * pi * center_freq * t);
        modulated_sine = envelope .* sine_wave;
        s_processed = s_processed + modulated_sine;
    end
    
    energy_processed = sum(s_processed.^2);
    if energy_processed > 0
        s_processed = s_processed * sqrt(energy_original / energy_processed);
    end
    if max(abs(s_processed)) > 1
        s_processed = s_processed / max(abs(s_processed));
    end
end

function create_filter_type_comparison_plots(original_signal, processed_signals, fs, lpf_cutoffs, filter_types, filter_orders, title_prefix)
    num_lpf = length(lpf_cutoffs);
    num_types = length(filter_types);
    num_orders = length(filter_orders);
    
    for l = 1:num_lpf
        lpf = lpf_cutoffs(l);
        subplot_rows = 1 + num_types * num_orders; 
        subplot_cols = 2;
        figure('Position', [100, 100, 1200, 200 * subplot_rows], 'Color', 'white');
        
        subplot(subplot_rows, subplot_cols, 1);
        t_orig = (0:length(original_signal)-1)/fs;
        plot(t_orig, original_signal, 'LineWidth', 1.5);
        title(['原始信号时域图 (LPF=', num2str(lpf), 'Hz)'], 'FontSize', 12);
        grid on;
        
        subplot(subplot_rows, subplot_cols, 2);
        N_orig = length(original_signal);
        f_orig = (-N_orig/2:(N_orig/2-1))*fs/N_orig;
        Y_orig_shifted = fftshift(abs(fft(original_signal)/N_orig));
        plot(f_orig, Y_orig_shifted, 'LineWidth', 1.5);
        title(['原始信号频域图 (LPF=', num2str(lpf), 'Hz)'], 'FontSize', 12);
        xlim([-8000 8000]);
        grid on;
        
        idx = 3;
        for t = 1:num_types
            filter_type = filter_types{t};
            for o = 1:num_orders
                processed_signal = processed_signals{l, t, o};
                
                subplot(subplot_rows, subplot_cols, idx);
                t_time = (0:length(processed_signal)-1)/fs; 
                plot(t_time, processed_signal, 'LineWidth', 1.5);
                title(sprintf('%s, 阶数%d, 时域图', filter_type, filter_orders(o)), 'FontSize', 12);
                grid on;
                idx = idx + 1;
                
                subplot(subplot_rows, subplot_cols, idx);
                N = length(processed_signal);
                f = (-N/2:(N/2-1))*fs/N;
                Y_shifted = fftshift(abs(fft(processed_signal)/N));
                plot(f, Y_shifted, 'LineWidth', 1.5);
                title(sprintf('%s, 阶数%d, 频域图', filter_type, filter_orders(o)), 'FontSize', 12);
                xlim([-8000 8000]);
                grid on;
                idx = idx + 1; 
            end
        end
        sgtitle(sprintf('%s - 不同滤波器对比 (LPF=%dHz)', title_prefix, lpf), 'FontSize', 14);
        saveas(gcf, [title_prefix, '_filter_type_comparison_LPF', num2str(lpf), '.png']);
    end
end

function create_filter_comparison_plots(original_signal, processed_signals, fs, lpf_cutoffs, filter_types, filter_orders, title_prefix)
    num_lpf = length(lpf_cutoffs);
    num_types = length(filter_types);
    num_orders = length(filter_orders);
    for l = 1:num_lpf
        lpf = lpf_cutoffs(l);
        figure('Position', [100, 100, 1200, 800], 'Color', 'white');
        
        subplot(num_types, num_orders + 1, 1);
        spectrogram(original_signal, 256, 128, 256, fs, 'yaxis');
        title(['原始信号 (LPF=', num2str(lpf), 'Hz)'], 'FontSize', 12);
        ylim([0 10]); colorbar;
        
        for t = 1:num_types
            filter_type = filter_types{t};
            for o = 1:num_orders
                idx = (t-1)*num_orders + o;
                processed_signal = processed_signals{l, t, o};
                subplot(num_types, num_orders + 1, idx + 1);
                spectrogram(processed_signal, 256, 128, 256, fs, 'yaxis');
                title(sprintf('%s, 阶数%d', filter_type, filter_orders(o)), 'FontSize', 12);
                ylim([0 10]); colorbar; caxis([-150 0]);
            end
        end
        sgtitle(sprintf('%s - 不同滤波器对比 (LPF=%dHz)', title_prefix, lpf), 'FontSize', 14);
        saveas(gcf, [title_prefix, '_filter_comparison_LPF', num2str(lpf), '.png']);
    end
end