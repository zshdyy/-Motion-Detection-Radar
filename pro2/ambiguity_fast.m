function [tau, fd, gprd] = ambiguity_fast(seq_sur_lpf, seq_ref_lpf, f_s, freq_range, time_shift_range)
    % 快速模糊函数：带有动态搜索范围的互相关计算
    
    Ts = (0:length(seq_ref_lpf)-1) / f_s;
    fd_2 = -40:2:40;
    
    tau = time_shift_range(1):time_shift_range(end); 
    fd_3 = freq_range(1):2:freq_range(end); 
    fd_column = find(fd_2 == freq_range(1));
    
    gprd = zeros(7, 41); 
    N = length(seq_ref_lpf);
    
    for t = 1:length(tau)
        s_tau = [seq_sur_lpf(tau(t)+1:N), zeros(1, tau(t))];
        for k = 1:length(fd_3)
            taott = s_tau .* conj(seq_ref_lpf) .* exp(-1i * 2 * pi * (freq_range(1)+(k-1)*2) * Ts);
            gprd(time_shift_range(1)+t, k+fd_column-1) = sum(taott); 
        end
    end
    
    M = max(max(gprd));
    [row, column] = find(gprd == M);
    
    fd = -40 + 2 * (column - 1); 
    tau = row - 1; 
end