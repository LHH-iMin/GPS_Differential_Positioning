function gps_data = read_rinex_nav(filename)
%GPS导航电文的详细数据参看rinex304的附录A6
% 初始化结构体存储数据
gps_data = struct(...
    'PRN', string([]), ...
    'Toe', datetime(zeros(0, 6)), ...%%这个报错半天
    'ClockBias', [], ...
    'ClockDrift', [], ...
    'ClockDriftRate', [], ...
    'IODE', [], ...
    'Crs', [], ...
    'DeltaN', [], ...
    'M0', [], ...
    'Cuc', [], ...
    'e', [], ...
    'Cus', [], ...
    'sqrtA', [], ...
    'Toe_sec', [], ...
    'Cic', [], ...
    'OMEGA0', [], ...
    'Cis', [], ...
    'i0', [], ...
    'Crc', [], ...
    'omega', [], ...
    'OMEGA_DOT', [], ...
    'IDOT', []);%轨道倾角变化率
    % 'GPS_Week', [], ...
    % 'SV_Accuracy', [], ...
    % 'SV_Health', [], ...
    % 'TGD', [], ...
    % 'IODC', [], ...
    % 'TransmissionTime', [],...%格式是周内时/s,最大为604800
    % 'FitInterval', []);  

% 读取文件内容
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件: %s', filename);
end

% 跳过文件头
while ~feof(fid)
    line = fgetl(fid);
    if contains(line, 'END OF HEADER'), break; end
end

% 解析数据块
while ~feof(fid)
    % 读取SV/EPOCH/SV/CLK行
    line = fgetl(fid);
    if isempty(line)
        continue; 
    % elseif (startsWith(line, 'G') ||startsWith(line, 'C') ||startsWith(line, 'E') )
    elseif (startsWith(line, 'G'))
        % 解析卫星号和时钟参数
        header = textscan(line, '%3c %4d %2d %2d %2d %2d %2d %19.12f%19.12f%19.12f', 1);
        [gps_data.PRN(end+1), year, month, day, hour, minute, sec] = deal(header{1:7});
        
        % 构建Toe时间戳
        gps_data.Toe(end+1) = datetime(year, month, day, hour, minute, sec);
        % 钟差参数
        gps_data.ClockBias(end+1) = header{8};
        gps_data.ClockDrift(end+1) = header{9};
        gps_data.ClockDriftRate(end+1) = header{10};
        
        % 读取广播轨道参数（7行）
        orbit = cell(1, 7);
        for i = 1:7
            line = fgetl(fid);
            line = regexprep(line, '[Dd]', 'E');  % 统一指数符号
            orbit{i} = sscanf(line(5:end), '%19f', 4);  % 跳过前4字符
        end
        
        % 解析轨道参数
        gps_data.IODE(end+1)        = orbit{1}(1);
        gps_data.Crs(end+1)         = orbit{1}(2);
        gps_data.DeltaN(end+1)      = orbit{1}(3);
        gps_data.M0(end+1)          = orbit{1}(4);
        
        gps_data.Cuc(end+1)         = orbit{2}(1);
        gps_data.e(end+1)           = orbit{2}(2);
        gps_data.Cus(end+1)         = orbit{2}(3);
        gps_data.sqrtA(end+1)       = orbit{2}(4);
        
        gps_data.Toe_sec(end+1)     = orbit{3}(1);
        gps_data.Cic(end+1)         = orbit{3}(2);
        gps_data.OMEGA0(end+1)      = orbit{3}(3);
        gps_data.Cis(end+1)         = orbit{3}(4);
        
        gps_data.i0(end+1)          = orbit{4}(1);
        gps_data.Crc(end+1)         = orbit{4}(2);
        gps_data.omega(end+1)       = orbit{4}(3);
        gps_data.OMEGA_DOT(end+1)   = orbit{4}(4);
        
        gps_data.IDOT(end+1)        = orbit{5}(1);
        %% 以下数据对于计算卫星位置没用用处
        % gps_data.GPS_Week(end+1)    = orbit{5}(3);  % 第3列为GPS周
        % 
        % gps_data.SV_Accuracy(end+1) = orbit{6}(1);
        % gps_data.SV_Health(end+1)   = orbit{6}(2);
        % gps_data.TGD(end+1)         = orbit{6}(3);
        % gps_data.IODC(end+1)        = orbit{6}(4);
        % 
        % gps_data.TransmissionTime(end+1) = orbit{7}(1);
        % gps_data.FitInterval(end+1)      = orbit{7}(2);  % 新增FitInterval
        % 
        % % 处理传输时间调整
        % if abs(gps_data.TransmissionTime(end)) > 604800
        %     gps_data.TransmissionTime(end) = mod(gps_data.TransmissionTime(end), 604800);
        % end
    end
end

fclose(fid);
end