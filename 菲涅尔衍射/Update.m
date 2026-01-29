function Update(app)
    
    %% ========== 参数设置 ==========
    fprintf('=== 参数设置 ===\n');
    
    lambda = app.lambda;        % 激光波长(m)
    dx = app.pix_size;          % 像素尺寸 (决定计算精度和视场)
    free_prop_distance = app.free_prop_distance;   % 默认自由传播距离 (无透镜时)
    
    % 获取透镜数据
    if isprop(app, 'Lens') && ~isempty(app.Lens)
        Lens = app.Lens; % [f, D, z_pos]
    else
        Lens = [];
    end
    
    % 初始化光场
    img = app.img;
    if size(img, 3) == 3; img = rgb2gray(img); end
    E0 = im2double(img);
    E_field = sqrt(E0); % 初始复振幅
    
    [N, M] = size(E_field);
    fprintf('图像尺寸: %d x %d (%.2f x %.2f mm)\n', N, M, N*dx*1000, M*dx*1000);
    
    %% 确定成像位置
    fprintf('\n=== 1. 几何光学系统分析 ===\n');
    
    % 调用独立的几何光学追踪函数
    [final_display_z, imaging_status, geometric_image_z, use_lens_system, num_lenses] = ...
        Optics_Tracking(Lens, free_prop_distance);
    
    object_z = 0; % 物体位置 (z=0)
    
    %% 绘制光路图 
    Plot_Optical_Path(app, object_z, geometric_image_z, Lens, final_display_z, imaging_status);
    
    %% 衍射模拟
    fprintf('\n=== 2. 物理光场传播 ===\n');
    
    current_wave_z = 0; % 波前的当前位置
    
    if use_lens_system
        %依次穿过每个透镜
        for i = 1:num_lenses
            lens_z = Lens(i, 3);
            lens_f = Lens(i, 1);
            lens_D = Lens(i, 2);
            
            % 传播到透镜前表面
            dz = lens_z - current_wave_z;
            if dz > 1e-6
                fprintf('  传播 %.3f m 到透镜%d (菲涅尔FFT法)\n', dz, i);
                E_field = FresnelFFT(E_field, lambda, dz, dx);
            end
            
            % 应用透镜相位和孔径
            fprintf('  应用透镜 %d (f=%.3f, D=%.3f)\n', i, lens_f, lens_D);
            E_field = Apply_Lens(E_field, lambda, lens_f, lens_D, dx);
            
            current_wave_z = lens_z;
        end
        
        %从最后一个透镜传播到决定的显示平面
        dz_final = final_display_z - current_wave_z;
        if dz_final > 1e-6
            fprintf('  传播 %.3f m 到显示平面 (菲涅尔FFT法)\n', dz_final);
            E_field = FresnelFFT(E_field, lambda, dz_final, dx);
            current_wave_z = final_display_z;
        end
    else
        % 无透镜
        fprintf('  自由传播 %.3f m (菲涅尔FFT法)\n', free_prop_distance);
        E_field = FresnelFFT(E_field, lambda, free_prop_distance, dx);
        current_wave_z = free_prop_distance;
    end
    
    %% 结果显示
    Intensity = abs(E_field).^2;
    
    % 源图像
    cla(app.src_Axes);
    imshow(img, 'Parent', app.src_Axes);
    title(app.src_Axes, '原始物体 (z=0)', 'FontSize', 10);
    
    % 结果图像
    cla(app.dst_Axes);
    
    % 智能归一化显示
    max_I = max(Intensity(:));
    if max_I > 0

        I_disp = Intensity / max_I;
        imagesc(app.dst_Axes, I_disp);
    else
        imagesc(app.dst_Axes, zeros(size(Intensity)));
    end
    
    colormap(app.dst_Axes, 'gray');
    colorbar(app.dst_Axes);
    axis(app.dst_Axes, 'image');
    axis(app.dst_Axes, 'off');
    
    % 标题信息
    if use_lens_system
        if strcmp(imaging_status, '成实像')
            title_str = sprintf('实像平面 (z=%.3fm)\n峰值强度: %.2e', current_wave_z, max_I);
        elseif strcmp(imaging_status, '成虚像')
            title_str = sprintf('虚像 (理论位置 z=%.3fm)\n观测面: z=%.3fm (后焦面)', geometric_image_z, current_wave_z);
        else % 平行光
            title_str = sprintf('平行光输出\n观测面: z=%.3fm (后焦面)', current_wave_z);
        end
    else
        title_str = sprintf('自由传播 z=%.3fm\n菲涅尔FFT法', current_wave_z);
    end
    
    title(app.dst_Axes, title_str, 'FontSize', 10);
    fprintf('完成。最终观测面 z=%.3f m\n', current_wave_z);
end



