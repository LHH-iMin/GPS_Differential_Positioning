% 伪距单差定位函数
function [pos, delta_dtr] = single_diff_pseudorange_positioning(...
        base_pseudo, rover_pseudo, base_pos, sat_positions)
    
    max_iter = 10;
    tol = 1e-6;
    pos = base_pos; % 初始位置
    delta_dtr = 0;  % 初始钟差差,单位为m
    
    for iter = 1:max_iter
        [A, b] = build_pseudorange_equations(...
            pos, base_pseudo, rover_pseudo,...
            base_pos, sat_positions,delta_dtr);
        
        dx = A \ b;
        pos = pos + dx(1:3)';
        delta_dtr = delta_dtr + dx(4);
        
        if norm(dx(1:3)) < tol
            break;
        end
    end
end

% 伪距方程构建函数
function [A, b] = build_pseudorange_equations(...
        pos, base_pseudo, rover_pseudo,...
        base_pos, sat_positions,delta_dtr)
    
    num_sats = size(sat_positions, 1);
    A = zeros(num_sats, 4);
    b = zeros(num_sats, 1);
    
    for i = 1:num_sats
        sat_pos = sat_positions(i,:);
        geo_dist = norm(pos - sat_pos);
        line_of_sight = (pos - sat_pos) / geo_dist;
        
        A(i, 1:3) = line_of_sight;
        A(i, 4) = 1;
        b(i) = (rover_pseudo(i) - base_pseudo(i)) - ...
               (geo_dist - norm(base_pos - sat_pos)) - ...
               1*delta_dtr;   
    end
end