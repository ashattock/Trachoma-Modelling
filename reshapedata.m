%% RESHAPE DATA SET
%
% Reshapes a few data fields for easy access.

function data = reshapedata(data, opt)

% Run years
nrunyears   = opt.nyears;
nburnyears  = opt.burnperiod;

% Data years
ndatagroups = opt.dataagegroups;
ndatayears  = opt.ndatayears;

% Number of communities
ncomms = data.ncommunities;


%% 3D reshape (multiple data points per community per year)

% Identify which data arrays to reshape (and the second dimension)
fieldstoshape = {'screeningcoverage', 'cleanfaceprev', 'treatmentround'};
seconddim     = [ndatagroups, ndatagroups, 2]; % Associated with above

% Iterate through the fields
for i = 1:numel(fieldstoshape)
    
    % Current field
    thisfield = fieldstoshape{i};
    
    % Initiate new data array
    shapeddata = nan(ncomms, seconddim(i), nrunyears);
    
    % Reshape the data into a 3-dimensional matrix
    shapeddata(:, :, nburnyears + (1:ndatayears)) = reshape(...
        data.(thisfield), ncomms, seconddim(i), ndatayears);
    
    % Overwrite the field
    data.(thisfield) = shapeddata;
end


%% 2D reshape (single data point per community per year)

% Identify which data arrays to reshape
fieldstoshape = {'screeninground'};

% Iterate through the fields
for i = 1:numel(fieldstoshape)
    
    % Current field
    thisfield = fieldstoshape{i};
    
    % Initiate new data array
    shapeddata = nan(ncomms, nrunyears);
    
    % Reshape the data into a 3-dimensional matrix
    shapeddata(:, nburnyears + (1:ndatayears)) = data.(thisfield);
    
    % Overwrite the field
    data.(thisfield) = shapeddata;
end
end