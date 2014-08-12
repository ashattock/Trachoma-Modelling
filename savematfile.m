%% SAVE MAT FILE
%
% Had a few issues with saving mat files as they are so big, so doing the
% whole process in here to keep things compact.

function savematfile(data, opt, simsets, thisparams) %#ok<INUSL>

% Display what we're up to
disp([10 'Saving...']);

% Create regional folder if it does not exist
if ~exist(opt.savepath, 'dir'), mkdir(opt.savepath); end

% Remember current directory, then move to saving location
thisdir = cd; cd(opt.savepath);

% Standard projection year
if opt.runyears(end) <= 2020
    
    % Create this beasty file name to differentiate from others
    savename = ['scen_' num2str(opt.futurescenario) ...
        '--pe_' num2str(opt.pastevaluation) ...
        '--sims_' num2str(thisparams(1)) 'to' num2str(thisparams(end)) ...
        '--date_' date '.mat'];
else
    
    % Create this file name for projections further than 2020
    savename = ['scen_' num2str(opt.futurescenario) ...
        '--pe_' num2str(opt.pastevaluation) ...
        '--sims_' num2str(thisparams(1)) 'to' num2str(thisparams(end)) ...
        '--projyear_' num2str(opt.runyears(end)) '.mat'];
end

% Save the simulation (using version 7.3 as file may be huge!)
save(savename, 'data', 'opt', 'simsets', '-v7.3');

% Revert back to the model directory
cd(thisdir);

