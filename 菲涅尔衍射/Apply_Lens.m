function E_out = Apply_Lens(E_in, lambda, f, D, dx)
    % 应用薄透镜相位和孔径
    [N, M] = size(E_in);
    x = (-M/2 : M/2-1) * dx;
    y = (-N/2 : N/2-1) * dx;
    [X, Y] = meshgrid(x, y);
    
    % 孔径
    radius = D / 2;
    Mask = double((X.^2 + Y.^2) <= radius^2);
    
    % 透镜相位
    k = 2 * pi / lambda;

    Phase = exp(-1i * k * (X.^2 + Y.^2) / (2 * f));
    
    E_out = E_in .* Mask .* Phase;
end