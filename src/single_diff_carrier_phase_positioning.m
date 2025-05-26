function [fixed_ambiguities, rover_position] = single_diff_carrier_phase_positioning(base_pseudo, rover_pseudo, ...
    base_phase, rover_phase, base_pos, sat_positions, wavelength)
    % 参数定义
    % c = 299792458; % 光速 (m/s)
    num_sats = size(sat_positions, 1);
    % 计算基准站到卫星的几何距离
    rho_base = vecnorm(base_pos - sat_positions, 2, 2);
    
    % 步骤1: 伪距单差定位获取初始位置
    [initial_pos, delta_dtr] = single_diff_pseudorange_positioning(...
        base_pseudo, rover_pseudo, base_pos, sat_positions);
    
    % 步骤2: 构建载波相位单差观测方程
    [A, b] = build_phase_observation_matrix(...
        initial_pos, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base,delta_dtr);
    
    % 步骤3: 最小二乘解算浮点解
    float_solution = A \ b;
    pos_correction = float_solution(1:3);
    amb_float = float_solution(5:end);
    
    % 步骤四 计算模糊度协方差矩阵
    % residuals = b - A*float_solution;
    % sigma2 = (residuals'*residuals)/(size(A,1)-size(A,2)); % 验后方差估计
    % Q_amb = inv(A'*A);  % 模糊度协方差矩阵
    % Q_amb = Q_amb(5:end,5:end)*sigma2;  % 提取模糊度部分
    % 
    % % 步骤4: LAMBDA模糊度固定
    % [amb_fixed, success, ~] = LAMBDA(amb_float, Q_amb, 'ratio', 3.0);
    % 
    % if ~success
    %     fprintf('模糊度固定失败，使用浮点解取整');
    %     amb_fixed = round(amb_float); 
    % end
    amb_fixed = round(amb_float);
    
    % 步骤5: 固定模糊度后重新计算位置
    [A_fixed, b_fixed] = build_fixed_ambiguity_equations(...
        initial_pos + pos_correction', delta_dtr,...
        amb_fixed, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base);
    
    final_correction = A_fixed \ b_fixed;
    rover_position = (initial_pos + pos_correction') + final_correction(1:3)';
    fixed_ambiguities = amb_fixed;
end

% 相位观测方程构建函数
function [A, b] = build_phase_observation_matrix(...
        pos, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base,delta_dtr)
    
    num_sats = size(sat_positions, 1);
    A = zeros(2*num_sats, 3 + 1 + num_sats); % 位置+钟差+模糊度
    b = zeros(2*num_sats, 1);
    
    for i = 1:num_sats
        sat_pos = sat_positions(i,:);
        geo_dist = norm(pos - sat_pos);
        line_of_sight = (pos - sat_pos) / geo_dist;
        
        % 伪距部分
        A(i, 1:3) = line_of_sight;
        A(i, 4) = 1;
        b(i) = (rover_pseudo(i) - base_pseudo(i)) - ...
               (geo_dist - rho_base(i))  -1*delta_dtr; 
        
        % 相位部分
        phase_row = num_sats + i;
        A(phase_row, 1:3) = line_of_sight;
        A(phase_row, 4) = 1;
        A(phase_row, 4+i) = wavelength;
        b(phase_row) = (rover_phase(i) - base_phase(i))*wavelength - ...
                      (geo_dist - rho_base(i))  -1*delta_dtr; 
    end
end

% 固定模糊度后的方程构建
function [A, b] = build_fixed_ambiguity_equations(...
        pos, delta_dtr, amb_fixed, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base)
    
    num_sats = size(sat_positions, 1);
    A = zeros(2*num_sats, 4);
    b = zeros(2*num_sats, 1);
    
    for i = 1:num_sats
        sat_pos = sat_positions(i,:);
        geo_dist = norm(pos - sat_pos);
        line_of_sight = (pos - sat_pos) / geo_dist;
        
        % 伪距部分
        A(i, 1:3) = line_of_sight;
        A(i, 4) = 1;
        b(i) = (rover_pseudo(i) - base_pseudo(i)) - ...
               (geo_dist - rho_base(i))  -1*delta_dtr; 
        
        % 相位部分
        phase_row = num_sats + i;
        A(phase_row, 1:3) = line_of_sight;
        A(phase_row, 4) = 1;
        b(phase_row) = (rover_phase(i) - base_phase(i))*wavelength - ...
                      (geo_dist - rho_base(i)) - ...
                      wavelength*amb_fixed(i)  -1*delta_dtr; 
    end
end