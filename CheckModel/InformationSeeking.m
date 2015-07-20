function out_pC = InformationSeeking( pC, gauge, alpha_grid, beta_softmax )
% This function has to be launched on a particular 
% The algoritm works as follows:
%   - it identifies the first check (based on the first-level modules),
%   - it initializes the second-level module at the time of this first
%       check,
%   - for each trial following the first check, p(Check) is recomputed
%       ("re" because ) by making the product of the p(Check) coming
%       from the first-level modules and the p(Check) that comes from
%       the second-level module,
%   - at each trial, the new p(Check) is then transformed (by a round
%       or a softmax) to decide whether a check has been made,
%   - the first
    
% Get the total number of trials
N = numel(pC);

% We need the model to check
if      isempty(beta_softmax), CheckStar = logical(round(pC));
elseif ~isempty(beta_softmax), CheckStar = logical(DrawnFromSoftmax(pC, beta_softmax));
end

% First, we look for the first check (it does not depend on the value of alpha)
FirstCheck = find(CheckStar, 1, 'first');

% INFORMATION SEEKING MODULE: exponential decay
if    ~isempty(gauge) % => smart monkey: takes into accout the gauge size
    phi = @(alpha, tridx, c_last, g_last) 1 - exp(repmat(tridx - c_last, numel(alpha), 1) .* ... %
        repmat(alpha', 1, numel(tridx)) .* ... %
        repmat(log(g_last), numel(alpha), numel(tridx))); %
elseif isempty(gauge) % => dummy monkey: does not take into account the gauge size (simple the distance since the last check)
    phi = @(alpha, tridx, c_last, g_last) 1 - exp(repmat(tridx - c_last, numel(alpha), 1) .* ... %
        repmat(alpha', 1, numel(tridx))); %
end
% The output is a 2D matrix:
%   - trials' numbers as columns,
%   - alpha values as rows.

% For each possible value of alpha (sorry, that's a loop over parameter values)
out_pC = NaN(numel(alpha_grid), N);
for a = 1:numel(alpha_grid)

    % p(Check) in the trials before the first check is only determined by first-level module(s)
    out_pC(a,1:FirstCheck) = pC(:,1:FirstCheck);
    LastCheck = FirstCheck;

    % For each trial following the first check
    for t = FirstCheck+1:N

        % Perform a forward updating of the p(Check) values based on:
        %   - the p(Check) coming from the first-level modules,
        %   - the p(Check) coming from the second-level module.
        new_pC = pC(t) .* phi(alpha_grid(a), t, LastCheck, gauge(LastCheck)/7);

        % And store it in order to further export the combined p(Check)
        out_pC(a,t) = new_pC;

        % Binarized it to get the check choices
        if      isempty(beta_softmax), CheckOrNot = logical(round(new_pC));
        elseif ~isempty(beta_softmax), CheckOrNot = logical(DrawnFromSoftmax(new_pC, beta_softmax));
        end

        % If there was a check, update the location of the last check
        if     CheckOrNot == 1, LastCheck = t;
        elseif CheckOrNot == 0, % Do nothing...
        end
    end
end

end