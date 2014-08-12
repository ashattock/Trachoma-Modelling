%% PREVALENCE PLOT
%
% Plot regional prevalence over time for any scenario.

% Tidy up
clear; clc; close all;

% Display what we're up to
disp('Plotting prevalence figures');


%% Plot options

% Region to run
regionref = [1 2 3];

% Which scenarios to plot
plotscens = [99 3 4 8 10]; % NaN for past evaluation

% Statistical summaries to plot
stats = [2.5 50 97.5];

% Plot either the median of mean curve
maincurve = 'mean'; % Use 'mean' or 'median'

% Flag to plot past evaluation figure used in manuscript
pastevalfig = 0;


%% Figure properties

% Set elimination threshold to plot
elimthr = 5; % Set to NaN to turn off

% Explanation of confidence intervals
ciexp  = 'none'; % 'none' = meaningless width; 'range' = width shows range in times

% Confidence interval details
cistep  = 4; % Timesteps for meaningless width
ciwidth = 2; % Width of plotted line

% Cut lower end of x axis at this year
xlowlim = 2006;

% Set colour and linewidtch to use for all sims
simcolour = [.75 .75 .75];
simwidth  = 2;

% Width of confidence interval and median curves
intwidth  = 4;
fullwidth = 10;

% Marker size of data points
datasize = 10;

% Set text font properties (fontsize: title, labels, ticks)
font = 'Calibri'; fontsize = [42 34 26];

% Initiate figure counter
nfig = 0;


%% Organise multiple regions if necessary

% Overwrite regions to plot if pastevalfig flag is on
if pastevalfig == 1, regionref = [2 3]; end

% Number of regions specified
nregions = numel(regionref);

% Get the name of the region or regions
if nregions == 1, regionname = regname(regionref);
else for i = 1:nregions, regionname{1, i} = regname(regionref(i)); end; end %#ok<SAGROW>

% Iterate through the regions
for k = 1:nregions
    
    % Get current region to analyse (could be within a cell array or just a string)
    if nregions > 1, thisregion = regionname{k}; else thisregion = regionname; end
    
    
    %% Scenario properties
    
    % Overwrite scenarios to plot if pastevalfig flag is on
    if pastevalfig == 1, plotscens = [NaN 0]; end
    
    % Number of scenarios to plot
    nscens    = numel(plotscens);
    scennames = cell(1, nscens);
    
    % Full scenario names of scenario references given in plotscens
    for i = 1:nscens, scennames{i} = scenname(plotscens(i), thisregion); end
    
    % Use scenario colour scheme to get rgb matrix
    colours = scenariocolours(scennames);
    
    
    %% Create summary data (if necessary)
    
    % Check that all indicators have been summarised for these scenarios
    summariseinds(thisregion, 'regionprev', plotscens);
    
    % Load regional input data (added regionalprev too late!)
    load(['.\Input Data\' thisregion ' Data.mat']);
    
    
    %% Statistical summary checks
    
    % Loaction of median and interval indicies
    whichmed = (stats == 50); whichint = find(~whichmed);
    
    % Make sure that user has defined the median as one of teh statistical summaries
    assert(sum(whichmed) > 0, 'Statistical summary vector ''stats'' should include 50 (i.e. the median)');
    
    
    %% Plot the figures
    
    % Iterate through the
    for i = 1:nscens
        
        % Load the regional prevalence summary for this scenario
        load(['.\Simulations\' thisregion '\scen_' num2str(plotscens(i)) '--summary--regionprev.mat']);
        
        % Easy reference the regional prevalence
        thisprev = summary.regionprev .* 100; pts = summary.pts;
        
        % Set up figure window
        if or(pastevalfig == 0, and(k == 1, i == 1)), nfig = nfig + 1; figfullscreen(nfig); end
        
        % Set up subplots of producing past evaluation plot
        if pastevalfig == 1 && i == 1, cksubplot([2 1], [k 1], [90 68], [0 0], [8 -12]); end
        
        % Plot the regional prevalence of all simulations
        if pastevalfig ~= 1, plot(pts, thisprev', 'color', simcolour, 'linewidth', simwidth); end; hold on;
        
        % Calcualte statistical summary
        thisstats = prctile(thisprev, stats) ;
        
        % Interate through summaries
        for j = 1:numel(whichint)
            
            % Plot the interval curves
            plot(pts, thisstats(whichint(j), :), 'color', colours(i, :), 'linewidth', intwidth);
        end
        
        % Set up switch case for type of curve to plot
        switch maincurve
            
            case 'median'
                
                % Plot the median curve
                plot(pts, thisstats(whichmed, :), 'color', colours(i, :), 'linewidth', fullwidth);
                
            case 'mean'
                
                % Mean regional prevalence
                samples  = size(thisprev, 1) - unique(sum(isnan(thisprev)));
                meanprev = nansum(thisprev) ./ samples;
                
                % Plot the mean curve
                plot(pts, meanprev, 'color', colours(i, :), 'linewidth', fullwidth);
                
                % Throw an error if not recognised
            otherwise, error(['Curve ' num2str(maincurve) ' not recognised'])
        end
        
        
        %% Now we need to make it look pretty...
        
        % Cut the x axis at a suitable point and show whole years
        xlim([xlowlim pts(end)]); set(gca, 'xtick', ceil(xlowlim):pts(end));
        
        % Set lower y limit to 0, leave upper as matlab default
        if pastevalfig == 1, ylim([0 27]);
        else ylims = get(gca, 'ylim'); ylim([0 ylims(2)]); end
        
        % All screening times, and the mean
        screentimes = data.screeninground;
        meantime    = round(nanmean(screentimes));
        
        % Which entries of the mean vector are valid (NaNs are not)
        validinds = and(~isnan(meantime), meantime <= numel(pts));
        meantime  = pts(meantime(validinds));
        
        % Set up switch case for explanation of confidence intervals
        switch ciexp
            
            case 'range' % CIs show the range in screening timing
                
                % Min and max screening times
                mintime  = pts(min(screentimes(:, validinds)));
                maxtime  = pts(max(screentimes(:, validinds)));
                
            case 'none' % CIs don't have another function (aside from being CIs!)
                
                % Min and max screening times
                mintime  = meantime - ((1 / summary.opt.timestep) * cistep);
                maxtime  = meantime + ((1 / summary.opt.timestep) * cistep);
        end
        
        % Emperical prevalence from data struct
        empprev = data.regionalprev(:, validinds) .* 100;
        
        % Plot data points and vertical confidence interval line
        plot(meantime, empprev(2, :), 'ko', 'markerfacecolor', 'k', 'markersize', datasize);
        plot(repmat(meantime, 2, 1), [empprev(1, :); empprev(3, :)], 'k', 'linewidth', ciwidth);
        
        % Plot the vertical confidence interval lines for the upper and lower ci bounds
        for j = [1 3], plot([mintime; maxtime], repmat(empprev(j, :), 2, 1), 'k', 'linewidth', ciwidth); end
        
        % Set title of figure dependent on whether we're producing past evaluation figure
        if pastevalfig == 1
            
            % Set figure title for each of the subplots
            if k == 1, title('Region A'); else title('Region B'); end

            % Set title for other figures
        else title([thisregion ': ' scennames{i}]);
        end
        
        % Plot elimination threshold if required
        if ~isnan(elimthr), plot([pts(1) pts(end)], ones(1, 2) .* elimthr, '--k', 'linewidth', 3); end
        
        % Set x and y axes labels
        if k == 1, ylabel(['Prevalence of disease (% of 5-9 year olds)' 10]); end; xlabel('Year');
        
        % Set all of the different text sizes
        settext({'title', 'labels', 'ticks'}, font, fontsize);
        
        % Sort out the ticks
        set(gca, 'tickdir', 'out', 'ticklength', [.005 .005]); box off;
    end
end

% Closing message
disp([10 'D O N E.'])

