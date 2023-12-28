function [emdata, mat_header, ratio_nan, orig_Property] = comb_gemsdat_1day_15hz(sta_Name, time_Tag, path_Root)
% combining all gems.dat in a one-day folder
% padding nan into lost points with fs=15hz
% function [volt_emchn, mat_header, nmbr_nan, origProperty] = comb_gemsdat_1day_15hz(sta_Name, time_Tag, path_Root)
% input:
%       sta_Name = string, 'KUOL'
%       time_Tag = [yyyy, mm, dd], [2013, 1, 1]
%       path_Root = 'G:\GEMS\'
% output:
%       emdata = [time, chn1, chn2, chn3, chn4]
%       mat_header = [header1;header2;...]
%       ratio_nan = ratio of nan to all points
%       origProperty = struct, included isDirExited, isTimeSorted, isTimeDuplicated
% called func:
%       read_gemsdat.m
% e.g.:
%       [emdata, mat_header, ratio_nan, orig_Property] = comb_gemsdat_1day_15hz('PULI',[2013,1,1],'G:\GEMS\')
% written by ChenHJ on 20180703
% modified by ChenHJ on 20211011
%   Verification is Done.

if nargin < 3
    path_Root = 'G:\GEMSdat\';
end
fs = 15;
nmbr_Chn = 4;
emdata = []; mat_header = []; ratio_nan = 1;
orig_Property = struct('isDirExisted', true, ...
                      'isTimeSorted', true, ...
                      'isTimeDuplicated', false, ...
                      'number_of_file', 0, ...
                      'number_of_not_full_eof', 0);

time_Tag = floor(datenumtype(time_Tag));
gemsParam = get_gemsParam(sta_Name);
path_data = [path_Root, gemsParam.staCode{1}, '\REC\', ...
          'Y', datestr(time_Tag, 'yyyy'), '\', ...
          'M', datestr(time_Tag, 'mm'), '\', ...
          'D', datestr(time_Tag, 'dd'), '\'];
if ~exist(path_data,"dir")
    disp(['No folder: ', path_data])
    orig_Property.isDirExisted = false;
    return; % no folder
end

file_List=ls([path_data,'*.dat']);
if isempty(file_List)
    disp(['No dat-file: ', path_data])
    return; % no .dat file
end

time = time_Tag:1/86400/fs:time_Tag+1;
emdata = nan(86400*fs, nmbr_Chn+1);
emdata(:, 1) = time(1:end-1);
nmbr_datfile = size(file_List, 1);
nmbr_field_header = 50;
mat_header = nan(nmbr_field_header, nmbr_datfile);
%% data combine
for iFil = 1:nmbr_datfile
    absolute_FileName = [path_data, file_List(iFil,:)];
    [data, header] = read_gemsdat(absolute_FileName);
    % make sure no 0kb file
    if isempty(data)
        continue;
    end
    mat_header(:,iFil) = header;
    % make sure the time is sorted
    if ~issorted(data(:,1))
        [~, idx_stm] = sort(data(:,1));
        data = data(idx_stm, :);
        orig_Property.isTimeSorted = false;
    end
    % make sure no duplicate time
    if sum(diff(data(:,1))==0) > 0
        [~, idx_unid] = unique(data(:,1));
        data = data(idx_unid, :);
        orig_Property.isTimeDuplicated = true;
    end
    % interp to pad lost points with each dat file
    for iData = 2:size(data,2)
        idx_time = emdata(:,1) >= data(1,1) & emdata(:,1) <= data(end,1);
        F = griddedInterpolant(data(:,1), data(:,iData));
        y = F(emdata(idx_time, 1));
        emdata(idx_time, iData) = y;
    end
end
orig_Property.number_of_file = nmbr_datfile;
orig_Property.number_of_not_full_eof = sum(mat_header(10,:));
ratio_nan = sum(isnan(emdata(:,2)))/length(emdata(:,2));

end%func