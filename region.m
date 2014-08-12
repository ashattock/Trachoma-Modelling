%% REGION
%
% A layer of the region-community-household-agent structure

classdef region < handle
    
    
    %% Define community properties
    properties(SetAccess = private, GetAccess = public)
        
        % Append options and identifier
        opt
        identifier
        
        % Region name and communities in region
        regionname
        communitiesinregion
    end
    
    
    %% Persistent variables
    methods(Static = true)
        
        % Persistent community mixing matrix
        function value = houseconstruction(input)
            
            % Keep birth rates in memory
            persistent storedvalue;
            
            % Commit input to memory
            if nargin == 1, storedvalue = input; end
            
            % Output the memorised rates
            value = storedvalue;
        end
    end
    
    
    %% Region functionality
    methods(Access = public)
        
        % Region constructor function
        function this = region(data, opt)
            
            % Append the options struct
            this.opt = opt;
            
            % Append region reference and name
            this.identifier = opt.regionref;
            this.regionname = opt.regionname;
            
            % Create containers and set up region fields
            this.communitiesinregion = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            
            % Create the desired number of communities
            this.createcommunity(opt, data)
        end
        
        % Agent death
        function ndeaths = agentdeath(this)
            
            % Step 1) Resident or temporary agent deaths
            
            % Initiate counter and array
            ndeaths = 0; awaydeaths = [];
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Determine who will die this time step
                [deaths, tempagents] = communities{i}.agentdeath();
                
                % Increment counter and concatonate temp agent deaths
                ndeaths    = ndeaths + deaths;
                awaydeaths = [awaydeaths tempagents]; %#ok<AGROW>
            end
            
            % Step 2) Remove away agents from resident container
            
            % Iterate through dead away agents
            for i = 1:numel(awaydeaths)
                
                % Remove dead agents from resident container
                communities{awaydeaths{i}.communityid}.agentdeathaway(awaydeaths{i})
            end
        end
        
        % Agent birth
        function nbirths = agentbirth(this, t)
            
            % Initiate counter
            nbirths = 0;
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Give birth as appropriate
                nbirths = nbirths + communities{i}.agentbirth(t);
            end
        end
        
        % Progress infection
        function progressinfection(this, t)
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Progress agents disease state as necessary
                communities{i}.progressinfection(t);
            end
        end
        
        % Transmission between agents in the community
        function waifw = transmissioncommunity(this, t)
            
            % Set up counter for who-acquires-infection-from-whom
            waifw = zeros(this.opt.nagegroups);
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Determine who gets infected from who
                waifw = waifw + communities{i}.transmissioncommunity(t);
            end
        end
        
        % Transmission between agents in the household
        function waifw = transmissionhousehold(this, t)
            
            % Set up blank counter
            waifw = zeros(this.opt.nagegroups);
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Determine who gets infected from who
                waifw = waifw + communities{i}.transmissionhousehold(t);
            end
        end
        
        % Moves all of the agents about for temporary migration
        function agentmigration(this, t)
            
            % Step 1) Move any people out (resident or temporary)
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            allhouses   = this.housespercommunity;
            
            % Initiate arrays
            migratingagents = [];
            returningagents = [];
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % All migrating and returning agents from the community
                [migrating, returning] = communities{i}.agentmigrationout(t, allhouses);
                
                % Concatonate agents
                migratingagents = [migratingagents migrating]; %#ok<AGROW>
                returningagents = [returningagents returning]; %#ok<AGROW>
            end
            
            % Step 2) Move migrating people into temporary household
            
            % Iterate through migrating agents
            for i = 1:numel(migratingagents)
                
                % Move migrating people into temporary household
                communities{migratingagents{i}.actualtempcommunity}...
                    .agentmigrationin(migratingagents{i}, 'Temporary')
            end
            
            % Step 3) Move returning people back into resident household
            
            % Iterate through returning agents
            for i = 1:numel(returningagents)
                
                % Move returning people back into resident household
                communities{returningagents{i}.communityid}...
                    .agentmigrationin(returningagents{i}, 'Resident')
            end
        end
        
        % Screening process
        function [screen, details] = screeningprocess(this, t, y, details)
            
            % All of the communities in the region
            communities  = values(this.communitiesinregion);
            
            % Initiate screening results matrix
            screen = zeros(numel(communities), 2);
            
            % Which communities are to be screened in this timestep
            communitiestoscreen = communities(cellfun(@(x) x.nextscreening == t, communities));
            
            % Iterate through the communities to be screened in the region
            for i = 1:numel(communitiestoscreen)
                
                % Get current community
                currcommunity = communitiestoscreen{i};
                
                % Test conditions for a community to stop screening
                %
                % a) Community has been below 5% prevalence for 5 concecutive years
                % b) Community has graduated under alternative projection 10
                ceaseconds = ([currcommunity.yearsunder5percent ...
                    currcommunity.hypo5yearcount] >= [5 3]);
                
                % Check that this community should still be screened
                if ~any(ceaseconds)
                    
                    % Screen the current community
                    [nscreen, details] = currcommunity.screeningprocess(t, y, details);
                    
                    % Store how many people were screened this round
                    screen(currcommunity.identifier, :) = sum(nscreen, 1);
                    
                    % Current communities clean face prevalence for the next year
                    thiscleanfaceprev = details.cleanfaceprev(currcommunity.identifier, :, y);
                    
                    % Update the clean face prevalence vector for current community
                    currcommunity.updatecleanfaces(thiscleanfaceprev);
                end
            end
        end
        
        % Assign next screening event as a property
        function nextscreenevent(this, y, details)
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Assign next screening event to this community as a property
                communities{i}.nextscreenevent(y, details);
            end
        end
        
        % Treatment process
        function [treat, details] = treatmentprocess(this, t, y, details)
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Initiate screening results matrix
            treat = zeros(numel(communities), 2);
            
            % Which communities are to be treated in this timestep
            communitiestotreat = communities(cellfun(@(x) and(t >= x.nexttreatment(1), t <= x.nexttreatment(2)), communities));
            
            % Iterate through the communities to be treated in the region
            for i = 1:numel(communitiestotreat)
                
                % Get current community
                currcommunity = communitiestotreat{i};
                
                % Get nexttreatment vector for current community
                nexttreat = currcommunity.nexttreatment;
                
                % Probability of treating community this time point (from nexttreat)
                if t == nexttreat(2), probtreatnow = 1;
                else probtreatnow = 1 / numel(nexttreat(1):nexttreat(2)); end
                
                % Treat people in the current community
                [ntreat, details] = currcommunity.treatmentprocess(t, y, details, probtreatnow);
                
                % Store how many people were screened this round
                treat(currcommunity.identifier, :) = sum(ntreat, 1);
            end
        end
        
        % Assign next treatment event as a property
        function nexttreatevent(this, y, details)
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % Assign next treatment event to this community as a property
                communities{i}.nexttreatevent(y, details);
            end
        end
        
        % Build new houses through housing construction scheme
        function buildnewhouses(this, t, y)
            
            % All of the communities in the region
            communities = values(this.communitiesinregion);
            
            % Step 1) Set new building plan at the beginning of each year
            
            % Check that a new year has started
            if mod(t, this.opt.timestep) == 1
                
                % The number of years building has been going on
                projectyear = this.opt.runyears(y) - this.opt.housingscheme(1) + 1;
                
                % Persistant housing construction array
                houseconstruction = this.houseconstruction;
                
                % Number of houses in each community
                nhousescommunity = this.housespercommunity;
                
                % Iterate through the communities in the region
                for i = 1:numel(communities)
                    
                    % The current community
                    currcommunity = communities{i};
                    currcommid    = currcommunity.identifier;
                    
                    % Get the number of houses to build this year
                    nhousestobuild = houseconstruction(currcommid, projectyear) - nhousescommunity(1, currcommid);
                    
                    % Set the communities building plan for this year
                    currcommunity.setbuildingplan(nhousestobuild);
                end
            end
            
            % Step 2) Build the houses
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % The current community
                currcommunity     = communities{i};
                currhousestobuild = currcommunity.housestobuild;
                
                % Check houses should actually be built this year
                if currhousestobuild > 0 && currcommunity.housesbuilt < currhousestobuild
                    
                    % Work out the time between each build
                    timebetweenbuilds = floor(this.opt.timestep / currhousestobuild);
                    
                    % If we should build this week continue
                    if mod(t, timebetweenbuilds) == 0, currcommunity.buildnewhouses(); end
                end
            end
        end
        
        % Get number of houses in each community
        function nhouses = housespercommunity(this)
            
            % Communities in the region
            communities  = values(this.communitiesinregion);
            ncommunities = numel(communities);
            
            % Initiate array to store number of houses
            nhouses = zeros(1, ncommunities);
            
            % Iterate through the communities in the region
            for i = 1:ncommunities
                
                % People by community
                nhouses(i) = numel(values(communities{i}.housesincommunity));
            end
        end
        
        % Get number of people by age and trachoma status
        function allpeople = people(this)
            
            % Communities in the region
            communities = values(this.communitiesinregion);
            
            % 3-dim matrix with age x n trachoma states X n communities
            allpeople = zeros(this.opt.maxage + 1, this.opt.nstates, numel(communities));
            
            % Iterate through the communities in the region
            for i = 1:numel(communities)
                
                % People by community
                allpeople(:, :, i) = sum(communities{i}.people, 3);
            end
        end
    end
    
    
    %% Private functionality
    methods(Access = private)
        
        % Create community function
        function createcommunity(this, opt, data)
            
            % Preallocate some essential structures
            create        = struct;
            diseasestruct = struct;
            
            % Iterate through child age groups (including 15+)
            for j = 1:opt.nagegroups
                
                % Append disease states
                diseasestruct(j).diseasestate = opt.states;
            end
            
            % Easy index screening and treatment rounds
            screenrounds = data.screeninground;
            treatrounds  = data.treatmentround;
            
            % Create NumberOfCommunities many communitiesinregion
            for i = 1:data.ncommunities
                
                % Community ID
                create(i).identifier = i;
                
                % Number of houses and agents in this community
                create(i).nhouses = data.demographics(i, 2);
                create(i).nagents = data.demographics(i, 1);
                
                % Get the preferred holiday destination for all in the community
                create(i).preftempcommunity = data.migrationdata(i, 1);
                
                % Are interventions switched on?
                if opt.pastevaluation == 0
                    
                    % Index of first screen and treat rounds
                    firstscind = find(~isnan(screenrounds(i, :)), 1, 'first');
                    firsttrind = (find(~isnan(treatrounds(i,  :, :)), 1, 'first') + 1) / 2;
                    
                    % Ensure treatment round data is in correct form
                    assert(~isnan(treatrounds(i, 2, firsttrind)), ...
                        'Error with treatment timing data');
                    
                    % First screen round
                    create(i).nextscreen = screenrounds(i, firstscind);
                    create(i).nexttreat  = treatrounds(i, :, firsttrind);
                else
                    
                    % Set trivial timings if running without interventions
                    create(i).nextscreen = 0; create(i).nexttreat = [0 0];
                end
                
                % Set an initailly trivial retreatment flag
                create(i).retreatment = 0;
                
                % Iterate through child age groups
                for j = 1:opt.nagegroups
                    
                    % Indices of trachoma distributions across age groups
                    theseinds = opt.nstates * (j - 1) + 1:opt.nstates * j;
                    
                    % Append trachoma distribution across age groups
                    diseasestruct(j).pdf = data.childtrachoma(i, theseinds);
                end
                
                % Get the age structure (from 0 to opt.maxage)
                agestruct.age = 0:opt.maxage;
                agestruct.pdf = data.agestructure(i, :);
                
                % Append these substructures
                create(i).diseasestruct = diseasestruct;
                create(i).agestruct     = agestruct;
                
                % Get the clean face prevalence of the community
                create(i).cleanfaces = data.initialcleanface(i, :);
                
                % Finally, append all the options
                create(i).opt = opt;
                
                % Create the community
                thiscommunity = community(create(i));
                
                % Add the community to this region
                this.addcommunity(thiscommunity);
                
                % Add the appropriate number of agents to the community
                thiscommunity.addagents(create(i).nagents, data.demographics(:, 2)');
            end
        end
        
        % Add household function
        function addcommunity(this, community)
            
            % Add the given community to the communitiesinregion container
            this.communitiesinregion(community.identifier) = community;
        end
    end
end