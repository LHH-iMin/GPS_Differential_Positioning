%%%%%%%%%%%%%%%% LAMBDA 核心函数 %%%%%%%%%%%%%%%%
function [amb_fixed, success, ratio] = LAMBDA(amb_float, Q_amb, varargin)
    % 参数解析
    p = inputParser;
    addParameter(p, 'ratio', 2.0, @isnumeric); 
    parse(p, varargin{:});
    ratio_thres = p.Results.ratio;
    
    % --- Step 1: 降相关（改进Z矩阵构造） ---
    [Z_trans, Q_z, z_float] = decorrelate(amb_float, Q_amb);
    
    % --- Step 2: 高效格网搜索（改进剪枝策略） ---
    [candidates, residuals] = ILS_search(z_float, Q_z); % 返回排序后的候选解
    
    % --- Step 3: 反变换并验证（修正Ratio检验） ---
    if isempty(candidates)
        amb_fixed = amb_float;
        success = false;
        ratio = 0;
        return;
    end
    
    % 最优解与次优解
    best_z = candidates(:,1);
    best_amb = Z_trans \ best_z;  % 等价于 inv(Z_trans)*best_z
    best_amb = round(best_amb);   % 确保整数
    
    if size(candidates,2) >= 2
        second_best_z = candidates(:,2);
        residual_best = residuals(1);
        residual_second = residuals(2);
        ratio = residual_second / residual_best;
    else
        ratio = Inf;  % 仅一个候选解时强制接受
    end
    
    % Ratio检验
    success = (ratio > ratio_thres);
    amb_fixed = best_amb;
end

%--------------------------------------------------------------------
function [Z, Q_z, z_float] = decorrelate(amb_float, Q_amb)
    % 改进的降相关函数（包含LDL分解、整数高斯变换和排序）
    n = size(Q_amb,1);
    Z = eye(n);
    P = 1:n;  % 初始排列索引
    
    % LDL分解并排序对角线元素（降序）
    [L, D, p] = ldl(Q_amb, 'vector');
    [~, idx] = sort(diag(D(p,p)), 'descend');
    P = p(idx);  % 更新排列
    
    % 更新L和D矩阵
    L = L(P, P);
    D = diag(diag(D(P, P)));
    
    % 整数高斯变换（从下到上处理非对角元素）
    for k = n:-1:2
        for j = k-1:-1:1
            mu = round(L(k,j));
            if mu ~= 0
                % 更新L矩阵
                L(:,j) = L(:,j) - mu * L(:,k);
                % 更新Z矩阵
                Z(:,j) = Z(:,j) - mu * Z(:,k);
            end
        end
    end
    
    % 最终变换矩阵与协方差矩阵
    Z = Z(:,P);  % 应用排列
    Q_z = Z' * Q_amb * Z;
    z_float = Z' * amb_float(P); % 注意排列后的amb_float
end

%--------------------------------------------------------------------
function [candidates, residuals] = ILS_search(z_float, Q_z)
    % 修正后的整数最小二乘搜索（解决初始半径Inf问题）
    n = length(z_float);
    L = chol(Q_z, 'lower');      % Cholesky分解加速残差计算
    inv_L = inv(L);
    
    % 初始化候选解与最优残差
    candidates = [];
    residuals = [];
    current_z = zeros(n, 1);
    
    % 初始最优残差：浮点解取整的残差（避免初始Inf）
    initial_z = round(z_float);
    best_residual = norm(inv_L * (z_float - initial_z))^2;
    
    % 定义递归函数（闭包共享变量）
    function search_layer(layer)
        if layer > n
            % 计算完整残差
            residual = norm(inv_L * (z_float - current_z))^2;
            
            % 更新最优残差并保存候选解
            if residual < best_residual
                best_residual = residual;
            end
            if residual <= best_residual
                candidates = [candidates, current_z];
                residuals = [residuals, residual];
                % 保留最优的100个解
                [residuals, idx] = sort(residuals);
                candidates = candidates(:, idx);
                if length(residuals) > 100
                    candidates = candidates(:, 1:100);
                    residuals = residuals(1:100);
                end
            end
            return;
        end
        
        % 动态计算搜索半径（处理初始best_residual）
        if isinf(best_residual)
            % 初始半径基于当前层方差
            radius_factor = 5;  % 可调参数
            radius = radius_factor * sqrt(Q_z(layer, layer));
        else
            radius = sqrt(best_residual) * norm(inv_L(layer:end, layer));
        end
        
        % 生成候选值范围
        center = z_float(layer);
        lower = ceil(center - radius);
        upper = floor(center + radius);
        z_candidates = lower:upper;
        
        % 按距离中心远近排序
        [~, order] = sort(abs(z_candidates - center));
        
        % 遍历候选值并递归
        for k = order
            z = z_candidates(k);
            current_z(layer) = z;
            
            % 计算部分残差（提前剪枝）
            partial_residual = norm(inv_L(1:layer, 1:layer) * (z_float(1:layer) - current_z(1:layer)))^2;
            if partial_residual > best_residual
                continue;
            end
            
            search_layer(layer + 1);  % 递归下一层
        end
    end
    
    % 启动递归搜索
    search_layer(1);
    
    % 若无候选解，返回浮点解取整值
    if isempty(candidates)
        candidates = initial_z;
        residuals = best_residual;
    end
end