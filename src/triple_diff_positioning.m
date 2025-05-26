function [rover_positions] = triple_diff_positioning(prev_rover_pos,...
        curr_base_pseudo, curr_rover_pseudo, curr_base_phase, curr_rover_phase,curr_common_sat,curr_sat_pos, ...
        prev_base_pseudo, prev_rover_pseudo, prev_base_phase, prev_rover_phase,prev_common_sat,prev_sat_pos,...
        base_pos, wavelength)
    % 参数定义
    ref_sv = 1; % 参考卫星
    
    % 初始化输出
    rover_positions = zeros(1, 3);
    velocity = zeros(1, 3);

    %寻找公共卫星数据
    [~, idx1, idx2] = intersect(prev_common_sat,curr_common_sat);
    curr_base_pseudo=curr_base_pseudo(idx2);
    curr_rover_pseudo=curr_rover_pseudo(idx2);
    curr_base_phase=curr_base_phase(idx2);
    curr_rover_phase=curr_rover_phase(idx2);
    curr_sat_pos=curr_sat_pos(idx2,:);
    prev_base_pseudo=prev_base_pseudo(idx1);
    prev_rover_pseudo=prev_rover_pseudo(idx1);
    prev_base_phase=prev_base_phase(idx1);
    prev_rover_phase=prev_rover_phase(idx1);
    prev_sat_pos= prev_sat_pos(idx1,:);
    
    % 步骤2: 构建三差观测方程
    [A_td, b_td] = build_triple_diff_equations(prev_rover_pos, ...
        curr_base_pseudo, curr_rover_pseudo, curr_base_phase, curr_rover_phase,curr_sat_pos, ...
        prev_base_pseudo, prev_rover_pseudo, prev_base_phase, prev_rover_phase,prev_sat_pos,...
        base_pos, wavelength, ref_sv);
    
    % 步骤3: 最小二乘解算位置变化
    delta_pos = A_td \ b_td;
    
    % 更新位置
    rover_positions(1,:) = prev_rover_pos + delta_pos';

    % 三差观测方程构建函数
    function [A, b] = build_triple_diff_equations(prev_rover_pos, ...
        curr_base_pseudo, curr_rover_pseudo, curr_base_phase, curr_rover_phase,curr_sat_pos, ...
        prev_base_pseudo, prev_rover_pseudo, prev_base_phase, prev_rover_phase,prev_sat_pos,...
        base_pos, wavelength, ref_sv)
        
        num_sats = size(curr_sat_pos, 1);
        num_dd = num_sats - 1;
        A = zeros(2*num_dd, 3); % 仅需估计位置变化
        b = zeros(2*num_dd, 1);
        
        % 计算上一历元几何距离
        prev_rho_base = vecnorm(base_pos - prev_sat_pos, 2, 2);
        prev_rho_rover = vecnorm(prev_rover_pos - prev_sat_pos, 2, 2);
        
        % 当前历元几何距离（预测值）
        curr_rho_base = vecnorm(base_pos - curr_sat_pos, 2, 2);
        curr_rho_rover = vecnorm(prev_rover_pos - curr_sat_pos, 2, 2);
        
        % 生成卫星索引
        sv_idx = setdiff(1:num_sats, ref_sv);
        
        for i = 1:num_dd
            sv = sv_idx(i);
             %双差伪距观测值（当前历元）
            dd_pseudo_curr = (curr_rover_pseudo(sv) - curr_base_pseudo(sv)) - ...
                            (curr_rover_pseudo(ref_sv) - curr_base_pseudo(ref_sv));

            dd_pseudo_prev = (prev_rover_pseudo(sv) - prev_base_pseudo(sv)) - ...
                            (prev_rover_pseudo(ref_sv) - prev_base_pseudo(ref_sv));

            %三差伪距观测
            td_pseudo = dd_pseudo_curr - dd_pseudo_prev;

            % 双差相位观测（当前历元）
            dd_phase_curr = (curr_rover_phase(sv) - curr_base_phase(sv)) - ...
                           (curr_rover_phase(ref_sv) - curr_base_phase(ref_sv));
            
            % 双差相位观测（上一历元）
            dd_phase_prev = (prev_rover_phase(sv) - prev_base_phase(sv)) - ...
                           (prev_rover_phase(ref_sv) - prev_base_phase(ref_sv));
            
            % 三差相位观测
            td_phase = (dd_phase_curr - dd_phase_prev) * wavelength;
            
            % 几何距离变化
            delta_geometry = (curr_rho_rover(sv) - curr_rho_base(sv)) - (curr_rho_rover(ref_sv) - curr_rho_base(ref_sv))-...
                            ((prev_rho_rover(sv) - prev_rho_base(sv)) - (prev_rho_rover(ref_sv) - prev_rho_base(ref_sv)));
            
            % 视线向量（上一历元和当前历元平均）
            los_prev = (prev_rover_pos - prev_sat_pos(sv,:)) / norm(prev_rover_pos - prev_sat_pos(sv,:));
            los_curr = (prev_rover_pos - curr_sat_pos(sv,:)) / norm(prev_rover_pos - curr_sat_pos(sv,:));
            avg_los = 0.5*(los_prev + los_curr);
            
            % 参考卫星视线向量
            los_ref_prev = (prev_rover_pos - prev_sat_pos(ref_sv,:)) / norm(prev_rover_pos - prev_sat_pos(ref_sv,:));
            los_ref_curr = (prev_rover_pos - curr_sat_pos(ref_sv,:)) / norm(prev_rover_pos - curr_sat_pos(ref_sv,:));
            avg_los_ref = 0.5*(los_ref_prev + los_ref_curr);
            

            % 设计矩阵构建
            %伪距
            A(i, 1:3) = (avg_los - avg_los_ref);
            b(i) = td_pseudo - delta_geometry;

            %载波相位
            A(num_dd+i, 1:3) = (avg_los - avg_los_ref); % 位置变化系数
            b(num_dd+i) = td_phase - delta_geometry;
        end
    end
end