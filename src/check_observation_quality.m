function [bad_sats] = check_observation_quality(...
    base_pseudo, rover_pseudo, base_phase, rover_phase)
% 输入参数：
%   base_pseudo    : 基准站伪距观测值 (cell array, 每个元素为一颗卫星的观测值)
%   rover_pseudo   : 流动站伪距观测值 (cell array)
%   base_phase     : 基准站载波相位观测值 (cell array)
%   rover_phase    : 流动站载波相位观测值 (cell array)
% 输出参数：
%   bad_sats_base  : 基准站异常卫星索引
%   bad_sats_rover : 流动站异常卫星索引

% 物理量检查阈值
MIN_PSEUDO = 1.9e7;  % 最小合理伪距值 (20,000 km)
MAX_PSEUDO = 3e7;  % 最大合理伪距值 (30,000 km)
PHASE_JUMP_TH = 1e3; % 相位跳变阈值 (周)

% 初始化异常卫星列表
bad_sats_base = [];
bad_sats_rover = [];

%% 基准站异常检测
for s = 1:length(base_pseudo)
    % 获取当前卫星观测值
    pseudo = base_pseudo(s);
    phase = base_phase(s);
    
    % 零值/NaN检测
    is_zero = (pseudo == 0) | (phase == 0);
    is_nan = isnan(pseudo) | isnan(phase);
    
    % 物理量级检测
    invalid_pseudo = (pseudo < MIN_PSEUDO) | (pseudo > MAX_PSEUDO);
    
    % 相位跳变检测
    if length(phase) > 1
        phase_diff = abs(diff(phase));
        has_jump = any(phase_diff > PHASE_JUMP_TH);
    else
        has_jump = false;
    end
    
    % 标记异常卫星
    if any(is_zero | is_nan | invalid_pseudo) || has_jump
        bad_sats_base = [bad_sats_base, s];
    end
end

%% 流动站异常检测
for s = 1:length(rover_pseudo)
    pseudo = rover_pseudo(s);
    phase = rover_phase(s);
    
    is_zero = (pseudo == 0) | (phase == 0);
    is_nan = isnan(pseudo) | isnan(phase);
    invalid_pseudo = (pseudo < MIN_PSEUDO) | (pseudo > MAX_PSEUDO);
    
    if length(phase) > 1
        phase_diff = abs(diff(phase));
        has_jump = any(phase_diff > PHASE_JUMP_TH);
    else
        has_jump = false;
    end
    
    if any(is_zero | is_nan | invalid_pseudo) || has_jump
        bad_sats_rover = [bad_sats_rover, s];
    end
end

%% 交叉验证（基准站与流动站公共卫星）
common_sats = intersect(bad_sats_base, bad_sats_rover);
if ~isempty(common_sats)
    fprintf('发现共同异常卫星: %s\n', mat2str(common_sats));
end
bad_sats=[bad_sats_base bad_sats_rover];
end