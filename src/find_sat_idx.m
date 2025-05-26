function sat_idx=find_sat_idx(nav_prns,nav_Toes,obs_prn,obs_time)
    sat_idx=0;
    sat_idxs=find(nav_prns==obs_prn);%寻找既含有观测值又有导航电文数据的GNSS卫星
    if isempty(sat_idxs)
        return;
    elseif isscalar(sat_idxs)%判断sat_idxs是不是一行一列，是则返回1
        sat_idx=sat_idxs;
    else
        %如果广播星历中有多个该卫星的数据
        %寻找广播星历历元时间和观测历元时间最近的那个轨道参数
        best_idx=sat_idxs(1);
        mint=abs(seconds(obs_time-nav_Toes(sat_idxs(1))));
        for i=2:length(sat_idxs)
            dt=abs(seconds(obs_time-nav_Toes(sat_idxs(i))));
            if(dt<mint)
                mint=dt;
                best_idx=sat_idxs(i);
            end
        end
        sat_idx=best_idx;
    end
end