fileMon = '/Users/cpkmanchee/Google Drive/PhD/Data/2017-01-17 Oscillator power stability/2017-01-17 RM log.txt';
filePow = '/Users/cpkmanchee/Google Drive/PhD/Data/2017-01-17 Oscillator power stability/PM100_17-Jan-17_14-15.txt';

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
