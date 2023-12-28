function [data, header] = read_gemsdat(absolute_FileName)
% read YYYY_MM_DD_hh_mm_ss.dat of GEMS (from anasystem)
% GEMS.dat formant
% Header is the first 100 bytes.
% All parameters in header is in a unit of 2 bytes
% Hence, the header has 50 fields.
% 0-11 bytes is for date
% 0-1: year
% 2-3: month
% 4-5: day
% 6-7: hour
% 8-9: minute
% 10-11: second
% 12-13: sampling rate
% 14-15: Channel Options (15 has 4 CHs,255 has 4 CHs,7 has 3 CHs,3 has 2 CHs)
% 16-99 bytes are padded by zero, for later use.
%
% From 100 byte on, every 4 byte is used to save data,
% the order is TimeStamp,Ch1, Ch2, Ch3, Ch4.
% If one channel is not used,skip it,
% e.g., only use chn1 and chn3, then recording order is TimeStamp,Ch1, Ch3, TimeStamp, Ch1, Ch3, and so on. 
% Every cycle, TimeStamp is a 4-byte integer, time drift from the header time, unit is minisecond.
% channel's data is 4-byte single-precision float. 
% Note that the byte order of all data is "little endian."
%
% function [data, header] = read_gemsdat(absolute_FileName)
% input:
%     fileName: string, absolute full file name
% output:
%     data = []/ [time,chn1,chn2,chn3,chn4]
%     header = []/[yyyy;mm;dd;HH;MM;SS.SS;fs;chnOPT;...]
% called func:
% 
% e.g.:
%     [data, header] = read_gemsdat('g:\GEMSdat\em10\REC\Y2012\M02\D07\2012_02_07_16_45_00.dat');
% modified from readanasystem.m written by HsuHL
% written by ChenHJ on 20180701
% modified by ChenHJ on 20211011
%   Verification is Done.

data = []; header = [];
%% file check
if ~exist(absolute_FileName, "file")
    disp(['No file exists: ', absolute_FileName])
    return;
end

fileID = fopen(absolute_FileName, "r");
if fileID < 0
    disp(['Error in File open: ', absolute_FileName])
    fclose(fileID);
    return;
end

%% header
fseek(fileID, 0, 'bof'); % from Beginning-of-File
header = fread(fileID, 50, 'int16', 'ieee-le'); %short=int16, 2bytes
if feof(fileID)
    disp(['Error in End-of-file (just header no data): ', absolute_FileName])
    fclose(fileID);
    return;
end
if sum(header(1:7) < 0) %yyyy, mm, dd, HH, MM, SS, fs, (error in header)
    disp(['Error in Time header: ', absolute_FileName])
    fclose(fileID);
    return;
end

% fs = header(7); %sampling rate

if header(8) == 15 %2^4-1
    nmbr_ChnUse = 4;
elseif header(8) == 255 || header(8) == -256 % -256 written by new instrument -2^8, 2^8-1
    nmbr_ChnUse = 4;
elseif header(8) == 7 %2^3-1
    nmbr_ChnUse = 3;
elseif header(8) == 3 %2^2-1
    nmbr_ChnUse = 2;
else
    disp(['Error in Number of Channel Use: ', absolute_FileName])
    fclose(fileID);
    return;
end
header(9) = nmbr_ChnUse;

%% data
% read time increment
% int32: 32bits/4bytes
skip_float = 4*nmbr_ChnUse;  % skip channel data
fseek(fileID, 100, 'bof'); % from Beginning-of-File
time_Stamp = fread(fileID, [1 inf], 'int32', skip_float, 'ieee-le'); % time stamp is in mini-second

% read channel data
% float32: 32bits/4bytes
skip_int = 4;  % skip time increment
fseek(fileID, 100 + skip_int, 'bof'); % from Beginning-of-File
val_ElectV = fread(fileID, [1 inf], [num2str(nmbr_ChnUse),'*float32'], ...
                                skip_int, 'ieee-le'); % unit in V
fclose(fileID);

if mod(length(val_ElectV),nmbr_ChnUse) ~= 0
    disp(['Not full eof: ', absolute_FileName])
    header(10) = 1;
end
nmbr_Row = floor(length(val_ElectV)/nmbr_ChnUse);
val_ElectV = reshape(val_ElectV(1:nmbr_ChnUse*nmbr_Row), [nmbr_ChnUse nmbr_Row])';

% data=[time,chn1,chn2,chn3,chn4]
time = datenum(header(1:6)') + time_Stamp'/1000/86400;% unit: day
data = [time(1:nmbr_Row), val_ElectV];

end %func