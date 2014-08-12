%% FIND COMMUNITIES
%
% Find which communities are hyper, meso and hypo endemic according to
% their mean observed trachoma prevalence in the emperical data.

function segcomms = findcomms(data, threshold, seggroup)

% Number of groups to segregate into
if iscell(seggroup), ngroup = numel(seggroup); else ngroup = 1; end

% Initiate output and community counter
segcomms = cell(1, ngroup); allsegcomms = [];

% Iterate through the groups
for i = 1:ngroup
    
    % Get current region (could be within a cell array or just a string)
    if ngroup > 1, thisgroup = seggroup{i}; else thisgroup = seggroup; end
    
    % This gorups threshold
    try thisthres = threshold.(thisgroup); catch; end; %#ok<CTCH>
    
    % Set up switch case for this group
    switch thisgroup
        
        case 'hyper', bounds = [thisthres inf];             % Hyper-endemic bounds
            
        case 'meso',  bounds = [thisthres threshold.hyper]; % Meso-endemic bounds
            
        case 'hypo',  bounds = [thisthres threshold.meso];  % Hypo-endemic bounds
            
        case 'non',   bounds = [0 threshold.hypo];          % Non-endemic bounds
            
            % Throw an error if case not recognised
        otherwise, error(['Case ' thisgroup ' not recognised']);
    end
    
    % Mean trachoma prevalence in observed years
    meanprev = nanmean(data.trachprev, 2);
    
    % Find which communities are above this threshold
    segcomms{i} = find(and(meanprev > bounds(1), meanprev <= bounds(2)));
    
    % Collect all segregated communities
    allsegcomms = [allsegcomms segcomms{i}'];  %#ok<AGROW>
end

% Quick sanity check that all communities have been segregated with no repetition
assert(isequal(unique(allsegcomms), sort(allsegcomms)), 'Not segregating correctly')

