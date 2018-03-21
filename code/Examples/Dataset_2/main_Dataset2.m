%--------------------------------------------------------------------------
%
%   This script shows the standard pupil size analysis pipeline, as applied
%   to a two-pupil dataset generated from by E-Prime and the Eye-Tracking
%   Extensions for Tobii.
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

% Housekeeping:
clc; clear;

% Add paths:
addpath(genpath('..\..\helperFunctions\'));
addpath('..\..\dataModels\');

% Check if the code needs to run in legacy mode (if MATLAB is older than
% v2013b and the 'table' datatype has not yet been introduced, a folder
% containing a table spoofer is added to the path, see
% ..\..\helperFunctions\LEGACY\):
legacyModeCheck();

% Convert files (to save time, comment the line below out if the gazedata
% files have already been converted to mat files):
batchFileConverter_Dataset2();

% Get files:
folderName       = './matlabData/';
rawFiles         = dir([folderName '*.mat']);
nFiles           = length(rawFiles);

% Display file information:
printToConsole('L1');
printToConsole(1, 'Found %i files...\n', nFiles);
printToConsole(2, 'Starting analysis pipeline...\n');
printToConsole('L2');

% Get settings the standard setttings:
customSettings   = PupilDataModel.getDefaultSettings();

% You can set the number of deviation filter passes by modifying the field
% below (set it to 0 to disable the filter completely, the default value
% is 4):
customSettings.raw.residualsFilter_passes            = 2;

% Additionally, you can customize the mad multipliers, which determine the
% acceptance thresholds, to increase the filter performance on your
% dataset:
customSettings.raw.residualsFilter_MadMultiplier     = 8; % default = 16
customSettings.raw.dilationSpeedFilter_MadMultiplier = 8; % default = 16

% Construct one PupilDataModel instance per file using the bacthConstructor
% method:
hPupilData = PupilDataModel.batchConstructor(...
    folderName,rawFiles,customSettings);


%% Filtering the Raw Data:
% Raw raw data contain samples that are either 'valid' or 'invalid'; the
% latter being the result of a measurement artifact or a physical
% disturbance, such as a blink. These invalid datapoints do not contain
% information that we want to carry into our interpolated smooth signal,
% and therefore need to be filtered out. This is done by the filterRawData
% method, which, through the steps described in the accompanying article,
% marks a subset of the raw samples as being 'valid'.

% Run standard pipeline:
hPupilData.filterRawData();


%% Interpolating and Filtering the Valid Samples:
% Once the valid samples are identified, they can be used to create a
% smooth high-resolution pupil size signal through interpolation and
% low-pass filtering, which is what the processValidSamples method does.

% Process the valid samples:
hPupilData.processValidSamples();


%% Analyze Processed Data:
% After processing the valid samples, the pupil size data must be analyzed
% per segment. These segments are defined in the hPupilData instance, see
% the RawFileModel documentationn for details. The analyzeSegments method
% analyzes either the sole available pupil, or both pupils and their mean,
% and horizontally concatenates the results, together with the segmentsData
% table, per PupilDataModel instance. The results are returned in a cell
% array.

% Get the analysis results, vertically concatenate them, and view the
% resulting master table:
results      = hPupilData.analyzeSegments();
PupilResults = vertcat(results{:});

% Take note of the table metadata, which describes the variables in the
% table:
printToConsole('L1');
printToConsole(1, 'Table Metadata:\n');
cellfun(@(name,unit,desc) ...
    fprintf('\n  > %s [%s]:\n   - %s\n',name,unit,desc)...
    ,PupilResults.Properties.VariableNames...
    ,PupilResults.Properties.VariableUnits...
    ,PupilResults.Properties.VariableDescriptions);
printToConsole(1, ['Tip: use ''writetable'' to save the table'...
    ' containing the variables described above as an Excel file.\n']);
printToConsole('L2');


%% Visualizing the Data:
% The PupilDataModel class can visualize its data via the plotData method,
% which can be called on a PupilDataModel array. Note that, if the
% keepFilterData flag was set to true, the intermediate filering steps will
% be plotted as well, which may be slow when plotting multiple objects.

% NOTE: plotting too many files may cause MATLAB to become unresponsive.

% Plotting:
hPupilData.plotData


%% Accessing Data:
% This sections shows how to access data saved in a PupilDataModel and
% ValidSampleModel instances.
%
% In this example, which is only meant to highlight handy MATLAB commands
% and syntax and doesn't reflect any meaningful analysis, the recording is
% split into the trials defined in the segmentData table. The pupil
% diameter signal inside those trials are then baseline corrected using the
% mean of the pupil diameter in the first 0.5 seconds of the trial. All
% trials are then plotted as superimposed curves.

% Get a handle to the desired data object:
hDataObj     = hPupilData(1);

% Let's analyze the mean pupil size signal generated from the data of both
% eyes:
hMeanDiaObj  = hDataObj.meanPupil_ValidSamples;

% Use all epochs:
segments2use = 1:72;

% Isolate which sections of the signal belong to which segments:
segmentSectionz = arrayfun(...
    ...
    @(segNum) ...
    (hMeanDiaObj.signal.t >= hDataObj.segmentsTable.segmentStart(segNum)...
    & hMeanDiaObj.signal.t < hDataObj.segmentsTable.segmentEnd(segNum))'...
    ...
    , segments2use, 'UniformOutput', false);

% Normalize the time and diameter signals of each segment, and output one
% timeseries per trial (as a cell array of 2 column--time and 
% diameter-matrices):
sectionedSegments = cellfun(@(secz) ...
    [...
    (hMeanDiaObj.signal.t(secz) ...
    - hMeanDiaObj.signal.t(find(secz,1)))...
    ...
    hMeanDiaObj.signal.pupilDiameter(secz)...
    - nanmean(hMeanDiaObj.signal.pupilDiameter(...
    find(secz,0.5*hMeanDiaObj.settings.interp_upsamplingFreq)))...
    ],segmentSectionz,'UniformOutput',false);

% Plot:
figure('Color',[1 1 1]);
axes(PupilDataModel.getPlotStyleParams.axesParams{:}); hold on;
hLine = cellfun(@(segSec) {plot(segSec(:,1),segSec(:,2))},sectionedSegments);
title('Superimposed pupil diameter curves, per trial.');
xlabel('Time [s]');
ylabel('Baseline Corrected Pupil Diameter [mm]');

% If old graphics engine, color the lines manually:
if verLessThan('matlab','8.4')
    arrayfun(@(h,c) set(h{1},'Color',c{1})...
        ,hLine',num2cell(jet(numel(hLine)),2));
end




