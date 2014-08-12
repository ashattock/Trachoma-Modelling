%% HOUSEHOLD
%
% A layer of the region-community-household-agent structure

classdef household < handle
    
    
    %% Define household properties
    properties(SetAccess = private, GetAccess = public)
        
        % Append options, identifier and community
        opt
        identifier
        communityid
        
        % Agents in the household (resident and temporary)
        agentsinhousehold   = []
        tempagentshousehold = []
        agentsawayhousehold = []
        
        % Whether trachoma was found in the household
        trachomafound
    end
    
    
    %% Persistent variables
    methods(Static = true)
        
        % Persistent birth rate
        function value = birthrate(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent death rate
        function value = deathrate(input)
            
            % Keep death rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent household mixing matrix
        function value = householdmixingmatrix(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent temporary household mixing matrix
        function value = temporarymixingmatrix(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent community transmission coefficient
        function value = betahousehold(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent migration rate
        function value = migrationrate(input)
            
            % Keep migration rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
        
        % Persistent migration duration
        function value = migrationduration(input)
            
            % Keep migration rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
    end
    
    
    %% Household functionality
    methods(Access = public)
        
        % Household constructor function
        function this = household(create)
            
            % Append options, identifier and community
            this.opt         = create.opt;
            this.identifier  = create.identifier;
            this.communityid = create.community;
            
            % Agents in the household (resident and temporary)
            this.agentsinhousehold   = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            this.tempagentshousehold = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            this.agentsawayhousehold = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            
            % Whether trachoma was found in the household
            this.trachomafound = 0;
        end
        
        % Agent death (returns number dead and visiting agents)
        function [ndeaths, awaydeaths] = agentdeath(this)
            
            % Initiate outputs
            ndeaths = 0; awaydeaths = [];
            
            % Persistant death rate
            deathrate = household.deathrate;
            
            % Check both residents and temporary visitors
            agenttype = {'agentsinhousehold', 'tempagentshousehold'};
            
            % Iterate through the types of agents to check
            for i = 1:numel(agenttype)
                
                % All of the agents in the household
                agents = values(this.(agenttype{i}));
                
                % Iterate through the agents in the household
                for j = 1:numel(agents)
                    
                    % The current agent, and their age
                    curragent = agents{j}; currage = curragent.age;
                    
                    % Get the number of deaths for a person of that age
                    deathsyear = deathrate(2, currage + 1);
                    
                    % Get the factor to turn this into a probability
                    %
                    % NOTE: Per 100,000 people for all non-babies (and per 1000 babies)
                    if currage == 0, perperson = 10e2; else perperson = 10e4; end
                    
                    % The probability of death for the currentAgent
                    probdeath = deathsyear / (perperson * this.opt.timestep);
                    
                    % Check for agent death and increment the counter
                    if rand < probdeath, ndeaths = ndeaths + 1;
                        
                        % Remove dead residents from household container
                        if i == 1, this.removeagent(curragent); else
                            
                            % Remove temporary visitors from container
                            this.removetempagent(curragent);
                            
                            % Output the dead temp agent
                            %
                            % NOTE: This is to remove them from their resident container
                            awaydeaths = [awaydeaths agents(j)]; %#ok<AGROW>
                        end
                    end
                end
            end
        end
        
        % Agent births
        function birth = agentbirth(this, t, cleanfaceprev)
            
            % Trivial output
            birth = 0;
            
            % Persistant birth rate
            birthrate = this.birthrate;
            maxadults = size(birthrate, 2);
            
            % Determine number of adults in house (from people array)
            adultages = this.opt.childagegroups(end) + 1:this.opt.maxage;
            nadults   = min(sum(sum(this.people(adultages + 1, :))), maxadults);
            
            % It takes 2 to tango...
            if nadults < 2, return; end
            
            % Check if the the household will produce a birth
            if rand < birthrate(2, nadults), birth = 1;
                
                % Ok, let's create a new agent
                
                % Determine a parent (for preferred destination details)
                agents = values(this.agentsinhousehold);
                adages = cellfun(@(x) x.agegroup, agents);
                parent = agents{randsample(find(adages == max(adages)), 1)};
                
                % Append agent age, age group and birthday
                create.age      = 0;
                create.agegroup = 1;
                create.birthday = mod(t, 52);
                
                % Assume child is born susceptible
                create.diseasestate = 'S';
                
                % Determine clean face status based on community prevalence
                if rand < cleanfaceprev, create.cleanface = 1;
                else create.cleanface = 0; end
                
                % Community and household ID
                create.community = this.communityid;
                create.household = this.identifier;
                
                % Temporary community and household ID
                create.tempcommunity = parent.preftempcommunity;
                create.temphousehold = parent.preftemphousehold;
                
                % Set last disease cases as trivial
                last.exposed = 0; last.infected = 0; last.diseased = 0;
                
                % Append trivial disease conditions
                create.nextprogress = 0; create.thisduration = 0; create.last = last;

                % Finally, append the options
                create.opt = this.opt;
                
                % Create this new agent
                babyagent = agent(create);
                
                % Add the new agent to this household
                this.addagent(babyagent)
            end
        end
        
        % Progress infection
        function progressinfection(this, t)
            
            % All of the agents in the household
            agents     = values(this.agentsinhousehold);
            tempagents = values(this.tempagentshousehold);
            
            % Gather them together
            allagents = [agents tempagents];
            
            % Iterate through the agents in the household
            for i = 1:numel(allagents)
                
                % The current agent
                curragent = allagents{i};
                
                % Also age agents - check if the agent has a birthday
                if mod(t - curragent.birthday, this.opt.timestep) == 0
                    
                    % If so, age them by by one year
                    curragent.agentbirthday();
                end
                
                % Conditions to be satisfied to progress trachoma state for 1) t=1, and 2) t>1
                conditions = [curragent.trachomaupdatetime + curragent.trachomastateduration <= 1, ...
                    t == curragent.trachomaupdatetime + curragent.trachomastateduration];
                
                % Use condition(1) for the first timestep, and condition(2) thereafter
                if t == 1, thiscond = conditions(1); else thiscond = conditions(2); end
                
                % Check whether condition is satisfied
                if thiscond == 1
                    
                    % Get the Trachoma Status of the currentAgent
                    switch curragent.trachomastate;
                        
                        % Progress agent to the infected class
                        case 'E', curragent.trachomastateE2I(t)
                            
                            % Progress agent to the diseased class
                        case 'I', curragent.trachomastateI2D(t)
                            
                            % Progress agent back to the partially diseased class
                        case 'D', curragent.trachomastateD2P(t)
                            
                            % Progress agent back to the susceptible class
                        case 'P', curragent.trachomastateP2S(t)
                    end
                end
            end
        end
        
        % Transmission between agents in the household
        function waifw = transmissionhousehold(this, t)
            
            % Set up blank counter
            waifw = zeros(this.opt.nagegroups);
            
            % Obtain all transmission factors
            infectivity   = community.infectivity;   % Infectivity by age array
            betahousehold = household.betahousehold; % Household coefficient
            gamma         = community.gamma;         % Dirty face transmission factor
            
            % Also call the two types of mixing matrix
            mixingmatrix  = household.householdmixingmatrix(); % Mixing matrix
            tempmixmatrix = household.temporarymixingmatrix(); % Temp mixing matrix
            
            % Also the community dependent transmission parameters
            foivalues = community.foivalues;         % Community dependent coefficient
            thisfoi   = foivalues(this.communityid); % Coefficient for this community
            
            % Concatonate all the infectious agents
            allinfagents = this.infectiousagents;
            ninfagents   = numel(allinfagents);
            
            % Only bother if any infecteds in this household
            if ninfagents > 0
                
                % Initiate matrices to store key facts about infectious agents
                thisinfage = zeros(1, ninfagents);
                infgroup   = zeros(1, ninfagents);
                infface    = zeros(1, ninfagents);
                
                % Also initiate two mixing matrices for temp and resident
                infmix      = zeros(this.opt.nagegroups, ninfagents);
                inftempmix  = zeros(this.opt.nagegroups, ninfagents);
                
                % Iterate through infectious agents
                for i = 1:ninfagents
                    
                    % Store key stats about infectious agents
                    thisinfage(i) = allinfagents{i}.age;
                    infgroup(i)   = allinfagents{i}.agegroup;
                    
                    % Determine the appropriate transmission factor for a dirty face
                    if allinfagents{i}.dirtyface == 1, infface(i) = 1;
                        
                        % ... and also for having a clean face
                    else infface(i) = 1 / gamma;
                    end
                    
                    % Check if agent is from different community
                    if allinfagents{i}.communityid ~= this.communityid,
                        
                        % Set mixing probabilitis accordingly
                        infmix(:, i) = tempmixmatrix(:, infgroup(i));
                        
                        % ... or if they are a resident member
                    else infmix(:, i) = mixingmatrix(:, infgroup(i));
                    end
                    
                    % If looking at temp susceptible use temp matrix regardless
                    inftempmix(:, i) = tempmixmatrix(:, infgroup(i));
                end
                
                % Infectivity of infecteds (+1 is for 0 year olds)
                infect = infectivity(2, thisinfage + 1);
                
                % All of the agents in the household
                agents  = values(this.agentsinhousehold);
                tagents = values(this.tempagentshousehold);
                
                % All the susceptible agents
                susagents     = agents(cellfun(@(x)  x.trachomastate == 'S' || 'D' || 'P', agents));
                sustempagents = tagents(cellfun(@(x) x.trachomastate == 'S' || 'D' || 'P', tagents));
                
                % Concatonate all the susceptible agents
                allsusagents = [susagents sustempagents];
                nsusagents   = numel(allsusagents);
                
                % Iterate through susceptible agents
                for i = 1:nsusagents
                    
                    % The current susceptible agent
                    curragent = allsusagents{i};
                    
                    % Easy index some key stats about this agent
                    currgroup = curragent.agegroup;
                    
                    % Check if agent is from different community
                    if curragent.communityid ~= this.communityid,
                        
                        % Set mixing probabilitis accordingly
                        mixing = inftempmix(currgroup, :);
                        
                        % ... or if they are a resident member
                    else mixing = infmix(currgroup, :);
                    end
                    
                    % Determine transmission factor due to susceptibles dirty face
                    currface       = curragent.dirtyface;
                    currfacefactor = currface + (1 - currface) * (1 / gamma);
                    
                    % The proability of infection between the two agents
                    probinfection = ones(1, ninfagents) ... Number of contacts
                        .* currfacefactor ...   Susceptible dirty face factor  ...
                        .* infface ...          Infected dirty face factor
                        .* thisfoi ...          This community transmission factor
                        .* betahousehold ...    Household transmission factor
                        .* mixing ...           Mixing rate
                        .* infect;  %           Infectivity of infected
                    
                    % Generate random numbers to check for transmission
                    acquiredinfection = rand(1, ninfagents) < probinfection;
                    
                    % Check if the transmission occurs
                    if any(acquiredinfection)
                        
                        % The age of the person that infected this susceptible
                        thisinfage = infgroup(find(acquiredinfection == 1, 1, 'first'));
                        
                        % Increment who-acquires-infection-from-whom counter
                        waifw(thisinfage, currgroup) = waifw(thisinfage, currgroup) + 1;
                        
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
        
        % Move migrating and returning agents out of household
        function [migrating, returning] = agentmigrationout(this, t, allhouses)
            
            % Obtain all persistent migration factors
            migrationrate     = this.migrationrate();
            migrationduration = this.migrationduration();
            
            % All of the agents in the household
            agents = values(this.agentsinhousehold);
            
            % Which agents will actually migrate from this household
            migrating = agents(rand(1, numel(agents)) < ...
                migrationrate(2, cellfun(@(x) x.age + 1, agents)));
            
            % Iterate through the migrating agents
            for i = 1:numel(migrating)
                
                % The current agent
                curragent = migrating{i};
                
                % Update migration time
                curragent.migrationstart = t;
                
                % Determine period of temporary migration
                curragent.migrationduration = community.discreteinvrnd(migrationduration, 1, 1);
                
                % Add them to temp container and remove from resident container
                this.addagentaway(curragent);
                this.removeagent(curragent);
                
                % Is agent going to migrate to preferred temporary destination?
                if rand < this.opt.probtempdest
                    
                    % Get preferred holiday destination details
                    tempcommunity = curragent.preftempcommunity;
                    temphousehold = curragent.preftemphousehold;
                else
                    
                    % Otherwise generate new holiday destination details
                    tempcommunity = ceil(rand * length(allhouses));
                    temphousehold = ceil(rand * allhouses(tempcommunity));
                end
                
                % Store the details of where this agent is headed
                curragent.actualtempcommunity = tempcommunity;
                curragent.actualtemphousehold = temphousehold;
            end
            
            % All of the temp agents in the household
            tempagents = values(this.tempagentshousehold);
            
            % Which agents will move home from this household
            returning = tempagents(cellfun(@(x) x.migrationstart + ...
                x.migrationduration, tempagents) == t);
            
            % Remove all returning agents from temporary container
            for i = 1:numel(returning), this.removetempagent(returning{i}); end
        end
        
        % Screening process
        function nscreen = screeningprocess(this, t, y, details)
            
            % Initiate screening results matrix
            nscreen = zeros(this.opt.maxage + 1, 2);
            
            % Screening coverage for this community in this year
            thiscoverage = details.screen.coverage(this.communityid, :, y);
            
            % If screening coverage is 0 return out of function
            if nansum(thiscoverage) == 0, return; end
            
            % Set up a switch case for screening method
            switch details.screen.method
                
                % What are the age conditions of this method
                case '1-14', agecond = [1 14];
                case '5-9',  agecond = [5 9];
            end
            
            % Screen both residents and temporary visitors
            agenttype = {'agentsinhousehold', 'tempagentshousehold'};
            
            % Incorporate temporary agent factor
            typefactor = [1 this.opt.migschool];
            
            % Iterate through the types of agents to check
            for i = 1:numel(agenttype)
                
                % Appropriate factors for resident and temporary agents
                thisfactor = typefactor(i);
                
                % All of the agents in the household
                agents = values(this.(agenttype{i}));
                
                % Iterate through the agents in the household
                for j = 1:numel(agents)
                    
                    % The current agent, and their age
                    curragent = agents{j};
                    currage   = curragent.age;
                    
                    % Is the agent of the appropriate age?
                    if and(currage >= agecond(1), currage <= agecond(2))
                        
                        % Will they be screened (according to screening coverage)?
                        if rand < thiscoverage(curragent.agegroup) * thisfactor
                            
                            % Increment the screened column
                            nscreen(currage + 1, 1) = nscreen(currage + 1, 1) + 1;
                            
                            % Check whether the agent is diseased
                            diseased = strcmp(curragent.trachomastate, this.opt.states(this.opt.disease));
                            
                            % Screen the current agent and treat disease straight away
                            if any(diseased)
                                
                                % Treat infectious agents straight away
                                if diseased(1) == 1, curragent.treatinfectedagent(t); end
                                
                                % Increment the active disease column
                                nscreen(currage + 1, 2) = nscreen(currage + 1, 2) + 1;
                            end
                        end
                    end
                end
            end
            
            % Set whether trachoma was found as a property of the household
            if sum(nscreen(:, 2)) > 0, this.trachomafound = 1;
            else this.trachomafound = 0; end
        end
        
        % Update clean face prevalence after screening
        function updatecleanfaces(this, cleanfaceupdate)
            
            % All of the agents in the household and those away
            agents     = values(this.agentsinhousehold);
            awayagents = values(this.agentsawayhousehold);
            
            % Concatonate all agents
            allagents = [agents awayagents];
            
            % Get only the young agents in the household
            childagents = allagents(cellfun(@(x) x.age <= this.opt.childagegroups(end), allagents));
            
            % Iterate through the young agents
            for i = 1:numel(childagents)
                
                % The current agent
                curragent = childagents{i};
                
                % The new clean face prevalence for a child of this age group
                thisupdate = cleanfaceupdate(curragent.agegroup);
                
                % Skip process if no update is available
                if ~isnan(thisupdate)
                    
                    % See if agent should have a dirty face
                    if rand < thisupdate, curragent.dirtyface = 0;
                    else                  curragent.dirtyface = 1; end
                end
            end
        end
        
        % Treat all agents in a household
        function ntreat = treathousehold(this, t, details, type)
            
            % Set up switch case for type of agent to be treated
            switch type
                
                % Set age constraint on who is to be treated
                case 'all',      agecon = this.opt.maxage + 1;
                case 'children', agecon = this.opt.childagegroups(end) + 1;
            end
            
            % Initiate matrix and easy reference treatment coverage
            ntreat        = zeros(this.opt.maxage + 1, 2);
            treatcoverage = details.treat.coverage;
            
            % All of the agents in the household
            agents     = values(this.agentsinhousehold);
            tempagents = values(this.tempagentshousehold);
            
            % Concatonate all agents and get those to be treated
            allagents   = [agents tempagents];
            theseagents = allagents(cellfun(@(x) x.age <= agecon, allagents));
            theseagents = theseagents(rand(1, numel(theseagents)) < treatcoverage / 100);
            
            % Iterate through agents
            for i = 1:numel(theseagents)
                
                % The current agent
                curragent = theseagents{i};
                currage   = curragent.age;
                
                % Increment the treated column
                ntreat(currage + 1, 1) = ntreat(currage + 1, 1) + 1;
                
                % Set up switch case for trachoma state of agent
                switch curragent.trachomastate
                    
                    % Treat exposed agents
                    case 'E', curragent.treatexposedagent();
                        
                        % Increment the treated with infection column
                        ntreat(currage + 1, 2) = ntreat(currage + 1, 2) + 1;
                        
                        % Treat infected agents
                    case 'I', curragent.treatinfectedagent(t);
                        
                        % Increment the treated with infection column
                        ntreat(currage + 1, 2) = ntreat(currage + 1, 2) + 1;
                end
            end
        end
        
        % Add agent to household as a resident
        function addagent(this, agent)
            
            % Add agent to the current household
            this.agentsinhousehold(agent.identifier) = agent;
        end
        
        % Remove agent from household container
        function removeagent(this, agent)
            
            % Remove agent from the current household
            remove(this.agentsinhousehold, agent.identifier);
        end
        
        % Add agent to temporary migration container
        function addtempagent(this, agent)
            
            % Add temporary agent to current household
            this.tempagentshousehold(agent.identifier) = agent;
        end
        
        % Remove agent from temporary migration container
        function removetempagent(this, agent)
            
            % Remove agent from temporary migration container
            remove(this.tempagentshousehold, agent.identifier);
        end
        
        % Add agent to temporarily away container
        function addagentaway(this, agent)
            
            % Add agent temporarily away container
            this.agentsawayhousehold(agent.identifier) = agent;
        end
        
        % Remove agent from temporarily away container
        function removeagentaway(this, agent)
            
            % Remove agent from temporarily away container
            remove(this.agentsawayhousehold, agent.identifier);
        end
        
        % Get all infectious agents in the household
        function infagents = infectiousagents(this)
            
            % All of the agents in the household
            agents     = values(this.agentsinhousehold);
            tempagents = values(this.tempagentshousehold);
            
            % Concatonate them together
            allagents = [agents tempagents];
            
            % Get only the infectious agents
            infagents = allagents(cellfun(@(x) x.trachomastate == 'I', allagents));
        end
        
        % Get number of people by age and trachoma status
        function allpeople = people(this)
            
            % Matrix with dimensions age x n trachoma states (+1 for age 0)
            allpeople = zeros(this.opt.maxage + 1, this.opt.nstates);
            
            % All of the agents in the household
            agents     = values(this.agentsinhousehold);
            tempagents = values(this.tempagentshousehold);
            
            % Concatonate them together
            allagents = [agents tempagents];
            
            % Iterate through the agents in the household
            for i = 1:numel(allagents)
                
                % Matrix representing this agent
                thisagent = zeros(size(allpeople));
                
                % Place a one in the appropriate element (age x trachoma)
                thisagent(allagents{i}.age + 1, strcmp(this.opt.states, ...
                    allagents{i}.trachomastate)) = 1;
                
                % Increment the household matrix by one
                allpeople = allpeople + thisagent;
            end
        end
    end
end
