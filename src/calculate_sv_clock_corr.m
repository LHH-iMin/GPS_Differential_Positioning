function clock_corr = calculate_sv_clock_corr(gps_data, prn_idx, t)
%%计算卫星位置和钟差改正
% 输入参数：
% - gps_data: 通过read_rinex_nav读取的导航电文数据结构
% - prn_idx: 卫星在结构体中的索引（例如第1颗卫星为1）
% - t: 当前时间

% 从导航电文中提取钟差改正参数
toe_sec=gps_data.Toe_sec(prn_idx);
sqrt_a = gps_data.sqrtA(prn_idx);
delta_n = gps_data.DeltaN(prn_idx);%平均角速度校正值
M0 = gps_data.M0(prn_idx);
e = gps_data.e(prn_idx);
a0 = gps_data.ClockBias(prn_idx);
a1 = gps_data.ClockDrift(prn_idx);
a2 = gps_data.ClockDriftRate(prn_idx);

% 常量定义
c = 299792458;              % 光速 (m/s)
max_dt = 7200;              % 星历有效期阈值 (±2小时)
GM = 3.986005e14;      % WGS-84地球引力常数 (m³/s²)

tk = t - toe_sec;%也可以由两个周内时进行计算（需要进行下边的时间调整，如果只根据两历元相减，则不存在偏差）
% 检查时间有效性(这一部分在主函数中已经检验)
% if abs(tk) > max_dt
%     fprintf('PRN为%s的星历数据已过期 (Δt=%.0f秒)\n', gps_data.PRN(prn_idx), tk);
% end

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


% 计算基本卫星钟差
sv_clock_bias = a0 + a1*tk + a2*tk^2;

% 相对论效应校正
F = -2*sqrt(GM)/(c^2);                          % 相对论校正因子
rel_corr = F * e * sqrt_a * sin(Ek);            % 校正项

% 总钟差改正量
clock_corr = sv_clock_bias + rel_corr;

end