%% SUMMARISE INDICATORS
%
% Gather necessary information about given indicators and save in a nice 
% small file - this makes plotting a lot less painful. Trust me.

function summariseinds(region, indicators, scenarios)

% Number of input indicators 
if iscell(indicators), ninds = numel(indicators); else ninds = 1; end

% Path to files
savepath = ['.\Simulations\' region '\'];

% Iterate through scenarios
for i = 1:numel(scenarios)
    
    % This scenario reference
    thisscen = scenarios(i); tocreate = {};

    % Iterate through indicators
    for j = 1:ninds
        
        % Get current region to analyse (could be within a cell array or just a string)
        if ninds > 1, thisind = indicators{j}; else thisind = indicators; end
        
        % Has this indicator already been collated for this scenario
        thisfile = [savepath 'scen_' num2str(thisscen) '--summary--' thisind '.mat'];
        
        % If it hasn't yet been created, prepare for it to be fed into collatesims
        if ~exist(thisfile, 'file'), tocreate = [tocreate thisind]; end %#ok<AGROW>
    end
    
    % If any of the indicators don't exist, create them - a big job!
    if ~isempty(tocreate), collatesims(region, thisscen, tocreate); end
end
end