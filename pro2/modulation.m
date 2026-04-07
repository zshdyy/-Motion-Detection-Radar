function [osur,oref] = modulation(number,t0,ts,Fn)
    % 处理信号输出所有图像并且返回滤波之后的值
    % number == data数
    % t0为开始时间，ts为结束时间, Fn为滤波阶次
    
    % 请确保当前路径下有 data 文件夹及对应数据
    % addpath('data') 
    load(sprintf('data_%d.mat',number)); % 建议用相对路径，方便 GitHub 开源
    
    dT = 1/(f_s):1/(f_s):0.5;
    N0 = t0*f_s;
    N = ts*f_s;
    tuse = t0+1/(f_s) : 1/(f_s):ts;
    
    % 处理画图数
    seq_ref_g = seq_ref(N0+1:N); 
    seq_sur_g = seq_sur(N0+1:N); 
    
    % 频域分析：使用 FFT 计算频谱 
    f = (-f_s/2):(f_s/2 - 1); % 频率向量
    f_use = f(1:1/(ts-t0):end);
    
    % 计算参考信号的 FFT
    fft_ref = fftshift(fft(seq_ref(N0+1:N))); 
    fft_sur = fftshift(fft(seq_sur(N0+1:N))); 
    
    %--------------------- 频移处理 (DDC)
    t = (1/f_s):(1/f_s):(N-N0)*(1/f_s);
    seq_ref_d =seq_ref_g.*exp(1i*18*10^6*t);
    seq_sur_d =seq_sur_g.*exp(1i*18*10^6*t);
    fft_ref_d=fftshift(fft(seq_ref_d));
    fft_sur_d=fftshift(fft(seq_sur_d));
    
    %---------------------- 滤波处理
    fcut = 9*10^6;
    [b,a] = butter(Fn,fcut/(f_s/2));
    
    seq_ref_l=filter(b,a,seq_ref_d);
    seq_sur_l=filter(b,a,seq_sur_d);
    fft_ref_l=fftshift(fft(seq_ref_l));
    fft_sur_l=fftshift(fft(seq_sur_l));
    
    oref = seq_ref_l;
    osur = seq_sur_l;
    
    % 绘制频域波形 (原信号)
    figure;
    subplot(4,2,1); plot(tuse,real(seq_ref_g)); title(sprintf('第%d段参考信号（时域）', number)); ylim([-0.004,0.004]);
    subplot(4,2,2); plot(tuse,real(seq_sur_g)); title(sprintf('第%d段监视信号（时域）', number)); ylim([-0.004,0.004]);
    subplot(4,2,3); plot(f_use,real(20*log10(fft_ref))); title(sprintf('第%d段参考信号（频域）',number));
    subplot(4,2,4); plot(f_use,real(20*log10(fft_sur))); title(sprintf('第%d段监视信号（频域）', number));
    sgtitle(sprintf('原第%d段信号', number));
    
    % 绘制频移处理后信号
    figure;
    subplot(4,2,1); plot(tuse,real(seq_ref_d)); title(sprintf('第%d段参考信号（时域）', number)); ylim([-0.004,0.004]);
    subplot(4,2,2); plot(tuse,real(seq_sur_d)); title(sprintf('第%d段监视信号（时域）', number)); ylim([-0.004,0.004]);
    subplot(4,2,3); plot(f_use,real(20*log10(fft_ref_d))); title(sprintf('第%d段参考信号（频域）',number));
    subplot(4,2,4); plot(f_use,real(20*log10(fft_sur_d))); title(sprintf('第%d段监视信号（频域）', number));
    sgtitle(sprintf('频移处理后的第%d段信号', number));
    
    % 绘制滤波处理后信号
    figure;
    subplot(4,2,1); plot(tuse,real(seq_ref_l)); title(sprintf('第%d段参考信号（时域）', number)); ylim([-0.004,0.004]);
    subplot(4,2,2); plot(tuse,real(seq_sur_l)); title(sprintf('第%d段监视信号（时域）', number)); ylim([-0.004,0.004]);
    subplot(4,2,3); plot(f_use,real(20*log10(fft_ref_l))); title(sprintf('第%d段参考信号（频域）',number));
    subplot(4,2,4); plot(f_use,real(20*log10(fft_sur_l))); title(sprintf('第%d段监视信号（频域）', number));
    sgtitle(sprintf('滤波处理后的第%d段信号', number));
    grid on;
end