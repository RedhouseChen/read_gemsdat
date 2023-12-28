% script_save_comb_gmesdat_1day_15hz.m
% input:
% 
% output:
%   file name= SHRL.yyyymmdd.mat
% variable:
%   volt_emchn = [CHN1, CHN2] in V
%   time_Beg = datenum
%   fs = 15
%   dt = 1/fs
%   mat_header = 50xN, N=144-288
%   orig_Property
%   ratio_nan = 0-1
% called func:
%     comb_gemsdat_1day_15hz.m
% e.g.:
%  
% written by ChenHJ on 2018/7/4

clear; clc;
path_Root = 'g:\GEMSdat\';
path_output = 'd:\MyDrive\EarthScienceDatabase\SPrawdata_15Hz_CH1CH2\';
fs = 15;
dt = 1/fs;
tmBeg = datenum([2021, 1, 1]);
tmEnd = datenum([2021, 6, 5]);
tmTag = tmBeg:1:tmEnd;%time tag

staNmCell = get_emStaN2S();
nmbr_Sta = length(staNmCell);
%!====== make directory
for iSta = 1:nmbr_Sta
    staNm = staNmCell{iSta};
    % disp([path_output,staNm])
    if ~exist([path_output,staNm],'dir')
        mkdir([path_output,staNm]);
    end
end

%!====== comb gemsdat with 15Hz
%!====== transform into emNE
%!====== save emT emNE as STAB.1HZ.TW.yyyymmdd.mat
for iSta = 1:nmbr_Sta
    for iTm = 1:length(tmTag)
        staNm = staNmCell{iSta};
        disp(['Doing ',staNm,' ======== ',datestr(tmTag(iTm),'yyyy.mm.dd')])
        [emdata, mat_header, ratio_nan, orig_Property] = comb_gemsdat_1day_15hz(staNm, tmTag(iTm), path_Root);
        if isempty(emdata)
            volt_emchn = [];
            time_Beg = tmTag(iTm);
        else
            volt_emchn = emdata(:,2:3);
            time_Beg = datenum(emdata(1,1));
        end
        save([path_output,staNm,'\', ...
                staNm,datestr(tmTag(iTm),'.yyyymmdd'),'.mat'],'volt_emchn','mat_header','ratio_nan','orig_Property','time_Beg','fs','dt');
        clear emdata volt_emchn mat_header ratio_nan orig_Property
    end
end