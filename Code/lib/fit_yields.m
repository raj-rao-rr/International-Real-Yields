%
% Author, Rajesh Rao 
% 
% Fit soveregin bonds with either Nelson-Siegel or Svensson model 
% ------------------------------------------------------------------------
% 
% Inputs:
%   :param: cnt (type cell) - cell containing str variable
%       The country code being examined (e.g. UK, US) which corresponds to
%       the country ids stored as sheet names within excel files
%   :param: flag (type int) - 1x1
%       A Boolean flag to determine type of fit (i.e., nominal or real)
%       NOTE: 1 = Real Bond, 0 = Nominal Bond
%   :param: face_value (type int) - 1x1
%       A bonds conventions for securities according to the soveregin
%       issuer's standard reporting for face value
% 
% Output:
%   :param: curves (type TimeTable) - M x N matrix
%       The table stores the corresponding curve fit object with name
%   :param: tables (type TimeTable) - M x N matrix
%       The table store the noise parameters for the series, computing the 
%       difference between the realized yeilds and fitted curve
% 

function [curves, noise] = fit_yields(cnt, flag, face_value)
    
    assert(flag == 0 | flag == 1, ...
    'Error: Flag must be integer 0 or 1, where 1 = Real and 0 = Nominal.')

    cntry_bonds = strcat(cnt{:}, '_Bonds');
    cntry_prices = strcat(cnt{:}, '_Prices');
    
    % load in corresponding bond and price data from country
    variables = {cntry_bonds, cntry_prices}; 
    
    if flag == 0
        DATA = load('NOMINAL.mat', variables{:});
        fprintf('\n\tLoading Nominal Bond Data\n')                    
    elseif flag == 1
        DATA = load('REAL.mat', variables{:});
        fprintf('\n\tLoading Real Bond Data\n')
    end
        
    % data loading in from structure related to real bonds
    b_data = DATA.(cntry_bonds);
    price_data = DATA.(cntry_prices);
    
    % ----------------------------------------------------------
    % Data & Estimation Handling for Bond Fits
    % ----------------------------------------------------------
    
    b_data = b_data(~ismember(b_data{:, 'Maturity'}, ''), :);               % Filter out empty Maturity bonds
    b_data = b_data(~ismember(b_data{:, 'Issue Date'}, ''), :);             % Filter out empty Issue date bonds
    b_data = b_data(~ismember(b_data{:, 'First Cpn Dt'}, ''), :);           % Filter out empty Coupon Date bonds
    b_data = b_data(ismember(b_data{:, 'Coupon Type'}, 'FIXED'), :);        % Filter for FIXED coupon bonds  
    b_data = b_data(ismember(b_data{:, 'Mty Type'}, 'AT MATURITY'), :);     % Filter for AT MATURITY bonds
    
    % check to see Maturity data ALWAYS is greater than Issue date
    ind = datenum(b_data{:, 'Maturity'})-datenum(b_data{:, 'Issue Date'});
    b_data = b_data(ind > 0, :);
    
    % remove all bonds without referenced Par Value
    b_data = b_data(~isnan(b_data{:, 'Par Amt'}), :);
    
    % Filter corresponding bonds from price series
    cusip_ids = cellfun(@(x) x + " Govt", b_data.CUSIP)';                   
    price_data = price_data(:,ismember(price_data.Properties.VariableNames, ...
            cusip_ids)); 
    
%     %%%
%     % used only for debuging to reduce the runtime of fit algo
%     price_data = price_data(178:180, :);
%     %%%
    
    M = size(price_data, 1);                                                % number of days
    N = size(b_data, 1);                                                    % number of bonds
    
    Maturity = array2table(zeros(M, N), 'VariableNames', ...
        b_data{:, 'CUSIP'}');
    Coupon = array2table(zeros(M, N), 'VariableNames', ...
        b_data{:, 'CUSIP'}');
    AccruedInterest = array2table(zeros(M, N), 'VariableNames', ...
        b_data{:, 'CUSIP'}');
    
    % itterate through bonds to collect information
    for cusip = b_data.CUSIP'
        
        name = cusip{:} + " Govt";
        fprintf('\t\tCurrent cusip %s\n', name);
        
        % search for corresponding data figures
        maturity_date = b_data{ismember(b_data{:, 'CUSIP'}, cusip{:}), ...
            'Maturity'};
        coupon_rate = b_data{ismember(b_data{:, 'CUSIP'}, cusip{:}), ...
            'Cpn'};
        coupon_date = b_data{ismember(b_data{:, 'CUSIP'}, cusip{:}), ...
            'First Cpn Dt'};
        issue_date = b_data{ismember(b_data{:, 'CUSIP'}, cusip{:}), ...
            'Issue Date'};
        
        % map corresponding series for datasets correctly
        Maturity.(cusip{:}) = repmat(maturity_date, [M, 1]);
        Coupon.(cusip{:}) = repmat(coupon_rate/100, [M, 1]);
        
        % computing the accrued interest time series for each settlement
        for j = 1:M
            settle_date = price_data.Dates(j);
            
            AccruedInterest{j, cusip} = accrued_interest(datenum(issue_date), ...
                datenum(settle_date), datenum(coupon_date), face_value, ...
                coupon_rate/100); 
        end
        
    end
    
    Maturity = table2timetable(Maturity, 'RowTimes', price_data.Dates);
    Coupon = table2timetable(Coupon, 'RowTimes', price_data.Dates);
    AccruedInterest = table2timetable(AccruedInterest, 'RowTimes', ...
        price_data.Dates);
    
    fprintf('\n\n\tBegin Nelson-Siegel/Svensson Estimation\n');
    
    % ----------------------------------------------------------
    % Engine Optimization for Interest Rate Curve Fitting
    %
    %   For detailed information on the methodologies implemented
    %   refer to Ken Nyholm's MATLAB lectures on his website entilted
    %   "A short summary on how to fit a yield curve to bond data"
    % ----------------------------------------------------------
    
    % modifying optimization engine for determining optimal fits
    optOptions_  = optimset('TolFun', 1e-5, 'TolX', 1e-5, ...
        'MaxFunEvals', 1e4, 'MaxIter', 1e4, 'Display', 'final');
    
    b_0  = [ 4.00  -5.00  0.40  -0.50  3.50  1.50 ];
    lb_  = [ 0  -inf  -inf  -inf   0.00  0.00 ];
    ub_  = [ 25.0   inf   inf   inf    inf   inf ];
    
    fitOptions_ss = IRFitOptions(b_0, 'FitType', 'durationweightedprice', ...
        'LowerBound', lb_, 'UpperBound', ub_, 'OptOptions', optOptions_ );
    
    % construct the curve fit and noise series container
    noise = table(price_data.Dates, nan(M,1), nan(M,1));
    noise.Properties.VariableNames = {'Date', 'rmse', 'r2'};

    curves = table(price_data.Dates, cell(M,1), cell(M,1), cell(M,1));
    curves.Properties.VariableNames = {'Dates', 'CurveFit', 'FitType', ...
        'Bonds'};
    
    for row=1:M
        fprintf('\t\tFitting curve for %s\n', ...
            datestr(price_data.Dates(row)));
        
        settle_date = price_data.Dates(row);
        
        s = repmat(datenum(settle_date), [N 1]);                            % settlement date
        m = datenum(Maturity{row, :});                                      % maturity date
        p = price_data{row, :}';                                            % bond price        
        c = Coupon{row, :}';                                                % coupon rate
        a = AccruedInterest{row, :}';                                       % accrued interest
        
        bonds = [s, m, p-a, c];
        
        % -----------------------------------------------------
        % Bond Filtering for Maturity and Issuance
        % -----------------------------------------------------

        matured_inds = (bonds(:,2) - bonds(:,1) < 30*9) | ...               % exclude all bonds with less than nine months to maturity              
            (bonds(:,2) - bonds(:,1) > 365*15);                             % exclude all bonds with greater than 15 years to maturity  
        bonds(matured_inds == 1,:) = nan;
        
        % if yield quoted instead of price, estimate bond price
        for j=1:length(bonds)
            if bonds(j,3) < 30  % ambigous threshold set in legacy
                bonds(j,3) = bndprice(p(j)/100, c(j), s(j), m(j));
            end
        end
        
        % remove any rows where there exists a NaN value
        full_rows = ~any(isnan(bonds), 2);
        bonds = bonds(full_rows,:);
        
        % -----------------------------------------------------
        % Remove outliers for stability of the sample
        % -----------------------------------------------------
        
        if ~isempty(bonds)
            
            % actual bond yields from data
            actual_yields = bndyield(bonds(:, 3), bonds(:,4), ...
                bonds(:, 1), bonds(:,2));
            
            % impose cut-off restrictions for accepting yields
            % NOTE: Arbitary cutoffs for YTM > -2% and < 15%
            bonds = bonds((actual_yields > -0.02) | ...
                (actual_yields < 0.15), :);
            
        end
        
        % -----------------------------------------------------
        % Fit Nelson-Siegel or Svensson depending on Maturity
        % -----------------------------------------------------
        
        % if nominal bond, always fit Svensson
        if flag == 0 && size(bonds, 1) >= 6
            
            % fit Svensson Model on more liquid nominal bonds 
            model = IRFunctionCurve.fitSvensson('Zero', settle_date, ...
                bonds, 'IRFitOptions', fitOptions_ss);
            
            curves.Bonds{row} = bonds;
            
            % construct the fitterd yields under term structure model
            fitted_yields = model.getZeroRates(bonds(:, 2));
            
            curves.CurveFit{row} = {model};
            curves.FitType{row} = {'Svensson'};
            
        elseif flag == 1
            
            % if Real bond has more than 6 active traded, fit Svensson
            if size(bonds, 1) >= 6
                
                % fit Svensson Model on more liquid nominal bonds 
                model = IRFunctionCurve.fitSvensson('Zero', settle_date, ...
                    bonds, 'IRFitOptions', fitOptions_ss);
                
                curves.Bonds{row} = bonds;
                
                % construct the fitted yields under term structure model
                fitted_yields = model.getZeroRates(bonds(:, 2)); 
                
                curves.CurveFit{row} = {model};
                curves.FitType{row} = {'Svensson'};
                
            elseif 4 <= size(bonds, 1) && size(bonds, 1) < 6

                % fit Svensson Model on more liquid nominal bonds 
                model = IRFunctionCurve.fitNelsonSiegel('Zero', ...
                    settle_date, bonds);
                
                curves.Bonds{row} = bonds;
                
                % construct the fitted yields under term structure model
                fitted_yields = model.getZeroRates(bonds(:, 2));
                
                curves.CurveFit{row} = {model};
                curves.FitType{row} = {'NelsonSiegel'};

            end
            
        end
        
        % -----------------------------------------------------
        % Constructing errors for noise parameters
        % -----------------------------------------------------
        try  
            actual_yields = bndyield(bonds(:, 3), bonds(:,4), ...
                bonds(:, 1), bonds(:,2));

            sst = sum((actual_yields - mean(actual_yields)).^2); 
            sse = sum((actual_yields-fitted_yields).^2);
            noise.rmse(row) = sqrt(mean((actual_yields-fitted_yields).^2));
            noise.r2(row) = 1 - sse/sst;

            fprintf('\n\tR2 Measure on %s was %f\n', ...
                datestr(settle_date), 1-sse/sst)
        catch 
           fprintf('\n\t\tNo curve was fit, insufficient number of bonds')
           
        end
        
    end
    
end
