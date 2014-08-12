%% COMMUNITY ELIMINATION PLOT
%
% Determines the liklihood of community elimination for the different
% segregations of community by endemicity.

% Tidy up
clear; clc; close all;

% Display what we're up to
disp('Plotting community elimination figures');

% Set the random number seed
rng(0); % For reproducible bootstraping


%% Plot options

% Regions to include in analysis
regionrefs = [1 2 3];

% Scenarios to include in analysis
scens = [99 8 3 4 10]; % [99 8 3 4 9 11 10];

% Which epidemic groups to plot
epigroups = {'hyper', 'meso', 'hypo'};

% Time properties for evaluating elimination liklihood
elimyear  = 2020; % Elimination year
timerange = 52;   % Number of time points to take average prevalence across

% Method of obtaining uncertainty bounds
cimethod = 'bootstrap'; % Use 'bootstrap' or 'percentile'

% Number of bootstraps (used with 'bootstrap' method)
nbootstraps = 1000; alpha = 0.0000005;

% Percentile summaries (used with 'percentile' method)
prctsum = [50 2.5 97.5]; % Median first!

% Elimination threshold (prevalence % in 5-9 year olds)
elimvalue = 0.05; % 5%


%% Figure properties

% Set text font properties (fontsize: title, ylabel, ticks, legend)
font = 'Calibri'; fontsize = [22 26 20 20];

% Set y axis label (only feautures once)
yaxlabel = sprintf(['Likelihood of community trachoma prevalence\n' ...
    'below elimination threshold by %d\n'], elimyear);

% % Position of the epigroups in figure
% subrow = [1 1 2]; subcol = [1 2 1];
% 
% % Sanity check for the number of elements of these arrays
% assert(numel(subrow) == numel(epigroups), 'subrow and subcol not correctly defined');

% Consistent y-limit and x-axis gaps
ylimit = 100; xgaps = 0.4;

% Linewidth of error bars
errwidth = 3;

% Initiate figure counter
nfig = 0;


%% Scenario properties

% Number of scenarios to plot
nscens    = numel(scens);
scennames = cell(1, nscens);

% Full scenario names of scenario references given in plotscens
for i = 1:nscens, scennames{i} = scenname(scens(i), 'all regions'); end

% Use scenario colour scheme to get rgb matrix
colours = scenariocolours(scennames);


%% Create summary data (if necessary) and organise communities 

% Number of regions specified
nregions = numel(regionrefs);
ngroups  = numel(epigroups);

% Get the name of the region or regions
if nregions == 1, regionname = regname(regionrefs);
else for i = 1:nregions, regionname{1, i} = regname(regionrefs(i)); end; end %#ok<SAGROW>

% Get threshold details from global options function
opt = globaloptions('thresholds'); threshold = opt.threshold;

% Preallocate cell arrays
segcomms  = cell(nregions, ngroups);
elimcomms = cell(nregions, ngroups);

% Iterate through the regions
for i = 1:nregions
    
    % Get current region (could be within a cell array or just a string)
    if nregions > 1, thisregion = regionname{i}; else thisregion = regionname; end
    
    % Check that all indicators have been summarised for these scenarios
    summariseinds(thisregion, 'commprev', scens);

    % Load regional input data (added regionalprev too late!)
    regionfield = strrep(thisregion, ' ', '');
    alldata.(regionfield) = load(['.\Input Data\' thisregion ' Data.mat']);
   
    % Data of this region
    thisdata = alldata.(regionfield).data;
    
    % Segregate these communities into
    segcomms(i, :) = findcomms(thisdata, threshold, epigroups);
end


%% Determine elimination liklihoods

% Preallocate array to store stats summaries
statsum = zeros(nscens, 3, ngroups);
    
% Iterate through the scenarios
for i = 1:nscens
    
    % Details of this scenario
    thisscen = scens(i); thisscenname = scennames{i};
    
    % Initiate results display for this scenario
    disp([10 'Elimination liklihoods for ''' thisscenname ''' scenario'])
    
    % Iterate through the regions to analyse
    for j = 1:nregions
        
        % Get current region (could be within a cell array or just a string)
        if nregions > 1, thisregion = regionname{j}; else thisregion = regionname; end
        
        % Load the regional prevalence summary for this scenario
        load(['.\Simulations\' thisregion '\scen_' num2str(thisscen) '--summary--commprev.mat']);
        
        % Model iterated time points
        pts = summary.pts; elimpt = find(pts == elimyear);
        
        % Which points to analyse for elimination
        elimpts = (elimpt - timerange + 1):elimpt;
        
        % Mean community prevalence across these timepoints
        meanpts = squeeze(mean(summary.commprev(:, elimpts, :), 2));
        meanpts(any(isnan(meanpts), 2), :) = []; samples = size(meanpts, 1);
        
        % Iterate through the endemic categories
        for k = 1:ngroups
            
            % Initiate field in allsims structure on first iteration
            if and(i == 1, j == 1), allsims.(epigroups{k}) = []; end
            
            % Communities to analyse for elimination
            thesecomms = segcomms{j, k}; commsgroup = meanpts(:, thesecomms);
            
            % Percentage of communities to achieve elimination in each simulation
            elimlikli = 100 .* sum(commsgroup < elimvalue, 1) ./ samples;
            
            % Concatonate results with others of the same endemicity
            allsims.(epigroups{k}) = [allsims.(epigroups{k}) elimlikli];
            
            % Sum everything up and take averages on last region iteration
            if j == nregions, thisgroupdata = allsims.(epigroups{k});
                
                % Set up switch case for bounds method
                switch cimethod
                    
                    % Obtain confidence intervals of the mean of the sample through boostraping 
                    case 'bootstrap',  thisstats = [mean(thisgroupdata) bootci(nbootstraps, {@(x) mean(x), thisgroupdata}, 'alpha', alpha)'];

                        % Obtain the percentiles defined by user (median first!)
                    case 'percentile', thisstats = prctile(thisgroupdata, prctsum);
                        
                        % Throw an error if cimethod not recognised
                    otherwise, error(['Uncertainty method ' num2str(cimethod) ' not recognised']);
                end
                
                % Display the results in the command window (with uncertainty bounds)
                fprintf('  %s-endemic communities: %.1f%% [%.1f - %.1f]\n', epigroups{k}, thisstats)
                
                % Store stats summary
                statsum(i, :, k) = thisstats;
            end
        end
    end
end


%% Produce plot

% Set up figure window
nfig = nfig + 1; figfullscreen(nfig);

% Iterate through the endemic categories
for i = 1:ngroups
    
    % Set up subplot window
    subplot(2, 2, i)
    
    % Plot the bars
    bh = bar(diag(statsum(:, 1, i)), 'stacked'); hold on;
    
    % Set colours of scenario bars appropriately
    for j = 1:nscens, set(bh(j), 'facecolor', colours(j, :)); end
    
    % Plot the error bars in the centrally on top of the bars
    plot(repmat(1:nscens, 2, 1), [statsum(:, 2, i) statsum(:, 3, i)]', ...
        'color', 'k', 'linewidth', errwidth);
    
    % Sort out axes limits
    ylim([0 ylimit]); xlim([xgaps nscens + 1 - xgaps]);
    
    % Set figure title
    title(firstcap([epigroups{i} 'endemic communities']));
    
    % Set ylabel on first iteration and set blank x ticks
    if i == 1, ylabel(yaxlabel); end; set(gca, 'xticklabel', '');
    
    % Set all of the different text sizes
    settext({'title', 'labels', 'ticks'}, font, fontsize(1:3));
    
    % Turn off box and set y grid lines
    box off; set(gca, 'ygrid', 'on');
end

% Display the legend
lh = legend(bh, scennames);

% Set the legend position
position = [0.51146 0.12633 0.45817 0.32119];

% Set the legend properties
set(lh, 'FontName', 'Arial', 'FontSize', 20, 'Position', position, ...
    'YColor', [1 1 1], 'XColor', [1 1 1]);

% Closing message
disp([10 'D O N E.'])

