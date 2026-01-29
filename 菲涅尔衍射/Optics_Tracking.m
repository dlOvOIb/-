%% ========== 独立的几何光学追踪函数 ==========
function [final_display_z, imaging_status, geometric_image_z, use_lens_system, num_lenses] = ...
    Optics_Tracking(Lens, free_prop_distance)
    
    % 初始化返回值
    final_display_z = free_prop_distance;
    imaging_status = '无透镜';
    geometric_image_z = inf;
    use_lens_system = ~isempty(Lens);
    num_lenses = 0;
    
    if use_lens_system
        num_lenses = size(Lens, 1);
        
        % 追踪光束状态
        % 初始状态：物在 z=0
        current_img_z = 0;      % 当前像的位置（作为下一级的物）
        is_parallel = false;    % 当前光束是否为平行光
        
        fprintf('系统包含 %d 个透镜，开始追踪光路：\n', num_lenses);
        
        for i = 1:num_lenses
            f = Lens(i, 1);
            z_lens = Lens(i, 3);

            % 计算物距 u (透镜位置 - 上一次像的位置)
            if is_parallel
                u = inf; % 入射光是平行光，物距无限远
            else
                u = z_lens - current_img_z;
            end
            
            % 计算像距 v (高斯成像公式 1/v + 1/u = 1/f)
            %入射是平行光 (u = Inf) -> v = f
            if isinf(u)
                v = f;
                is_parallel_out = false;
                
            % 物在焦点上 (u = f) -> 出射平行光 (v = Inf)
            elseif abs(u - f) < 1e-6
                v = inf;
                is_parallel_out = true;
                
            % 普通成像
            else
                v = (f * u) / (u - f);
                is_parallel_out = false;
            end
            
            % 更新状态
            is_parallel = is_parallel_out;
            
            if is_parallel
                fprintf('出射: 平行光\n');
                current_img_z = inf; % 标记像在无穷远
            else
                % 计算绝对坐标系下的像位置
                current_img_z = z_lens + v; 
                
                % 判断虚实
                if v > 0
                    fprintf('像距 v=%.3fm (实像, z=%.3fm)\n', v, current_img_z);
                else
                    fprintf('像距 v=%.3fm (虚像, z=%.3fm)\n', v, current_img_z);
                end
            end
        end
        
        %current_img_z 为最终像面位置 ---
        geometric_image_z = current_img_z;
        
        % 决策：物理模拟要传播到哪里显示？
        if is_parallel
            imaging_status = '平行光输出';
            % 平行光无法在无穷远处显示，显示在"后焦面"或"透镜后一段距离"
            final_display_z = Lens(end, 3) + free_prop_distance; 
            fprintf('>> 最终结果为平行光，模拟平面设为末透镜后焦面: z=%.3fm\n', final_display_z);
            
        elseif current_img_z < Lens(end, 3)
            imaging_status = '成虚像';
            % 我们将屏幕放在透镜后方，通常也放在后焦面或稍远处观察光斑
            final_display_z = Lens(end, 3) + free_prop_distance;
            fprintf('>> 最终结果为虚像 (位于 z=%.3fm)，模拟平面设为末透镜后焦面: z=%.3fm\n', current_img_z, final_display_z);
            
        else
            imaging_status = '成实像';
            final_display_z = current_img_z;
            fprintf('>> 最终结果为实像，模拟平面设为像平面: z=%.3fm\n', final_display_z);
        end
        
    else
        fprintf('无透镜，自由传播。\n');
    end
end