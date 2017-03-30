function varargout = regen_monitor(varargin)
% REGEN_MONITOR MATLAB code for regen_monitor.fig
%      REGEN_MONITOR, by itself, creates a new REGEN_MONITOR or raises the existing
%      singleton*.
%
%      H = REGEN_MONITOR returns the handle to a new REGEN_MONITOR or the handle to
%      the existing singleton*.
%
%      REGEN_MONITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REGEN_MONITOR.M with the given input arguments.
%
%      REGEN_MONITOR('Property','Value',...) creates a new REGEN_MONITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before regen_monitor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to regen_monitor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help regen_monitor

% Last Modified by GUIDE v2.5 30-Nov-2016 11:23:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @regen_monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @regen_monitor_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- User defined functions

%Scan for daq device and set up channels. Set up daq
function [e,msg] = scanDev(hObject, handles)
%should insert section to check for and delete a current session handle if
%it exists

if isfield(handles, 'lh') || isfield(handles, 'session')
    stopMon(handles.figure1)
    handles = guidata(handles.figure1);
    handles = rmfield(handles, 'session');
end
guidata(handles.figure1,handles);

try
device = daq.getDevices;
catch err
    errordlg(['Error retrieving device list: ' err.identifier]);
    e = -1;
    msg = ['Error retrieving device list: ' err.identifier];
    return
end 

if isempty(device)
    e = 0;
    msg = 'No devices found';
    return
end

k = strcmpi('National Instruments USB-6009', device.Description);

if all(k==0)
    e = 0;
    msg = 'USB-6009 not found';
    return
end

% try
%get index of matching element
index = find(k);
index = index(1);

%get vendor and devicesID info
vendor = device(index).Vendor.ID;
devID = device(index).ID;

%create session
s = daq.createSession(vendor);
s.Rate = handles.sampleRate;
s.IsContinuous = true;

%create channels
%add if's to change if channels are created (check box in giu?)
[pwrCh, handles.pwrIdx] = addAnalogInputChannel(s, devID, 'ai7', 'Voltage');
pwrCh.Name = 'DiodePower';
pwrCh.InputType = 'SingleEnded';
pwrCh.Range = [-10,10];
[crvCh, handles.crvIdx] = addAnalogInputChannel(s, devID, 'ai3', 'Voltage');
crvCh.Name = 'DiodeCrossover';
crvCh.InputType = 'SingleEnded';
crvCh.Range = [-10,10];
[tmp1Ch, handles.tmp1Idx] = addAnalogInputChannel(s, devID, 'ai1', 'Voltage');
tmp1Ch.Name = 'Temperature1';
tmp1Ch.InputType = 'SingleEnded';
tmp1Ch.Range = [-10,10];
[tmp2Ch, handles.tmp2Idx] = addAnalogInputChannel(s, devID, 'ai5', 'Voltage');
tmp2Ch.Name = 'Temperature2';
tmp2Ch.InputType = 'SingleEnded';
tmp2Ch.Range = [-10,10];
[pscCh, handles.pscIdx] = addAnalogInputChannel(s, devID, 'ai2', 'Voltage');
pscCh.Name = 'PowerSupplyCurrent';
pscCh.InputType = 'Differential';
pscCh.Range = [-10, 10];

handles.session = s;
guidata(handles.figure1,handles);

%set up/enable monitor button
set(handles.monToggle, 'BackgroundColor', [0,1,0]);
set(handles.monToggle, 'String', 'Start monitor');
set(handles.monToggle, 'Enable', 'on');

e = 1;
msg = 'Setup successful';
return

% catch err
%     e = -1;
%     msg = ['Device found - error occured during setup: ' err.identifier];
% end


%Start monitoring
function startMon(hObject)
%hObject should be main figure handle.... can probably fix this
%must be called once the devices are setup
%daq session stored in handles.session

handles = guidata(hObject);

%check for device session
if ~isfield(handles, 'session')
    errordlg('Error starting monitors: No session ID', 'Session Start Error')
    return
end

%initialize logging, if enabled
if get(handles.logCheck, 'Value') == 1
    
    status = ovrwrtChecker(handles.figure1);
    switch status
        case 0
            set(handles.monToggle, 'Value', 0);
            return
            
        case 1
            logData(handles,[]);
            
        case 2
            
        otherwise
            set(handles.monToggle, 'Value', 0);
            return      
    end
    
end

%set up listener
handles.session.NotifyWhenDataAvailableExceeds = handles.avgN;
handles.lh = addlistener(handles.session, 'DataAvailable', @(scr, event) updateDisplays(scr, event, hObject));
startBackground(handles.session);
guidata(hObject,handles);

%disable changes to logging
set(handles.logCheck, 'Enable', 'off');
set(handles.logFilename, 'Enable', 'off');
set(handles.browseFileButton, 'Enable', 'off');

%Change monitor toggle button
set(handles.monToggle, 'BackgroundColor', [1,0,0]);
set(handles.monToggle, 'String', 'Stop Monitor');


%Stop monitoring
function stopMon(hObject)
%stop daq session
handles = guidata(hObject);

if isfield(handles, 'session')
    stop(handles.session);
end

%delete listener
if isfield(handles,'lh')
    delete(handles.lh)
    handles = rmfield(handles, 'lh');
end

guidata(hObject,handles);

%Enable changes to logging
set(handles.logCheck, 'Enable', 'on');
set(handles.logFilename, 'Enable', 'on');
set(handles.browseFileButton, 'Enable', 'on');

%Change monitor toggle button
set(handles.monToggle, 'BackgroundColor', [0,1,0]);
set(handles.monToggle, 'String', 'Start Monitor');
if get(handles.monToggle, 'Value') == 1
    set(handles.monToggle, 'Value', 0);
end


%Update plots and monitor displays
function updateDisplays(src, event, hObject)
%hObject is mainfigure object
%General approach:
%1. check for display field: ensures data for display will be available
%2. get raw voltage measurement from daq
%3. convert voltage to relavent quantity
%4. check range of measurement (safe, warning, danger), set display color
%5. change string and color of display

handles = guidata(hObject);

%Get raw voltages
pwrVlt = mean(event.Data(:,handles.pwrIdx));
crvVlt = mean(event.Data(:,handles.crvIdx));
tmp1Vlt = mean(event.Data(:,handles.tmp1Idx));
tmp2Vlt = mean(event.Data(:,handles.tmp2Idx));
pscVlt = mean(event.Data(:,handles.pscIdx));

%Updte raw Voltage Displays
set(handles.dpvDisp, 'String', num2str(pwrVlt,'%.4f'));
set(handles.dcvDisp, 'String', num2str(crvVlt,'%.4f'));
set(handles.pcvDisp, 'String', num2str(pscVlt,'%.4f'));
set(handles.t1vDisp, 'String', num2str(tmp1Vlt,'%.4f'));
set(handles.t2vDisp, 'String', num2str(tmp2Vlt,'%.4f'));

%Power display
if pwrVlt <= 0.01
   curPow = 0; 
elseif pwrVlt < 5.014
    curPow = polyval(handles.pwrCalCoef,pwrVlt);
else
    curPow = polyval(handles.pwrEstCoef,pscVlt);
end

powStr = num2str(curPow,'%.1f');
set(handles.pwrDisp, 'String', powStr);

%Current, power supply display
if pscVlt <0.002
    curPsc = 0;
else
    curPsc = polyval(handles.pscCalCoef, pscVlt);
end

pscStr = num2str(curPsc,'%4.2f');
set(handles.pscDisp, 'String', pscStr);

%Crossover display
curCrv = (crvVlt/4.0);

if curCrv >= handles.crvDng 
   crvCol = handles.dngCol;    %danger, red color
elseif curCrv >= handles.crvWrn
    crvCol = handles.wrnCol;   %warning, yellow
else
    crvCol = handles.safeCol;   %safe, green
end

crvStr = num2str(curCrv,'%.4f'); 
set(handles.crvDisp, 'String', crvStr);
set(handles.crvDisp, 'ForegroundColor', crvCol);

%Temperature 1 display
curTmp1 = (tmp1Vlt - handles.tmp1Ofs)/handles.tmp1Cal;

if curTmp1 <= handles.tmpDng1(1) || curTmp1 >= handles.tmpDng1(2) 
   tmpCol = handles.dngCol;    %danger, red color
elseif curTmp1 <= handles.tmpWrn1(1) || curTmp1 >= handles.tmpWrn1(2)
    tmpCol = handles.wrnCol;   %warning, yellow
else
    tmpCol = handles.safeCol;   %safe, green
end

set(handles.tmp1Disp, 'String', num2str(curTmp1,'%.1f'));
set(handles.tmp1Disp, 'ForegroundColor', tmpCol);

%Temperature 2 (xstal) display
curTmp2 = (tmp2Vlt - handles.tmp2Ofs)/handles.tmp2Cal;

if curTmp2 <= handles.tmpDng2(1) || curTmp2 >= handles.tmpDng2(2) 
   tmpCol = handles.dngCol;    %danger, red color
elseif curTmp2 <= handles.tmpWrn2(1) || curTmp2 >= handles.tmpWrn2(2)
    tmpCol = handles.wrnCol;   %warning, yellow
else
    tmpCol = handles.safeCol;   %safe, green
end

set(handles.tmp2Disp, 'String', num2str(curTmp2,'%.1f'));
set(handles.tmp2Disp, 'ForegroundColor', tmpCol);

%time of day
set(handles.todText, 'String', datestr(now, 'dd-mmm-yyyy HH:MM:SS'));

%Log data if enabled
if get(handles.logCheck, 'Value') == 1
    %only log every second
    i = handles.logNum;
    if mod(i,handles.refreshRate) == 0
        logData(handles,[(event.TriggerTime + mean(event.TimeStamps)/86400),curPsc,curPow,curCrv,curTmp1,curTmp2]);
    end
    handles.logNum = i+1;
    guidata(hObject,handles);
end



%Log data to file
function logData(handles, data)
%send empty data field to initialize log
% data format --> [timeNum, power, crossover, temp1, temp2]

if isempty(data)
    %initialize log file
    fileid = fopen(get(handles.logFilename, 'String'), 'wt');
    fprintf(fileid, '%s\n', datestr(now, 'dd-mmm-yyyy HH:MM:SS'));
    fprintf(fileid, 'REGEN System Monitor\n\n');
    fprintf(fileid, 'Sampling rate =\t%.3f Hz\n', handles.sampleRate);
    fprintf(fileid, 'Number of samples averaged =\t%.0f\n', handles.avgN);
    fprintf(fileid, 'Power Calibration (a0...aN):\t%s\n', sprintf('%.4f\t', handles.pwrCalCoef));
    
    fprintf(fileid,'\n%23s\t%8s\t%8s\t%8s\t%8s\t%8s\n','Time','Current','Power','Crossover', 'T1', 'T2');
    fprintf(fileid,'%23s\t%8s\t%8s\t%8s\t%8s\t%8s\n','yyyy/mm/dd hh:mm:ss.fff','(A)','(W)','(ratio)', '(degC)', '(degC)');
    fclose(fileid);
    
else
    %append to log
    if length(data) < 6
        data = [data, zeros(6-length(data))];
    end
    
    fileid = fopen(get(handles.logFilename, 'String'), 'at');
    fprintf(fileid,'%23s\t%8.4f\t%8.3f\t%8.5f\t%8.2f\t%8.2f\n', datestr(data(1), 'yyyy/mm/dd HH:MM:SS.FFF'),data(2:6));
    fclose(fileid);
    
end


function status = ovrwrtChecker(mainFigure)
%status = 0 means do not proceed (to be used by calling function)
%status = 1 means proceed to overwrite
%status = 2 means append file

handles = guidata(mainFigure);
[path,name,ext] = fileparts(get(handles.logFilename, 'String'));

status = 0;
%check for existing file
if exist(fullfile(path,[name ext]),'file') == 2
    
    %file already exists, promt for overwrite
    buttonName = questdlg(sprintf('File already exists. Overwrite?\nCancel to change file.'), 'Path warning', 'Overwrite', 'Append file', 'Disable log', 'Disable log');
    switch buttonName
        case 'Append file'
            status = 2;
            
        case 'Overwrite'
            status = 1;
            
        case 'Disable log'
            set(handles.logCheck, 'Value', 0);
            status = 1;
            
        otherwise
            set(handles.logCheck, 'Value', 0);
            status = 0;
    end
    
else
    %file does not exist, will be created when logging begins
    status = 1;
end


function setCalibration(mainFigure)
    %This function sets the power calibration coefficients based on the set temperature
    %mainFigure = main figure handle
    %output = [a3, a2, a1, a0]

handles = guidata(mainFigure);

temp = handles.diodeCalTemp;

cal_temp = [20,25,30,35];
%a3,a2,a1,a0
cal_coef = [...
    [0.3905250144, -3.401362994, 26.70952837, 0.9935367105];...
    [0.4286940672, -3.881127898, 26.58477872, 0.1994011716];...
    [0.3739759038, -2.827344471, 21.78657583, 0.916108326];...
    [0.3451878422, -2.234112458, 19.82081582, 1.052686614]];

output_coef = interp1(cal_temp,cal_coef,temp, 'linear', 'extrap');

handles.pwrCalCoef = output_coef;

guidata(mainFigure,handles);


% --- End user functions


% --- Executes just before regen_monitor is made visible.
function regen_monitor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to regen_monitor (see VARARGIN)

% Choose default command line output for regen_monitor
handles.output = hObject;

% Update handles structure, set 'global' parameters
handles.pwrCalCoef = [0.4315403228 28.14068064 -3.770681968 0.4096289863];   %power cal coeffs, calc power from monitor voltage, a0 a1...
handles.pwrEstCoef = [30.76897313 -11.93860021];    %power estimate coeffs, calc power from current mon voltage, a0 a1...
handles.pscCalCoef = [5.977168596 0.009309869398];  %curent power supply cal coeffs, a0 a1...	
handles.diodeCalTemp = 35;                %temperature for diode calibration

handles.crvWrn = 0.8;               %crv Warning level
handles.crvDng = 1;                 %crv Danger level
handles.tmp1Cal = 0.00499;          %temp1 calibration, V/degC
handles.tmp1Ofs = 1.2370;           %temp1 offset, V
handles.tmp2Cal = 0.004905;         %temp2 calibration, V/degC
handles.tmp2Ofs = 1.2335;           %temp2 offset, V
handles.tmpWrn1 = [25,40];           %temp warning, degC, diode
handles.tmpDng1 = [20,45];           %temp danger, degC, diode
handles.tmpWrn2 = [10,20];           %temp warning, degC, xstal
handles.tmpDng2 = [05,25];           %temp danger, degC, xstal

handles.avgN = 1000;                %number of scans to average per update
handles.refreshRate = 5;            %refresh rate, times per second
handles.logNum = 0;
handles.dngCol = [.75 0 0];         %'danger' color (red)
handles.wrnCol = [.75 .5 0];       %'warning' color (yellow)
handles.safeCol = [.25 .5 0];        %'safe' color (green)

maxSampleRate = 9600;
handles.sampleRate = handles.avgN*handles.refreshRate;

if handles.sampleRate >= maxSampleRate
    handles.sampleRate = maxSampleRate;
    handles.refreshRate = handles.sampleRate/handles.avgN;
end

%set(findall(handles.cryPanel, '-property', 'enable'), 'enable', 'off')

guidata(hObject, handles);
setCalibration(handles.figure1);

% UIWAIT makes regen_monitor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = regen_monitor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function tmp1Unit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tmp1Unit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%sets display  to deg Celcius
set(hObject, 'String', [char(176),'C'])


% --- Executes on button press in scanBtn.
function scanBtn_Callback(hObject, eventdata, handles)
% hObject    handle to scanBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%scan for devices
[e,msg] = scanDev(hObject, handles);

switch e
    case -1
        %error occured
        errordlg(msg, 'Connection Error');
    case 0
        %no deivces
        msgbox(msg,'Connection Error', 'warn');
    case 1
        %all good
    otherwise
        %error
        errordlg(['Unknown error occured: ' msg], 'Connection Error');
end


% --- Executes on button press in monToggle.
function monToggle_Callback(hObject, eventdata, handles)
% hObject    handle to monToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

button_state = get(hObject,'Value');

if button_state == get(hObject, 'Max')
    %button presed
%     try
        startMon(handles.figure1);
%     catch err
%         errordlg(['Error starting monitors: ' err.identifier], 'Monitor Error');
%         
%     end
    
    
elseif button_state == get(hObject, 'Min')
    %not pressed
    try
        stopMon(handles.figure1);
    catch err
        errordlg(['Error stoping monitors: ' err.identifier], 'Monitor Error');
    end
end


% --- Executes on button press in logCheck.
function logCheck_Callback(hObject, eventdata, handles)
% hObject    handle to logCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of logCheck
if get(hObject, 'Value') == 1
    %separate filename and path
    [path,name,ext] = fileparts(get(handles.logFilename, 'String'));
    
    %check for valid path
    while exist(path, 'dir') ~= 7
        %open system dialog to select file/location
        [fileName, pathName] = uiputfile( '*.txt', 'Invalid save location', 'D:\Miller Group Users');

        %if the user presses 'cancel', uncheck log box
        if pathName == 0
            set(handles.logCheck, 'Value', 0);
            break;
        end

        %set file location string
        set(handles.logFilename,'String',[pathName,fileName]);
        [path,name,ext] = fileparts(get(handles.logFilename, 'String'));
    end

%     %check for existing file
%     changeFile = true;
%     while changeFile
% 
%         if exist(fullfile(path,[name ext]),'file') == 2
% 
%             %file already exists, promt for overwrite
%             buttonName = questdlg('File already exists. Overwrite?', 'Path warning', 'Cancel', 'Change file', 'Overwrite', 'Cancel');
%             switch buttonName
%                 case 'Cancel'
%                     set(handles.logCheck, 'Value', 0);
%                     return
%                     
%                 case 'Change file'
%                     %open system dialog to select new file
%                     [fileName, path] = uiputfile( '*.txt', 'Invalid save location', 'D:\Miller Group Users');
%                     set(handles.logFilename,'String',[path,fileName]);
%                     [path,name,ext] = fileparts(get(handles.logFilename, 'String'));
%                     
%                 case 'Overwrite'
%                     changeFile = false;
%                     
%                 otherwise
%                     set(handles.logCheck, 'Value', 0);
%                     return
%             end
%             
%         else
%             %file does not exist, will be created when logging begins
%             changeFile = false;
%         end
%         
%     end
    
end

function logFilename_Callback(hObject, eventdata, handles)
% hObject    handle to logFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of logFilename as text
%        str2double(get(hObject,'String')) returns contents of logFilename as a double

%run log checkbox callback to determine if filename is ok
logCheck_Callback(handles.logCheck, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function logFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to logFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseFileButton.
function browseFileButton_Callback(hObject, eventdata, handles)
% hObject    handle to browseFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%opens system dialog to selecct file
[fileName, pathName] = uiputfile( '*.txt', 'Save file', 'D:\Miller Group Users');
set(handles.logFilename,'String',[pathName,fileName]);

%run log checkbox callback to determine if filename is ok
logCheck_Callback(handles.logCheck, eventdata, handles);



function calTempEdit_Callback(hObject, eventdata, handles)
% hObject    handle to calTempEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calTempEdit as text
%        str2double(get(hObject,'String')) returns contents of calTempEdit as a double

temp = str2double(get(hObject,'String'));

if isnan(temp)
    set(hObject, 'String', num2str(handles.diodeCalTemp));
else
    handles.diodeCalTemp = temp;
end

guidata(handles.figure1,handles);
setCalibration(handles.figure1);



% --- Executes during object creation, after setting all properties.
function calTempEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calTempEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
