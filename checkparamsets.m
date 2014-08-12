%% CHECK PARAMETER SETS
%
% If any parameter sets have failed the calibration process, replace them

function [parametersets, opt] = checkparamsets(parametersets, opt, type, simsets)

% Only use this function is calibration flag is on, and throw an error if parameter sets are missing
if opt.calibration == 0, assert(sum(sum(isnan(parametersets))) == 0, 'Missing parameter sets'); return; end

% Set up switch case for different functionality
switch type
    
    case 'fill' % Replace empty parameter sets with new latin hyper cube samples
        
        % Missing parameter sets have failed - find them
        opt.failedparams = find(isnan(parametersets(1, :)));
        
        % Check if there are any missing
        if isempty(opt.failedparams), return; else
            
            % How many have failed?
            nfailed = numel(opt.failedparams);
            
            % Explain as much
            cprintf([.7 .1 .1], '\nReplacing %d failed parameter sets...\n', nfailed)
            
            % Get nfailed many new latin hyper cube samples
            newparams = lhcsamples(nfailed, opt.regionref, 'give');
            
            % Put these new samples sets into the parametersets array
            parametersets(:, opt.failedparams) = newparams';
        end
        
    case 'empty' % Get rid of parameter sets that have failed
        
        % Determine which of the parameter sets have failed the calibration test
        failed  = find(cellfun(@(x) isfield(x.calibration, 'rejected'), simsets));
        nfailed = numel(failed);
        
        % Trivially replace failed parameter sets
        parametersets(:, failed) = nan;
        
        % Explain as much
        cprintf([.7 .1 .1], '\nDeleting %d failed parameter sets:\n', nfailed)
        for i = 1:nfailed, cprintf([.7 .1 .1], '  %d\n', failed(i)); end
        
        % Overwrite parameters spreadsheet
        xlswrite(opt.parampath, parametersets', opt.regionref)
        
        % Throw an error message if cqase not defined
    otherwise, error(['Case ' num2str(type) ' not defined']);
end

