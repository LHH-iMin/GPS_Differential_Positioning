function seconds_in_week = gps_week_seconds(dt)
% GPS_WEEK_SECONDS 计算 datetime 对应的 GPS 周内秒
% 输入：dt - datetime 变量
% 输出：seconds_in_week - GPS 周内秒（从周日 00:00:00 开始的秒数）

    % GPS 起始时间（1980年1月6日00:00:00 UTC，星期日）,默认时区为'TimeZone'
    gps_epoch = datetime(1980, 1, 6, 0, 0, 0);
    
    % 计算从 GPS 起始时间到指定时间的秒数
    seconds_since_gps_epoch = seconds(dt - gps_epoch);
    
    % % 考虑 GPS 时与 UTC 之间的闰秒差（截至2023年7月为18秒）
    % leap_seconds = 18;  % 根据当前日期调整此值
    % seconds_since_gps_epoch = seconds_since_gps_epoch + leap_seconds;
    seconds_since_gps_epoch = seconds_since_gps_epoch;%导航星历中利用的都是UTC时间，所以暂时不考虑闰秒
    % 计算周内秒（即对一周总秒数取模）
    seconds_in_week = mod(seconds_since_gps_epoch, 7 * 24 * 3600);
end