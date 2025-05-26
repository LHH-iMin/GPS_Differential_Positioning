function distance = calculate_Distance(point1, point2, max_iter, tol)
    % WGS84 椭球参数
    a = 6378137.0; % 长半轴 (m)
    f = 1 / 298.257223563;
    b = a * (1 - f); % 短半轴 (m)
    e_sq = 2 * f - f^2; % 偏心率平方
    if nargin < 3
        max_iter = 200;
    end
    if nargin < 4
        tol = 1e-12;
    end
    % 将角度转换为弧度
    lat1_rad = deg2rad(point1(1));
    lon1_rad = deg2rad(point1(2));
    lat2_rad = deg2rad(point2(1));
    lon2_rad = deg2rad(point2(2));
    % 初始值
    U1 = atan((1 - f) * tan(lat1_rad));
    U2 = atan((1 - f) * tan(lat2_rad));
    L = lon2_rad - lon1_rad;
    lambda_old = L;
    
    sin_alpha = 0;
    cos2_alpha = 0;
    sigma = 0;
    
    for iter = 1:max_iter
        sin_sigma = sqrt((cos(U2) * sin(lambda_old))^2 + (cos(U1) * sin(U2) - sin(U1) * cos(U2) * cos(lambda_old))^2);
        cos_sigma = sin(U1) * sin(U2) + cos(U1) * cos(U2) * cos(lambda_old);
        sigma = atan2(sin_sigma, cos_sigma);
        
        sin_alpha = (cos(U1) * cos(U2) * sin(lambda_old)) / sin_sigma;
        cos2_alpha = 1 - sin_alpha^2;
        
        cos_2sigma_m = cos_sigma - (2 * sin(U1) * sin(U2)) / cos2_alpha;
        C = f / 16 * cos2_alpha * (4 + f * (4 - 3 * cos2_alpha));
        lambda_new = L + (1 - C) * f * sin_alpha * (sigma + C * sin_sigma * (cos_2sigma_m + C * cos_sigma * (-1 + 2 * cos_2sigma_m^2)));
        
        if abs(lambda_new - lambda_old) < tol
            break;
        end
        lambda_old = lambda_new;
    end
    
    if iter == max_iter
        error('Vincenty算法未收敛');
    end
    
    % 计算距离
    u_sq = cos2_alpha * (a^2 - b^2) / b^2;
    A = 1 + u_sq / 16384 * (4096 + u_sq * (-768 + u_sq * (320 - 175 * u_sq)));
    B = u_sq / 1024 * (256 + u_sq * (-128 + u_sq * (74 - 47 * u_sq)));
    delta_sigma = B * sin_sigma * (cos_2sigma_m + B / 4 * (cos_sigma * (-1 + 2 * cos_2sigma_m^2) - B / 6 * cos_2sigma_m * (-3 + 4 * sin_sigma^2) * (-3 + 4 * cos_2sigma_m^2)));
    distance = b * A * (sigma - delta_sigma);
end
 

