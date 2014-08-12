%% SCENARIO NAME
%
% Given a future scenario number, this function returns the name of the
% scenario as per the following options:
%
% 0   = No future projection
% 99  = Baseline projection
% 10  = Proposed targets
% 11  = Current targets
% 1   = Alternative 1, ... , Alternative n
% 101 = Alternative 1a, 102 = Alternative 1b, etc
%
% Alice Springs: 99, 1,        2, 3, 4, 501, 502, 6,    8, 9, 90, 10, 11
% Kimberley:     99, 101, 102, 2, 3, 4,           6, 7, 8, 9, 90, 10, 11
% Darwin Rural:  99, 1,        2, 3, 4, 501, 502, 6,    8, 9, 90, 10, 11

function futurescenname = scenname(futurescenario, regionname)


% Set up switch case for future scenario number
switch futurescenario
    
    %    #                      Name                                    Availability
    
    case 0,   futurescenname = 'No future projection';
        
    case 99,  futurescenname = 'Baseline projection';
        
    case 10,  futurescenname = 'Proposed targets';
        
    case 11,  futurescenname = 'Current targets';
        
    case 1,   futurescenname = 'Increase screening';                    checkavail({'Alice Springs Remote', 'Darwin Rural'});
        
    case 101, futurescenname = 'Increase screening';                    checkavail({'Kimberley'});
        
    case 102, futurescenname = 'Further increase screening';            checkavail({'Kimberley'});
        
    case 2,   futurescenname = 'Increase treatment';
        
    case 3,   futurescenname = 'Increase facial cleanliness';
        
    case 4,   futurescenname = 'Increase facial cleanliness, screening and treatment';
        
    case 501, futurescenname = 'Synchronise screening';                 checkavail({'Alice Springs Remote', 'Darwin Rural'});
        
    case 502, futurescenname = 'Further synchronise screening';         checkavail({'Alice Springs Remote', 'Darwin Rural'});
        
    case 6,   futurescenname = 'Re-treat hyperendemic communities every 6 months';
        
    case 7,   futurescenname = 'Screen only 5-9 year olds';             checkavail({'Kimberley'});
        
    case 8,   futurescenname = 'Increase housing construction';
        
    case 9,   futurescenname = 'Combination of all interventions';
        
    case 90,  futurescenname = 'Combination of interventions without housing construction';
        
    otherwise % Check for NaN if scenario reference not recognised
        
        % An NaN scenario reference is given for past evaluation - no interventions
        if isnan(futurescenario), futurescenname = 'Past Evaluation'; else error('Scenario reference not recognised'); end
end

% Define which scenarios are discussed in the manuscript
manscens = [0 99 10 11 3 4 8 9];

% If the scenario being run is not one of these scenarios, warn the user
if ~ismember(futurescenario, manscens) && ~isnan(futurescenario), warning('Not a manuscript scenario!'); keyboard; end


%% Nested function - Check availability of scenario for region
    function checkavail(regionsavailable)
        
        % Potential error message explaining what's gone wrong
        errmessage = ['Scenario ''' futurescenname ''' not available for ' regionname];
        
        % Make sure condition is met, or throw the above error message
        assert(ismember(regionname, regionsavailable), errmessage);
    end
end

