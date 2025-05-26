function obs_data = read_rinex_obs(filename)
% READ_RINEX_OBS 读取RINEX 3.04观测文件中的GPS伪距信息
% 输入参数：
%   filename : RINEX观测文件名（例如 'SMAR00CHN_R_20251090603.25o'）
% 输出参数：
%   obs_data : 包含伪距信息的结构体，字段包括：
%              - epoch_time : 历元时间（datetime数组）
%              - num        : 数组，每个元素为每个历元的观测到的卫星数
%              - prn        : cell数组，每个元素为字符串数组（卫星PRN号）
%              - pseudorange: cell数组，每个元素为数值数组（伪距观测值，单位：米）

% 初始化结构体（按历元存储）
obs_data = struct(...
    'epoch_time', datetime(zeros(0, 6)), ...%%这个报错半天
    'num',[] ,...%每个历元卫星的数目
    'prn', {[]}, ...           % cell数组，每个元素为字符串数组
    'freq', {[]}, ...           % 频段
    'pseudorange', {[]},...% 伪距
    'carrierphase',{[]});   %载波相位% cell数组，每个元素为数值数组
% 打开文件
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件: %s', filename);
end

% 跳过文件头并解析观测类型
obs_types = [];
while ~feof(fid)
    line = fgetl(fid);
    if contains(line, 'END OF HEADER')
        break;
    end
end

% 初始化临时变量
current_epoch = [];
current_prn =  string([]);
current_freq =  string([]);
current_pseudorange = [];
current_carrierphase=[];

% 读取数据块
while ~feof(fid)
    line = fgetl(fid);
    if isempty(line), continue; end
    
    % 解析历元时间行（以'>'开头）
    if startsWith(line, '>')
        % 保存前一个历元的数据
        if ~isempty(current_epoch)
            obs_data.epoch_time(end+1) = current_epoch;
            obs_data.num(end+1)=sat_counter;
            obs_data.prn{end+1} = current_prn;
            obs_data.pseudorange{end+1} = current_pseudorange;
            obs_data.carrierphase{end+1} = current_carrierphase;
            %初始化数据用来存下一个历元的数据
            current_epoch = [];
            current_prn = string([]);
            current_freq =  string([]);
            current_pseudorange = [];
            current_carrierphase=[];
        end
        
        % 初始化新历元
        parts = strsplit(line);
        year = str2double(parts{2});
        month = str2double(parts{3});
        day = str2double(parts{4});
        hour = str2double(parts{5});
        minute = str2double(parts{6});
        second = str2double(parts{7});
        current_epoch = datetime(year, month, day, hour, minute, second);
        num_sat = str2double(parts{9});  % 当前历元的卫星数量
        sat_counter = 0;  % 当前历元卫星计数器
        continue;
    end
    
    % 解析卫星观测数据行（处理GPS,北斗，Galileo卫星）
    % if (startsWith(line, 'G') ||startsWith(line, 'C') ||startsWith(line, 'E') )&& ~isempty(current_epoch)
    if (startsWith(line, 'G'))&& ~isempty(current_epoch)
        prn = line(1:3); % 卫星PRN（例如G03）
        values = strsplit(line(4:end));
        values = values(~cellfun(@isempty, values));  % 移除空单元格
        % 提取伪距并存储到临时变量
        num=length(values)/4;
        num=1;%只读第一个伪距和载波相位观测值
        for i=1:1
            if(str2double(values{4*(i-1)+1})~=0)
            current_prn(end+1) = prn;%保存卫星编号
            current_pseudorange(end+1) = str2double(values{4*(i-1)+1});%保存伪距
            current_carrierphase(end+1)=str2double(values{4*(i-1)+2});%保存载波相位
            sat_counter = sat_counter + 1;%卫星数据+1
            end
        end
    end
end

% 保存最后一个历元的数据
if ~isempty(current_epoch)
    obs_data.epoch_time(end+1) = current_epoch;
    obs_data.num(end+1)=sat_counter;
    obs_data.prn{end+1} = current_prn(1:sat_counter);        % 去除预分配多余部分
    obs_data.pseudorange{end+1} = current_pseudorange(1:sat_counter);
    obs_data.carrierphase{end+1} = current_carrierphase(1:sat_counter);
end
obs_data.epoch_time=obs_data.epoch_time';
obs_data.num=obs_data.num';
obs_data.prn=obs_data.prn';
obs_data.pseudorange=obs_data.pseudorange';
obs_data.carrierphase=obs_data.carrierphase';
fclose(fid);
end