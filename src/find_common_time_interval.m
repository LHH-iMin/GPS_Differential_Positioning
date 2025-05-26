function [common_base, common_rover] = find_common_time_interval(obs_data_base, obs_data_rover)
% 找出两个GPS观测数据结构体的公共时间区间并截取相应数据
% 输入:
%   obs_data_base - 基准站观测数据结构体，包含epoch_time字段(datetime类型)
%   obs_data_rover - 流动站观测数据结构体，包含epoch_time字段(datetime类型)
% 输出:
%   common_base - 基准站在公共时间区间内的数据
%   common_rover - 流动站在公共时间区间内的数据

    % 检查输入结构体是否包含epoch_time字段
    if ~isfield(obs_data_base, 'epoch_time') || ~isfield(obs_data_rover, 'epoch_time')
        error('输入结构体必须包含epoch_time字段');
    end
    
    % 确保epoch_time是datetime类型
    if ~isa(obs_data_base.epoch_time, 'datetime') || ~isa(obs_data_rover.epoch_time, 'datetime')
        error('epoch_time字段必须是datetime类型');
    end
    
    % 获取时间向量
    t_base = obs_data_base.epoch_time;
    t_rover = obs_data_rover.epoch_time;
    
    % 确定公共时间区间
    start_time = max(min(t_base), min(t_rover));
    end_time = min(max(t_base), max(t_rover));
    
    % 检查是否存在公共时间
    if start_time >= end_time
        warning('两个数据集没有公共时间区间');
        common_base = struct();
        common_rover = struct();
        return;
    end
    
    % 找出基准站数据在公共区间内的索引
    base_idx = (t_base >= start_time) & (t_base <= end_time);
    
    % 找出流动站数据在公共区间内的索引
    rover_idx = (t_rover >= start_time) & (t_rover <= end_time);
    
    % 截取公共时间区间内的数据
    common_base = struct();
    common_rover = struct();
    
    % 复制基准站数据
    fields = fieldnames(obs_data_base);
    for i = 1:length(fields)
        field = fields{i};
        if isvector(obs_data_base.(field)) && length(obs_data_base.(field)) == length(t_base)
            % 如果是与时间向量等长的向量，进行截取
            common_base.(field) = obs_data_base.(field)(base_idx);
        else
            % 否则直接复制原始值
            common_base.(field) = obs_data_base.(field);
        end
    end
    
    % 复制流动站数据
    fields = fieldnames(obs_data_rover);
    for i = 1:length(fields)
        field = fields{i};
        if isvector(obs_data_rover.(field)) && length(obs_data_rover.(field)) == length(t_rover)
            % 如果是与时间向量等长的向量，进行截取
            common_rover.(field) = obs_data_rover.(field)(rover_idx);
        else
            % 否则直接复制原始值
            common_rover.(field) = obs_data_rover.(field);
        end
    end
    
    % 输出公共时间区间信息
    fprintf('找到公共时间区间:\n');
    fprintf('起始时间: %s\n', datetime(start_time, 'Format', 'yyyy-MM-dd HH:mm:ss'));
    fprintf('结束时间: %s\n', datetime(end_time, 'Format', 'yyyy-MM-dd HH:mm:ss'));
    fprintf('基准站数据点数: %d\n', sum(base_idx));
    fprintf('流动站数据点数: %d\n', sum(rover_idx));
end    