function fitqual = FitParamSet( method, modelpred, monkeycheck )

fitqual = [];

try parpool(feature('numCores')); catch; end

try
    parfor p = 1:size(modelpred,1)
        fitqual(1,1,p) = FitMethods(method, modelpred(p,:), monkeycheck);
    end
    
catch
    for p = 1:size(modelpred,1)
        fitqual(1,1,p) = FitMethods(method, modelpred(p,:), monkeycheck);
    end
end

end