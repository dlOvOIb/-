function E_out = FresnelFFT(E_in, lambda, z, dx)
    % 菲涅尔衍射的FFT实现方法
    
    [N, M] = size(E_in);
    k = 2 * pi / lambda;
    
    % 空域坐标 (输入平面)
    x1 = (-M/2 : M/2-1) * dx;
    y1 = (-N/2 : N/2-1) * dx;
    [X1, Y1] = meshgrid(x1, y1);
    
    quad_phase_in = exp(1i * k * (X1.^2 + Y1.^2) / (2 * z));
    E_mod = E_in .* quad_phase_in;
    
    E_fft = fftshift(fft2(ifftshift(E_mod)));
    
    x = (-M/2 : M/2-1) * dx;
    y = (-N/2 : N/2-1) * dx;
    [X, Y] = meshgrid(x, y);
    
    A1 = (exp(1i * k * z) / (1i * lambda * z)) * (exp(1i * k * (X.^2 + Y.^2) / (2 * z)));
    
    E_out = A1 .* E_fft / (M * N); % 归一化因子
    
end