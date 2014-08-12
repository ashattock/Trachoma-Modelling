%% LHC (Latin hyper-cube) SAMPLER
%
% Calls latinhypercube function and returns 'a' parameter sets to run the
% model with.

function out = lhcsamples(a, region, type)

% Set up switch case for region
switch region
    
    % Values for regional-specific parameters
    case 1, b = .45; c = .65;
    case 2, b = .4;  c = .6;
    case 3, b = .3;  c = .4;
end
        
% Region specific parameters
x1 = latinhypercube('uniform', a, b, c);

% Standard parameters across all regions
x2 = latinhypercube('uniform', a,  20,  30);
x3 = latinhypercube('uniform', a, 1.5,  2);
x4 = latinhypercube('uniform', a,  80,  85);
x5 = latinhypercube('uniform', a, .04, .12);
x6 = latinhypercube('uniform', a, .18, .26);
x7 = latinhypercube('uniform', a, .34, .42);
x8 = latinhypercube('uniform', a, .48, .56);

% Concatonate all parameters and samples
x = [x1 x2 x3 x4 x5 x6 x7 x8];

% Set up switch case for functionality
switch type
    
    % Write the new parameter sets to a spreadsheets
    case 'write', xlswrite('New LHC Samples.xlsx', x); out = [];
        
        % Output the newly generated parameter sets
    case 'give', out = x;
        
        % Throw an error if functionality not recognised
    otherwise, error(['Input ' num2str(type) ' not defined']);
end


