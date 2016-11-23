function savescan(handles)

if exist('handles.func') ~= 0
    all = [handles.actualpos; handles.signal; handles.func]';
else
    all = [handles.actualpos; handles.signal]';
end

fullfolder = get(handles.savingfolder,'string');

if isempty(get(handles.filenametext,'string'))
    set(handles.filenametext,'string','autocorr1.dat')
end

fullpath = [fullfolder '\' get(handles.filenametext,'string')];

[status result] = system(['dir ' fullpath]);
numname = [];

if status == 1
    fullpathup = fullpath;
else
    [pathstr,name,ext] = fileparts(fullpath);
    for j = 1:numel(name)
        if ~isnan(str2double(name(numel(name)+1-j)))
            numname = [name(numel(name)+1-j) numname];
        else
            break;
        end
    end

    num = str2double(numname);

    name = [name(1:numel(name)-j+1) num2str(num+1)];

    fullpathup = [pathstr '\' name ext];
    [status result] = system(['dir ' fullpathup]);
end

[pathstr,name,ext] = fileparts(fullpathup);

set(handles.filenametext,'string',[name ext])
save(fullpathup, 'all', '-ascii', '-tabs');

msgbox('Save successful', 'Saving scan');