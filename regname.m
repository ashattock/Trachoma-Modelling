%% REGION NAME
%
% Trivial function to return region name given region reference. Just
% because we wan to do it in several places.

function regionname = regname(regionref)

% Set up switch case for region reference
switch regionref
    
    % Assign region name according to region reference
    case 1, regionname = 'Alice Springs Remote';
    case 2, regionname = 'Kimberley';
    case 3, regionname = 'Darwin Rural';
end