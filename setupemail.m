%% SET UP EMAIL
%
% Determine a suitable email subject and body for the success and failure
% of the simulations of the trachoma project.

function [subject, body] = setupemail(opt, type, otherinput)


%% Subject

% Set up switch case
switch type
   
    % Set success email subject
    case 'success', subject = ['Simulations on ' opt.thismachine ' complete!'];

        % Set failure email subject
    case 'failure', subject = ['Error occured on ' opt.thismachine];

        % Otherwise throw an error
    otherwise, error(['Case ' num2str(type) ' not defined']);
end


%% Body

% Which fields to report home about
optfields = {'regionname', 'futurescenario', ...
    'futurescenname', 'pastevaluation', 'calibration'};

% Initiate email body
body = [];

% Iterate through the fields
for i = 1:numel(optfields)

    % Create line for email body
    thisfield = optfields{i};
    thisline  = [thisfield ': ' num2str(opt.(thisfield)) 10];
    
    % Add this line to the email body
    body = [body thisline]; %#ok<AGROW>
end

% Append error or time taken message as appropriate
if strcmp(type, 'failure'), body = [body 10 'error: ' otherinput.message];
else body = [body 10 'time taken: ' otherinput]; end

