function batchFileConverter_Dataset1()
% batchFileConverter_Dataset1 Example of how to converts EDF files to MATLAB.
%
%   This function is specifically written for the accompanying dataset, use
%   it only as a guide on how to implement the edfDataConverter function
%   and the RawFileModel class.to convert your files.
%
%--------------------------------------------------------------------------
%
%   This code is part of the supplement material to the article:
%
%    Preprocessing Pupil Size Data. Guideline and Code.
%     Mariska Kret & Elio Sjak-Shie. 2018.
%
%--------------------------------------------------------------------------
%
%     Pupil Size Preprocessing Code (v1.1)
%      Copyright (C) 2018  Elio Sjak-Shie
%       E.E.Sjak-Shie@fsw.leidenuniv.nl.
%
%     This program is free software: you can redistribute it and/or
%     modify it under the terms of the GNU General Public License as
%     published by the Free Software Foundation, either version 3 of
%     the License, or (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%     General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see
%     <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------


%% Process Directory:

% Get files:
sourceFolderName = './rawData/';
destFolderName   = './matlabData/';
rawFiles         = dir([sourceFolderName '*.edf']);

% Process subset of files:
nFiles  = length(rawFiles);

% Disp file information:
printToConsole('L1');
printToConsole(1, 'Processing %i files...\n', nFiles);

% Loop through files:
for fileIndx = 1:nFiles
    edfDataConverter([sourceFolderName rawFiles(fileIndx).name]...
        ,[destFolderName rawFiles(fileIndx).name(1:end-4) '.mat'])
    printToConsole(2, 'Done with file %i.\n',fileIndx);
end
printToConsole(2, 'Done with folder.\n');
printToConsole('L2');

end


%% edfDataConverter Function:

function edfDataConverter(edfFilename,matFilename)
% edfDataConverter Converts a single edf file to a matlab file.

% Read raw edf file:
hMex   = @edfmex; %#ok<NASGU>
[~,rawEDF] = evalc(['edfmex(''' edfFilename ''');']);

t_ms        = double(rawEDF.FSAMPLE.time)';
zeroTime_ms = t_ms(1);
t_ms        = (t_ms - zeroTime_ms);
L_raw           = double(rawEDF.FSAMPLE.pa(1,:)');
R_raw           = double(rawEDF.FSAMPLE.pa(2,:)');

% Only keep the correct eye, and label it the left for convenience:
if all(L_raw == intmin('int16'))
    L = R_raw;
    curEye = 'right';
else
    L = L_raw;
    curEye = 'left';
end

% Remove the 0 samples:
L(L==0) = NaN;

% Process events (only extract relevant events):
evtRows = arrayfun(@(f) ~isempty(f.message),rawEDF.FEVENT);
eventData.t    = (double(vertcat(rawEDF.FEVENT(evtRows).sttime))...
    -zeroTime_ms)/1000;
eventData.name = {rawEDF.FEVENT(evtRows).message}';

% Find trials start and end times:
trailStartRows = find(strcmp(eventData.name,'pictureTrial_Start'));
assert(length(trailStartRows)==36);
segmentStart   = eventData.t(trailStartRows);
segmentEnd     = eventData.t(trailStartRows+9);

% Extract trial metadata:
trialNum = regexp(eventData.name...
    ,'!V TRIAL_VAR trial (\d{2,3})','tokens','once');
assert(isequal(find(~cellfun(@isempty,trialNum)),trailStartRows+5))
trial = str2double([trialNum{:}]');

% Extract CA metadata:
trialCA = regexp(eventData.name...
    ,'!V TRIAL_VAR CA (\d|?)','tokens','once');
assert(isequal(find(~cellfun(@isempty,trialCA)),trailStartRows+7))
CA = str2double([trialCA{:}]');

% Extract Condition metadata:
trialCondition = regexp(eventData.name...
    ,'!V TRIAL_VAR Condition (\d)','tokens','once');
assert(isequal(find(~cellfun(@isempty,trialCondition)),trailStartRows+8))
Condition = str2double([trialCondition{:}]');

% Extract picture metadata:
trialPicture = regexp(eventData.name...
    ,'!V TRIAL_VAR picture (.)+$','tokens','once');
assert(isequal(find(~cellfun(@isempty,trialPicture)),trailStartRows+6))
picture = [trialPicture{:}]';

% Make table:
segmentName  = strcat('pictureSeq_'...
    ,strrep(cellstr(num2str((1:36)')),' ','0'));
SegmentSource      = segmentName;
[~,justFileName,~] = fileparts(edfFilename);
SegmentSource(:)   = {justFileName};
fileType           = SegmentSource;
fileType(:)        = regexp(edfFilename...
    ,'.+(F|B|iCB1|iCB2).edf','tokens','once');
eyeUsed           = segmentName;
eyeUsed(:)        = {curEye};
segmentData = table(...
    segmentStart,segmentEnd,segmentName,SegmentSource...
    ,fileType,trial,CA,Condition,picture,eyeUsed);

% Build RawFileModel instance, which saves the data to a mat file that is
% compatible with the other data models:
diameterUnit = 'px';
diameter     = struct('t_ms',t_ms,'L',L,'R',[]);
RawFileModel(diameterUnit,diameter,segmentData...
                ,zeroTime_ms,matFilename);
            
end











