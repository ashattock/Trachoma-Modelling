%% COLLATE SIMS
%
% Collect and combine all sim sets of a scenario.
%
% Model outputs that we can compile:
%   regionprev - Regional prevalence
%   commprev   - Community prevalence
%   treated    - Number of treatments distributed 

function collatesims(region, scen, indicators)

% Display what we're up to
disp([10 'Collating simsets... go get a cup of tea'])

% Intialise output
nindicator = numel(indicators);
indsoutput = struct;

% Remember current directory, then move to file location
thisdir = cd; cd(['.\Simulations\' region '\']);

% All files in this directory
allfiles = ls; nfiles = size(allfiles, 1);

% Intialise and populate cells to hold the strings
cellfiles = cell(1, nfiles);
for i = 1:nfiles, cellfiles{1, i} = strrep(allfiles(i, :), ' ', ''); end

% Scenario reference in mat file name
scenref = ['scen_' num2str(scen) '--pe']; firstref = 'sims_1to';

% Files that contain simulations for this scenario
sceninds  = cellfun(@(x) ~isempty(strfind(x, scenref)), cellfiles);
scenfiles = cellfiles(sceninds);

% The first load of simulations for this scenario
firstind  = cellfun(@(x) ~isempty(strfind(x, firstref)), scenfiles);
firstfile = scenfiles(firstind);

% Load the first bunch of simulations
fprintf('  loading %s...', firstfile{1});
firstsims = load(firstfile{1}); fprintf(' done\n');

% Obtain the data and option structures
data = firstsims.data; opt = firstsims.opt;

% Easy reference some key fields
ncomms = data.ncommunities;
pts    = firstsims.simsets{1}.pts;
npts   = numel(pts);

% Total number of sims, and how divided they are
samples   = opt.samplestoload;
divparfor = opt.divparfor;

% Sanity check for the number of files we are combining
assert(numel(scenfiles) == divparfor, 'Number of files does not match opt.divparfor');

% Number of simsets stored per file
simsperfile = samples / divparfor;

% Iterate through indicators to set up output arrays
for i = 1:nindicator
    
    % This indicator
    thisind = indicators{i};
    indsoutput(i).indicator = thisind;
    
    % Set up switch case to define size of output array
    switch thisind
        
        % Define size of output array
        case 'regionprev', indsoutput(i).allsims = zeros(samples, npts);
        case 'commprev',   indsoutput(i).allsims = zeros(samples, npts, ncomms);
        case 'treated',    indsoutput(i).allsims = zeros(samples, npts, ncomms);
            
            % Otherwise through an error
        otherwise, error(['Indicator ' thisind ' not recognised']);
    end
    
    % Populate first load of rows of this array with output from firstsims
    for j = 1:simsperfile, indsoutput = outputarray(indsoutput, i, j, j, firstsims); end
end

% Clear firstsims as this is a beasty file
clear firstsims;

% Simulation number of the first and last sim sets stored in each file
simsbtw = [1:simsperfile:samples-simsperfile+1; simsperfile:simsperfile:samples]';

% Iterate through all but the first file
for i = 2:divparfor
    
    % Which sims are we loading next?
    thissimref = ['sims_' num2str(simsbtw(i, 1)) 'to' num2str(simsbtw(i, 2)) '--'];
    thesesamples = simsbtw(i, 1):simsbtw(i, 2);
    
    % Find the appropriate file
    thisind  = cellfun(@(x) ~isempty(strfind(x, thissimref)), scenfiles);
    thisfile = scenfiles(thisind);
    
    % Load these simulations
    fprintf('  loading %s...', thisfile{1});
    thissims = load(thisfile{1}); fprintf(' done\n');

    % Populate first load of rows of this array with output from thissims
    for j = 1:nindicator, for k = 1:simsperfile, indsoutput = ...
                outputarray(indsoutput, j, thesesamples(k), k, thissims); end; end
    
    % Clear thissims as this is a beasty file
    clear thissims;
end

% Iterate through indicators once more
for i = 1:nindicator
    
    % Create file name to save results with
    savefile = ['scen_' num2str(scen) '--summary--' indsoutput(i).indicator];
    
    % Append scenario ref, data and opt to a summary struct
    summary.scenario = scen; summary.data = data; summary.opt = opt;
    
    % Also append the all important array
    summary.(indsoutput(i).indicator) = indsoutput(i).allsims; summary.pts = pts;
    
    % Save the array (using version 7.3 as file may be big)
    fprintf('\nSaving %s of all simsets in single file...', indsoutput(i).indicator);
    save(savefile, 'summary', '-v7.3'); fprintf(' done\n');
    
    % Clear summary
    clear summary;
end

% Finally revert back to the model directory
cd(thisdir);


%% Nested function - output array
    function out = outputarray(out, ind, sample, simind, sim)
        
        % This indicator
        thisindic = indicators{ind};
        
        % Attempt to get indicator, - the occasional sim may have failed
        if isfield(sim.simsets{simind}, thisindic)
            
            try
            
            % Set up switch case for indicator
            if strcmp(thisindic, 'regionprev'), out(ind).allsims(sample, :) = sim.simsets{simind}.(thisindic);
            else                                out(ind).allsims(sample, :, :) = sim.simsets{simind}.(thisindic)'; end
            
            catch
                
                disp('CUTTING DOWN OUTPUT BY 1 YEAR')
                
                % Set up switch case for indicator
                if strcmp(thisindic, 'regionprev')
                    
                    out(ind).allsims(sample, :) = sim.simsets{simind}.(thisindic)(1, 1:521);
                else
                    
                    out(ind).allsims(sample, :, :) = sim.simsets{simind}.(thisindic)(:, 1:521)';
                
                end
                
                
                
            end
        else
            
            % If a sim has failed, just fed back NaNs as the results
            if strcmp(thisindic, 'regionprev'), out(ind).allsims(sample, :) = nan(1, npts); else out(ind).allsims(sample, :, :) = nan(1, npts, ncomms); end
            
            % Let the user know the parameter set has failed
            disp(['No results for parameter set ' num2str(sample)])
        end
    end


end

