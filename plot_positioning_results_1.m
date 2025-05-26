% 输入数据示例（需要替换为实际数据）
% base_pos_blh = [经度, 纬度, 高程];  % 基准站数据（1×3）
% rover_pos_sf = [经度1 纬度1 高程1;   % 流动站数据（n×3）
%                    经度2 纬度2 高程2;
%                    ...              ];

% 提取经纬度数据
base_lat = base_pos_blh(1);       % 基准站纬度
base_lon = base_pos_blh(2);       % 基准站经度
rover_lat_sf = blh_rover_pos_sf(:,1); % 单差流动站纬度数组
rover_lon_sf = blh_rover_pos_sf(:,2); % 单差流动站经度数组
rover_lat_df = blh_rover_pos_df(:,1); % 双差流动站纬度数组
rover_lon_df = blh_rover_pos_df(:,2); % 双差流动站经度数组
rover_lat_tf = blh_rover_pos_tf(:,1); % 双差流动站纬度数组
rover_lon_tf = blh_rover_pos_tf(:,2); % 双差流动站经度数组

% 创建画布
figure('Position', [100, 100, 800, 500]);
hold on;                             % 保持绘图状态

% 绘制单差流动站分布
plot( rover_lon_sf,rover_lat_sf,'bo',...  % 绿色圆圈表示流动站
    'MarkerSize', 3,...              % 点大小
    'MarkerFaceColor', [0 0 1],... % 填充颜色
    'DisplayName', '单差流动站');hold on;

% 绘制双差流动站分布
plot(rover_lon_df, rover_lat_df,'go',...  % 蓝色圆圈表示流动站
    'MarkerSize', 3,...              % 点大小
    'MarkerFaceColor', [0 1 0],... % 填充颜色
    'DisplayName', '双差流动站');hold on;

% 绘制三差流动站分布
plot(rover_lon_tf, rover_lat_tf,'ro',...  % 红色圆圈表示流动站
    'MarkerSize', 3,...              % 点大小
    'MarkerFaceColor', [1 0 0],... % 填充颜色
    'DisplayName', '三差流动站');hold on;

% 绘制基准站位置
plot(base_lon, base_lat,'rp',...    % 红色五角星表示基准站
    'MarkerSize', 12,...             % 标记大小
    'MarkerFaceColor', 'r',...      % 填充颜色
    'DisplayName', '基准站');hold on;

% 图形美化
xlabel('经度 (°)', 'FontSize', 12)  % x轴标签
ylabel('纬度 (°)', 'FontSize', 12) % y轴标签
title('基准站与流动站位置分布', 'FontSize', 14)
legend('show', 'Location', 'best')     % 显示图例
grid on                                % 显示网格
axis equal                            % 等比例坐标轴
box on                                % 显示边框

% 自动调整坐标范围（保留5%边界）
margin=0.1;
rover_lon=[rover_lon_sf;rover_lon_df;rover_lon_tf;base_lon];
rover_lat=[rover_lat_sf;rover_lat_df;rover_lat_tf;base_lat];
lon_range = range(rover_lon);
lat_range = range(rover_lat);
xlim([min(rover_lon)-margin*lon_range,max(rover_lon)+margin*lon_range])
ylim([min(rover_lat)-margin*lat_range,max(rover_lat)+margin*lat_range])

% 可选：添加数据统计信息
text(0.02, 0.02,...
    sprintf('流动站数量: %d\n经度范围: %.4f°~%.4f°\n纬度范围: %.4f°~%.4f°',...
    length(rover_lon_sf),...
    min(rover_lon_sf), max(rover_lon_sf),...
    min(rover_lat_sf), max(rover_lat_sf)),...
    'Units', 'normalized',...
    'FontSize', 9,...
    'VerticalAlignment', 'bottom',... % 顶部对齐
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [1 1 1 0.8],... % 半透明白底
    'EdgeColor', [0.5 0.5 0.5],...     % 灰色边框
    'Margin', 2);                     % 内边距     
