%% MonkeyCheck
% Create a pool of models with different properties:
%   - M1: a simple time pressure
%   - M2: a weighted accumulator
%   - M3: a weighted accumulator with a time pressure (the one that is above)
%   - M4: a time pressure with an informativeness account
%   - M5: a weighted accumulator with an informativeness account
%   - M6: a weighted accumulator with an informativeness account and a time pressure

% Maxime Maheu
% Cogmaster (ENS, Paris 5, EHESS)
% NeuroSpin, UNICOG (INSERM, CEA)

%% Initialization %%

exseq = [ 0 0 0 0 1; ...
          0 0 0 1 0; ...
          0 0 1 0 0; ...
          0 1 0 0 0; ...
          1 0 0 0 0; ...
          1 1 1 1 0; ...
          1 1 1 0 1; ...
          1 1 0 1 1; ...
          1 0 1 1 1; ...
          0 1 1 1 1  ];
      
%          Gamma and Beta parameters
monkeys = [0.40,     0.05; ... % non-checker
           0.75,     0.30];    % checker

% Set some options and start the loop
subset = 5;
figure; colors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980];
M1 = cell(1, size(exseq, 1)); M2 = cell(1, size(exseq, 1));
M3 = cell(1, size(exseq, 1)); M4 = cell(1, size(exseq, 1));
M5 = cell(1, size(exseq, 1)); M6 = cell(1, size(exseq, 1));
M7 = cell(1, size(exseq, 1));
for i = 1:size(exseq, 1)
    currentseq = exseq(i,:);

    %% Time pressure %%

    lambda = [0:0.001:1]';
    lambda_subset = linspace(1, numel(lambda), subset);
    theta = 0;
    
    tau = @(lambda, theta, seq)  1 ./ (1 + exp(-lambda * ([1:numel(seq)] - theta)));
    tau_gs = tau(lambda, theta, currentseq);
    
    subplot(4, size(exseq,1)/2, 1);
    plot(1:numel(currentseq), tau_gs(lambda_subset,:), 'o-');
    legend(num2str(lambda(lambda_subset)), 'Location', 'NorthWest');
    xlabel('Trial number'); ylabel('Value'); title('Time pressure ($\lambda$)', 'Interpreter', 'LaTeX');
    
    tau_gs = tau_gs(:,end);
    
    %% Exponential-decay accumulator %%

    gamma = [0:0.001:1]';
    gamma_subset = linspace(1, numel(gamma), subset);
    
    omega = @(gamma, seq) exp(gamma * ([1:numel(seq)] - 1));
    omega_gs = omega(gamma, currentseq);
    
    kappa = @(omega, gamma, seq) cumsum(omega .* repmat(seq, numel(gamma), 1), 2) ./ ...
                                 cumsum(omega .* ones(numel(gamma), numel(seq)), 2);
	kappa_gs = kappa(omega_gs, gamma, currentseq);
    
    subplot(4, size(exseq, 1) / 2, 2);
    plot(1:numel(currentseq), omega_gs(gamma_subset,:), 'o-');
    legend(num2str(gamma(gamma_subset)), 'Location', 'NorthWest');
    xlabel('Trial number'); ylabel('Value'); title('Decay accumulator ($\gamma$)', 'Interpreter', 'LaTeX');
    
    kappa_gs = kappa_gs(:,end);
    
    %% Information seeking module %%

    alpha = [0:0.001:1]';
    alpha_subset = 1;
    
    phi = @(alpha, lastC, lastG) 1 - exp(lastC .* log(1 - lastG));
    
    last_check = 1:10;
    gauge_size = 0:0.2:1;
    phi_gs = NaN(numel(gauge_size), numel(last_check));
    for j = 1:numel(gauge_size)
        phi_gs(j,:) = phi(alpha_subset, last_check, gauge_size(j));
    end
    
    subplot(4, size(exseq, 1) / 2, 5);
    plot(last_check, phi_gs, 'o-'); axis([last_check(1),last_check(end),0,1]);
    set(gca, 'XTick', last_check); legend(num2str(gauge_size'), 'Location', 'SouthEast');
    xlabel('Trial number post-check'); ylabel('$p(\rm{check})$', 'Interpreter', 'LaTeX');
    title('Information seeking module ($g_{\rm{last}}$)', 'Interpreter', 'LaTeX');
    
    %% Models %%
    
    M1{i} = tau_gs;
    M2{i} = kappa_gs;
    M3{i} = kappa_gs * tau_gs';
%     M4{i} = ; % Need to perform an iterative softmax to get the "check"
%     M5{i} = ;   trials of the model and then used them in the information
%     M6{i} = ;   seeking module.
    
    %% Plot %%
    
    subplot(4, size(exseq, 1) / 2, i + size(exseq, 2));
    imagesc(lambda, gamma, flipud(M3{i}));
    caxis([0, 1]); colormap(jet);
    set(gca, 'XTick', 0:0.2:1, 'YTick', 0:0.2:1, 'YTickLabel', flipud(num2str([0:0.2:1]')));
    xlabel('Strength of the temporal pressure'); ylabel('Strength of the accumulator decay'); title(mat2str(currentseq));
end
cbr = colorbar('Location', 'SouthOutside');
cbr.Label.String = '$p(\rm{check})$';
cbr.Label.Interpreter = 'LaTeX';
set(cbr, 'Position', [0.4594 0.7673, 0.12, 0.01]);
caxis([0, 1]); colormap(jet);

%% Simulation %%

L = 100;
theta = 10;
choices = BernoullianSeqStim(L, 1/4) - 1;

kappa_monkey  = NaN(size(monkeys, 1), L);
lambda_monkey = NaN(size(monkeys, 1), L);
for monkey = 1:size(monkeys, 1)
    kappa_monkey(monkey,:)  = kappa(omega(monkeys(monkey,1), choices), monkeys(monkey,1), choices);
    lambda_monkey(monkey,:) = tau(monkeys(monkey,2), theta, choices);
end
pC_monkey = kappa_monkey .* lambda_monkey;

subplot(4, size(exseq, 1) / 2, (size(exseq, 2)*3) + [1:size(exseq, 2)]);
for monkey = 1:size(monkeys, 1)
    plot(1:L, kappa_monkey(monkey,:), '--', 'Color', colors(monkey,:)); hold('on');
    plot(1:L, lambda_monkey(monkey,:), ':', 'Color', colors(monkey,:));
    plot(1:L, pC_monkey(monkey,:), '-', 'LineWidth', 2, 'Color', colors(monkey,:));
end
axis([1,L,0,1]);
SuperposeSequence(choices + 1);
xlabel('Trial number'); ylabel('$p(\rm{check})$', 'Interpreter', 'LaTeX');
title('Checker versus non-checker monkey');

%% Save %%

% matlab2tikz('figurehandle', gcf, '~/MonkeyCheck/Figure/MonkeyCheck.tex', 'showInfo', false, 'standalone', true);