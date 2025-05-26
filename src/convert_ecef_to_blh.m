function BLH = convert_ecef_to_blh(position)
% XYZ2BLH 将地心地固坐标系(ECEF)的坐标转换为大地坐标系(经纬高)
% 输入参数：
%   x, y, z : 地心地固坐标 (单位: 米)
%   a       : 椭球长半轴 (例如WGS-84的a=6378137米)
%   e       : 椭球第一偏心率 (例如WGS-84的e≈0.0818191908426)
%   epsilon : 迭代收敛阈值 (单位: 度, 例如1e-12)
% 输出参数：
%   B       : 大地纬度 (单位: 度)
%   L       : 大地经度 (单位: 度)
%   H       : 大地高 (单位: 米)

    r2d = 180 / pi;   % 弧度转角度因子
    epsilon=1e-12;    %收敛阈值 (1e-12度)
    a = 6378137;                % 长半轴 (米)
    e = 0.0818191908426;        % 第一偏心率
    % 初始化变量
    tmpX = position(1);
    temY = position(2);
    temZ = position(3);
    
    curB = 0;         % 当前纬度估计值
    calB = atan2(temZ, sqrt(tmpX^2 + temY^2));  % 初始纬度计算
    
    % 迭代计算纬度
    counter = 0;
    while (abs(curB - calB) * r2d > epsilon) && (counter < 25)
        curB = calB;
        N = a / sqrt(1 - e^2 * sin(curB)^2);     % 卯酉圈曲率半径
        calB = atan2(temZ + N * e^2 * sin(curB), sqrt(tmpX^2 + temY^2));
        counter = counter + 1;
    end
    
    % 最终参数计算
    N = a / sqrt(1 - e^2 * sin(curB)^2);         % 最终的N值
    L = atan2(temY, tmpX) * r2d;                 % 经度 (度)
    B = curB * r2d;                              % 纬度 (度)
    H = temZ / sin(curB) - N * (1 - e^2);        % 高度 (米)
    
    % 处理可能的奇异点 (sin(curB)=0)
    if abs(sin(curB)) < 1e-16
        H = 0;  % 赤道或两极附近的高度需特殊处理
    end
    BLH=[B, L, H];
end