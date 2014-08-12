%% AGENT
%
% A layer of the region-community-household-agent structure

classdef agent < handle
    
    
    %% Define agent properties
    properties(SetAccess = public, GetAccess = public)
        
        % Append options and set identifier
        opt         
        identifier  
        
        % Age related details
        age
        agegroup
        birthday
        
        % Resident community and household details
        householdid
        communityid
        
        % Temporary community and household details
        preftemphousehold
        preftempcommunity
        actualtemphousehold
        actualtempcommunity
        
        % Trachoma state details
        trachomastate
        trachomaupdatetime
        trachomastateduration
        
        % Previous trachoma state details
        lastexposedduration
        lastinfectedduration
        lastdiseasedduration
        
        % Dirty face and migration details
        dirtyface
        migrationstart
        migrationduration
    end
    
    
    %% Agent functionality
    methods(Access = public)
            
        % Agent constructor function
        function this = agent(create)
            
            % Append the options struct
            this.opt = create.opt;
            
            % Creates an identifier (some <= 10 digit number) for each agent
            this.identifier = int32(unifrnd(1, 100000000));
            
            % Age related details
            this.age      = create.age;
            this.agegroup = create.agegroup;
            this.birthday = create.birthday;
            
            % Resident community and household details
            this.householdid = create.household;
            this.communityid = create.community;
            
            % Temporary community and household details
            this.preftemphousehold   = create.temphousehold;
            this.preftempcommunity   = create.tempcommunity;
            this.actualtemphousehold = 0;
            this.actualtempcommunity = 0;
            
            % Trachoma state details
            this.trachomastate         = create.diseasestate;
            this.trachomaupdatetime    = create.nextprogress;
            this.trachomastateduration = create.thisduration;
            
            % Previous trachoma state details
            this.lastexposedduration  = create.last.exposed;
            this.lastinfectedduration = create.last.infected;
            this.lastdiseasedduration = create.last.diseased;
            
            % Dirty face and migration details
            this.dirtyface         = 1 - create.cleanface;
            this.migrationstart    = 0;
            this.migrationduration = 0;
        end
        
        % Increase agent Age as it is their birthday. Yay.
        function agentbirthday(this)
            
            % Increment agent's age (as long as it's under maxage)
            if this.age < this.opt.maxage, this.age = this.age + 1; end
            
            % Update age group index
            agegroups     = [this.opt.childagegroups this.opt.maxage];
            this.agegroup = find(this.age <= agegroups, 1, 'first');
            
            % If they have just become an adult, they have a clean face
            if this.age > this.opt.childagegroups(end), this.dirtyface = 0; end
        end
        
        % Change trachoma state after infection
        function trachomastateS2E(this, t)
            
            % Change agents trachoma state following transmission
            this.trachomastate = 'E';
            
            % Updates the agents disease progression time
            this.trachomaupdatetime = t;
            
            % Generates the agents new trachoma state duration
            this.trachomastateduration = community.discreteinvrnd(community.exposed, 1, 1);
            
            % Update the agents last exposed class duration
            this.lastexposedduration = this.trachomastateduration;
        end
        
        % Change trachoma state after re-infection
        function trachomastateP2I(this, t)
            
            % Change agentstrachoma state following transmission
            this.trachomastate = 'I';
            
            % Updates the agents Disease Progression Time
            this.trachomaupdatetime = t;
            
            % Generates the agents new Trachoma State Duration
            this.trachomastateduration = this.lastinfectedduration;
        end
        
        % Update trachoma state after re-infection
        function trachomastateD2D(this, t)
            
            % Updates the agents Trachoma Update Time
            this.trachomaupdatetime = t;
        end
        
        % Progress trachoma state from exposed to infected
        function trachomastateE2I(this, t)
            
            % Progress agent from 'E' class to 'I' class
            this.trachomastate = 'I';
            
            % Updates the agents trachoma update time
            this.trachomaupdatetime = t;
            
            % Get the infected duration pdf
            infduration = community.infected;
            
            % Generate the new infected period
            infperiod = community.discreteinvrnd(infduration(this.agegroup, :), 1, 1);
            
            % Generates the agents new trachoma state duration
            this.trachomastateduration = max(1, infperiod - this.lastexposedduration);
            
            % Update the agents last infected class duration
            this.lastinfectedduration = this.trachomastateduration;
        end
        
        % Progress trachoma state from infected to diseased
        function trachomastateI2D(this, t)
            
            % Progress agent from 'I' class to 'D' class
            this.trachomastate = 'D';
            
            % Updates the agents trachoma update time
            this.trachomaupdatetime = t;
            
            % Get the diseased duration pdfs
            disduration = community.diseased;
            
            % Generate the new infected period
            disperiod = community.discreteinvrnd(disduration(this.agegroup, :), 1, 1);
            
            % Generates the agents new trachoma state duration
            this.trachomastateduration = round(max(1, disperiod - this.lastinfectedduration) / 2);
        end
        
        % Progress trachoma state from diseased to partially diseased
        function trachomastateD2P(this, t)
            
            % Progress agent from 'D' class to 'S' class
            this.trachomastate = 'P';
            
            % Updates the agents trachoma update time
            this.trachomaupdatetime = t;
        end
        
        % Progress trachoma state from partially diseased to susceptible
        function trachomastateP2S(this, t)
            
            % Progress agent from 'D' class to 'S' class
            this.trachomastate = 'S';
            
            % Updates the agents trachoma update time
            this.trachomaupdatetime = t;
            
            % Reset the agents trachoma state duration
            this.trachomastateduration = 0;
            
            % Also reset last episode information
            this.lastexposedduration = 0;
            this.lastinfectedduration = 0;
            this.lastdiseasedduration = 0;
        end
        
        % Change agent trachoma state after treatment
        function treatexposedagent(this)
            
            % Change agents trachoma state following treatment
            this.trachomastate = 'S';
            
            % Make the necessary trivial updates
            this.trachomaupdatetime    = 0;
            this.trachomastateduration = 0;
            this.lastexposedduration   = 0;
        end
        
        % Change agent trachoma state after treatment
        function treatinfectedagent(this, t)
            
            % Progress agent from 'I' class to 'D' class
            this.trachomastate = 'D';
            
            % Updates the agents trachoma update time
            this.trachomaupdatetime = t;
            
            % Get the diseased duration pdfs
            disduration = community.diseased;
            
            % Generate the new infected period
            disperiod = community.discreteinvrnd(disduration(this.agegroup, :), 1, 1);
            
            % Generates the agents new Trachoma State Duration
            this.trachomastateduration = round(max(1, disperiod - this.lastinfectedduration) / 2);
            
            % Then reset the agents last infectious class duration
            this.lastinfectedduration = 0;
        end
    end
end