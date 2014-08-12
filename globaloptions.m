%% LAUNCH OPTIONS
%
% Globally set all of the launch options. It makes life easier to have them
% in one place.

function opt = globaloptions(varargin)

% Create display 
disp(['Setting global options...' 10])

% If argument is given, return only what is specified
if nargin == 1, onlyreturn = varargin{1}; else onlyreturn = ''; end


%% Region

% Select the region to run
opt.regionref = 1;

% OPTIONS:
%
% 1) Alice Springs Remote
% 2) Kimberley
% 3) Darwin Rural

% Assign region name according to region ref
opt.regionname = regname(opt.regionref);


%% Scenarios

% Run a future scenario (see options below) and append name
opt.futurescenario = 0; % 0 3 4 8 9 10 11 99

% Past evaluation (turn on to ignore 2006-2011 interventions)
opt.pastevaluation = 0;

% Future scenario options:
%
% 0   = No future projection
% 99  = Baseline projection
% 10  = Proposed targets
% 11  = Current targets
% 1   = Alternative 1, ... , Alternative n
% 101 = Alternative 1a, 102 = Alternative 1b, etc
%
% Alice Springs: 99, 1,        2, 3, 4, 501, 502, 6,    8, 9, 90, 10, 11
% Kimberley:     99, 101, 102, 2, 3, 4,           6, 7, 8, 9, 90, 10, 11
% Darwin Rural:  99, 1,        2, 3, 4, 501, 502, 6,    8, 9, 90, 10, 11

% Overwrite futurescenario to trivial value if past evaluation is turned on
if opt.pastevaluation == 1, opt.futurescenario = NaN; end
opt.futurescenname = scenname(opt.futurescenario, opt.regionname);

%% Run time

% Years to run the model for
opt.runyears  = 2001:2020;

% Years data is available for
opt.datayears = 2006:2011;

% Set number of timesteps per year
opt.timestep  = 52; % Weekly

% Overwrite runyears if running no future scenario or past evaluation
if opt.futurescenario == 0 || opt.pastevaluation == 1, opt.runyears = 2001:2012; end

% Outcomes appended for ease of access
opt.nyears     = numel(opt.runyears);
opt.ndatayears = numel(opt.datayears);
opt.burnperiod = opt.datayears(1) - opt.runyears(1);


%% Load and save settings 

% Load fresh data set and store in structure
opt.loaddata = 0;

% Set samples to load (create more using calibration flag)
opt.samplestoload = 1000;
opt.samplesignore = []; % Set to empty to turn off 

% Save the simulations to this file
opt.savepath  = ['.\Simulations\' opt.regionname '\'];
opt.parampath = '..\Data Spreadsheets\Parameter Sets.xlsx';


%% Simulation settings

% Set the possible trachoma states
opt.states  = {'S', 'E', 'I', 'D', 'P'};
opt.disease = [3 4 5]; % Which states contribute to prevalence
opt.nstates = numel(opt.states);
opt.prevyrs = 5:9; % Ages to use for prevalence records

% Define age breakdowns
opt.maxage         = 80; % Maximum age
opt.childagegroups = [4 9 14]; % 0-4, 5-9, 10-14, 15+
opt.dataagegroups  = numel(opt.childagegroups); % Number of age groups in input data
opt.nagegroups     = numel(opt.childagegroups) + 1; % Total number of age groups
opt.maxadultshouse = 20; % Maximum number of adults in a single household

% Define other simulation options
opt.migschool     = .5; % The chances of a migrant agent going to school
opt.ncontacts     = 50; % The number of community contacts
opt.probtempdest  = .6; % Probability of visiting preffered temporary community
opt.housingscheme = [2008 2018]; % Set years to run housing construction scheme

% Screening options
opt.screenmethod  = '1-14';     % Either screen 5-9 or 1-14 year olds
opt.observeprev   = [1 9; 5 9]; % Keep track of 1-9 and 5-9 prevalence during screening
opt.defaultpolicy = 'default';  % Default screening and treatment policy


%% Calibration settings

% Set calibration flags
opt.calibration = 0; % Flag to turn on calibration
opt.divparfor   = 25; % So parfor loop doesn't run out of memory

% Set properties for disgarding parameter set
opt.prevbounds = [.2 .4; .12 .24; .02 .1]; % Prevalence bounds
opt.maxerrors  = 15; % Number of errors allowed before rejection
opt.starterr   = opt.timestep / 2;

% Success and failure colours for calibration
opt.calcols = {[.8 0 0], [0 .8 .4]};


%% Epidemic categorisation thresholds

% We may only want to return epidemic thresholds
if strcmp(onlyreturn, 'thresholds'), clear opt; end

% Set prevalence thresholds for epidemic categorisations
opt.threshold.hyper = .2;  % Hyper-endemic communities
opt.threshold.meso  = .1;  % Meso-endemic communities
opt.threshold.hypo  = .05; % Hypo-endemic communities

% Return out of function when we're done
if strcmp(onlyreturn, 'thresholds'), return; end

%% Display settings

% Flags to produce displays during simulations
opt.startupdisp = 1; % Simulation display on start up
opt.weekdisp    = 0; % Display each iteration
opt.yeardisp    = 0; % Display each annual cycle
opt.rundisp     = 0; % Display which parameter set is running
opt.timedisp    = 1; % Display time taken to complete param set

% Colours for printing simulation details
opt.printcols = {[1 .5 0], [.9 .2 .2], [0 .8 .3], [.1 .5 .9]};


%% Add paths

% Be able to access my Matlab functions
addpath('P:\SEPPH\Modelling\Roo\My Matlab Functions');


%% Address for success/failure of simulations email

% Email address for delivery
opt.email = 'ashattock@kirby.unsw.edu.au';

% Which machine we are running on
opt.thismachine = thismachine;


