function sat_pos = calculate_sats_position(common_sat, nav_data_base, base_pseudo, obs_time)
    c = 299792458;              % 光速 (m/s)
    obs_time_toc=gps_week_seconds(obs_time);
    i=1;
    sat_pos=[];
    while(i<=length(common_sat)) 
        sat_idx=find_sat_idx(nav_data_base.PRN,nav_data_base.Toe,common_sat(i),obs_time);%找到卫星下标
        emission_time=obs_time_toc-base_pseudo(i)/c;%计算信号发射时刻
        clock_corr = calculate_sv_clock_corr(nav_data_base, sat_idx, emission_time);%计算钟差矫正
        emission_time= emission_time-clock_corr;
        dt=abs(emission_time-obs_time_toc);
        if (dt>7200),i=i+1;continue;end%%判断该星历数据是否有效
        sat= calculate_sat_position(nav_data_base,sat_idx,emission_time);%计算卫星位置
        sat_pos=[sat_pos;sat]; 
        i=i+1;
    end

end