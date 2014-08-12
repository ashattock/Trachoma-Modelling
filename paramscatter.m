%% PARAM SCATTER PLOT
%
% Simple scatter plot to complement the PRCC analysis. 

% Tidy up
clear; clc; close all;

% Display what we're up to
disp('Plotting parameter scatter figure');


%% Plot options

% Region to run
regionref = 1;

% Which scenarios to plot
plotscen = 99; % NaN for past evaluation

% Time properties for evaluating elimination liklihood
elimyear  = 2020; % Elimination year
timerange = 52;   % Number of time points to take average prevalence across

% Calibrated parameter names
calpmnames = {'1', ...
    '2', ...
    '3', ...
    '4', ...
    '5', ...
    '6', ...
    '7', ...
    '8'};


%% Figure properties

% Number of subplot windows
subsize = [2 4];

% Initiate figure counter
nfig = 0;


%% Load parameters and model output

% A few sanity checks - only suitable for 1 region and 1 scenario at a time
assert(numel(regionref) == 1, 'Incorrect number of regions specified');
assert(numel(plotscen) == 1, 'Incorrect number of scenarios specified');

% Name of the region
regionname = regname(regionref);

% Load the regional prevalence summary for this scenario
load(['.\Simulations\' regionname '\scen_' num2str(plotscen) '--summary--regionprev.mat']);

% Model iterated time points
pts = summary.pts; elimpt = find(pts == elimyear);

% Which points to analyse for elimination
elimpts = (elimpt - timerange + 1):elimpt;

% Mean community prevalence across these timepoints
meanpts = mean(summary.regionprev(:, elimpts), 2);
samples = ~isnan(meanpts);

% Set up for reading parameter sets
opt.samplestoload = size(summary.regionprev, 1);
opt.regionref     = regionref;

% Load all of the parameter sets
parametersets = loadparamsets(opt);
nparams       = size(parametersets, 1);

% Sanity check for number of calibrated parameters
assert(nparams == numel(calpmnames), 'Inappropriate number of names for calibrated parameters')


%% Perform analyses
disp([10 'Analysing...'])

% Perform partial-rank-correlation-coefficient analysis
[prcc, pvalue] = partialcorr(parametersets(:, samples')', meanpts(samples));

% Create figure window
nfig = nfig + 1; figfullscreen(nfig);

% Get a nice selection of colours from the cool coloyr map
allcols = colormap('cool');
allcols = allcols(1:((size(allcols, 1) / nparams) + 1):end, :);

% Iterate through the parameter sets
for i = 1:nparams
    
    % Create subplot window
    subplot(subsize(1), subsize(2), i);
    
    % The current parameter
    thispm = parametersets(i, :)';
    
    % Calculate the correlation coefficient
    cc = corrcoef(thispm(samples), meanpts(samples));
    cc = unique(cc); cc = cc(cc < 1); cc = thouseparator(cc(1), 0.001);

    % Plot the points to show correlation between parameter and model output
    plot(thispm, meanpts, 'ok', 'markerfacecolor', allcols(i, :), 'markeredgecolor', allcols(i, :));
end


%% Produce output for SASAT
disp([10 'Compiling SASAT files...'])

% Model input and output arrays
input  = parametersets(:, samples');
output = meanpts(samples)';

% Write excel files
xlswrite('.\SASAT\SASAT Parameters.xlsx', input);
xlswrite('.\SASAT\SASAT Model Output.xlsx', output);


%% Display SASAT output
disp([10 'Reading SASAT results...'])

% Read in excel file
[~, ~, sasatanal] = xlsread('.\SASAT\PRCC Analysis.xlsx');

% PRCC values for tornado plot
tplot  = cell2mat(sasatanal(2, 2:end))';
pnames = calpmnames; % sasatanal(1, 2:end);

% Set up required to sort rows
tplot = [tplot abs(tplot) (1:length(tplot))'];

% Do the sorting 
tplot  = sortrows(tplot, 2);
pnames = pnames(1, tplot(:, 3));

% Discard all values < 0.3
pnames = pnames(1, tplot(:, 2) >= 0.3);
tplot  = tplot(tplot(:, 2) >= 0.3, 1);

% Create figure window
nfig = nfig + 1; figfullscreen(nfig);

% Produce bar chart
h = barh(tplot(:,1), 'facecolor', [100 149 237] ./ 255);

% Set axes limits and ticks
axis([-1 1 .3 size(tplot, 1) + .7]); set(gca, 'xtick', -1:0.2:1)

% Label the y ticks with parameter names
set(gca, 'yticklabel', pnames); 

% Set title and axis label
title('Value of correlation coefficient with 5-9 year old prevalence in 2020');
ylabel('Model input parameters');

% Set text sizes
settext({'title', 'labels', 'ticks'}, 'Calibri', [40 36 26]);

% Closing message
disp([10 'D O N E.'])

