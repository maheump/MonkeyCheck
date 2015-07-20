function results = FitCheckModel( method, Model_pCheck, Monkey_Checks )

results = cellfun(@(modelpred) FitParamSet(method, modelpred, Monkey_Checks), Model_pCheck, 'UniformOutput', false);
results = cell2mat(results);

end