%% COMMUNITY
%
% A layer of the region-community-household-agent structure

classdef community < handle
    
    
    %% Define community properties
    properties(SetAccess = private, GetAccess = public)
        
        % Append options and set identifier
        opt
        identifier
        
        % Houses in community, and migration preference
        housesincommunity = []
        preftempcommunity
        
        % Upcoming screening and treatment events
        nextscreening
        nexttreatment
        
        % Current treatment policy
        retreatment
        biannualtreat
        annualtreat
        clustertreat
        
        % Graduation details
        hypo5yearplan
        hypo5yearcount
        yearsunder5percent
        
        % Disease and clean face prevalence
        observedprevalence
        cleanfaceprev
        
        % Disease and age structures
        diseasestruct
        agestruct
        
        % Household construction details
        housestobuild
        housesbuilt
    end
    
    
    %% Persistent variables
    methods(Static = true)
        
        % Persistent community mixing matrix
        function value = communitymixingmatrix(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent community transmission coefficient
        function value = betacommunity(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent clean face transmission reduction
        function value = gamma(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent infected duration
        function value = infected(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent diseased duration
        function value = diseased(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent exposed duration
        function value = exposed(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent infectivity rate
        function value = infectivity(input)
            
            % Keep infectivity rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent community FoI coefficients
        function value = foivalues(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Discrete inversion method function
        function value = discreteinvrnd(pdf, m, n)
            
            % Preallocate memory
            value = zeros(m, n);
            
            % Determine value
            for i = 1:m * n, value(i) = find(rand < cumsum(pdf), 1, 'first'); end
        end
    end
    
    
    %% Community functionality
    methods(Access = public)

        % Community constructor function
        function this = community(create)
            
            % Append options and set identifier
            this.opt        = create.opt;
            this.identifier = create.identifier;
            
            % Houses in community
            this.housesincommunity = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            
            % Migration preference
            this.preftempcommunity = create.preftempcommunity;
            
            % Upcoming screening and treatment events
            this.nextscreening = create.nextscreen;
            this.nexttreatment = create.nexttreat;
            
            % Current treatment policy
            this.retreatment   = create.retreatment;
            this.biannualtreat = 0;
            this.annualtreat   = 0;
            this.clustertreat  = 0;
            
            % Graduation details
            this.hypo5yearplan      = 0;
            this.hypo5yearcount     = 0;
            this.yearsunder5percent = 0;
            
            % Disease and clean face prevalence
            this.observedprevalence = 0;
            this.diseasestruct      = create.diseasestruct;
            
            % Disease and age structures
            this.agestruct     = create.agestruct;
            this.cleanfaceprev = create.cleanfaces;
            
            % Household construction details
            this.housestobuild = 0;
            this.housesbuilt   = 0;
            
            % Create the desired number of houses
            this.createhousehold(create.nhouses);
        end
        
        % Agent death (returns number dead and visiting agents)
        function [ndeaths, awaydeaths] = agentdeath(this)
            
            % Initiate outputs
            ndeaths = 0; awaydeaths = [];
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Determine who will die this time step
                [deaths, awayagents] = households{i}.agentdeath();
                
                % Increment counter and concatonate temp agent deaths
                ndeaths    = ndeaths + deaths;
                awaydeaths = [awaydeaths awayagents]; %#ok<AGROW>
            end
        end
        
        % Removes dead away agent from resident container
        function agentdeathaway(this, agent)
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Removed them from the temporarily away container
            households{agent.householdid}.removeagentaway(agent);
        end
        
        % Agent births
        function nbirths = agentbirth(this, t)
            
            % Initiate counter
            nbirths = 0;
            
            % Community clean face prevalence among young children
            childcleanface = this.cleanfaceprev(1);
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Iterate through the communities in the region
            for i = 1:numel(households)
                
                % Give birth as appropriate
                nbirths = nbirths + households{i}.agentbirth(t, childcleanface);
            end
        end
        
        % Progress infection
        function progressinfection(this, t)
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Progress their disease class if necessary
                households{i}.progressinfection(t);
            end
        end
        
        % Community transmission function
        function waifw = transmissioncommunity(this, t)
            
            % Set up counter for who-acquires-infection-from-whom
            waifw = zeros(this.opt.nagegroups);
            
            % Obtain all transmission factors
            infectivity   = community.infectivity;   % Infectivity by age array
            betacommunity = community.betacommunity; % Community coefficient
            gamma         = community.gamma;         % Dirty face transmission factor
            mixingmatrix  = community.communitymixingmatrix; % Mixing matrix
            
            % Also the community dependent transmission parameters
            foivalues = community.foivalues;         % Community dependent coefficient
            thisfoi   = foivalues(this.identifier);  % Coefficient for this community
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Set up empty vectors to store infecteds
            infecteds = [];
            
            % Iterate through the households
            for i = 1:numel(households)
                
                % Concatonate all of the infected agents from each household
                infecteds = [infecteds households{i}.infectiousagents]; %#ok<AGROW>
            end
            
            % Call the numbers infected
            ninfected = length(infecteds);
            
            % Work out how many of these an individual will actually meet this time step
            ninfcontacts = round((ninfected / sum(sum(sum(this.people)))) * this.opt.ncontacts);
            
            % So which ones can spread infection
            contacts = infecteds(ceil(ninfected * rand(1, ninfcontacts)));
            
            % Intiate matrix for ages and clean face status
            contage   = zeros(1, ninfcontacts);
            contgroup = zeros(1, ninfcontacts);
            contface  = zeros(1, ninfcontacts);
            
            % Iterate through this vector
            for i = 1:ninfcontacts
                
                % Store agent age
                contage(1, i)   = contacts{i}.age;
                contgroup(1, i) = contacts{i}.agegroup;
                
                % Determine the appropriate transmission factor for a dirty face
                if contacts{i}.dirtyface == 1, contface(1, i) = 1;
                    
                    % ... and also for having a clean face
                else contface(1, i) = 1 / gamma;
                end
            end
            
            % Infectivity of contacts (+1 is for 0 year olds)
            continfect = infectivity(2, contage + 1);
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Get current household
                currhousehold = households{i};
                
                % All of the agents in the Current household
                agents     = values(currhousehold.agentsinhousehold);
                tempagents = values(currhousehold.tempagentshousehold);
                
                % Concatonate agents
                allagents = [agents tempagents];
                
                % Susceptible children
                susagents = allagents(cellfun(@(x) x.age <= this.opt.childagegroups(end), allagents));
                susagents = susagents(cellfun(@(x) ~any(strcmp(x.trachomastate, {'E', 'I'})), susagents));
                
                % Iterate through these Agents
                for j = 1:numel(susagents)
                    
                    % The current agent
                    curragent = susagents{j};
                    
                    % Determine how agent mixes with contacts
                    currind = curragent.agegroup;
                    mixing  = mixingmatrix(currind, contgroup);
                    
                    % Determine transmission factor due to susceptibles dirty face
                    currface       = curragent.dirtyface;
                    currfacefactor = currface + (1 - currface) * (1 / gamma);
                    
                    % Force of infection for the infected contacts
                    probinfection = ones(1, ninfcontacts) ... Number of contacts
                        .* currfacefactor ...    Susceptible dirty face factor
                        .* contface ...          Infected dirty face factor
                        .* thisfoi ...           This community transmission factor
                        .* betacommunity ...     Community transmission factor
                        .* mixing ...            Mixing rate
                        .* continfect; %         Infectivity of infected
                    
                    % Generate random numbers to check for transmission
                    acquiredinfection = rand(1, ninfcontacts) < probinfection;
                    
                    % Has this agent acquired infection from the contacts?
                    if any(acquiredinfection)
                        
                        % The age of the person that infected this susceptible
                        thiscontage = contgroup(find(acquiredinfection == 1, 1, 'first'));
                        
                        % Increment who-acquires-infection-from-whom counter
                        waifw(thiscontage, currind) = waifw(thiscontage, currind) + 1;
                        
                        % The trachoma status of the current agent
                        switch curragent.trachomastate;
                            
                            % Agent moves to exposed class
                            case 'S', curragent.trachomastateS2E(t);
                                
                                % Agent restarts in the diseased stage
                            case 'D', curragent.trachomastateD2D(t);
                                
                                % Agent goes back to the infected stage
                            case 'P', curragent.trachomastateP2I(t);
                        end
                    end
                end
            end
        end
        
        % Transmission between agents in the household
        function waifw = transmissionhousehold(this, t)
            
            % Set up counter for who-acquires-infection-from-whom
            waifw = zeros(this.opt.nagegroups);
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Determine who gets infected from who
                waifw = waifw + households{i}.transmissionhousehold(t);
            end
        end
        
        % Move migrating and returning agents out of household
        function [migrating, returning] = agentmigrationout(this, t, allhouses)
            
            % Initiate arrays
            migrating = [];
            returning = [];
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Move migrating and returning agents out of household
                [thismigrating, thisreturning] = households{i}.agentmigrationout(t, allhouses);
                
                % Concatonate agents
                migrating = [migrating thismigrating]; %#ok<AGROW>
                returning = [returning thisreturning]; %#ok<AGROW>
            end
        end
        
        % Moves migrating and returning agent into household
        function agentmigrationin(this, agent, type)
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Set up switch case for type
            switch type
                
                case 'Resident'
                    
                    % Add the agent back into the resident container
                    households{agent.householdid}.addagent(agent);
                    
                    % Removed them from the temporarily away container
                    households{agent.householdid}.removeagentaway(agent);
                    
                case 'Temporary'
                    
                    % Add the agent back into the resident container
                    households{agent.actualtemphousehold}.addtempagent(agent)
                    
                otherwise, error('Migration case unknown');
            end
        end
        
        % Screening process
        function [nscreen, details] = screeningprocess(this, t, y, details)
            
            % Step 1) Screen each household in this community
            
            % Initiate screening results matrix
            nscreen = zeros(this.opt.maxage + 1, 2);
            
            % All of the households in the community
            households = values(this.housesincommunity);
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Screen the current household
                nscreen = nscreen + households{i}.screeningprocess(t, y, details);
            end
            
            % Easy indes which observed prevalences we want to calculate
            observe = this.opt.observeprev;
            
            % Iterate through how many we need to do
            for i = 1:size(observe, 1)
                
                % Set up a suitable field name
                thisfield = ['prev' num2str(observe(i, 1)) 'to' num2str(observe(i, 2))];
                
                % The indices these ages correspond to in nscreen matrix
                thisinds = observe(i, 1):observe(i, 2);
                
                % Observed prevalence in this age group
                thisprev = sum(nscreen(thisinds, 2)) / sum(nscreen(thisinds, 1));
                
                % Append the field with the prevalence
                observedprev.(thisfield) = thisprev;
            end
            
            % Set structure as a class property
            this.observedprevalence = observedprev;
            
            % Step 2) Determine future policy based on this screening event
            
            % Easy access epidemic thresholds
            threshold = this.opt.threshold;
            
            % Reset these incase they've been turned on by the previous session
            this.biannualtreat = 0; this.annualtreat = 0;
            
            % Set up switch case for screening policy
            switch details.screentreatpolicy
                
                case {'default', 'retreat'} % Defualt screening policy
                    
                    % Check if the stars have alighned to perform biannual treatment
                    if strcmp(details.screentreatpolicy, 'retreat') && ...
                            observedprev.prev1to9 >= threshold.hyper
                        
                        % Switch on biannual treatment and reset hypo counter
                        this.biannualtreat      = 1;
                        this.yearsunder5percent = 0;
                        
                        % For Alice Springs Remote, don't screen again for ynextscreen years
                        if strcmp(this.opt.regionname, 'Alice Springs Remote')
                            
                            % Number of years later to screen again
                            ynextscreen = details.ynextscreen;
                            
                            % Screen again in ynextscreen years
                            details.screen.timing(this.identifier, y + ynextscreen) = ...
                                t + (this.opt.timestep * ynextscreen);
                            
                            % Make sure we don't go screening before then
                            details.screen.timing(this.identifier, y + 1:y + ynextscreen - 1) = nan;
                            
                            % Assign next screening event as a property
                            nextscreenevent(this, y, details);
                            
                            return % Return out of the screening function
                        end
                    end
                    
                    % Check prevalence of 1-9 year olds is under hypo threshold
                    if observedprev.prev1to9 < threshold.hypo
                        
                        % Increment the number of conceutive years the community has been under 5%
                        this.yearsunder5percent = this.yearsunder5percent + 1;
                        
                        % If the counter has reached 5
                        if this.yearsunder5percent >= 5
                            
                            % Set the next screening and treatment events to 0
                            this.nextscreening = 0; this.nexttreatment = [0 0];
                        end
                        
                        % Reset the consecutive years counter if greater than threshold
                    elseif observedprev.prev1to9 >= threshold.hypo, this.yearsunder5percent = 0;
                    end
                    
                    % Check that screening should continue
                    if this.yearsunder5percent < 5
                        
                        % Assign next screening event as a property
                        nextscreenevent(this, y, details);
                    end
                    
                case 'biannual' % Screen hyper and meso communities every 3 years, bianually treat hyper
                    
                    % Prevalence in 5-9 year olds is above hypo threshold
                    if observedprev.prev5to9 >= threshold.hypo
                        
                        % Hyperendemic communities get biannual treatment, others get annual
                        if observedprev.prev5to9 >= threshold.hyper, this.biannualtreat = 1;
                        else this.annualtreat = 1; end
                        
                        % Switch off 5 year plan and reset the counter
                        this.hypo5yearplan = 0; this.hypo5yearcount = 0;
                        
                        % Number of years later to screen again
                        ynextscreen = details.ynextscreen;
                        
                        % Screen again in ynextscreen years
                        details.screen.timing(this.identifier, y + ynextscreen) = ...
                            t + (this.opt.timestep * ynextscreen);
                        
                        % Make sure we don't go screening before then
                        details.screen.timing(this.identifier, y + 1:y + ynextscreen - 1) = nan;
                        
                        % Prevalence in 5-9 year olds is under hypo threshold
                    elseif observedprev.prev5to9 < threshold.hypo
                        
                        % Increment the number of screens the community has been under hypo threshold
                        this.hypo5yearcount = this.hypo5yearcount + 1;
                        
                        % If the counter has reached 3
                        if this.hypo5yearcount == 3
                            
                            % Set the next screening and treatment events to 0
                            this.nextscreening = 0; this.nexttreatment = [0 0];
                            
                            return % Return out of the screening function
                        end
                        
                        % If this community doesn't have a 5 year plan, begin one
                        if this.hypo5yearplan == 0, this.hypo5yearplan = 1;
                            
                            % Screen in 1, 3 and 5 years time (so nan out 2 and 4 years time)
                            details.screen.timing(this.identifier, [y + 2, y + 4]) = nan;
                        end
                        
                        % Ensure that a treatment event occurs next week
                        this.nexttreatment = [t + 1 t + 1];
                    end
                    
                    % Assign next screening event as a property
                    nextscreenevent(this, y, details);
            end
        end
        
        % Assign next screening event as a property
        function nextscreenevent(this, y, details)
            
            % Future screening times from details.timing
            thiscomtimes  = details.screen.timing(this.identifier, :);
            thiscomfuture = thiscomtimes(1, (y + 1):end);
            
            % Which future indices are non NaN
            futureinds = ~isnan(thiscomfuture);
            
            % Assign the closest future screening time
            if sum(futureinds) == 0, nextscreen = nan;
            else nextscreen = thiscomfuture(find(futureinds, 1, 'first')); end
            
            % Append this result as a property
            this.nextscreening = nextscreen;
        end
        
        % Update clean face prevalence after screening
        function updatecleanfaces(this, cleanfaceupdate)
            
            % Iterate through the enteries of cleanfaceprev vector
            for i = 1:this.opt.dataagegroups
                
                % Update community clean face prevalence as a property
                if ~isnan(cleanfaceupdate(i)), this.cleanfaceprev(1, i) = cleanfaceupdate(i); end
            end
            
            % Make sure there's at least one non-nan
            if any(~isnan(cleanfaceupdate))
                
                % All of the households in the community
                households = values(this.housesincommunity);
                
                % Iterate through the households in the community
                for i = 1:numel(households)
                    
                    % Distribute clean faces accordingly among the agents
                    households{i}.updatecleanfaces(cleanfaceupdate);
                end
            end
        end
        
        % Treatment process
        function [ntreat, details] = treatmentprocess(this, t, y, details, probtreatnow)
            
            % Initiate treatment output matrix
            ntreat = zeros(this.opt.maxage + 1, 2);
            
            % Also easy reference treatment policy and region name
            regionname = this.opt.regionname;
            threshold  = this.opt.threshold;
            policy     = details.screentreatpolicy;
            
            % All of the households in the community
            households = values(this.housesincommunity);
            nhouses    = numel(households);
            
            % Prevalence proxy to be used to decide treatment policy
            if strcmp(policy, 'biannual'), thisprev = this.observedprevalence.prev5to9;
            else thisprev = this.observedprevalence.prev1to9; end
            
            % Only treat this community if screening process occured
            if isnan(thisprev), return; end
            
            % Step 1) Set up retreatments if necessary (different policies for each region)
            
            % Set up switch case for the different regions
            switch regionname
                
                case 'Alice Springs Remote'
                    
                    % Check if necessary future projection is set up
                    if ~strcmp(policy, 'biannual')
                        
                        % For two treatment sessions per year without screening
                        if this.biannualtreat == 1;
                            
                            % Iterate through the households in the community
                            for i = 1:nhouses, ntreat = ntreat + households{i}.treathousehold(t, details, 'all'); end
                            
                            % Set the retreatment time to be in 6 months and return out of function
                            this.nexttreatment = repmat(t + this.opt.timestep / 2, 1, 2); return;
                        end
                        
                        % Alice Springs Remote had a shift in policy in 2010
                        if this.opt.runyears(y) >= 2010 && this.nexttreatment(1) == t
                            
                            % Turn off retreatment procress if already a retreatment
                            if this.retreatment == 1, this.retreatment = 0; else
                                
                                % Or arrange to retreat in six months time if appropriate
                                if thisprev >= threshold.hyper, this.retreatment = 1; end
                            end
                        end
                    end
                    
                case {'Kimberley', 'Darwin Rural'}
                    
                    % Check if necessary future projection is set up
                    if strcmp(policy, 'retreat') && this.nexttreatment(1) == t
                        
                        % Region specific thresholds (for Kimberley and Darwin Rural)
                        retreatthresh = [nan, threshold.meso, threshold.hypo];
                        thisthresh    = retreatthresh(this.opt.regionref);
                        
                        % Turn off retreatment procress or arrange to retreat in six months
                        if this.retreatment == 1, this.retreatment = 0;
                        else if thisprev >= thisthresh, this.retreatment = 1; end; end
                    end
            end
            
            % Step 2) Treat those that require treatment
            
            % Create a blank mask on the first iteration to determine who has already been treated
            if this.nexttreatment(1) == t, this.clustertreat = ones(1, nhouses); end
            
            % The houses to be treated in this timestep (considering probtreatnow)
            housestotreat = households(logical(this.clustertreat));
            housestotreat = housestotreat(rand(1, numel(housestotreat)) < probtreatnow);
            
            % Set threshold to not treat household if no trachoma was found there
            if strcmp(policy, 'biannual'), thisthres = 'hypo'; else thisthres = 'hyper'; end
            
            % Iterate through these households
            for i = 1:numel(housestotreat), currhousehold = housestotreat{i};
                
                % A seires of conditions to be met to not treat all in household
                conds = [strcmp(regionname, 'Kimberley'), strcmp(policy, 'default'), ...
                    currhousehold.trachomafound == 0, thisprev >= threshold.hyper];
                
                % Treat only children in every households if all above conditions are met
                if all(conds), ntreat = ntreat + currhousehold.treathousehold(t, details, 'children');
                else
                    
                    % If community is nonhyperendemic, treat household only if trachoma was found there
                    if thisprev < threshold.(thisthres) && currhousehold.trachomafound == 0, break; end
                    
                    % If we've made it this far, then treat all agents in the household
                    ntreat = ntreat + currhousehold.treathousehold(t, details, 'all');
                end
                
                % Resest this households need for treatement
                this.clustertreat(1, currhousehold.identifier) = 0;
            end
            
            % Step 3) Determine when next treatment event should occur
            
            % Set annual or biannual treatment times
            if strcmp(policy, 'biannual')
                
                % Set the retreatment time to be 6 or 12 months from now (dependent on policy)
                if this.biannualtreat == 1,   this.nexttreatment = repmat(t + this.opt.timestep/2, 1, 2);
                elseif this.annualtreat == 1, this.nexttreatment = repmat(t + this.opt.timestep,   1, 2); end
            else
                
                % Check whether it is the end of the treatment process
                if this.nexttreatment(2) == t
                    
                    % Set the retreatment time to be in 6 months if appropriate
                    if this.retreatment == 1, this.nexttreatment = repmat(t + this.opt.timestep / 2, 1, 2);
                    else
                        
                        % Future screening times from details.timing
                        thiscomtimes  = squeeze(details.treat.timing(this.identifier, :, :));
                        thiscomfuture = thiscomtimes(:, (y + 1):end);
                        
                        % Which future indices are non NaN
                        futureinds = ~isnan(thiscomfuture(1, :));
                        
                        % Assign the closest future treatment time
                        if sum(futureinds) == 0, nexttreat = [nan nan];
                        else nexttreat = thiscomfuture(:, find(futureinds, 1, 'first')); end
                        
                        % Append this result as a property
                        this.nexttreatment = nexttreat';
                    end
                end
            end
        end
        
        % Assign next treatment event as a property
        function nexttreatevent(this, y, details)
            
            % Future treatment times from details.timing
            thiscomtimes  = squeeze(details.treat.timing(this.identifier, :, :));
            thiscomfuture = thiscomtimes(:, (y + 1):end);
            
            % Which future indices are non NaN
            futureinds = ~isnan(thiscomfuture(1, :));
            
            % Assign the closest future screening time
            if sum(futureinds) == 0, nexttreat = [nan nan];
            else nexttreat = thiscomfuture(:, find(futureinds, 1, 'first')); end
            
            % Append this result as a property
            this.nexttreatment = nexttreat';
        end
        
        % Set housing construction plan for community
        function setbuildingplan(this, nhousestobuild)
            
            % Reset the number of houses that have been built this year
            this.housesbuilt = 0;
            
            % Set this communities building plan for this year
            this.housestobuild = nhousestobuild;
        end
        
        % Build new houses through housing construction scheme
        function buildnewhouses(this)
            
            % Number of houses currently in the community
            nhouseholds = numel(values(this.housesincommunity));
            
            % Create the new household (with id nhouses +1)
            this.createnewhousehold(nhouseholds + 1);

            % Put some people into the new household
            this.populatenewhousehold(nhouseholds + 1);
            
            % Increment the number of houses built this year
            this.housesbuilt = this.housesbuilt + 1;
        end
        
        % Populate household that has just been constructed
        function populatenewhousehold(this, householdid)
            
            % The household we want to populate
            households  = values(this.housesincommunity);
            nhouseholds = numel(households);
            thishouse   = households{householdid};
            
            % Average number of people per household in this community
            nagentsmove = ceil(sum(sum(sum(this.people))) / (nhouseholds - 1));
            fromhouse   = ceil(rand(1, nagentsmove) .* (nhouseholds - 1));
            
            % Iterate upto this number
            for i = 1:nagentsmove
                
                % Agents in house to take from
                oldhousehold   = households{fromhouse(i)};
                agentsoldhouse = values(oldhousehold.agentsinhousehold);
                
                % Set up a counter to ensure we don't get stuck
                findotherhousehold = 0;
                
                % Check that the household has more than one resident
                while numel(agentsoldhouse) <= 1

                    % Generate a new former household
                    oldhousehold = households{ceil(rand * (nhouseholds - 1))};
                    
                    % Get the agents in the former household
                    agentsoldhouse = values(oldhousehold.agentsinhousehold);
                    
                    % Make sure we don't get stuck - increment and break out if necessary
                    findotherhousehold = findotherhousehold + 1;
                    if findotherhousehold > 100, break; end
                end
                
                % Which agent is going to move
                movingagent = agentsoldhouse{ceil(rand * numel(agentsoldhouse))};
                
                % Remove them from former house container
                oldhousehold.removeagent(movingagent);
                
                % Update agent's houshold identifier
                movingagent.householdid = householdid;
                
                % Add them to the new household container
                thishouse.addagent(movingagent);
            end
        end

        % Assigns an age, a household and trachoma status to agents
        function addagents(this, nagents, othercomms)
            
            % Determine ages for our agents
            ageind = community.discreteinvrnd(this.agestruct.pdf, nagents, 1);
            ages   = this.agestruct.age(ageind); % This is essentially just -1
            
            % Randomly set up the households for these agents
            nhouseholds = numel(values(this.housesincommunity));
            households  = ceil(rand(1, nagents) * nhouseholds);
            
            % Randomly set up temporary households for these agents
            preferredtemphouse = ceil(rand(1, nhouseholds) * othercomms(this.preftempcommunity))';
            
            % Concatonate all age groups
            agegroups = [this.opt.childagegroups this.opt.maxage];
            
            % Concatonate adult liklihood of clean face (assuming 100%)
            cleanfaceprob = [this.cleanfaceprev 1];
            
            % Preallocate structure to hold agent details
            create = struct;
            
            % Iterate through each agent
            for i = 1:nagents
                
                % Append agent age
                create(i).age = ages(i);
                
                % Age group index (between 1 and this.opt.nagegroups)
                groupind = find(ages(i) <= agegroups, 1, 'first');
                create(i).agegroup = groupind;
                
                % Assign agent random birthday
                create(i).birthday = floor(rand * this.opt.timestep);
                
                % Index of trachoma status
                trachomaind = community.discreteinvrnd(...
                    this.diseasestruct(groupind).pdf, 1, 1);
                
                % The trachoma status associated with this index
                create(i).diseasestate = this.diseasestruct(groupind)...
                    .diseasestate{trachomaind};
                
                % Determine clean face status
                if rand < cleanfaceprob(1, groupind), create(i).cleanface = 1;
                else create(i).cleanface = 0; end
                
                % Community and household ID
                create(i).community = this.identifier;
                create(i).household = households(i);
                
                % Temporary community and household ID
                create(i).tempcommunity = this.preftempcommunity;
                create(i).temphousehold = preferredtemphouse(create(i).household);
                
                % Preset last disease cases as trivial - altered if necessary
                last.exposed = 0; last.infected = 0; last.diseased = 0;
                
                % Set up switch case dependent on trachoma state
                switch create(i).diseasestate
                    
                    % Trivial for susceptible state
                    case 'S', nextprogress = 0; thisduration = 0;
                        
                    case 'E' % Exposed state
                        
                        % Determine trachoma state duration and time update accordingly
                        last.exposed = max(1, community.discreteinvrnd(community.exposed, 1, 1));
                        
                        % When to next update trachoma state
                        nextprogress = round(rand * last.exposed) - last.exposed;
                        thisduration = last.exposed;
                        
                    case 'I' % Infected state
                        
                        % Get the infected duration pdf
                        iduration = community.infected; iduration = iduration(groupind, :);
                        
                        % Determine trachoma state duration
                        last.infected = max(1, community.discreteinvrnd(iduration, 1, 1) ...
                            - community.discreteinvrnd(community.exposed, 1, 1));
                        
                        % When to next update trachoma state
                        nextprogress = round(rand * last.infected) - last.infected;
                        thisduration = last.infected;
                        
                    case {'D', 'P'} % Diseased state
                        
                        % Get the infected and diseased duration pdfs
                        dduration = community.diseased; dduration = dduration(groupind, :);
                        iduration = community.infected; iduration = iduration(groupind, :);
                        
                        % Let the last infected duration be the same
                        lastinfected = max(1, community.discreteinvrnd(iduration, 1, 1) ...
                            - community.discreteinvrnd(community.exposed, 1, 1));
                        
                        % Determine trachoma state duration and time update accordingly
                        last.diseased = round(max(1, (community.discreteinvrnd(dduration, 1, 1) ...
                            - lastinfected) / 2));
                        
                        % When to next update trachoma state
                        nextprogress = round(rand * last.diseased) - last.diseased;
                        thisduration = last.diseased;
                end
                
                % Append these outcomes to the create structure
                create(i).nextprogress = nextprogress;
                create(i).last         = last;
                create(i).thisduration = thisduration;
                
                % Finally, append the options
                create(i).opt = this.opt;
                
                % Get the current agent and their household
                thisagent      = agent(create(i));
                agenthousehold = this.housesincommunity(create(i).household);
                
                % Add the Current agent to the Selected household
                agenthousehold.addagent(thisagent);
            end
        end
        
        % Get number of people by age and trachoma status
        function allpeople = people(this)
            
            % Households in the community
            households = values(this.housesincommunity);
            
            % 3-dim matrix with age x n trachoma states X n households
            allpeople = zeros(this.opt.maxage + 1, this.opt.nstates, numel(households));
            
            % Iterate through the households in the community
            for i = 1:numel(households)
                
                % Get current household
                currhousehold = households{i};
                
                % People by household
                allpeople(:, :, i) = currhousehold.people;
            end
        end
    end
    
    
    %% Private functionality
    methods(Access = private)
        
        % Create household
        function createhousehold(this, nhouses)
            
            % Preallocate structure array
            create = struct;
            
            % Create NumberOfHouseholds many housesincommunity
            for i = 1:nhouses
                
                % household identifier and community
                create(i).identifier = i;
                create(i).community  = this.identifier;
                
                % Append the options
                create(i).opt = this.opt;
                
                % Create household
                thishousehold = household(create(i));
                
                % Add the household to this community
                this.addhousehold(thishousehold);
            end
        end
        
        % Create new household from housing construction
        function createnewhousehold(this, newhouseid)
            
            % household identifier and community
            create.identifier = newhouseid;
            create.community  = this.identifier;
            
            % Append the options
            create.opt = this.opt;
            
            % Set up correct properties for the household
            newhousehold = household(create);
            
            % Add the newHousehold to this Community
            this.addhousehold(newhousehold);
        end
        
        % Add household to housesincommunity container
        function addhousehold(this, household)
            
            % Add the given household to housesincommunity container
            this.housesincommunity(household.identifier) = household;
        end
    end
end