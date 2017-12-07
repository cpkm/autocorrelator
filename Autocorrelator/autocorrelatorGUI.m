function varargout = autocorrelatorGUI(varargin)
% AUTOCORRELATORGUI MATLAB code for autocorrelatorGUI.fig
%      AUTOCORRELATORGUI, by itself, creates a new AUTOCORRELATORGUI or raises the existing
%      singleton*.
%
%      H = AUTOCORRELATORGUI returns the handle to a new AUTOCORRELATORGUI or the handle to
%      the existing singleton*.
%
%      AUTOCORRELATORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUTOCORRELATORGUI.M with the given input arguments.
%
%      AUTOCORRELATORGUI('Property','Value',...) creates a new AUTOCORRELATORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before autocorrelatorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to autocorrelatorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help autocorrelatorGUI

% Last Modified by GUIDE v2.5 01-May-2017 16:33:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @autocorrelatorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @autocorrelatorGUI_OutputFcn, ...
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


% --- Executes just before autocorrelatorGUI is made visible.
function autocorrelatorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to autocorrelatorGUI (see VARARGIN)

%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handles.computeripconex = 'localhost'; % Set server computer IP or URL for Conex
handles.instrumentname = 'Conex';
handles.conexcommport = 'COM3'; % Set server serial port for Conex server
handles.serialserversocketport = 32000; % Set server socket port for Conex server
handles.baudrate = '921600'; % Set baudrate for Conex server
handles.bits = 8; % Set data bits for Conex server
handles.flowcontrol = 'XON/XOFF'; % Set flow control for Conex server
handles.termchar = 'CRLF'; % Set termination character for Conex server

handles.computeripthorlabs = 'localhost'; % Set server computer IP or URL for Thorlabs powermeter
handles.thorlabssocketport = 28000; % Set server socket port for Thorlabs powermeter server

handles.computeripNIDAQ = 'localhost'; % Set server computer IP or URL for NIDAQ
handles.NIDAQsocketport = 29000; % Set server socket port for NIDAQ server

handles.MAXCHECKS = 1000;           %maximum position checks during movement


[status,result] = system(['title conex & "D:\MATLAB\Autocorrelator\server.exe" ' handles.instrumentname ' ' num2str(handles.serialserversocketport) ' &']);

[status,result] = system('title thorlabs & "D:\MATLAB\Autocorrelator\server_thorlabs.exe" &');

%[status,result] = system('title NIDAQ & "E:\gustavo\University of Toronto\MATLAB\NIDAQ\server_NIDAQ\Release\server_NIDAQ.exe" &');


%%% Connect conex %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msg = {['OPEN ' handles.conexcommport ' ' handles.baudrate ' ' handles.flowcontrol]}; % Creates a command to open the serial port for conex controller
[handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true);

errorconex = strfind(char(handles.answer),'COM opening error');

if isempty(errorconex)

    %%% Reference %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to check status
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

    isnotref = char(handles.answer);

    if ~isequal(isnotref(4:7),'0000')
        str=strcat('The following errors occured:\n',isnotref(4:7));
        errordlg(sprintf(str));
    end

    if isequal(isnotref(8),'0') || isequal(isnotref(8:9),'10') % Homing
        msg = {['SENDRCV ' handles.termchar ' ' '1OR'],['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to search for home
        [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

        ishomed=char(handles.answer);

        i=1;
        %Tests whether the linear activator reached the home position. If not wait
        %and try again.
        while (i<=50 && ~isequal(ishomed(8:9),'32'))
            pause(1);
            msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
            [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
            ishomed=char(handles.answer);
            i=i+1;
        end

        %Print out error message, if the Home mode was not reached.
        if ~isequal(ishomed(8:9),'32')
            str=strcat('Homing was not successfull current mode is ',ishomed(8:9),'.');
            errordlg(str);
        end

        %If errors occured while homing, print these errors, too.
        if ~isequal(ishomed(4:7),'0000')
            str=strcat('The following errors occured:\n',ishomed(4:7));
            errordlg(sprintf(str));
        end
    end

    %%%% Move the linear activator to the position 6mm

    msg = {['SENDRCV ' handles.termchar ' ' '1PA6'],['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to move absolute 2 mm
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

    ispositionreached=char(handles.answer);

    i=1;
    %Tests whether the linear activator reached the home position. If not wait and try again.
    while (i<=20 && ~isequal(ispositionreached(8:9),'33'))
        pause(0.1);
        msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
        [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
        ispositionreached=char(handles.answer);
        i=i+1;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    msg = {['SENDRCV ' handles.termchar ' ' '1TP'],['SENDRCV ' handles.termchar ' 1VA?'],['SENDRCV ' handles.termchar ' 1AC?'],['SENDRCV ' handles.termchar ' 1SL?'],['SENDRCV ' handles.termchar ' 1SR?']};
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
    
    answer = char(handles.answer(1));
    posmm = answer(4:end-2);
    set(handles.position,'string',num2str(str2double(posmm)*1000,'%6.1f'));

    answer = char(handles.answer(2));
    velmm = answer(4:end-2);
    set(handles.velocity,'string',num2str(str2double(velmm)*1000,'%6.1f'));

    answer = char(handles.answer(3));
    accmm = answer(4:end-2);
    set(handles.acceleration,'string',num2str(str2double(accmm)*1000,'%6.1f'));

    answer = char(handles.answer(4));
    handles.lowerlimit = str2double(answer(4:end-2));

    answer = char(handles.answer(5));
    handles.upperlimit = str2double(answer(4:end-2));

else
    uiwait(errordlg('COM opening error','Conex error','modal'));
    set(handles.velocity,'Enable','off')
    set(handles.acceleration,'Enable','off')
    set(handles.go,'Enable','off')
    set(handles.kill,'Enable','off')
    set(handles.home,'Enable','off')
    set(handles.destination,'Enable','off')
end


msg = {'OPEN'}; % Creates a command to open the serial port for thorlabs powermeter
[handles.answer handles.input_socketthorlabs] = thorlabs(handles.computeripthorlabs,handles.thorlabssocketport,msg);

errorthorlabs = strfind(char(handles.answer),'Error opening');

if isempty(errorthorlabs)
    %%% Get Wavelenght

    msg = {'SENDRCV GETWAVE'}; % Creates a command to open the serial port
    [handles.answer handles.input_socketthorlabs] = thorlabs(handles.computeripthorlabs,handles.thorlabssocketport,msg,handles.input_socketthorlabs);
    set(handles.wavelength,'string',strtok(char(handles.answer{1})))
    handles.powermeter = 1;
else
    uiwait(errordlg('Error opening','Thorlabs error','modal'));
    set(handles.wavelength,'enable','off')
    set(handles.irvisuv,'value',2)
    set(handles.irvisuv,'enable','off')
    handles.powermeter = 0;
end


%Opens nidaq serial port
% msg = {'GETDEV'};
% [handles.answer handles.input_socketNIDAQ] = NIDAQ(handles.computeripNIDAQ,handles.NIDAQsocketport,msg);
% handles.devname = strtok(char(handles.answer),[char(10) char(13)]);
% 
% if ~isempty(handles.devname)
%     handles.DAQ = 1;
%     msg = {['CHECKTR ' handles.devname(end)]};
%     [handles.answer handles.input_socketNIDAQ] = NIDAQ(handles.computeripNIDAQ,handles.NIDAQsocketport,msg,handles.input_socketNIDAQ);
%     if strcmp(strtok(char(handles.answer),[char(10) char(13)]),'NO_TRIGGER') == 1
%         uiwait(errordlg('No trigger detected','NIDAQ error','modal'));
%         % disable controllers
%     end
% else
%     uiwait(errordlg('Device is no longer present in the system.','NIDAQ error','modal'));
%     set(handles.irvisuv,'value',1)
%     set(handles.irvisuv,'enable','off')
%     handles.DAQ = 0;
%     % disable controllers
% end

 
%%% Set titles %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% char(181) is mu symbol
% char(178) is superscript 2
% 
set(handles.titlepos,'string',['Position (' char(181) 'm)'])
set(handles.titletar,'string',['Target (' char(181) 'm)'])
set(handles.titleop,'string','Operation Mode')
set(handles.titledest,'string',['Destination (' char(181) 'm)'])
set(handles.titlevel,'string',['Velocity (' char(181) 'm/s)'])
set(handles.titleaccel,'string',['Acceleration (' char(181) 'm/s' char(178) ')'])
set(handles.titlestep,'string',['Step size (' char(181) 'm)'])
set(handles.titlenumsteps,'string','Number of steps')
%set(handles.functiontext,'string','a(1)*exp(-(x-a(2))^2/(2*a(3)^2))+a(4)')

axes(handles.axes1)
xlabel('Position (um)')
ylabel('Power (W)')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Initial ffit parameters

initparam = [1 0 10 0];
set(handles.amplitude,'string',num2str(initparam(1)))
set(handles.center,'string',num2str(initparam(2)))
set(handles.sigma,'string',num2str(initparam(3)))
set(handles.offset,'string',num2str(initparam(4)))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


set(gcf,'CloseRequestFcn',{@exitmenu_Callback,handles}); % Change the default value of internal function CloseRequestFcn to call exit_Callback function.
%In this way when user close the windows pressing the X in the top
%right corner, the program first disconnect the server.


% Choose default command line output for autocorrelatorGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes autocorrelatorGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = autocorrelatorGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function position_Callback(hObject, eventdata, handles)
% hObject    handle to position (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of position as text
%        str2double(get(hObject,'String')) returns contents of position as a double


% --- Executes during object creation, after setting all properties.
function position_CreateFcn(hObject, eventdata, handles)
% hObject    handle to position (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function target_Callback(hObject, eventdata, handles)
% hObject    handle to target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of target as text
%        str2double(get(hObject,'String')) returns contents of target as a double


% --- Executes during object creation, after setting all properties.
function target_CreateFcn(hObject, eventdata, handles)
% hObject    handle to target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function destination_Callback(hObject, eventdata, handles)
% hObject    handle to destination (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of destination as text
%        str2double(get(hObject,'String')) returns contents of destination as a double


% --- Executes during object creation, after setting all properties.
function destination_CreateFcn(hObject, eventdata, handles)
% hObject    handle to destination (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function velocity_Callback(hObject, eventdata, handles)
% hObject    handle to velocity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of velocity as text
%        str2double(get(hObject,'String')) returns contents of velocity as a double

vel = get(handles.velocity,'string');
if str2double(vel) < 1e-3
    set(handles.velocity,'string','0.001');
    vel = get(handles.velocity,'string');
elseif str2double(vel) > 4000
    set(handles.velocity,'string','4000');
    vel = get(handles.velocity,'string');
else
end

msg = {['SENDRCV ' handles.termchar ' 1VA' num2str(str2double(vel)/1000)]}; % Creates a command to set the velocity
[handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function velocity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to velocity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function acceleration_Callback(hObject, eventdata, handles)
% hObject    handle to acceleration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of acceleration as text
%        str2double(get(hObject,'String')) returns contents of acceleration as a double

acc = get(handles.acceleration,'string');
if str2double(acc) < 1e-3
    set(handles.acceleration,'string','0.001');
    acc = get(handles.acceleration,'string');
elseif str2double(acc) > 2000
    set(handles.acceleration,'string','2000');
    acc = get(handles.acceleration,'string');
else
end

msg = {['SENDRCV ' handles.termchar ' 1AC' num2str(str2double(acc)/1000)]}; % Creates a command to set the acceleration
[handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function acceleration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to acceleration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in go.
function go_Callback(hObject, eventdata, handles)
% hObject    handle to go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.kill,'Value',0); % Set the kill button in "release" state

if get(handles.home,'Value') == 1 % Check the status of the Home button
    destum = '0'; % If Home was pressed set destum to 0
    set(handles.home,'Value',0); % Change the status back to unpressed
    set(handles.operation,'Value',1); % Set Operation to destination
    set(handles.direction,'Enable','off') % Disable direction
else
    destum = get(handles.destination,'String'); % Get destination from panel
end

if isempty(destum) ~= 1 % If destum is 0 (not destination set) do nothing
    set(handles.go,'Enable','off'); % Disable go button
    set(handles.home,'Enable','off'); % Disable home button
    msg = {['SENDRCV ' handles.termchar ' 1TP']}; % Creates the command to check the position
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
    answer = char(handles.answer);
    posmm = answer(4:end-4);
    set(handles.position,'string',num2str(str2double(posmm)*1000,'%6.1f'));

    if get(handles.operation,'Value') == 2 % If Operation mode is displacement (relative move)
        
        if str2double(get(handles.destination,'String')) < 0 % If destination is negative convert to positive. No negative numbers are allowed in displacement operation
            tempvalue = get(handles.destination,'String');
            positive = tempvalue(2:end);
            set(handles.destination,'String',positive);
        end
        
        if get(handles.direction,'Value') == 1 % Get direction (Forward)
            posumnew = num2str(str2double(posmm)*1000+str2double(get(handles.destination,'String')),'%6.1f'); % If forward do position + displacement
            if str2double(posumnew) > handles.upperlimit*1000
                uiwait(warndlg('The requested position is beyond the limits. Command ignored.','Limits warning','modal'))
            else
                set(handles.target,'String',posumnew); % Set target as the posumnew
                
                msg = {['SENDRCV ' handles.termchar ' 1PR' num2str(str2double(get(handles.destination,'string'))/1000)]}; % Creates the command to move relative
                [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,false,handles.input_socketconex);

                msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
                [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                
                if isempty(handles.answer)
                    ispositionreached = '000000000';
                else
                ispositionreached=char(handles.answer);
                end

                i=1;
                %Tests whether the linear activator reached the home position. If not wait and try again.
                while (i<= handles.MAXCHECKS && ~isequal(ispositionreached(8:9),'33'))
                    if get(handles.kill,'Value') == 1 % Leave the loop if kill button is pressed
                        i= handles.MAXCHECKS;
                        msg = {['SENDRCV ' handles.termchar ' 1ST']}; % Creates the command to stop the motor
                        [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);                    
                    end

                    msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
                    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                    if isempty(handles.answer)
                        ispositionreached = '000000000';
                    else
                        ispositionreached=char(handles.answer);
                    end

                    msg = {['SENDRCV ' handles.termchar ' 1TP']}; % Creates the command to check the position
                    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                    answer = char(handles.answer);
                    posmm = answer(4:end-4);
                    set(handles.position,'string',num2str(str2double(posmm)*1000,'%6.1f'));
                    i=i+1;
                end
            end

        else % Backward
            posumnew = num2str(str2double(posmm)*1000-str2double(get(handles.destination,'String')),'%6.1f'); % If backward do position - displacement
            if str2double(posumnew) < handles.lowerlimit*1000
                uiwait(warndlg('The requested position is beyond the limits. Command ignored.','Limits warning','modal'))
            else
                set(handles.target,'String',posumnew); % Set target as the posumnew
                
                msg = {['SENDRCV ' handles.termchar ' 1PR-' num2str(str2double(get(handles.destination,'string'))/1000)]}; % Creates the command to move relative
                [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,false,handles.input_socketconex);

                msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
                [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

                if isempty(handles.answer)
                    ispositionreached = '000000000';
                else
                ispositionreached=char(handles.answer);
                end
                
                i=1;
                %Tests whether the linear activator reached the home position. If not wait and try again.
                while (i<= handles.MAXCHECKS && ~isequal(ispositionreached(8:9),'33'))
                    if get(handles.kill,'Value') == 1 % Leave the loop if kill button is pressed
                        i= handles.MAXCHECKS;
                        msg = {['SENDRCV ' handles.termchar ' 1ST']}; % Creates the command to stop the motor
                        [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);                    
                    end

                    msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
                    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                    if isempty(handles.answer)
                       ispositionreached = '000000000';
                    else
                        ispositionreached=char(handles.answer);
                    end

                    msg = {['SENDRCV ' handles.termchar ' 1TP']}; % Creates the command to check the position
                    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                    answer = char(handles.answer);
                    posmm = answer(4:end-4);
                    set(handles.position,'string',num2str(str2double(posmm)*1000,'%6.1f'));
                    i=i+1;
                end
            end
        end
        
    else % operation mode is Absolute
        
        if str2double(destum) > handles.upperlimit*1000 || str2double(destum) < handles.lowerlimit*1000
            uiwait(warndlg('The requested position is beyond the limits. Command ignored.','Limits warning','modal'))
        else
            set(handles.target,'String',destum); % Copy destination in target panel
            posmm = num2str(str2double(get(handles.target,'string'))/1000);
            msg = {['SENDRCV ' handles.termchar ' 1PA' posmm]}; % Creates the command to move absolute
            [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,false,handles.input_socketconex);
            
            msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
            [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);

            ispositionreached=char(handles.answer);

            i=1;
            %Tests whether the linear activator reached the home position. If not wait and try again.
            while (i<= handles.MAXCHECKS && ~isequal(ispositionreached(8:9),'33'))
                if get(handles.kill,'Value') == 1 % Leave the loop if kill button is pressed
                    i= handles.MAXCHECKS;
                    msg = {['SENDRCV ' handles.termchar ' 1ST']}; % Creates the command to check the position
                    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);                    
                end

                msg = {['SENDRCV ' handles.termchar ' ' '1TS']}; % Creates a command to get positioner error and controller state
                [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                ispositionreached=char(handles.answer);

                msg = {['SENDRCV ' handles.termchar ' 1TP']}; % Creates the command to check the position
                [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
                answer = char(handles.answer);
                posmm = answer(4:end-4);
                set(handles.position,'string',num2str(str2double(posmm)*1000,'%6.1f'));
                i=i+1;
            end
        end
    end
    
    msg = {['SENDRCV ' handles.termchar ' 1TP']}; % Creates the command to check the position
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
    answer = char(handles.answer);
    posmm = answer(4:end-4);
    set(handles.position,'string',num2str(str2double(posmm)*1000,'%6.1f'));

    set(handles.go,'Enable','on'); % Enable go button
    set(handles.home,'Enable','on'); % Enable go button

end

guidata(hObject, handles)


% --- Executes on button press in kill.
function kill_Callback(hObject, eventdata, handles)
% hObject    handle to kill (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in home.
function home_Callback(hObject, eventdata, handles)
% hObject    handle to home (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

go_Callback(hObject, eventdata, handles); % Go to go_Callback function


% --- Executes on selection change in direction.
function direction_Callback(hObject, eventdata, handles)
% hObject    handle to direction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns direction contents as cell array
%        contents{get(hObject,'Value')} returns selected item from direction


% --- Executes during object creation, after setting all properties.
function direction_CreateFcn(hObject, eventdata, handles)
% hObject    handle to direction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in operation.
function operation_Callback(hObject, eventdata, handles)
% hObject    handle to operation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns operation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from operation


% --- Executes during object creation, after setting all properties.
function operation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to operation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function file_Callback(hObject, eventdata, handles)
% hObject    handle to file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function step_Callback(hObject, eventdata, handles)
% hObject    handle to step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of step as text
%        str2double(get(hObject,'String')) returns contents of step as a double
update_timewindow(handles);
set(handles.stepfs,'String', [num2str(1000*pos2del(str2double(get(hObject,'String')))) ' fs']);

% --- Executes during object creation, after setting all properties.
function step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numstep_Callback(hObject, eventdata, handles)
% hObject    handle to numstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numstep as text
%        str2double(get(hObject,'String')) returns contents of numstep as a double
update_timewindow(handles);


% --- Executes during object creation, after setting all properties.
function numstep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in scanbutton.
function scanbutton_Callback(hObject, eventdata, handles)
% hObject    handle to scanbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cla;
set(handles.scanbutton,'enable','off')

step = str2double(get(handles.step,'string'));
numsteps = str2double(get(handles.numstep,'string'));

posp = 0:step:numsteps*step/2;
R = rem(numsteps,2);
if R
    posn = -fliplr(posp(2:end));
    pos = [posn posp];
else
    posn = -fliplr(posp(2:end-1));
    pos = [posn posp];
end

set(handles.operation,'Value',2)
handles.actualpos = zeros(1,numel(pos));
handles.delay = zeros(1,numel(pos));
handles.signal = zeros(1,numel(pos));

for i = 1:numel(pos)

    if i == 1
        set(handles.destination,'string',num2str(pos(1),'%6.1f'))
        set(handles.direction,'Value',2)
        refpos = str2double(get(handles.position,'string'));
    else
        set(handles.destination,'string',num2str(step,'%6.1f'))
        set(handles.direction,'Value',1)
    end

    %stop scan on kill, must be directly before go_Callback()
    if get(handles.kill,'Value')==1
        break
    end
    go_Callback(hObject, eventdata, handles); % Go to go_Callback function
    
    handles.actualpos(i) = str2double(get(handles.position,'string')) - refpos;
    handles.delay(i) = pos2del(handles.actualpos)

    if handles.powermeter == 1
    
        msg = {'SENDRCV GETPOWER'}; % Creates a command to get power from powermeter
        [handles.answer handles.input_socketthorlabs] = thorlabs(handles.computeripthorlabs,handles.thorlabssocketport,msg,handles.input_socketthorlabs);
        [powerdimless remain] = strtok(char(handles.answer));
        handles.signal(i) = str2double(powerdimless);

        [number expon] = strtok(num2str(str2double(powerdimless),'%5.2e'),'e');

        switch expon
            case 'e-09'
                symbol = 'nW';
                factor = 1e9;
            case 'e-06'
                symbol = [char(181) 'W'];
                factor = 1e6;
            case 'e-03'
                symbol = 'mW';
                factor = 1e3;
            case 'e+0'
                symbol = 'W';
                factor = 1;
            otherwise
                symbol = [expon 'W'];
                factor = 1/eval(['1' expon]);
        end

        powerstr = num2str(str2double(powerdimless)*factor,'%5.3f');

        set(handles.powerind,'string',[powerstr ' ' symbol])
        
        
    elseif handles.DAQ == 1

%         msg = {['ANALOGINTR ' handles.devname(end) ' 23 10']}; % Creates a command to read photodiodes
%         msg = {['ANALOGIN ' handles.devname(end) ' 23']}; % Creates a command to read photodiodes
%         [handles.answer handles.input_socketNIDAQ] = NIDAQ(handles.computeripNIDAQ,handles.NIDAQsocketport,msg,handles.input_socketNIDAQ); % Send the commands
%         handles.photodiodes = textscan(char(handles.answer),'%f %f');
        
        for j = 1:numel(handles.photodiodes)
            handles.photonum(j) = handles.photodiodes{j};
        end
        handles.signal(i) = handles.photonum(1)/handles.photonum(2);
    end
    
    hold on
    plot(handles.actualpos(1:i),handles.signal(1:i),'.')
    xlim([pos(1) pos(end)])
    hold off
    
end

%move stage back to reference position
set(handles.destination,'string',num2str(refpos,'%6.1f'))
set(handles.operation,'Value',1)
go_Callback(hObject, eventdata, handles); % Go to go_Callback function

%fit curve
if get(handles.fitbox,'Value') == 1
    ffit_Callback(hObject, eventdata, handles);
end

if get(handles.savebox,'value') == 1
    savebutton_Callback(hObject, eventdata, handles);
%     [status result] = system(['dir ' get(handles.savingfolder,'string')]);
%     if isempty(get(handles.savingfolder,'string')) || status == 1
%         ButtonName = questdlg('Wrong or empty path', 'Path warning', 'Cancel', 'Select', 'Cancel');
%         
%         switch ButtonName
%             case 'Cancel'
%                 
%             case 'Select'
%                 dirname = uigetdir('c:\', 'Select folder');
%                 set(handles.savingfolder,'string',dirname)
%                 savescan(handles);
%         end
%     else
%         savescan(handles);
%     end
end

set(handles.scanbutton,'enable','on')
guidata(hObject, handles)


% --- Executes on button press in ffit.
function ffit_Callback(hObject, eventdata, handles)
% hObject    handle to ffit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

functions = get(handles.functionsel,'string');
type = char(functions(get(handles.functionsel,'Value')));
handles.initparam(1) = str2double(get(handles.amplitude,'string'));
handles.initparam(2) = str2double(get(handles.center,'string'));
handles.initparam(3) = str2double(get(handles.sigma,'string'));
handles.initparam(4) = str2double(get(handles.offset,'string'));

[handles.func fwhm handles.bestparam] = fitfunc(handles.actualpos,handles.signal,handles.initparam,type);

set(handles.amplitude,'string',num2str(handles.bestparam(1)))
set(handles.center,'string',num2str(handles.bestparam(2)))
set(handles.sigma,'string',num2str(handles.bestparam(3)))
set(handles.offset,'string',num2str(handles.bestparam(4)))

plot(handles.actualpos,handles.signal,'.',handles.actualpos,handles.func,'Color','b') % Plot Int vs pos (whole array)
xlim([handles.actualpos(1) handles.actualpos(end)])
xlabel('Position (um)')
ylabel('Power (W)')

set(handles.sig_text_um,'string',num2str(handles.bestparam(3)))
set(handles.sig_text_ps,'string',num2str(pos2del(handles.bestparam(3))))

if strcmpi('Gaussian',type)
    correctionfactor = sqrt(2); % Autocorrelation trace is longer that the pulse by this factor
    acfwhm = 2*sqrt(2*log(2))*pos2del(handles.bestparam(3));
elseif strcmpi('Sech2',type)
    correctionfactor = 1.54; % Autocorrelation trace is longer that the pulse by this factor
    acfwhm = 1.76*pos2del(handles.bestparam(3));
else
    acfwhm=0;
    correctionfactor= 1;
end
fwhm = acfwhm/correctionfactor;
set(handles.fwhm_text_ps,'string',num2str(fwhm))
set(handles.acfwhm_text_ps,'string',num2str(acfwhm))

guidata(hObject, handles)


% --- Executes on button press in savebox.
function savebox_Callback(hObject, eventdata, handles)
% hObject    handle to savebox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of savebox

% --- Executes on button press in fitbox.
function fitbox_Callback(hObject, eventdata, handles)
% hObject    handle to fitbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fitbox



function savingfolder_Callback(hObject, eventdata, handles)
% hObject    handle to savingfolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of savingfolder as text
%        str2double(get(hObject,'String')) returns contents of savingfolder as a double


% --- Executes during object creation, after setting all properties.
function savingfolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to savingfolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function amplitude_Callback(hObject, eventdata, handles)
% hObject    handle to amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amplitude as text
%        str2double(get(hObject,'String')) returns contents of amplitude as a double


% --- Executes during object creation, after setting all properties.
function amplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function center_Callback(hObject, eventdata, handles)
% hObject    handle to center (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of center as text
%        str2double(get(hObject,'String')) returns contents of center as a double


% --- Executes during object creation, after setting all properties.
function center_CreateFcn(hObject, eventdata, handles)
% hObject    handle to center (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sigma_Callback(hObject, eventdata, handles)
% hObject    handle to sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sigma as text
%        str2double(get(hObject,'String')) returns contents of sigma as a double


% --- Executes during object creation, after setting all properties.
function sigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function offset_Callback(hObject, eventdata, handles)
% hObject    handle to offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of offset as text
%        str2double(get(hObject,'String')) returns contents of offset as a double


% --- Executes during object creation, after setting all properties.
function offset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in functionsel.
function functionsel_Callback(hObject, eventdata, handles)
% hObject    handle to functionsel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns functionsel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from functionsel

if get(handles.functionsel,'Value') == 1
    set(handles.functiontext,'string','a(1)*exp(-(x-a(2))^2/(2*a(3)^2))+a(4)')
else
    set(handles.functiontext,'string','a(1)*sech((x-a(2))/a(3))^2 + a(4)')
end

% --- Executes during object creation, after setting all properties.
function functionsel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to functionsel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function wavelength_Callback(hObject, eventdata, handles)
% hObject    handle to wavelength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wavelength as text
%        str2double(get(hObject,'String')) returns contents of wavelength as a double

msg = {['SENDRCV SETWAVE ' get(handles.wavelength,'string')],'SENDRCV GETWAVE'}; % Creates a command to open the serial port
[handles.answer handles.input_socketthorlabs] = thorlabs(handles.computeripthorlabs,handles.thorlabssocketport,msg,handles.input_socketthorlabs);

set(handles.wavelength,'string',strtok(char(handles.answer(2))))

% --- Executes during object creation, after setting all properties.
function wavelength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wavelength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function filenametext_Callback(hObject, eventdata, handles)
% hObject    handle to filenametext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filenametext as text
%        str2double(get(hObject,'String')) returns contents of filenametext as a double


% --- Executes during object creation, after setting all properties.
function filenametext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filenametext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function exitmenu_Callback(hObject, eventdata, handles)
% hObject    handle to exitmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    msg = {'CLOSE'}; % Creates a command to close the serial port for Conex
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
    
    msg = {'QUIT'}; % Creates a command to quit the serial port for Conex
    [handles.answer handles.input_socketconex] = conex(handles.computeripconex,handles.serialserversocketport,msg,true,handles.input_socketconex);
    
    msg = {'CLOSE'}; % Creates a command to close communication with Thorlabs powermeter
    [handles.answer handles.input_socketthorlabs] = thorlabs(handles.computeripthorlabs,handles.thorlabssocketport,msg,handles.input_socketthorlabs);
    
    msg = {'QUIT'}; % Creates a command to quit communication with Thorlabs powermeter
    [handles.answer handles.input_socketthorlabs] = thorlabs(handles.computeripthorlabs,handles.thorlabssocketport,msg,handles.input_socketthorlabs);

    %msg = {'QUIT'}; % Creates a command to quit communication with NIDAQ
    %[handles.answer handles.input_socketNIDAQ] = thorlabs(handles.computeripNIDAQ,handles.NIDAQsocketport,msg,handles.input_socketNIDAQ);
catch err
    warning('Program did not shut down properly... fix it, dumbass!')
    display(err)
    display(err.stack)
end
system('taskkill /FI "WINDOWTITLE eq conex*" > nul');

system('taskkill /FI "WINDOWTITLE eq thorlabs*" > nul');

%system('taskkill /FI "WINDOWTITLE eq NIDAQ*" > nul');

delete(gcf); % Exit the program


% --- Executes on selection change in irvisuv.
function irvisuv_Callback(hObject, eventdata, handles)
% hObject    handle to irvisuv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns irvisuv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from irvisuv

if get(handles.irvisuv,'value') == 1
    handles.powermeter = 1;
    handles.DAQ = 0;
else
    handles.powermeter = 0;
    handles.DAQ = 1;
end

guidata(hObject, handles);
    

% --- Executes during object creation, after setting all properties.
function irvisuv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to irvisuv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in savebutton.
function savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 [status result] = system(['dir ' '"' get(handles.savingfolder,'string') '"']);
 if isempty(get(handles.savingfolder,'string')) || status == 1
     ButtonName = questdlg('Wrong or empty path', 'Path warning', 'Cancel', 'Select', 'Cancel');
     
     switch ButtonName
         case 'Cancel'
             
         case 'Select'
             dirname = uigetdir(pwd, 'Select folder');
             set(handles.savingfolder,'string',dirname)
             try
                 savescan(handles);
             catch
                 errordlg('Error saving file');
             end
     end
 else
     try
         savescan(handles);
     catch err
         display(err)
         errordlg('Error saving file');
     end
 end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dirname = uigetdir(pwd, 'Select folder');
set(handles.savingfolder,'string',dirname);


function time = pos2del(x)
c = 299.792458; % in um/ps
aoi = 15;
time = 2*x*cos(aoi*pi()/180)/c;

function update_timewindow(handles)
dx = str2double((get(handles.step, 'String')));
N = str2double((get(handles.numstep, 'String')));
t_time = pos2del(N*dx);
set(handles.windowum, 'String', num2str(N*dx));
set(handles.windowps, 'String', [num2str(t_time) ' ps']);


% --- Executes during object creation, after setting all properties.
function windowum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
