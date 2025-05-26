function position= calculate_sat_position(gps_data, prn_idx, t)
%%计算卫星位置
% 输入参数：
% - gps_data: 通过read_rinex_nav读取的导航电文数据结构
% - prn_idx: 卫星在结构体中的索引（例如第1颗卫星为1）
% - t: 当前时间（GPS周秒数）


% 提取当前卫星的导航参数
prn = gps_data.PRN(prn_idx);
toe_sec=gps_data.Toe_sec(prn_idx);
sqrt_a = gps_data.sqrtA(prn_idx);
delta_n = gps_data.DeltaN(prn_idx);%平均角速度校正值
M0 = gps_data.M0(prn_idx);
e = gps_data.e(prn_idx);
Cuc = gps_data.Cuc(prn_idx);
Cus = gps_data.Cus(prn_idx);
Crc = gps_data.Crc(prn_idx);
Crs = gps_data.Crs(prn_idx);
Cic = gps_data.Cic(prn_idx);
Cis = gps_data.Cis(prn_idx);
i0 = gps_data.i0(prn_idx);
OMG0 = gps_data.OMEGA0(prn_idx);
OMG0_DOT = gps_data.OMEGA_DOT(prn_idx);
IDOT = gps_data.IDOT(prn_idx);%轨道倾角变化率
omega = gps_data.omega(prn_idx);

% 常量定义
max_dt = 7200;              % 星历有效期阈值 (±2小时)
GM = 3.986005e14;      % WGS-84地球引力常数 (m³/s²)
omge = 7.2921151467e-5; % 地球自转角速度 (rad/s)

% ========== 计算轨道参数 ==========
% 1. 归化时间计算
%也可以由两个周内时进行计算（需要进行下边的时间调整，如果只根据两历元相减，则不存在偏差）
tk = t - toe_sec;
% 时间调整（保证tk在±302400秒内）三天半时间
if tk > 302400
    tk = tk - 604800;
elseif tk < -302400
    tk = tk + 604800;
end%确保后续轨道参数计算在合理的半周范围内进行，从而避免因时间溢出导致的数值错误

% 2. 轨道长半径
a = sqrt_a^2;

% 3. 平均角速度
n0 = sqrt(GM / a^3);%平均角速度
n = n0 + delta_n;%改正平角速度

% 4. 平近点角
Mk = M0 + n * tk;
Mk = mod(Mk, 2*pi); % 保持在0-2π范围内

% 5. 迭代计算偏近点角Ek
Ek = Mk; % 初始值
delta_E = 1;
iter = 0;
max_iter = 100;
while abs(delta_E) > 1e-12 && iter < max_iter
    E_prev = Ek;
    Ek = Mk + e * sin(E_prev);
    delta_E = Ek - E_prev;
    iter = iter + 1;
end

% 6. 真近点角vk
cosNu_k = (cos(Ek) - e) / (1 - e*cos(Ek));
sinNu_k = (sqrt(1 - e^2)*sin(Ek)) / (1 - e*cos(Ek));
vk = atan2(sinNu_k, cosNu_k); % 直接使用atan2处理象限

% 7. 升交距角fk
fk = vk + omega;%信号发射时刻的升交点角距

% 8. 摄动改正项（周期改正项）
delta_uk = Cuc*cos(2*fk) + Cus*sin(2*fk);
delta_rk = Crc*cos(2*fk) + Crs*sin(2*fk);
delta_ik = Cic*cos(2*fk) + Cis*sin(2*fk);

% 9. 摄动后参数
uk = fk + delta_uk;%计算改正后的向径
rk = a*(1 - e*cos(Ek)) + delta_rk;%改正后的向径
ik = i0 + delta_ik + IDOT*tk;%改正后的倾角

% 10. 轨道平面坐标
x_orb = rk * cos(uk);
y_orb = rk * sin(uk);

% 11. 升交点经度
lambda = OMG0 + (OMG0_DOT-omge)*tk - omge*toe_sec;

% 12. 地心地固坐标系（ECEF）坐标
x_ecef = (x_orb*cos(lambda) - y_orb*cos(ik)*sin(lambda)) ; 
y_ecef = (x_orb*sin(lambda) + y_orb*cos(ik)*cos(lambda)) ;
z_ecef = (y_orb*sin(ik)) ;
position=[x_ecef,y_ecef,z_ecef];
end