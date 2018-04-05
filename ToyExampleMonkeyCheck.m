% Toy example of the fit of the MonkeyCheck model

%% Get the data
% The data matrix is organized as follows (a row is a trial);
%   - 1: trials' number within an episode,
%   - 2: main task outcome,
%   - 3: cumulative sum of the main task outcomes within an episode,
%   - 4: check,
%   - 5: gauge state.

close('all'); clear; clc;
load('data_monkA.mat');
dat = cellfun(@(x) [1:size(x,2); x(1,:); cumsum(x(1,:)); x(2,:); x(3,:)]', ...
    dat, 'UniformOutput', false);

%% Simulate the models

% Initialize some useful variables
Nep = numel(dat);
CellpCheck = cell(1, Nep);

% We are interested by the more complex model
model_1stlevel = 3;
model_2ndlevel = 2;

% Get some information
[~, desc, pgrid] = CheckModel(dat{ep}(:,1)', dat{ep}(:,2)', dat{ep}(:,5)', model_1stlevel, model_2ndlevel, true);

% For each episode (use a parfor here to optimize the computation)
try parpool(feature('numCores')); catch; end
tic;
parfor ep = 1:Nep

    % Get the information related to the episode
    trials  = dat{ep}(:,1)';
    outcome = dat{ep}(:,2)';
    gauge   = dat{ep}(:,5)';

    % Simulate the models
    CellpCheck{ep} = CheckModel(trials, outcome, gauge, ... % information
                                model_1stlevel, model_2ndlevel, ... % model specification
                                true); % options
end
toc;

%% Prepare both simulated and real data

% Prepare
pCheck = CellpCheck{1};
MonkeyRealChecks = dat{1}(:,4)';
tic;
for ep = 2:Nep
    
    % Get the check of the monkeys (what we want to fit)
    MonkeyRealChecks = [MonkeyRealChecks, dat{ep}(:,4)'];
    
    % Next we have to concatene the model's predictions over episodes
    pCheck = cellfun(@(inp,add) [inp, add], pCheck, CellpCheck{ep}, 'UniformOutput', false); 
end

% To avoid numeric overflow, we only keep 2 decimals
pCheck = cellfun(@(x) round(x, 2), pCheck, 'UniformOutput', false);
toc;

%% Fit the data

tic;
FitQuality = FitCheckModel(1, pCheck, MonkeyRealChecks);

[BestFitQuality, LocBestFitQuality, BestParamsVal, f] = PlotFit(FitQuality, pgrid);
fprintf('Accuracy = %2.0f%%\n', (1 - (BestFitQuality / numel(MonkeyRealChecks)))*100);
toc;

save('test.mat', '-v7.3');