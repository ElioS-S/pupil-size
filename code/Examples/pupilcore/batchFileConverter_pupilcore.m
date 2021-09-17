function batchFileConverter_pupilcore()
% batchFileConverter_pupilcore Example of how to convert pupilcore files to MATLAB.
%
%   This function is specifically written for the accompanying dataset, use
%   it only as a guide on how to implement the pupilcoreDataConverter function
%   and the RawFileModel class.to convert your files.
%   
%   Written by Shu Sakamoto (mosh-shu.com), 20210917
%--------------------------------------------------------------------------


%% Process Directory:

% Get files:
sourceFolderName = './rawData/';
destFolderName   = './matlabData/';
rawFiles         = dir([sourceFolderName 'subj*']);

% Process subset of files:
nFiles  = length(rawFiles);

% Disp file information:
printToConsole('L1');
printToConsole(1, 'Processing %i files...\n', nFiles);

% Loop through files:
for fileIndx = 1:nFiles
    rawFolderName = [sourceFolderName rawFiles(fileIndx).name];
    matFilename = [destFolderName rawFiles(fileIndx).name '.mat'];
    pcDataConverter(rawFolderName, matFilename)
    printToConsole(2, 'Done with file %i.\n',fileIndx);
end
printToConsole(2, 'Done with folder.\n');
printToConsole('L2');

end


%% edfDataConverter Function:

function pcDataConverter(rawFolderName,matFilename)
% pcDataConverter Converts a single pupilcore csv file to a matlab file.

% Read raw csv file:

rawFilename = [rawFolderName '/pupil_positions.csv'];
infoFilename = [rawFolderName '/export_info.csv'];
eventFilename = [rawFolderName '/annotations.csv'];
blinkFilename = [rawFolderName, '/blinks.csv'];

rawcsv = tdfread(rawFilename, ',');
infocsv = tdfread(infoFilename, ',');
eventcsv = tdfread(eventFilename, ',');
blinkcsv = tdfread(blinkFilename, ',');

% Get diameter: only use 3d estimated data
is3d = contains(cellstr(rawcsv.method), 'pye3d');

isL = ~~rawcsv.eye_id & is3d;
isR = ~rawcsv.eye_id & is3d;

L = rawcsv.diameter_3d(isL);
R = rawcsv.diameter_3d(isR);

% Get time: t_msL and t_msR are almost identical
tmp = strsplit(infocsv.value(7, :));
zeroTime_sec = str2double(tmp{1});
zeroTime_ms = zeroTime_sec*1000;

t_secL = rawcsv.pupil_timestamp(isL);
t_secR = rawcsv.pupil_timestamp(isR);
t_msL = (t_secL - zeroTime_sec)*1000;
t_msR = (t_secR - zeroTime_sec)*1000;
t_ms = t_msL; % t_msL and t_msR are almost identical
% plot(t_msL, t_msR); % confirm the identical-ness

% Remove the 0 samples:
L(L==0) = NaN;
R(R==0) = NaN;

% Remove blinks
isblinkL = false(size(L));
isblinkR = false(size(R));

blinkstarts_ms = (blinkcsv.start_timestamp - zeroTime_sec)*1000;
blinkends_ms = (blinkcsv.end_timestamp - zeroTime_sec)*1000;
for blinkIdx = 1:size(blinkstarts_ms, 1)
    blinkstart_ms = blinkstarts_ms(blinkIdx);
    blinkend_ms = blinkends_ms(blinkIdx);
    blinklocL = blinkstart_ms<t_msL & t_msL<blinkend_ms;
    blinklocR = blinkstart_ms<t_msR & t_msR<blinkend_ms;
    isblinkL(blinklocL) = true;
    isblinkR(blinklocR) = true;
end
L(isblinkL) = NaN;
R(isblinkR) = NaN;

% Process events (only extract relevant events):
eventData.t    = eventcsv.timestamp - zeroTime_sec;
eventData.name = cellstr(eventcsv.label);

% Find trials start and end times:
segmentStart   = eventData.t(1:2:end);
segmentEnd     = eventData.t(2:2:end);
% get segment names
segmentName = erase(eventData.name(1:2:end), '_start');

% Make table
segmentData = table(...
    segmentStart,segmentEnd,segmentName);
segmentData.Properties.VariableDescriptions = {...
    'Start of segment.'...
    'End of segment.'...
    'Name of segment.'};
segmentData.Properties.VariableUnits = {'s' 's' '-'};

% Build RawFileModel instance, which saves the data to a mat file that is
% compatible with the other data models:
diameterUnit = 'mm';
diameter     = struct('t_ms',t_ms,'L',L,'R',R);
RawFileModel(diameterUnit,diameter,segmentData,zeroTime_ms,matFilename);
            
end











