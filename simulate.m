%% SIMULATE
%
% This function sets the persistant parameters and actually runs the model.

function sim = simulate(paramset, parameters, data, opt)

% Start the simulation timer
simtimer = tic;


%% Initalise sim structure with calibration details

% Append calibration details to output
sim.calibration.paramset   = paramset;
sim.calibration.parameters = parameters;

% Only test failed parameter sets if calibrating
if opt.calibration == 1
    
    % Which parameters have been calibrated
    caliparams = 1:opt.samplestoload;
    failparams = opt.failedparams;
    
    % Take out samples we want to ignore and those already calibrated
    failparams(ismember(failparams, opt.samplesignore)) = [];
    caliparams(ismember(caliparams, failparams)) = [];
    
    % Return back to launch if this parameter set has already been calibrated
    if ismember(paramset, caliparams), sim.calibration.alreadycalibrated = 1; return; end
end


%% Easy reference calibrated parameters

% Calibrated parameters
betahousehold     = parameters(1, 1);
betacommunity     = betahousehold / parameters(2, 1);
gamma             = parameters(3, 1);
treatcoverage     = parameters(4, 1);

% Probabilities of contact
contacts.low      = parameters(5, 1);
contacts.med      = parameters(6, 1);
contacts.high     = parameters(7, 1);
contacts.veryhigh = parameters(8, 1);


%% Easy reference key options and data

% Number of communities
ncommunities = data.ncommunities;

% Time related options
dt         = opt.timestep;   % Timesteps for each year
runyears   = opt.runyears;   % Run the model between these years
ndatayears = opt.ndatayears; % Number of years of data points (including 2006)
burnperiod = opt.burnperiod; % Years to run before screening and treatment begin

% Get the number iterations to run the simulations for
pts  = runyears(1):1/dt:runyears(end);      sim.pts  = pts;
npts = numel(pts);                          sim.npts = npts;

% Which iterations to display
weekdisp = opt.weekdisp;
yeardisp = opt.yeardisp;

% Used for prevalence calculations
prevyrs = opt.prevyrs;
disease = opt.disease;


%% Set persistant values

% Transmission coefficients
household.betahousehold(betahousehold);
community.betacommunity(betacommunity);

% Community dependent transmission coefficients
community.foivalues(data.foivalues(:, 1));

% Clean face reduction-in-transmission-probability factor
community.gamma(gamma);

% Set mixing matrices
household.householdmixingmatrix(contactmatrix('Household',      contacts));
household.temporarymixingmatrix(contactmatrix('Temp Household', contacts));
community.communitymixingmatrix(contactmatrix('Community',      contacts));

% Propensity of an agent to temporarily migrate
household.migrationrate(data.migrationbyage);
household.migrationduration(data.migrationduration);

% Probability of agent birth and death
household.birthrate(data.birthrate);
household.deathrate(data.deathrate);

% Infectivity of an agent by age
community.infectivity(data.infectivityrate);

% Length of various disease states
community.exposed(data.exposedduration);
community.infected(data.infectionduration);
community.diseased(data.diseaseduration);

% Housing construction scheme
region.houseconstruction(data.housingimprovements);


%% Screening method, timing and coverage

% Set screening details into single structure
details.screen.coverage = data.screeningcoverage;
details.screen.timing   = data.screeninground;
details.screen.method   = opt.screenmethod;

% Set treatment details into the same structure
details.treat.coverage  = treatcoverage;
details.treat.timing    = data.treatmentround;

% Set standard screening procedure
details.screentreatpolicy = opt.defaultpolicy;

% Observed clean face prevalence
details.cleanfaceprev = data.cleanfaceprev;

% Easy reference if running past evaluation (i.e. no interventions)
pasteval = opt.pastevaluation;


%% Initialise model output

% Preallocate 4-dimensional array
people = zeros(opt.maxage + 1, opt.nstates, ncommunities, npts);

% Preallocate prevalence arrays
regionprev = zeros(1, npts);
commprev   = zeros(ncommunities, npts);

% Preallocate brith and death arrays
deaths = zeros(1, npts);
births = zeros(1, npts);

% Set up blank counters for WAIFW matrices
waifwcommunity = zeros(opt.nagegroups, opt.nagegroups, npts);
waifwhousehold = zeros(opt.nagegroups, opt.nagegroups, npts);

% Preallocate arrays for numbers screened and treated
screened = zeros(ncommunities, npts);
treated  = zeros(ncommunities, npts);

% Preallocate arrays for number of infectious people screened and treated
screenedinfected = zeros(ncommunities, npts);
treatedinfected  = zeros(ncommunities, npts);


%% Simulation rejection settings

% Easy access calibration flag
calibration = opt.calibration;

% Prevalence bounds and number of errors allowed
prevbounds = opt.prevbounds(opt.regionref, :);
maxerrors  = opt.maxerrors;

% When to start and stop counting errors
starterr = opt.starterr;
stoperr  = burnperiod * dt;

% Initiate error counter
nerrs = [0 0];


%% Create a Region

% Set the random number generator seed
rng(paramset);

% Create the region
thisregion = region(data, opt);


%% The model

% Iterate through the timesteps
for t = 1:npts, y = ceil(t / dt);
    
    % Display the week that is simulating
    if weekdisp, disp(['  week ' num2str(t)]); end
    
    
    %% Return conditions for calibration
    
    % Check we want to count errors during this time step
    if t >= starterr && t <= stoperr
        
        % Check the regional trachoma prevalence against the lower bound
        if regionprev(t - 1) < prevbounds(1), nerrs(1) = nerrs(1) + 1;
            
            % Check the regional trachoma prevalence against the upper bound
        elseif regionprev(t - 1) > prevbounds(2), nerrs(2) = nerrs(2) + 1;
        end
        
        % If the iterations are consistantly above the bounds
        if max(nerrs) > maxerrors
            
            % Define the reason for failure (below or above bounds)
            if nerrs(1) > maxerrors, reason = 'below'; else reason = 'above'; end
            
            % Display what's going on, and when this has happened
            cprintf(opt.calcols{1}, ['Parameter set %d rejected for being %s' ...
                ' prevalence bounds after %d iterations\n'], paramset, reason, t);
            
            % Append the number of errors to the output
            sim.calibration.rejected = nerrs;
            
            return; % Return to launch
        end
        
        % Return back to launch if claibration flag is on
        if t == stoperr && calibration == 1
            
            % Display the good news!
            cprintf(opt.calcols{2}, 'Parameter set %d accepted (errors: [%d %d])\n', ...
                paramset, nerrs(1), nerrs(2));
            
            % Append the number of errors to the output
            sim.calibration.accepted = nerrs;
            
            return; % Return to launch
        end
    end
    
    
    %% Future intervention scenarios
    
    % Check if a new year has started
    if  mod(t, dt) == 1
        
        % Display which year we have finished iterating
        if yeardisp, disp(['  running year ' num2str(runyears(y))]); end
        
        % The conditions to be satisfied to call scenarios function
        conds = [pasteval == 0, opt.futurescenario ~= 0, ...
            t == (burnperiod + ndatayears) * dt + 1];
        
        % Call scenario to determine future screening, treatment and housing policy
        if all(conds), details = scenarios(y, details, data, opt);
            
            % Call function to give communities new screening dates
            thisregion.nextscreenevent(y - 1, details);
            thisregion.nexttreatevent(y - 1, details);
        end
    end
    
    
    %% Weekly operations
    
    % Weekly operation 1 - Agent death
    deaths(t) = thisregion.agentdeath();
    
    % Weekly operation 2 - Agent birth
    births(t) = thisregion.agentbirth(t);
    
    % Weekly operation 3 - Progress agents through the disease classes
    thisregion.progressinfection(t);
    
    % Weekly operation 4 - Community transmission
    waifwcommunity(:, :, t) = thisregion.transmissioncommunity(t);
    
    % Weekly operation 5 - Household transmission
    waifwhousehold(:, :, t) = thisregion.transmissionhousehold(t);
    
    % Weekly operation 6 - Agent migration between communities
    thisregion.agentmigration(t);
    
    % Check that the housing scheme is in progress
    if and(pts(t) >= opt.housingscheme(1), pts(t) < opt.housingscheme(2)) && pasteval == 0
        
        % Weekly operation 7 - Build new houses
        thisregion.buildnewhouses(t, y);
    end
    
    
    %% Screening and treatment operations
    
    % Start checking for screening and treatment events after burn period
    if t >= burnperiod * dt && pasteval == 0
        
        % Screen as necessary
        [nscreen, details] = thisregion.screeningprocess(t, y, details);
        
        % Treat as necessary
        [ntreat, details] = thisregion.treatmentprocess(t, y, details);
        
        % Store number screened and treated (and number infectious screened and treated)
        screened(:, t) = nscreen(:, 1); screenedinfected(:, t) = nscreen(:, 2);
        treated(:, t)  = ntreat(:, 1);  treatedinfected(:, t)  = ntreat(:, 2);
    end
    
    
    %% Weekly outputs
    
    % Update people array
    people(:, :, :, t) = thisregion.people;
    
    % Determine region level prevalence
    regionprev(t) = sum(sum(sum(people(prevyrs + 1, disease, :, t)))) ...
        / sum(sum(sum(people(prevyrs + 1, :, :, t))));
    
    % Determine community level prevalence
    commprev(:, t) = squeeze(sum(sum(people(prevyrs + 1, disease, :, t))) ...
        ./ sum(sum(people(prevyrs + 1, :, :, t))));
    
    
end


%% Append all model output into sim structure

% 4-dim people array
sim.people = people;

% Region and community-level prevalence
sim.regionprev = regionprev;
sim.commprev   = commprev;

% Number of briths and deaths
sim.deaths = deaths;
sim.births = births;

% Who-acquires-infection-from-whom matrices
sim.waifwcommunity = waifwcommunity;
sim.waifwhousehold = waifwhousehold;

% Screening results
sim.screened         = screened;
sim.screenedinfected = screenedinfected;

% Treatment results
sim.treated         = treated;
sim.treatedinfected = treatedinfected;

% Finally append the simulation time
sim.timetaken = datestr(datenum(0, 0, 0, 0, 0, toc(simtimer)), 'HH:MM:SS');

% Display the time taken if appropriate
if opt.timedisp, disp(['  paramater set ' num2str(paramset) ' complete (' sim.timetaken ')']); end


end

