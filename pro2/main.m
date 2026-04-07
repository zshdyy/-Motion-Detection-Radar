% Project 2: Motion Detection via Communication Signals - 主分析脚本
clear; close all; clc;

% 数据文件配置 (如果在 GitHub 上开源，建议使用相对路径如 'data/')
basePath = 'C:\Users\28683\Desktop\data2'; 
numbers = 1:1:20;

% 初始的频率范围和时移范围
freq_range = [-40, 40]; 
time_shift_range = 0:6; 
cord = zeros(20, 41); % 用于保存用于绘制 Time-Doppler 谱的数据

elapsed_times = zeros(1, length(numbers)); 
f_ddc = -3e6;
f_lp = 9e6;

fprintf('开始分析 20 段目标回波数据...\n');

for i = 1:length(numbers)
    number = numbers(i);
    filename = sprintf('data_%d.mat', number);
    fullPath = fullfile(basePath, filename);
    load(fullPath); % 加载 seq_ref 和 seq_sur
    
    % 处理 seq_ref (DDC 和 LPF)
    dt = 0.5 / length(seq_ref);
    seq_ref_ddc1 = seq_ref .* exp(-1j * 2 * pi * f_ddc * dt * (0:length(seq_ref)-1));
    [b, a] = butter(30, f_lp / (f_s / 2));
    seq_ref_lpf1 = filter(b, a, seq_ref_ddc1);
    
    % 处理 seq_sur (DDC 和 LPF)
    seq_sur_ddc1 = seq_sur .* exp(-1j * 2 * pi * f_ddc * dt * (0:length(seq_ref)-1));
    seq_sur_lpf1 = filter(b, a, seq_sur_ddc1);
    
    % 使用快速模糊函数进行匹配
    tic; 
    [tau, fd, data] = ambiguity_fast(seq_sur_lpf1, seq_ref_lpf1, f_s, freq_range, time_shift_range);
    elapsed_time = toc; 
    
    cord(i,:) = data(tau+1, :); % 保存最大相关峰所在行的多普勒剖面
    elapsed_times(i) = elapsed_time;
    
    fprintf('data_%d 分析完毕，耗时: %.4f 秒\n', number, elapsed_time);
    
    % 绘制单次匹配度 3D 图
    x = -40:2:40;
    y = 0:12:72;
    figure;
    surf(x, y, abs(data)); 
    colorbar; view(0, 90); ylim([0, 72]); 
    title(sprintf('%.1f-%.1f s: %.2f Hz, %.2f m', 0.5*(number-1), 0.5*number, fd, tau * 12));
    xlabel('Frequency (Hz)'); ylabel('Range (m)'); yticks(0:12:72); 
    
    % 动态更新搜索范围以加速下一次计算
    [max_val, max_idx] = max(abs(data(:))); 
    [max_tau_idx, max_fd_idx] = ind2sub(size(data), max_idx); 
    
    tau_center = max_tau_idx; 
    time_shift_range = [max(0, tau_center - 2), min(6, tau_center)]; 
    fd_1 = -40:2:40;
    new_freq_min = fd_1(max_fd_idx) - 30;
    new_freq_max = fd_1(max_fd_idx) + 30;
    freq_range = [max(-40, new_freq_min), min(40, new_freq_max)]; 
end

% 绘制算法耗时柱状图
figure;
bar(elapsed_times);
xticks(1:length(numbers));
xticklabels(arrayfun(@(x) sprintf('data%d', x), numbers, 'UniformOutput', false));
xlabel('Data File'); ylabel('Time (seconds)');
title('Calculation Time for Each Data File (with Dynamic Search)');
grid on;

% 绘制最终的 Time-Doppler Spectrum (原 Task 3 的核心输出)
y = 0:0.5:9.5;
x = -40:2:40;
[X,Y] = meshgrid(x,y);

figure;
surf(X, Y, abs(cord));
colorbar; view(0, 90); 
ylim([0, 9.5]); yticks(0:0.5:9.5);
xlabel('Doppler Frequency (Hz)');
ylabel('Time (s)');
title('Time-Doppler Spectrum');