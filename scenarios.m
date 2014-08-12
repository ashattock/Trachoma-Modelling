%% SCENARIOS
%
% Defines future screening, treatment and housing policy dependent on
% future projection defined in global options

function details = scenarios(y, details, data, opt)

% Number of future year and their indices
nfut = opt.nyears - y + 1; yfut = y:opt.nyears;

% Easy referece timestep
dt = opt.timestep;

% Number of communities in the region
ncomms = data.ncommunities;


%% Standard projection - same setup for each region

% Set treatment properties of new policy
details.treat.coverage = .85;
weeksbeforetreat       = 3;

% Set flat clean face prevalence and screening coverage projection for all future years
details.cleanfaceprev(:, :, yfut)   = repmat(data.cleanfaceproject, [1 1 nfut]);
details.screen.coverage(:, :, yfut) = repmat(data.screeningproject, [1 1 nfut]);

% Iterate through the communities
for i = 1:ncomms
    
    % Index of last screening session
    lastind = find(~isnan(details.screen.timing(i, :)), 1, 'last');
    
    % Timepoints of all future screening sessions (may later be altered in the model)
    futurescreens = details.screen.timing(i, lastind) + dt .* (yfut - lastind);
    
    % Set these new times in details structure
    details.screen.timing(i, yfut) = futurescreens;
    
    % Determine how much later the treatment sessions will occur
    thentreat       = floor(rand(2, nfut) .* (weeksbeforetreat + 1));
    thentreat(2, :) = max(thentreat);
    
    % Timepoints of all future treatment sessions (again, may later be altered in the model)
    futuretreat = repmat(futurescreens, 2, 1) + thentreat;
    
    % Reshape treatment timings into details structure
    details.treat.timing(i, :, yfut) = reshape(futuretreat, 1, 2, nfut);
end


%% Alternative projections - seperated by region

% Set up switch case for the 3 regions
switch opt.regionname
    
    case 'Alice Springs Remote' % Alice Springs Remote alternative scenarios
        
        % Set up switch case for future scenario
        switch opt.futurescenario
            
            case 1   % Increase screening
                
                % New minimum screening coverage
                screeningproject = [.5 .8 .8];
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
            case 2   % Increase treatment
                
                % New treatment coverage
                details.treat.coverage = .98;
                
            case 3   % Increase facial cleanliness
                
                % New minimum clean face prevalence
                cleanfaceproject = [.6 .9 .9];
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 4   % Increase facial cleanliness, screening and treatment
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.5 .8 .8]; cleanfaceproject = [.6 .9 .9];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 501 % Synchronise screening
                
                % Number of weeks to synchronise within
                screensync = 8; treatsync = 4;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
            case 502 % Further synchronise screening
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
            case 503 % Test scenario
                
                % Let the user know that this is a test scenario
                disp('Running test scenario...')
                
                % Number of weeks to synchronise within
                screensync = 1; treatsync = 1;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
                % New minimum screening coverage
                screeningproject = [1 1 1]; cleanfaceproject = [1 1 1];
                
                % New treatment coverage
                details.treat.coverage = 1;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 6   % Re-treat hyperendemic communities every 6 months
                
                % Retreat hyper biannually for 3 years then sceen again
                %
                % NOTE: policy specific to Alice Springs Remote
                details.screentreatpolicy = 'retreat';
                details.ynextscreen       = 3;
                
            case 8   % Increase housing construction
                
                % Set new housing construction plan for the region
                region.houseconstruction(data.furtherconstruction);
                
            case 9   % Combination of all interventions
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.5 .8 .8]; cleanfaceproject = [.6 .9 .9];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
                % Retreat hyper biannually for 3 years then sceen again
                %
                % NOTE: policy specific to Alice Springs Remote
                details.screentreatpolicy = 'retreat';
                details.ynextscreen       = 3;
                
                % Set new housing construction plan for the region
                region.houseconstruction(data.furtherconstruction);
                
            case 90  % Combination of interventions without housing construction
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.6 .9 .9]; cleanfaceproject = [.6 .9 .9];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
                % Retreat hyper biannually for 3 years then screen again
                %
                % NOTE: policy specific to Alice Springs Remote
                details.screentreatpolicy = 'retreat';
                details.ynextscreen       = 3;
                
            case 10  % Proposed targets
                
                % New screening method of only 5-9 year olds
                details.screen.method = '5-9';
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [0 .85 0]; cleanfaceproject = [.85 .85 .85];
                
                % New treatment coverage
                details.treat.coverage = .85;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Select alternative policy number
                details.screentreatpolicy = 'biannual';
                details.ynextscreen       = 3;
                
                % Biannual screening and treatment policy
                %
                % 1) Binally re-treats hyperendemic communities (>=20%) every 6 months for 2
                % years (MDA), then screen 36 months after inital screening
                %
                % 2) Annually re-treats meso- and hypo-endemic communities (>=5%, <20%) for 2
                % years (MDA), then screen 36 months after initial screening
                %
                % 3) One-off treats communities with prevalence less than 5% (household contacts),
                % then re-screen them 12, 36 and 60 months after inital screening (assuming that
                % prevalence remains under 5%)
                
            case 11  % Current targets
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.8 .8 .8]; cleanfaceproject = [.7 .7 .7];
                
                % New treatment coverage
                details.treat.coverage = .9;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
        end
        
    case 'Kimberley'            % Kimberley alternative scenarios
        
        % Set up switch case for future scenario
        switch opt.futurescenario
            
            case 101 % Increase screening
                
                % New minimum screening coverage
                screeningproject = [.5 .9 .5];
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
            case 102 % Further increase screening
                
                % New minimum screening coverage
                screeningproject = [.8 .9 .9];
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
            case 2   % Increase treatment
                
                % New treatment coverage
                details.treat.coverage = .98;
                
            case 3   % Increase facial cleanliness
                
                % New minimum clean face prevalence
                cleanfaceproject = [.9 1 1];
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 4   % Increase facial cleanliness, screening and treatment
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.8 .9 .9]; cleanfaceproject = [.9 1 1];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 6   % Re-treat hyperendemic communities every 6 months
                
                % Set alternative treatment policy
                details.screentreatpolicy = 'retreat';
                
            case 7   % Screen only 5-9 year olds
                
                % New screening method of only 5-9 year olds
                details.screen.method = '5-9';
                
                % New minimum screening coverage
                screeningproject = [0 .9 0];
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
            case 8   % Increase housing construction
                
                % Set new housing construction plan for the region
                region.houseconstruction(data.furtherconstruction);
                
            case 9   % Combination of all interventions
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.8 .9 .9]; cleanfaceproject = [.9 1 1];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
                % Set alternative treatment policy
                details.screentreatpolicy = 'retreat';

                % Set new housing construction plan for the region
                region.houseconstruction(data.furtherconstruction);
                            
            case 90  % Combination of interventions without housing construction
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.8 .9 .9]; cleanfaceproject = [.9 1 1];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Set alternative treatment policy
                details.screentreatpolicy = 'retreat';
                
            case 10  % Proposed targets
                
                % New screening method of only 5-9 year olds
                details.screen.method = '5-9';
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [0 .85 0]; cleanfaceproject = [.85 .85 .85];
                
                % New treatment coverage
                details.treat.coverage = .85;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Select alternative policy number
                details.screentreatpolicy = 'biannual';
                details.ynextscreen       = 3;
                
                % Biannual screening and treatment policy
                %
                % 1) Binally re-treats hyperendemic communities (>=20%) every 6 months for 2
                % years (MDA), then screen 36 months after inital screening
                %
                % 2) Annually re-treats meso- and hypo-endemic communities (>=5%, <20%) for 2
                % years (MDA), then screen 36 months after initial screening
                %
                % 3) One-off treats communities with prevalence less than 5% (household contacts),
                % then re-screen them 12, 36 and 60 months after inital screening (assuming that
                % prevalence remains under 5%)
  
            case 11  % Current targets
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.8 .8 .8]; cleanfaceproject = [.7 .7 .7];
                
                % New treatment coverage
                details.treat.coverage = .9;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
        end
        
    case 'Darwin Rural'         % Darwin Rural alternative scenarios
        
        % Set up switch case for future scenario
        switch opt.futurescenario
            
            case 1   % Increase screening
                
                % New minimum screening coverage
                screeningproject = [.5 .9 .9];
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
            case 2   % Increase treatment
                
                % New treatment coverage
                details.treat.coverage = .98;
                
            case 3   % Increase facial cleanliness
                
                % New minimum clean face prevalence
                cleanfaceproject = [.8 .95 .95];
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 4   % Increase facial cleanliness, screening and treatment
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.5 .9 .9]; cleanfaceproject = [.8 .95 .95];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
            case 501 % Synchronise screening
                
                % Number of weeks to synchronise within
                screensync = 8; treatsync = 4;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
            case 502 % Further synchronise screening
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
            case 6   % Re-treat hyperendemic communities every 6 months
                
                % Set alternative treatment policy
                details.screentreatpolicy = 'retreat';
                
            case 8   % Increase housing construction
                
                % Set new housing construction plan for the region
                region.houseconstruction(data.furtherconstruction);
                
            case 9   % Combination of all interventions
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.5 .9 .9]; cleanfaceproject = [.8 .95 .95];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
                % Set alternative treatment policy
                details.screentreatpolicy = 'retreat';
                
                % Set new housing construction plan for the region
                region.houseconstruction(data.furtherconstruction);
                
            case 90  % Combination of interventions without housing construction
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.5 .9 .9]; cleanfaceproject = [.8 .95 .95];
                
                % New treatment coverage
                details.treat.coverage = .98;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Number of weeks to synchronise within
                screensync = 4; treatsync = 2;
                
                % Call nested synchronise function to sort out details
                details = syncscreentreat(screensync, treatsync, details);
                
                % Set alternative treatment policy
                details.screentreatpolicy = 'retreat';
                
            case 10  % Proposed targets
                
                % New screening method of only 5-9 year olds
                details.screen.method = '5-9';
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [0 .85 0]; cleanfaceproject = [.85 .85 .85];
                
                % New treatment coverage
                details.treat.coverage = .85;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
                
                % Select alternative policy number
                details.screentreatpolicy = 'biannual';
                details.ynextscreen       = 3;
                
                % Biannual screening and treatment policy
                %
                % 1) Binally re-treats hyperendemic communities (>=20%) every 6 months for 2
                % years (MDA), then screen 36 months after inital screening
                %
                % 2) Annually re-treats meso- and hypo-endemic communities (>=5%, <20%) for 2
                % years (MDA), then screen 36 months after initial screening
                %
                % 3) One-off treats communities with prevalence less than 5% (household contacts),
                % then re-screen them 12, 36 and 60 months after inital screening (assuming that
                % prevalence remains under 5%)
                
            case 11  % Current targets
                
                % New minimum screening coverage and clean face prevalence
                screeningproject = [.8 .8 .8]; cleanfaceproject = [.7 .7 .7];
                
                % New treatment coverage
                details.treat.coverage = .9;
                
                % Set this minimum coverage into the treatment details structure
                details.screen.coverage(:, :, yfut) = max(details.screen.coverage...
                    (:, :, yfut), repmat(screeningproject, [ncomms, 1, nfut]));
                
                % Set this minimum prevalence into details structure
                details.cleanfaceprev(:, :, yfut) = max(details.cleanfaceprev...
                    (:, :, yfut), repmat(cleanfaceproject, [ncomms, 1, nfut]));
        end  
end


%% NESTED FUNCTIONS

% Syncronise screening and treatment events
    function details = syncscreentreat(screensync, treatsync, details)
        
        % Start in the middle of the year and determine this years screening
        startscreen = ((y-1)*dt + dt/2) - (screensync/2);
        firstscreen = startscreen + floor(rand(ncomms, 1) .* screensync + 1);
        
        % After end of screening, determine this years treatment timings
        starttreat = max(firstscreen) + floor(rand(2, 1) .* (weeksbeforetreat + 1)); starttreat(2, 1) = max(starttreat);
        firsttreat = repmat(starttreat', ncomms, 1) + repmat(floor(rand(ncomms, 1) .* treatsync + 1), 1, 2);
        
        % Ensure that all treatment sessions are within treatsync timesteps
        firsttreat = min(firsttreat, min(firsttreat(:, 1)) + treatsync);
        
        % Each consecutive round of screening and treatment for each community
        details.screen.timing(:, yfut) = repmat(firstscreen, 1, nfut) + ...
            [zeros(ncomms, 1) repmat((1:nfut-1) .* dt, ncomms, 1)];
        details.treat.timing(:, :, yfut) = repmat(firsttreat, [1 1 nfut]) + ...
            repmat(reshape([zeros(ncomms, 1) repmat((1:nfut-1) .* dt, ncomms, 1)], ncomms, 1, nfut), [1 2 1]);
    end
end