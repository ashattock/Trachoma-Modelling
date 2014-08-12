%% CREATE DATA SET
%
% Load regional data, create a data structure and store in a mat file.
% Reduces loading time and makes data easier to move about

function data = createdataset(opt)

% Create display
disp([10 'Loading input data:']);


%% Easy indexing

% Region details
regionref  = opt.regionref;
regionname = opt.regionname;

% Store region name and reference
data.regionname = regionname;
data.regionref  = regionref;

% Age and data related stuff
maxage     = opt.maxage;
datayears  = opt.ndatayears;
datagroups = opt.dataagegroups;


%% File paths and save location

% Set path to input spreadsheets
xlpath = '..\Data Spreadsheets\';
txpath = '.\Data Text Files\';

% File to be saved
datafile = ['.\Input Data\' regionname ' Data.mat'];


%% Demographics
disp('  demographics...')

% Load the data
thisfile = [xlpath 'Demographics.xlsx'];
[~, ~, demographics] = xlsread(thisfile, regionref);

% Resize the data if need be and store
demographics      = cell2mat(demographics);
data.demographics = demographics(~isnan(demographics(:, 1)), :);

% Append umber of communities
data.ncommunities = size(data.demographics, 1);
ncomstr = num2str(data.ncommunities);


%% Prevalence
disp('  trachoma prevalence...')

% File and cells to load
thisfile = [xlpath 'Trachoma Prevalence.xlsx'];
loadcell = ['A1:' alphaexcelcol(datayears) ncomstr];

% Load the data
[~, ~, trachprev] = xlsread(thisfile, regionref, loadcell);
data.trachprev    = cell2mat(trachprev);

% File and cells to load
thisfile = [xlpath 'Regional Prevalence.xlsx'];
loadcell = ['A1:' alphaexcelcol(datayears) '3'];

% Load the data
[~, ~, regionalprev] = xlsread(thisfile, regionref, loadcell);
data.regionalprev    = cell2mat(regionalprev);


%% Birth rates
disp('  birth rates...')

% Load the data
birthrate      = load([txpath 'Birth_Data.txt']);
data.birthrate = [1:opt.maxadultshouse; birthrate'];


%% Death rates
disp('  death rates...')

% Load the data
deathrate      = load([txpath 'Death_Data.txt']);
data.deathrate = [0:maxage; deathrate'];


%% Infectivity rates
disp('  infectivity rates...')

% File and cells to load
thisfile = [xlpath 'Infectivity Rates.xlsx'];
loadcell = ['A1:A' num2str(maxage + 1)];

% Load the data
[~, ~, infectivityrate] = xlsread(thisfile, regionref, loadcell);
data.infectivityrate    = [0:maxage; cell2mat(infectivityrate)'];


%% Disease duration
disp('  disease duration...')

% Load the data
data.infectionduration = load([txpath 'Infection_Duration.txt'])';
data.diseaseduration   = load([txpath 'Disease_Duration.txt'])';
data.exposedduration   = load([txpath 'Exposed_Data.txt'])';


%% Trachoma distribution
disp('  trachoma distribution...')

% File and cells to load
thisfile = [xlpath 'Child Trachoma Distribution.xlsx'];
loadcell = ['A1:' alphaexcelcol(opt.nagegroups * opt.nstates) ncomstr];

% Load the data
[~, ~, childtrachoma] = xlsread(thisfile, regionref, loadcell);
data.childtrachoma    = cell2mat(childtrachoma);


%% Facial cleanliness
disp('  facial cleanliness...')

% File and cells to load
thisfile = [xlpath 'Facial Cleanliness.xlsx'];
loadcell = ['A1:' alphaexcelcol(datayears * datagroups) ncomstr];

% Load the data
[~, ~, cleanfaceprev] = xlsread(thisfile, regionref, loadcell);
data.cleanfaceprev    = cell2mat(cleanfaceprev);

% File and cells to load
thisfile = [xlpath 'Initial Clean Face Data.xlsx'];
loadcell = ['A1:' alphaexcelcol(datagroups) ncomstr];

% Load the data
[~, ~, initialcleanface] = xlsread(thisfile, regionref, loadcell);
data.initialcleanface    = cell2mat(initialcleanface);

% File and cells to load
thisfile = [xlpath 'Clean Face Projection.xlsx'];
loadcell = ['A1:' alphaexcelcol(datagroups) ncomstr];

% Load the data
[~, ~, cleanfaceproject] = xlsread(thisfile, regionref, loadcell);
data.cleanfaceproject    = cell2mat(cleanfaceproject);


%% Screening coverage
disp('  screening coverage...')

% File and cells to load
thisfile = [xlpath 'Screening Data.xlsx'];
loadcell = ['A1:' alphaexcelcol(datayears * datagroups) ncomstr];

% Load the data
[~, ~, screeningcoverage] = xlsread(thisfile, regionref, loadcell);
data.screeningcoverage    = cell2mat(screeningcoverage);

% File and cells to load
thisfile = [xlpath 'Screening Projection.xlsx'];
loadcell = ['A1:' alphaexcelcol(datagroups) ncomstr];

% Load the data
[~, ~, screeningproject] = xlsread(thisfile, regionref, loadcell);
data.screeningproject    = cell2mat(screeningproject);


%% Screening times
disp('  screening times...')

% File and cells to load
thisfile = [xlpath 'Screen Round.xlsx'];
loadcell = ['A1:' alphaexcelcol(datayears) ncomstr];

% Load the data
[~, ~, screeninground] = xlsread(thisfile, regionref, loadcell);
data.screeninground    = cell2mat(screeninground);


%% Treatment times
disp('  treatment times...')

% File and cells to load
thisfile = [xlpath 'Treat Round.xlsx'];
loadcell = ['A1:' alphaexcelcol(datayears * 2) ncomstr];

% Load the data
[~, ~, treatmentround] = xlsread(thisfile, regionref, loadcell);
data.treatmentround    = cell2mat(treatmentround);


%% Retreatment times
disp('  retreatment times...')

% File and cells to load
thisfile = [xlpath 'Retreat Round.xlsx'];
loadcell = ['A1:' alphaexcelcol(2) ncomstr];

% Load the data
[~, ~, retreatmentround] = xlsread(thisfile, regionref, loadcell);
data.retreatmentround    = cell2mat(retreatmentround);


%% Housing data
disp('  housing...')

% File and cells to load
thisfile = [xlpath 'Housing Data.xlsx'];
loadcell = ['A1:' alphaexcelcol(opt.housingscheme(2) - opt.housingscheme(1)) ncomstr];

% Load the data
[~, ~, housingimprovements] = xlsread(thisfile, regionref, loadcell);
data.housingimprovements    = cell2mat(housingimprovements);

% File and cells to load
thisfile = [xlpath 'Further Housing Data.xlsx'];
loadcell = ['A1:' alphaexcelcol(opt.housingscheme(2) - opt.housingscheme(1)) ncomstr];

% Load the data
[~, ~, furtherconstruction] = xlsread(thisfile, regionref, loadcell);
data.furtherconstruction    = cell2mat(furtherconstruction);


%% Migration data
disp('  migration...')

% File and cells to load
thisfile = [xlpath 'Migration Data.xlsx'];
loadcell = ['A1:' alphaexcelcol(1) ncomstr];

% Load the migration destination data
[~, ~, migrationdata] = xlsread(thisfile, regionref, loadcell);
data.migrationdata    = cell2mat(migrationdata);

% Load the migration by age data
migrationbyage      = load([txpath 'Migration_Data.txt'])';
data.migrationbyage = [0:maxage; migrationbyage];

% Load the migration duration data
data.migrationduration = load([txpath 'Migration_length_Data.txt']);


%% Age structure
disp('  age structure...')

% File and cells to load
thisfile = [xlpath 'Age Structure.xlsx'];
loadcell = ['A1:' alphaexcelcol(maxage + 1) ncomstr];

% Load the data
[~, ~, agestructure] = xlsread(thisfile, regionref, loadcell);
data.agestructure    = cell2mat(agestructure);


%% Force of infection
disp('  force of infection...')

% File and cells to load
thisfile = [xlpath 'Calibrated FoI.xlsx'];
loadcell = ['A1:' alphaexcelcol(4) ncomstr];

% Load the data
[~, ~, foivalues] = xlsread(thisfile, regionref, loadcell);
data.foivalues    = cell2mat(foivalues);


%% Save the structure
disp(['Saving data to ' datafile '...' 10])

% Append variables to saved structure
save(datafile, 'data');

