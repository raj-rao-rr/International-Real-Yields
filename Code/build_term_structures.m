% Builds structure of all yield parameters 

clearvars -except root_dir countries FaceValue;

%% Fit all bonds yields for both REAL and NOMINAL issues

fitted_n = struct;
fitted_r = struct;

fprintf('\n2. Fitting Nominal & Real bond yields.\n');
for country=countries
    fprintf('\n  Constructing Term Structure for %s\n', country{:});
    
    par_amount = FaceValue(country{:});
    
    % compute fitted parameters for soveregin bonds
    [nominal_param, nominal_noise] = fit_yields(country, 0, par_amount);
    
    % assign series accordingly for fitted curves
    fitted_n.(country{:}) = nominal_param;
    fitted_n.(strcat(country{:}, '_NOISE')) = nominal_noise;
    
    [real_param, real_noise] = fit_yields(country, 1, par_amount);
    fitted_r.(country{:}) = real_param;
    fitted_r.(strcat(country{:}, '_NOISE')) = real_noise;

end

save('Temp/FITS.mat', 'fitted_n', 'fitted_r');

%% Construct zero yield curve for both REAL and NOMINAL issues

yield_n = struct;
yield_r = struct;

fprintf('\n3. Constructing Par & Zero curves from sovereigns.\n');
for country=countries
    fprintf('\n  Constructing Yields for %s\n', country{:});
    
    % computed the zero rates from fitted bond parameters
    yield_n.(country{:}+ "Zero") = get_yields(country, 0, 'zero');
    yield_n.(country{:}+ "Par") = get_yields(country, 0, 'par');
    
    yield_r.(country{:}+ "Zero") = get_yields(country, 1, 'zero');
    yield_r.(country{:}+ "Par") = get_yields(country, 1, 'par');

end

save('Output/YIELDS.mat', 'yield_n', 'yield_r');

fprintf('\n\nAll curves have been constructed from provided countries.')
