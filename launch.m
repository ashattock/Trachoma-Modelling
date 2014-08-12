%% LAUNCH
%
% Loads the model input data and the calibrated parameter sets, then calls 
% the simulate function that runs the actual model.

% Tidy up
clear; clc; close all;

% Start the overall timer
launchtimer = tic;

% Set global options
opt = globaloptions;

% Create welcome display
disp(['Launching ' opt.regionname])


%% Load stuff

% Load parameter sets
parametersets        = loadparamsets(opt);
[parametersets, opt] = checkparamsets(parametersets, opt, 'fill');

% Create or load data structure
if opt.loaddata == 1, data = createdataset(opt); else
    load(['.\Input Data\' opt.regionname ' Data.mat']); end

% Reshape certain data fields
data = reshapedata(data, opt);


%% Start up multicore

% Check it's not already open
if ~matlabpool('size');
    
    % Display what we're up to
    disp([10 'Starting parallel Matlab...']);
    
    % For most machines we can use the following command
    try matlabpool(getenv('NUMBER_OF_PROCESSORS'));

    catch err % ... however Phobos doesn't cope with this well
        
        % So just hardcode the number of processor to operate
        matlabpool 12
    end
end


%% Simulation start up display

% Check flag for whether this should be displayed
if opt.startupdisp
    
    % Easy access colour vectors
    cols = opt.printcols;
    
    % Either running with interventions or doing a past evaluation
    if opt.pastevaluation == 1, cprintf(cols{1}, '\nRunning past evaluation'); else
        fprintf('\nRunning with inteventions'); end
    
    % Display what years we're simulating between
    fprintf(' from %d to %d', opt.runyears(1), opt.runyears(end))
    
    % Set up switch case for future scenario explanation
    if opt.pastevaluation == 0, switch opt.futurescenario %#ok<ALIGN>

            % Either no projection, baseline or alternative
            case 0,    cprintf(cols{2}, ' - no future projection')
            case 99,   cprintf(cols{3}, ' - baseline future projection ')
            otherwise, cprintf(cols{4}, ' - %s', lower(opt.futurescenname))
        end
    end
    
    disp('... '); % Start from a new line
end


%% Simulate parameter sets and save

% Initialise simsets and easy index
simsets = cell(1, opt.samplestoload);
rundisp = opt.rundisp;

try % Set up a try catch incase of any crashes (surely not)
    
    % Loop to prevent parfor running out of memory
    for i = 1:opt.divparfor
        
        % Which parameter sets to give this parfor loop
        thisparfor = opt.samplestoload / opt.divparfor;
        thisparams = (1:thisparfor) + thisparfor * (i-1);
        
        % Display which parameter sets are being run
        disp([10 'Running paramater sets ' num2str(thisparams(1)) '-' num2str(thisparams(end))]);
        
        % Iterate through the parameter sets
        parfor j = thisparams
            
            % Display which parameter set is being run
            if rundisp, disp(['Running paramater set ' num2str(j)]); end
            
            % Simulate the model using i^th parameter set
            simsets{j} = simulate(j, parametersets(:, j), data, opt);
        end
        
        % Which sims to save now
        savesims = simsets(thisparams);
        
        % Save all model output (plus opt and data) to mat file
        if opt.calibration == 0, savematfile(data, opt, savesims, thisparams); end
    end
    
catch err % If anything's gone wrong, catch the error
    
    % Set up an email subject and body
    [emailsubject, emailbody] = setupemail(opt, 'failure', err);
    
    % Send the email, and throw the error
    sendemail(opt.email, emailsubject, emailbody); throw(err);
end


%% Close up

% Throw out any failed parameter sets
checkparamsets(parametersets, opt, 'empty', simsets);

% Display how long the whole proccess took
totaltime = datestr(datenum(0, 0, 0, 0, 0, toc(launchtimer)), 'HH:MM:SS');
disp([10 'Simulations complete in ' totaltime]);

% If we're all good, send a nice email
[emailsubject, emailbody] = setupemail(opt, 'success', totaltime);
sendemail(opt.email, emailsubject, emailbody);

% Close parallel Matlab
matlabpool close;

% Closing message
disp([10 'D O N E.'])


