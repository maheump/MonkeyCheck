function C = DrawnFromSoftmax( pC, beta )
% This function decides whether to check or not based on a softmax function
% using p(Check) as continuous variable. The less the beta, the noisier the
% softmax function. When beta goes to + infinite, then the functions looks
% like a step function (which is equal to 0.5).
% Warning 1: contrary to the "round" function there is a random aspect in
% choosing to check or not here. That is, conclusions can fluctuate (for
% the same parameter values).
% Warning 2: the function assumes no bias toward a check or not. That is
% the p0 is centered at 0.5.
    
softmax = @(pC, beta) exp(pC .* beta) ./ (exp(pC .* beta) + exp((1-pC) .* beta));
N = numel(pC);
r = rand(1, N);
C = sum(r >= cumsum([0, 1 - softmax(pC, beta), softmax(pC, beta)])) - 1;
    
end