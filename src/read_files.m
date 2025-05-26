obsfile=[".\data\基准站\3312861153C.22O"
    ".\data\流动站\3312860153C.22O"];
navfile=[".\data\基准站\3312861153C.22N"
    ".\data\流动站\3312860153C.22N"];

nav_data_base = read_rinex_nav(navfile(1));%读取导航电文数据
nav_data_rover = read_rinex_nav(navfile(2));


obs_data_base = read_rinex_obs(obsfile(1));%读取观测数据
obs_data_rover = read_rinex_obs(obsfile(2));