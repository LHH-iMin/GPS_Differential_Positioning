function save_ambiguity_results(filename, sats, time_epoch, common_sats, fixed_ambs_sf, fixed_ambs_df)
    
    % 时间处理
    if ~isempty(time_epoch) && isdatetime(time_epoch)
        time_epoch.Format = 'yyyy-MM-dd HH:mm:ss'; 
        time_str = cellstr(time_epoch);
    else
        error('时间数据格式错误');
    end
    
    % 初始化单差表格（仅Fixed）
    amb_table_sf = array2table(nan(length(time_epoch), length(sats)),...
                  'VariableNames', sats);
    amb_table_sf.Time = time_str;
    amb_table_sf = movevars(amb_table_sf, 'Time', 'Before', sats{1});
    
    % 初始化双差表格（仅Fixed）
    amb_table_df = amb_table_sf; 
    
    for epoch = 1:length(time_epoch)
        curr_sats = common_sats{epoch};
        
        % 填充单差
        curr_sf = fixed_ambs_sf{epoch};
        for i = 1:length(curr_sats)
            prn = curr_sats{i};
            if ismember(prn, amb_table_sf.Properties.VariableNames)
                amb_table_sf{epoch, prn} = curr_sf(i);
            end
        end
        
        % 填充双差
        curr_df = fixed_ambs_df{epoch};
        for i = 1:length(curr_sats)-1 % 双差数量比卫星数少1
            prn = curr_sats{i+1};    % 从第二个卫星开始
            if ismember(prn, amb_table_df.Properties.VariableNames)
                amb_table_df{epoch, prn} = curr_df(i);
            end
        end
    end
    
    % 写入Excel文件
    writetable(amb_table_sf, filename, 'Sheet', 'SingleDiff', 'WriteMode', 'overwritesheet');
    writetable(amb_table_df, filename, 'Sheet', 'DoubleDiff', 'WriteMode', 'overwritesheet');
    
    disp(['模糊度数据已成功保存至: ' filename]);
end