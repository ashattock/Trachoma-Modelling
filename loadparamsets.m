%% LOAD PARAM SETS
%
% Load in calibrated parameter sets. Easy.

function parametersets = loadparamsets(opt)

% Create display
disp([10 'Loading ' num2str(opt.samplestoload) ' parameter sets...']);

% Set range of cells to read according to samplestoload
readcells = ['A1:H' num2str(opt.samplestoload)];
path      = '..\Data Spreadsheets\Parameter Sets.xlsx';

% Load the parameter sets
[~, ~, parametersets] = xlsread(path, opt.regionref, readcells);
parametersets         = cell2mat(parametersets)';

