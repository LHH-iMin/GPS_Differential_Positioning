function save_positioning_results(filename, time_epoch, ...
    dis_base_rover_sf, ecef_rover_pos_sf, blh_rover_pos_sf, ...
    dis_base_rover_df, ecef_rover_pos_df, blh_rover_pos_df, ...
    dis_base_rover_tf, ecef_rover_pos_tf, blh_rover_pos_tf)

% 检查时间格式并转换为字符串
if ~isempty(time_epoch) && isdatetime(time_epoch)
    time_epoch.Format = 'yyyy-MM-dd HH:mm:ss'; 
    time_str = cellstr(time_epoch);
else
    error('时间数据格式错误');
end

% 删除已存在的文件
if exist(filename, 'file')
    delete(filename);
end

% 定义工作表名称
sheet_names = {'SingleDiff', 'DoubleDiff', 'TripleDiff', 'Ambiguities'};

% 处理每个差分类型的数据
% 单差
if ~isempty(dis_base_rover_sf)
    prepare_and_write_sheet(sheet_names{1}, time_str, dis_base_rover_sf, ecef_rover_pos_sf, blh_rover_pos_sf, filename);
end

% 双差
if ~isempty(dis_base_rover_df)
    prepare_and_write_sheet(sheet_names{2}, time_str, dis_base_rover_df, ecef_rover_pos_df, blh_rover_pos_df, filename);
end

% 三差
if ~isempty(dis_base_rover_tf)
    prepare_and_write_sheet(sheet_names{3}, time_str, dis_base_rover_tf, ecef_rover_pos_tf, blh_rover_pos_tf, filename);
end

% 处理合并单元格
% merge_excel_cells(filename, sheet_names{1});
% merge_excel_cells(filename, sheet_names{2});
% merge_excel_cells(filename, sheet_names{3});

disp(['定位数据已成功保存至: ' filename]);
end

function prepare_and_write_sheet(sheet_name, time_str, dis_base_rover, ecef_pos, blh_pos, filename)
% 构造表头
header = {
    '历元时间', '相对距离/m', '', 'ECEF坐标', '', '', 'BLH坐标', '';
    '',          '',          'X',       'Y', 'Z', 'B',      'L', 'H'
};

% 转换为单元格数组
data_cell = [time_str, num2cell(dis_base_rover), num2cell(ecef_pos), num2cell(blh_pos)];

% 合并表头和数据
full_data = [header; data_cell];

% 写入Excel
writecell(full_data, filename, 'Sheet', sheet_name, 'WriteMode', 'overwritesheet');
end

function merge_excel_cells(filename, sheet_name)
try
    % 使用COM接口操作Excel
    excel = actxserver('Excel.Application');
    excel.Visible = false;
    workbook = excel.Workbooks.Open(filename);
    sheet = workbook.Sheets.Item(sheet_name);
    
    % 合并单元格
    sheet.Range('A1:A2').Merge;
    sheet.Range('B1:B2').Merge;
    sheet.Range('C1:E1').Merge;
    sheet.Range('F1:H1').Merge;
    
    % 保存并关闭
    workbook.Save;
    workbook.Close;
    excel.Quit;
    delete(excel);
catch ME
    disp(['合并单元格时出错：' ME.message]);
    if exist('workbook', 'var')
        workbook.Close(false);
    end
    if exist('excel', 'var')
        excel.Quit;
        delete(excel);
    end
end
end