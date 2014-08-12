%% CONTACT MATRIX
%
% Defines a 4x4 matrix of contact probability for three different settings.

function contactmat = contactmatrix(setting, probs)

% Easy index calibrated probabilities
v = probs.veryhigh;     h = probs.high;
m = probs.med;          l = probs.low;

% Set up switch case for type of setting
switch setting
    
    % Household setting
    case 'Household', contactmat = [h m l m; m v l m; l l m l; m m l l];
        
        % Temporary household setting
    case 'Temp Household', contactmat = [m l l l; l h l l; l l l l; l l l l];
        
        % Community setting
    case 'Community', contactmat = [m l l l; l v l l; l l l l; l l l l];
        
        % Throw an error is setting is not defined appropriately
    otherwise, error(['No contact matrix defined for setting ' setting]);
        
end





