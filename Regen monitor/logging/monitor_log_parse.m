fileMon = 'D:\Miller Group Users\Kyle\2016-05-12 power log\2016-11-22 MON temperature profile 90W.txt';
filePow = 'D:\Miller Group Users\Kyle\2016-05-12 power log\2016-11-22 PM100 voltagemon.txt';

%% Import Power meter data
filename = filePow;
delimiter = '\t';
startRow = 3;

formatSpec = '%s%f%s%[^\n\r]';

fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines', startRow-1, 'ReturnOnError', false);
fclose(fileID);

%convert date to datenum
dataArray{1} = datenum(dataArray{1}, 'mm/dd/yyyy HH:MM:SS.FFF AM');

% Allocate imported array to column variable names
tPM = dataArray{:, 1};
PM = dataArray{:, 2};

% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans;

%% Import Monitor data
filename = fileMon;
delimiter = '\t';
startRow = 10;

formatSpec = '%s%f%f%f%f%f%[^\n\r]';

fileID = fopen(filename,'r');
headerArray = textscan(fileID, '%s', startRow-1, 'Delimiter', '\n');
frewind(fileID);
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines', startRow-1, 'ReturnOnError', false);
fclose(fileID);

%convert date to datenum
dataArray{1} = datenum(dataArray{1}, 'yyyy/mm/dd HH:MM:SS.FFF');

% Allocate imported array to column variable names
tMon = dataArray{:, 1};
cur = dataArray{:, 2};
pMon = dataArray{:, 3};
crv = dataArray{:, 4};
T1 = dataArray{:, 5};
T2 = dataArray{:, 6};

%parse header
rr = cell2mat(textscan(headerArray{1}{4}, 'Sampling rate = %f'));
N = cell2mat(textscan(headerArray{1}{5}, 'Number of samples averaged = %f'));
coeffCal = cell2mat(textscan(headerArray{1}{6}, 'Power Calibration (a0...aN): %f%f%f%f'));

% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray headerArray ans;
