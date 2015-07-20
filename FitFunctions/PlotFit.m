function [ BestFitQuality, LocBestFitQuality, BestParamsVal, f ] = PlotFit( FitQuality, pgrid, Nparamtoplot )
%PLOTFIT plots the results of the fit of the MonkeyCheck model against
%monkeys' real checks.
%   Input arguments:
%       - "FitQuality": the 3D matrix containing fit quality values.
%       - "pgrid": the cell array containing tested values for each
%           paramater.
%       - "Nparamtoplot": facultative argument specifying the number of
%           subplots in the first figure.
%   Output arguments:
%       - "BestFitQuality":
%       - "LocBestFitQuality":
%       - "BestParamsVal":
%       - "f":

%% Get the best parameters

% Find the best parameters set
[BestFitQuality, LocBestFitQuality] = min(FitQuality(:));
[lambda_best, gamma_best, alpha_best] = ind2sub(size(FitQuality), LocBestFitQuality);
BestParamsVal = {pgrid{1}(lambda_best), pgrid{2}(gamma_best), pgrid{3}(alpha_best)};
% nsp = max(size(FitQuality));

% Get the parameters' values to plot
if nargin < 3, Nparamtoplot = 6; end
lambda_choosen = sort([BestParamsVal{1}, linspace(pgrid{1}(1), pgrid{1}(end), Nparamtoplot)]);
gamma_choosen  = sort([BestParamsVal{2}, linspace(pgrid{2}(1), pgrid{2}(end), Nparamtoplot)]);
alpha_choosen  = sort([BestParamsVal{3}, linspace(pgrid{3}(1), pgrid{3}(end), Nparamtoplot)]);

%% Plot

f{1} = figure('Position', [571 343 825 420]);
cm = colormap('jet');
for p = 1:Nparamtoplot
    
    %
    subplot(3, Nparamtoplot, p);
    imagesc(pgrid{1}, pgrid{2}, squeeze(FitQuality(:,:,pgrid{3} == alpha_choosen(p))));
    caxis([min(FitQuality(:)), max(FitQuality(:))]); colormap(flipud(cm)); axis('xy');
    xlabel('\lambda'); ylabel('\gamma'); title(['\rm{\alpha} = ', num2str(alpha_choosen(p))]);

    %
    subplot(3, Nparamtoplot, p+Nparamtoplot);
    imagesc(pgrid{1}, pgrid{3}, squeeze(FitQuality(:,pgrid{2} == gamma_choosen(p),:)));
    caxis([min(FitQuality(:)), max(FitQuality(:))]); colormap(flipud(cm)); axis('xy');
    xlabel('\lambda'); ylabel('\alpha'); title(['\rm{\gamma} = ', num2str(gamma_choosen(p))]);
    
    %
    subplot(3, Nparamtoplot, p+(Nparamtoplot*2));
    imagesc(pgrid{2}, pgrid{3}, squeeze(FitQuality(pgrid{1} == lambda_choosen(p),:,:)));
    caxis([min(FitQuality(:)), max(FitQuality(:))]); colormap(flipud(cm)); axis('xy');
    ylabel('\gamma'); ylabel('\alpha'); title(['\rm{\lambda} = ', num2str(lambda_choosen(p))]);
end

% f{2} = figure;
% [x,y,z] = meshgrid(pgrid{1}, pgrid{2}, pgrid{3});
% scatter3(x(:), y(:), z(:), [], FitQuality(:), 's');
% caxis([min(FitQuality(:)), max(FitQuality(:))]); colormap(flipud(cm)); colorbar;
% xlabel('\lambda'); ylabel('\gamma'); zlabel('\alpha'); view(-130, 20);

f{2} = figure;
h = slice(pgrid{1}, pgrid{2}, pgrid{3}, FitQuality, [], [], pgrid{3});
set(h, 'EdgeColor', 'none', 'FaceColor', 'interp'); alpha(0.25);
caxis([min(FitQuality(:)), max(FitQuality(:))]); colormap(flipud(cm)); colorbar;
xlabel('\lambda'); ylabel('\gamma'); zlabel('\alpha'); view(-130, 20);

end