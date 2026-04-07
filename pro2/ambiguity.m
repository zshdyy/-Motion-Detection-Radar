function [time_delay, fd, gprd] = ambiguity(seq_sur_lpf, seq_ref_lpf, f_s)
    % 输入两个信号，计算其模糊函数并返回最大值对应的时间延迟（tau）和频率偏移（fd）
    % 基础版本：采用全量静态搜索范围计算
    
    Ts = (0:length(seq_ref_lpf)-1) / f_s; % 离散时间序列 (自适应输入信号长度)
    time_delay_range = 0:6; % 时间延迟范围
    N = length(seq_ref_lpf); % 信号长度
    
    gprd = zeros(length(time_delay_range), 41); % 初始化存储模糊函数值的数组
    
    % 遍历不同的时间延迟（time_delay），范围从 0 到 6
    for t = 1:length(time_delay_range)
        % 通过时间延迟平移信号
        s_tau = [seq_sur_lpf(time_delay_range(t) + 1:N), zeros(1, time_delay_range(t))]; 
        
        for k = 0:40
            % 根据模糊函数公式计算，频率偏移从 -40 到 40 Hz
            fd_value = -40 + 2 * k; % 频率偏移值，步长为 2 Hz
            taott = s_tau .* conj(seq_ref_lpf) .* exp(-1i * 2 * pi * fd_value * Ts); 
            gprd(t, k + 1) = sum(taott); % 计算模糊函数值并求和
        end
    end
    
    % 找到模糊函数矩阵中的最大值
    M = max(max(gprd));
    
    % 找到最大值的行列索引
    [row, column] = find(gprd == M);
    
    % 计算频率偏移和时间延迟
    % 频率偏移（fd）从列索引计算，k=0对应-40Hz，步长为2Hz
    fd = -40 + 2 * (column - 1); 
    
    % 时间延迟（tau）从行索引计算
    time_delay = row - 1; 
    
end