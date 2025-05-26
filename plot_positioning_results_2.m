% 设置中文字体支持
set(0,'DefaultAxesFontName','SimHei');
set(0,'DefaultTextFontName','SimHei');

% 创建图表
figure('Position', [100, 100, 800, 500]);
hold on;                             % 保持绘图状态
% 绘制三种差分定位的距离曲线
plot(dis_base_rover_sf, 'LineWidth', 1.5, 'Color', [0.2, 0.4, 0.8]);      % 单差定位距离 - 蓝色
plot(dis_base_rover_df, 'LineWidth', 1.5, 'Color', [0.8, 0.2, 0.2]);      % 双差定位距离 - 红色
plot(dis_base_rover_tf, 'LineWidth', 1.5, 'Color', [0.2, 0.7, 0.2]);      % 三差定位距离 - 绿色

% 添加水平参考线（如果需要）
yline(7, 'r--', 'LineWidth', 1);
yline(21, 'g--', 'LineWidth', 1);
yline(137, 'b--', 'LineWidth', 1);

% 设置坐标轴属性
grid on;
% 添加图例、标题和坐标轴标签
legend('单差定位距离', '双差定位距离', '三差定位距离',"7米","21米","137米", 'Location', 'best');
title('流动站与基准站之间的相对距离', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('观测历元', 'FontSize', 12);
ylabel('相对距离 (米)', 'FontSize', 12);

% 优化布局
hold off;
box on;
axis tight;