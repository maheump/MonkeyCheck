function [ CellpCheck, desc, grid ] = CheckModel( trials, outcome, gauge, ... % information
                                                  model_1stlevel, model_2ndlevel, ... % model specification
                                                  plotmodules, beta_softmax, ... % options
                                                  lambda_grid, gamma_grid, alpha_grid ) % procision of the grid
%CHECKMODEL is the function implementing the combination of the
%computational modules aiming at modeling the checking behavior in Fred's
%monkey task.
%
%   Note that this model is highly optimized since there is no computation
%   that relies on the use of a for-loop.
%   pCheck is a variable containing the probability of checking for each
%   parameter set at each trials. It is a 2D cell array (rows:, columns:)
%   in which each cell contains a 2D matrix with p(Check) sepcified for
%   each value of alpha (rows) in each trial (columns).
%
%   Warning: This model only work on a single episode. It is therefore to
%   use a for-loop on the episodes to fit the behavior of the monkey.
%
%   This model is optimized for further grid-search fitting approach.
%
%   Here are the input variables:
%       - trials

%% Default grids definition and options

if nargin < 10
    alpha_grid  = 0:0.02:1;
    if nargin < 9
        gamma_grid  = 0:0.02:1;
        if nargin < 8
            lambda_grid = 0:0.2:10;
            if nargin < 7
                beta_softmax = [];
                if nargin < 6
                    plotmodules = false;
                end
            end
        end
    end
end

%% Algorithms, 1st level

% TIME-PRESSURE FUNCTION: an accumulation function (as in a RC circuit) of
% the number of trials since the beginning of the episode
tau = @(lambda, tridx) 1 - ...                                                                % We want the 
    exp(-repmat(tridx, numel(lambda), 1) ./ ...                                               % lambda values on the first dimension repeated over trials
    repmat(lambda, numel(tridx), 1)');                                                        % trials' numbers on the second dimension repeated over lambda values
% The output is a 2D matrix with:
%   - trials' number as columns,
%   - lambda values as rows.

% GOOD OUTCOME ACCUMULATOR: accumulation of the number of correct trials
% since the beginning of the block. The accumulation is weighted by an
% exponential decay such that the participation of the very last trial is
% far beyond the ones of older trials. Note that the exponential decay,
% initially implemented to inhibit post-error checking, also account for
% the memory since the older trials have very low weights (almost 0).
%   - gamma: the strength of the exponential decay,
%   - trotc: the outcome,
%   - tridx: trials' number.
kappa = @(gamma, tridx, trotc) cumsum(...                                                     % sum over trials weighted by the outcome (numerator)
    repmat(trotc, numel(gamma), 1) .* ...                                                     % outcome (at each trial, columns) repeated for each gamma value (rows)
    exp(repmat(gamma', 1, numel(tridx)) .* repmat(tridx - 1, numel(gamma), 1)), 2) ./ ...     % exponentially-transformed trials' numbers repeated for each gamma value (rows)
    cumsum(...                                                                                % sum over trials if every outcome is positive (denominator)
    exp(repmat(gamma', 1, numel(tridx)) .* repmat(tridx - 1, numel(gamma), 1)), 2);           % exponentially-transformed trials' numbers repeated for each gamma value (rows)
% The output is a 2D matrix with:
%   - trials' numbers as columns,
%   - gamma values as rows.
% Warning: it only works on a single episode (do not handle trials' number
% reinitialization).

%% 1st level modules simulation

timepressure      = tau(lambda_grid, trials);
rewardaccumulator = kappa(gamma_grid, trials, outcome);

if plotmodules
    figure;
    subplot(2,1,1);
    imagesc(trials, lambda_grid, timepressure); axis('xy');
    cbr = colorbar; caxis([0,1]); cbr.Label.String = 'p(check)';
    xlabel('Trials'); ylabel('\lambda'); title('Time pressure module');
    subplot(2,1,2);
    imagesc(trials, gamma_grid, rewardaccumulator); axis('xy');
    cbr = colorbar; caxis([0,1]); cbr.Label.String = 'p(check)';
    xlabel('Trials'); ylabel('\gamma'); title('Reward accumulator module');
end

%% 1st level modules combination

if model_1stlevel == 1
    pCheck = timepressure;
    desc{1} = 'First-level module simply based on a time pressure module';
elseif model_1stlevel == 2
    pCheck = rewardaccumulator;
    desc{1} = 'First-level module simply based on a reward accumulator module';
elseif model_1stlevel == 3
    pCheck = repmat(timepressure, 1, 1, size(rewardaccumulator, 1)) .* ... % 3D matrix: lambda (rows), trials (columns), gamma (slices)
        repmat(reshape(rewardaccumulator, 1, size(rewardaccumulator, 2), size(rewardaccumulator, 1)), size(timepressure, 1), 1, 1);
    desc{1} = 'First-level module based on a combination of a time pressure module and a reward accumulator module';
end

%% 2nd level modules simulation and combination

if model_2ndlevel ~= 0
    
    % We transforme the 3D matrix into a 2D cell array ...
    %   - with lambda as rows,
    %   - and gamma as columns.
    % in which each cell contains the p(Check) for each trial (columns).
    CellpCheck = squeeze(num2cell(pCheck, 2));
	
    % There are two possible 
    %   - the first simply considers the distance since the previous trial
    %   to decide whether one should check again or not.
    %   - the second both considers the distance since the previous trial
    %   as well as the gauge size that was displayed 
	if model_2ndlevel == 1
        gauge = [];
        desc{2} = 'Second-level algorithm without gauge size account';
    elseif model_2ndlevel == 2
        desc{2} = 'Second-level algorithm with gauge size account';
    else
        error('Please specify a correct option (1 or 2) for the second-level module.');
    end
    
    % The second-level module is specified in the "InformationSeeking.m"
    % file. It has been programmed in a separate function such that it can
    % be easily and efficiently applied on every cell of the "CellpCheck"
    % variable using the build-in Matlab "cellfun" function.
    CellpCheck = cellfun(@(x) InformationSeeking(x, gauge, alpha_grid, beta_softmax), CellpCheck, 'UniformOutput', false);
    
    % Plot the p(Check) according to alpha values and 
    if plotmodules
        Nparamtoplot = 6;
        lambda_choosen = linspace(lambda_grid(1), lambda_grid(end), Nparamtoplot);
        gamma_choosen = linspace(gamma_grid(1), gamma_grid(end), Nparamtoplot);
        figure;
        for l = 1:Nparamtoplot
            for g = 1:Nparamtoplot
                subplot(Nparamtoplot, Nparamtoplot, g+(Nparamtoplot*(l-1)));
                [~,loc_l] = min(abs(lambda_grid - lambda_choosen(l)));
                [~,loc_g] = min(abs(gamma_grid - gamma_choosen(g)));
                imagesc(trials, alpha_grid, CellpCheck{loc_l,loc_g});
                axis('xy'); caxis([0, 1]); colormap(jet);
                if l == Nparamtoplot, xlabel('Trials'); end
                if g == 1, ylabel('\alpha'); end
                title(['\lambda = ', num2str(lambda_grid(loc_l)), ' and \gamma = ', num2str(gamma_grid(loc_g))]);
            end
        end
    end
end

% Also export the grids
grid = {lambda_grid, gamma_grid, alpha_grid, beta_softmax};

end