
function Plot_Optical_Path(app, object_z, image_z, Lens, display_z, imaging_status)
%绘制光路图    
% 检查是否存在Lens_Axes
    if ~isprop(app, 'Lens_Axes')
        fprintf('警告：app.Lens_Axes不存在，无法绘制光路图\n');
        return;
    end
    
    % 清除当前轴
    cla(app.Lens_Axes);
    
    % 设置坐标轴
    hold(app.Lens_Axes, 'on');
    grid(app.Lens_Axes, 'on');
    box(app.Lens_Axes, 'on');
    
    % 1. 确定坐标范围
    if isempty(Lens)
        % 无透镜系统
        z_min = -0.05;
        z_max = 0.15;
    else
        % 有透镜系统
        lens_positions = Lens(:, 3);
        lens_focal_lengths = Lens(:, 1);
        
        % 将所有值转换为列向量再取最小/最大值
        all_z_values = [object_z; lens_positions(:); image_z; display_z];
        z_min = min(all_z_values) - 0.05;
        z_max = max(all_z_values) + 0.05;
        
        % 限制范围，避免过大
        if z_max - z_min > 2.0
            z_max = z_min + 2.0;
        end
    end
    
    % y轴范围
    y_max = 0.03; % 3cm 范围
    
    xlim(app.Lens_Axes, [z_min, z_max]);
    ylim(app.Lens_Axes, [-y_max, y_max]);
    
    % 2. 绘制物体 (物点)
    plot(app.Lens_Axes, object_z, 0, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'Parent', app.Lens_Axes);
    text(object_z, y_max*0.8, '物点', 'HorizontalAlignment', 'center', 'Color', 'b', 'FontSize', 10, 'Parent', app.Lens_Axes);
    text(object_z, -y_max*0.8, sprintf('z=%.2fm', object_z), 'HorizontalAlignment', 'center', 'Color', 'b', 'FontSize', 8, 'Parent', app.Lens_Axes);
    
    % 3. 绘制透镜
    if ~isempty(Lens)
        num_lenses = size(Lens, 1);
        
        for i = 1:num_lenses
            z_lens = Lens(i, 3);
            f = Lens(i, 1);
            D = Lens(i, 2);
            
            % 简单的透镜符号：两条竖线
            line([z_lens, z_lens], [-y_max*0.7, y_max*0.7], ...
                'Color', 'r', 'LineWidth', 2, 'Parent', app.Lens_Axes);
            
            % 标注透镜信息
            text(z_lens, y_max*0.8, sprintf('透镜%d\nf=%.1fcm', i, f*100), ...
                'HorizontalAlignment', 'center', 'Color', 'r', 'FontSize', 9, 'Parent', app.Lens_Axes);
            text(z_lens, -y_max*0.8, sprintf('D=%.1fcm', D*100), ...
                'HorizontalAlignment', 'center', 'Color', 'r', 'FontSize', 8, 'Parent', app.Lens_Axes);
        end
    end
    
    % 4. 绘制像面
    if ~isempty(Lens)
        if isinf(image_z)
            % 平行光情况
            line([display_z, display_z], [-y_max*0.9, y_max*0.9], ...
                'Color', 'g', 'LineStyle', '--', 'LineWidth', 2, 'Parent', app.Lens_Axes);
            text(display_z, y_max*0.8, '观测面', 'HorizontalAlignment', 'center', 'Color', 'g', 'FontSize', 10, 'Parent', app.Lens_Axes);
            text(display_z, -y_max*0.8, sprintf('z=%.2fm', display_z), 'HorizontalAlignment', 'center', 'Color', 'g', 'FontSize', 8, 'Parent', app.Lens_Axes);
        else
            % 实像或虚像
            if strcmp(imaging_status, '成实像')
                line_color = 'm';
                line_style = '-';
                label_text = '实像面';
            else
                line_color = 'c';
                line_style = ':';
                label_text = '虚像面';
            end
            
            line([image_z, image_z], [-y_max*0.9, y_max*0.9], ...
                'Color', line_color, 'LineStyle', line_style, 'LineWidth', 2, 'Parent', app.Lens_Axes);
            text(image_z, y_max*0.8, label_text, 'HorizontalAlignment', 'center', 'Color', line_color, 'FontSize', 10, 'Parent', app.Lens_Axes);
            text(image_z, -y_max*0.8, sprintf('z=%.2fm', image_z), 'HorizontalAlignment', 'center', 'Color', line_color, 'FontSize', 8, 'Parent', app.Lens_Axes);
            
            % 如果观测面和像面不同，也标注观测面
            if abs(display_z - image_z) > 1e-6
                line([display_z, display_z], [-y_max*0.7, y_max*0.7], ...
                    'Color', 'g', 'LineStyle', '--', 'LineWidth', 1.5, 'Parent', app.Lens_Axes);
                text(display_z, -y_max*0.6, sprintf('观测面\nz=%.2fm', display_z), ...
                    'HorizontalAlignment', 'center', 'Color', 'g', 'FontSize', 8, 'Parent', app.Lens_Axes);
            end
        end
    else
        % 无透镜系统，只标注观测面
        line([display_z, display_z], [-y_max*0.9, y_max*0.9], ...
            'Color', 'g', 'LineStyle', '--', 'LineWidth', 2, 'Parent', app.Lens_Axes);
        text(display_z, y_max*0.8, '观测面', 'HorizontalAlignment', 'center', 'Color', 'g', 'FontSize', 10, 'Parent', app.Lens_Axes);
        text(display_z, -y_max*0.8, sprintf('z=%.2fm', display_z), 'HorizontalAlignment', 'center', 'Color', 'g', 'FontSize', 8, 'Parent', app.Lens_Axes);
    end
    
    % 5. 添加标题
    title(app.Lens_Axes, '光学系统示意图', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(app.Lens_Axes, 'z 位置 (m)', 'FontSize', 10);
    ylabel(app.Lens_Axes, 'y 位置 (m)', 'FontSize', 10);
    
    hold(app.Lens_Axes, 'off');
end