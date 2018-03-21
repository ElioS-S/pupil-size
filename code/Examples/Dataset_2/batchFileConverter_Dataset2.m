function batchFileConverter_Dataset2()
%  batchFileConverter_Dataset2 Example script showing gazedata conversion.
%
%   This function is specifically written for the accompanying dataset, use
%   it only as a guide on how to convert .gazedata files into compatible
%   .mat files using the RawFileModel class.
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
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or (at
%     your option) any later version.
%
%     This program is distributed in the hope that it will be useful, but
%     WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%     General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------


%% Process Directory:

% Get files:
sourceFolderName = './rawData/';
destFolderName   = './matlabData/';
rawFiles         = dir([sourceFolderName '*.gazedata']);

% Process subset of files:
nFiles  = length(rawFiles);

% Disp file information:
printToConsole('L1');
printToConsole(1, 'Processing %i files...\n', nFiles);

% Loop through files:
for fileIndx = 1:nFiles
    fileConverter([sourceFolderName rawFiles(fileIndx).name]...
        ,[destFolderName rawFiles(fileIndx).name(1:end-8) 'mat'])
    printToConsole(2, 'Done with file %i.\n',fileIndx);
end
printToConsole(2, 'Done with folder.\n');
printToConsole('L2');

end


%% edfDataConverter Function:

function fileConverter(gazeDataFilename,matFilename)
% edfDataConverter Converts a single edf file to a matlab file.

[dataArray,headers] = readGazedata(gazeDataFilename);

% Process timestamps:
timeColName = 'TETTime';
timeColIndx = find(strcmp(headers,timeColName),1);
assert(~isempty(timeColIndx)...
    ,['Cannot find a column named '...
    '''Recording timestamp''']);
t_ms        = dataArray{timeColIndx};
zeroTime_ms = t_ms(1);
t_ms        = (t_ms - zeroTime_ms);

% Process diameters and remove useless samples:
L          = dataArray{strcmp(headers,'DiameterPupilLeftEye')};
R          = dataArray{strcmp(headers,'DiameterPupilRightEye')};
L_Validity = dataArray{strcmp(headers,'ValidityLeftEye')};
R_Validity = dataArray{strcmp(headers,'ValidityRightEye')};
okValidity = [0 1];
L(~ismember(L_Validity,okValidity)) = NaN;
R(~ismember(R_Validity,okValidity)) = NaN;
L(L<0) = NaN;
R(R<0) = NaN;

% Define segments:
TrialId = dataArray{strcmp(headers,'TrialId')};
[trialNum,trialStartRow,~] = unique(TrialId,'stable');
segmentStart   = t_ms(trialStartRow)/1000;
segmentEnd     = t_ms([trialStartRow(2:end);end]-1)/1000;
segmentName    = strcat('Trial_'...
    ,strrep(cellstr(num2str(trialNum)),' ','0'));

% For the sake of example, group the trials into blocks and add those as
% segments:
assert(length(segmentName)==72);
segmentName  = [segmentName;strcat('Block_',cellstr(num2str((1:4)')))];
segmentStart = [segmentStart;segmentStart(1:18:end)];
segmentEnd   = [segmentEnd;segmentEnd(18:18:end)];

SegmentSource  = segmentName;
[~,justName,~] = fileparts(gazeDataFilename);
SegmentSource(:) = {justName};
segmentData = table(...
    segmentStart,segmentEnd,segmentName,SegmentSource);
segmentData.Properties.VariableDescriptions = {...
    'Start of segment.'...
    'End of segment.'...
    'Name of segment.'...
    'Source of segment.'};
segmentData.Properties.VariableUnits = {'s' 's' '-' '-'};

% Build RawFileModel instance, which saves the data to a mat file that is
% compatible with the other data models:
diameterUnit = 'mm';
diameter     = struct('t_ms',t_ms,'L',L,'R',R);
RawFileModel(diameterUnit,diameter,segmentData...
                ,zeroTime_ms,matFilename);

end


%==========================================================================
function [dataArray,headers] = readGazedata(fn)
% Reads E-Prime gazedata file.

% Assume that the first few data columns in the gazedata file are numberic:
nNumericDataColumns = 24;

% Open file:
fileID         = fopen(fn,'r');
fileCloser     = onCleanup(@() fclose(fileID));
if fileID ~= -1
    
    % Get the headers from the first row:
    headerCell   = textscan(fileID,'%[^\n\r]',1);
    
    % Use regexp to parse the headers (new matlab alternative: headers =
    % strsplit(headerCell{1}{1},'\t');):
    headers     = regexp(headerCell{1}{1},'\w+','match');
    assert(length(headers)>=nNumericDataColumns);
    dataArray      = textscan(fileID...
        ,[repmat('%f',1,nNumericDataColumns) ...
        repmat('%s',1,length(headers)-nNumericDataColumns)]...
        ,'Delimiter', '\t');
else
    dataArray = [];
    fprintf(2,'Error opening file!\n');
    return
end
clear fileCloser;
end








