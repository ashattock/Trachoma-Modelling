%% SCENARIO COLOURS
%
% Defines the colour scheme for each of the defined scenarios
%
% NOTE: These are set up for manuscript figures

function colours = scenariocolours(scenario)

% Preallocate rgb matrix output
colours = zeros(numel(scenario), 3);

% Iterate through the scenarios
for i = 1:numel(scenario)
    
    % Set up switch case for scenario ref
    switch scenario{i}
        
        % Get the appropriate colour system for the given future scenarios
        case 'Baseline projection',                                     colour = [204 204 204]; % Grey
        case 'Increase housing construction',                           colour = [225 122  66]; % Orange
        case 'Increase facial cleanliness',                             colour = [224  73  87]; % Red
        case 'Increase facial cleanliness, screening and treatment',    colour = [230 101 166]; % Pink
        case 'Combination of all interventions',                        colour = [125  97 186]; % Purple
        case 'Current targets',                                         colour = [106 168  82]; % Green
        case 'Proposed targets',                                        colour = [132 188 213]; % Blue
            
            % Past evaluation scenarios 
        case 'No future projection',                                    colour = [ 90 151 206]; % Blue
        case 'Past Evaluation',                                         colour = [224  73  87]; % Red
            
            % Throw an error if scenario is not recognised
        otherwise, error(['Scenario ' num2str(scenario{i}) ' does not have a defined colour']);
    end
    
    % Scale the rgb matrix ready for output
    colours(i, :) = colour ./ 255;
end
end