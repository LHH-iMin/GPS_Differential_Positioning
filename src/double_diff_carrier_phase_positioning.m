function [fixed_ambiguities, rover_position] = double_diff_carrier_phase_positioning(...
        base_pseudo, rover_pseudo, base_phase, rover_phase,...
        base_pos, sat_positions, wavelength)
    
    % 参数定义
    % c = 299792458; % 光速 (m/s)
    num_sats = size(sat_positions, 1);
    ref_sv = 1; % 选择参考卫星（通常选高度角最高的卫星）

    % 计算基准站到各卫星的几何距离
    rho_base = vecnorm(base_pos - sat_positions, 2, 2);

    % 步骤1: 伪距单差定位获取初始位置
    [initial_pos, ~] = single_diff_pseudorange_positioning(...
        base_pseudo, rover_pseudo, base_pos, sat_positions);

    % 步骤2: 构建双差观测方程
    [A_dd, b_dd, amb_idx] = build_dd_equations(...
        initial_pos, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base, ref_sv);

    % 步骤3: 最小二乘解算浮点解
    float_solution = A_dd \ b_dd;
    pos_correction = float_solution(1:3);
    amb_float = float_solution(4:end); % 双差模糊度浮点解

    % 步骤4: 模糊度固定（需要LAMBDA方法）
    amb_fixed = round(amb_float); % 示例用取整代替LAMBDA

    % 步骤5: 固定模糊度后重新计算位置
    [A_fixed, b_fixed] = build_fixed_dd_equations(...
        initial_pos + pos_correction',...
        amb_fixed, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base, ref_sv, amb_idx);
    
    final_correction = A_fixed \ b_fixed;
    rover_position = (initial_pos + pos_correction') + final_correction';
    fixed_ambiguities = amb_fixed;
% 
end

% 双差观测方程构建函数
function [A, b, amb_idx] = build_dd_equations(...
        pos, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base, ref_sv)
    
    num_sats = size(sat_positions, 1);
    num_dd = num_sats - 1; % 双差观测数
    
    % 初始化设计矩阵和观测向量
    A = zeros(2*num_dd, 3 + num_dd); % 位置+双差模糊度
    b = zeros(2*num_dd, 1);
    
    % 生成双差索引（排除参考卫星）
    sv_idx = setdiff(1:num_sats, ref_sv);
    amb_idx = zeros(num_dd, 1);
    
    for i = 1:num_dd
        sv = sv_idx(i);
        
        % 双差几何距离差
        rho_rover_ref = norm(pos - sat_positions(ref_sv,:)) - rho_base(ref_sv);
        rho_rover_sv = norm(pos - sat_positions(sv,:)) - rho_base(sv);
        dd_geometry = (rho_rover_sv - rho_rover_ref);
        
        % 伪距双差
        dd_pseudo = (rover_pseudo(sv) - base_pseudo(sv)) - ...
                    (rover_pseudo(ref_sv) - base_pseudo(ref_sv));
        
        % 载波相位双差
        dd_phase = (rover_phase(sv) - base_phase(sv)) - ...
                  (rover_phase(ref_sv) - base_phase(ref_sv));
        
        % 视线向量计算
        los_ref = (pos - sat_positions(ref_sv,:)) / norm(pos - sat_positions(ref_sv,:));
        los_sv = (pos - sat_positions(sv,:)) / norm(pos - sat_positions(sv,:));
        
        % 设计矩阵构建
        A(i, 1:3) = los_sv - los_ref;         % 位置系数
        b(i) = dd_pseudo - dd_geometry;       % 伪距双差观测值
        
        phase_row = num_dd + i;
        A(phase_row, 1:3) = los_sv - los_ref; % 位置系数
        A(phase_row, 3+i) = wavelength;       % 模糊度系数
        b(phase_row) = dd_phase*wavelength - dd_geometry; % 相位双差
        
        amb_idx(i) = sv; % 记录模糊度对应的卫星索引
    end
end

% 固定模糊度后的方程构建
function [A, b] = build_fixed_dd_equations(...
        pos, amb_fixed, base_phase, rover_phase,base_pseudo,rover_pseudo,...
        sat_positions, wavelength, rho_base, ref_sv, amb_idx)
    
    num_dd = length(amb_idx);
    A = zeros(2*num_dd, 3);
    b = zeros(2*num_dd, 1);
    
    for i = 1:num_dd
        sv = amb_idx(i);
        
        % 双差几何距离差
        rho_rover_ref = norm(pos - sat_positions(ref_sv,:)) - rho_base(ref_sv);
        rho_rover_sv = norm(pos - sat_positions(sv,:)) - rho_base(sv);
        dd_geometry = (rho_rover_sv - rho_rover_ref);
        
        % 伪距双差
        dd_pseudo = (rover_pseudo(sv) - base_pseudo(sv)) - ...
                    (rover_pseudo(ref_sv) - base_pseudo(ref_sv));
        
        % 载波相位双差（已固定模糊度）
        dd_phase = ((rover_phase(sv) - base_phase(sv)) - ...
                   (rover_phase(ref_sv) - base_phase(ref_sv))) * wavelength ...
                   - wavelength*amb_fixed(i);
        
        % 视线向量
        los_ref = (pos - sat_positions(ref_sv,:)) / norm(pos - sat_positions(ref_sv,:));
        los_sv = (pos - sat_positions(sv,:)) / norm(pos - sat_positions(sv,:));
        
        % 设计矩阵
        A(i, 1:3) = los_sv - los_ref;
        b(i) = dd_pseudo - dd_geometry;
        
        phase_row = num_dd + i;
        A(phase_row, 1:3) = los_sv - los_ref;
        b(phase_row) = dd_phase - dd_geometry;
    end
end