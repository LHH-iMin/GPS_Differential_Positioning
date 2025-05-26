function ecef_pos = convert_lla_to_ecef(point)
    % 地球长半轴（米）
    a = 6378137;
    % 地球扁率
    f = 1/298.257223563;
    % 计算短半轴
    b = a * (1 - f);
    % 计算第一偏心率的平方
    e2 = (a^2 - b^2) / a^2;

    % 把角度转换为弧度
    lat=point(1);
    lon=point(2);
    alt=point(3);
    lat_rad = deg2rad(lat);
    lon_rad = deg2rad(lon);

    % 计算卯酉圈半径
    N = a / sqrt(1 - e2 * sin(lat_rad).^2);

    % 计算 ECEF 坐标
    X = (N + alt) .* cos(lat_rad) .* cos(lon_rad);
    Y = (N + alt) .* cos(lat_rad) .* sin(lon_rad);
    Z = (N * (1 - e2) + alt) .* sin(lat_rad);
    ecef_pos=[X Y Z];
end