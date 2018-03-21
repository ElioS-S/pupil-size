%--------------------------------------------------------------------------
%
%   This script shows the standard pupil size analysis pipeline, as applied
%   to single-pupil dataset generated from SR-Research Eye-Tracker data.
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

% Convert files (to save time, comment the line below out if the edf files
% have already been converted to mat files):
batchFileConverter_Dataset1();

% Get files:
folderName       = './matlabData/';
rawFiles         = dir([folderName '*.mat']);
nFiles           = length(rawFiles);

% Display file information:
printToConsole('L1');
printToConsole(1, 'Found %i files...\n', nFiles);
printToConsole(2, 'Starting analysis pipeline');
printToConsole('L2');

% Get settings the standard setttings:
customSettings  = PupilDataModel.getDefaultSettings();

% Customize settings (the current dataset features arbitrary units; as
% such, no absolute maximum can be applied. Instead, the max is set to
% infinite, and the min to a really low values):
customSettings.raw.PupilDiameter_Max = inf;
customSettings.raw.PupilDiameter_Min = 0.1;

% The following flag determines if the raw data filter saves information
% about each intermediate filter step. Enabling it uses considerably more
% memory, and makes plotting multiple files slow. Use it only when
% designing and tweaking the filter parameters.
customSettings.raw.keepFilterData    = true;

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

% The code below open the PupilResults results in the variable viewer:
openvar PupilResults

% All pupil size data are now saved in the results table. If baseline
% correction is desired, the baseline segments can easily be subtracted
% from their concerning response epoch(s). To simplify this, it is handy to
% add a metadata column to the segmentData table containing an identifier
% labeling the epoch as a baseline. A baseline table can then be generated
% by extracting the rows featuring the baseline identifier from the results
% table. Similarly, a response table can be generated by extracting the
% desired response epochs. These baseline and response tables can then be
% combined using the 'join' table operation, producing a table with
% matched baseline and response columns.


%% Visualizing the Data:
% The PupilDataModel class can visualize its data via the plotData method,
% which can be called on a PupilDataModel array. Note that if the
% keepFilterData flag was set to true, the intermediate filering steps will
% be plotted as well, which may be slow when plotting multiple objects.
%
% The segments are visualized as stacked non-overlapping rectangles in the
% top axes. Their colors are random. 
%
% *** You can click the segment rectangle to view its info ***.

% Plotting:
hPupilData.plotData;



