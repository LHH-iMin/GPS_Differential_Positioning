%%2025年5月13日 李厚华
%%GNSS观测与实践-差分单点定位
clc;clear all;close all;
addpath(".\src");
% read_files();%读取数据
load("data.mat");%读取原有保存的数据
%O文件中的准确位置
pos_base=[-2156267.5946  4373762.4864  4097439.3811];%W84坐标系
pos_rover=[-2156281.1198  4373769.5317  4097424.6984];
wavelength=299792458/1575.42e6;%波长，暂时只用L1波段的观测值
%截取公共时间区间的观测数据
[obs_common_base, obs_common_rover] = find_common_time_interval(obs_data_base, obs_data_rover);
clear obs_data_base obs_data_rover;
num_epoch=length(obs_common_rover.epoch_time)-1;
% num_epoch=100;
start_epoch=1;
end_epoch=start_epoch+num_epoch;
min_sat=8;
%保存每一历元的公共伪距与相位观测值,以及公共卫星的位置,编号
common_sats={};
time_epoch=datetime(zeros(0, 6));
%%
%保存单差双差三差解算位置
ecef_rover_pos_sf=[];
blh_rover_pos_sf=[];
ecef_rover_pos_df=[];
blh_rover_pos_df=[];
ecef_rover_pos_tf=[];
blh_rover_pos_tf=[];
%保存模糊度解算
fixed_ambs_sf={};
fixed_ambs_df={};
%%
epoch=start_epoch;
val_epoch=1;
while(epoch<end_epoch)
        %寻找公共卫星及其下标
        [common_sat, idx1, idx2] = intersect(obs_common_base.prn{epoch}, obs_common_rover.prn{epoch});
        %提取当前历元的公共卫星的伪距与载波相位观测值
        base_pseudo = obs_common_base.pseudorange{epoch}(idx1);
        rover_pseudo = obs_common_rover.pseudorange{epoch}(idx2);
        base_phase = obs_common_base.carrierphase{epoch}(idx1);
        rover_phase = obs_common_rover.carrierphase{epoch}(idx2);
        % 执行质量检查
        [bad_sats] = check_observation_quality(...
            base_pseudo, rover_pseudo, base_phase, rover_phase);
        % 剔除异常数据
        good_sats = setdiff(1:length(idx1), bad_sats);
        if(length(good_sats)<min_sat)%如果没有公共观测卫星或者公共卫星数少于4，则跳过当前历元
            epoch=epoch+1;
            fprintf("历元%d的卫星数目少于%d,其中异常卫星为%s\n",epoch,min_sat,mat2str(idx1(bad_sats)));
            continue;
        end
        curr_base_pseudo = base_pseudo(good_sats )';
        curr_rover_pseudo = rover_pseudo(good_sats )';
        curr_base_phase = base_phase(good_sats )';
        curr_rover_phase = rover_phase(good_sats)';
        curr_common_sat=common_sat(good_sats)';

        %根据伪距和观测时刻,卫星编号，计算信号发射时刻的卫星位置
        obs_time=obs_common_base.epoch_time(epoch);%当前历元的时间
        curr_sat_pos = calculate_sats_position(curr_common_sat, nav_data_base, curr_base_pseudo, obs_time);
        %%单双差位置解算
        %%单差定位--------------------------------------------------------------------------------------------------------
        [fixed_amb_sf, rover_pos_sf] = single_diff_carrier_phase_positioning(curr_base_pseudo, curr_rover_pseudo, ...
            curr_base_phase, curr_rover_phase, pos_base, curr_sat_pos, wavelength);
        fixed_ambs_sf{val_epoch}=fixed_amb_sf;
        ecef_rover_pos_sf(val_epoch,:)=rover_pos_sf;
        blh_rover_pos_sf(val_epoch,:)=convert_ecef_to_blh(rover_pos_sf);
        %%双差定位--------------------------------------------------------------------------------------------------------
        [fixed_amb_df, rover_pos_df] = double_diff_carrier_phase_positioning(curr_base_pseudo, curr_rover_pseudo, ...
            curr_base_phase, curr_rover_phase, pos_base, curr_sat_pos, wavelength);
        fixed_ambs_df{val_epoch}=fixed_amb_df;
        ecef_rover_pos_df(val_epoch,:)=rover_pos_df;
        blh_rover_pos_df(val_epoch,:)=convert_ecef_to_blh(rover_pos_df);
        %%三差定位--------------------------------------------------------------------------------------------------------
        if(val_epoch==1)%第一个历元使用双差定位
            [~, rover_pos_tf] = double_diff_carrier_phase_positioning(curr_base_pseudo, curr_rover_pseudo, ...
            curr_base_phase, curr_rover_phase, pos_base, curr_sat_pos, wavelength);
        else
            rover_pos_tf= triple_diff_positioning(prev_rover_pos,...
        curr_base_pseudo, curr_rover_pseudo, curr_base_phase, curr_rover_phase,curr_common_sat,curr_sat_pos, ...
        prev_base_pseudo, prev_rover_pseudo, prev_base_phase, prev_rover_phase,prev_common_sat,prev_sat_pos,...
        pos_base, wavelength);
        end
        ecef_rover_pos_tf(val_epoch,:)=rover_pos_tf;
        blh_rover_pos_tf(val_epoch,:)=convert_ecef_to_blh(rover_pos_tf);
        
        prev_rover_pos=rover_pos_tf;

        prev_base_pseudo=curr_base_pseudo;
        prev_rover_pseudo=curr_rover_pseudo;
        prev_base_phase=curr_base_phase;
        prev_rover_phase=curr_rover_phase;
        prev_sat_pos= curr_sat_pos;
        prev_common_sat=curr_common_sat;

        if(mod(epoch,100)==0)
            fprintf("已读取第%d历元数据\n",epoch);
        end 
        time_epoch(end+1)=obs_time;
        common_sats{end+1}=curr_common_sat;
        epoch=epoch+1;
        val_epoch=val_epoch+1;
end
clear  common_sat epoch idx1 idx2 obs_time 
clear  base_pseudo rover_pseudo base_phase rover_phase good_sats bad_sats
clear  curr_base_pseudo curr_rover_pseudo curr_base_phase curr_rover_phase curr_common_sat curr_sat_pos
clear  prev_base_pseudo prev_rover_pseudo prev_base_phase prev_rover_phase prev_common_sat prev_sat_pos
%行向量转置为列向量，方便查看
time_epoch=time_epoch';
common_sats=common_sats';
%%准确位置
rover_pos_blh=convert_ecef_to_blh(pos_rover);
base_pos_blh=convert_ecef_to_blh(pos_base);
%与基准站距离
dis_base_rover_sf=vecnorm(ecef_rover_pos_sf-pos_base,2,2);
dis_base_rover_df=vecnorm(ecef_rover_pos_df-pos_base,2,2);
dis_base_rover_tf=vecnorm(ecef_rover_pos_tf-pos_base,2,2);

plot_positioning_results_1();%显示经纬度
plot_positioning_results_2();%显示与基准站之间的距离


%保存数据
pos_filename='GNSS_Differential_Position.xlsx';
amb_filename='GNSS_Differential_Ambiguity.xlsx';
sats=["G01"	"G03"	"G07"	"G08"	"G14"	"G17"	"G19"	"G21"	"G28"	"G30"];
save_positioning_results(pos_filename, time_epoch, ...
    dis_base_rover_sf, ecef_rover_pos_sf,blh_rover_pos_sf, ...
    dis_base_rover_df, ecef_rover_pos_df,blh_rover_pos_df,...
    dis_base_rover_tf, ecef_rover_pos_tf,blh_rover_pos_tf);
save_ambiguity_results(amb_filename, sats, time_epoch, common_sats, fixed_ambs_sf, fixed_ambs_df);
