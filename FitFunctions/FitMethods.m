function fitqual = FitMethods( m, pred, real )

if m == 1
    fitqual = nansum((pred - real) .^2);
elseif m == 2
    [b, dev, stats] = glmfit(pred', real', 'binomial', 'link', 'logit');
    fitqual = b(2);
end
    
end