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
        fprintf('\nLoading Nominal Bond Data\n')                    
    elseif flag == 1
        DATA = load('REAL.mat', variables{:});
        fprintf('\nLoading Real Bond Data\n')
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
    
    %%%
    % used only for debuging to reduce the runtime of fit algo
    price_data = price_data(2800:3200, :);
    %%%
    
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
        fprintf('Current cusip %s\n', name);
        
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
    
    fprintf('\n\nBegin Nelson-Siegel/Svensson Estimation\n');
    
    % ----------------------------------------------------------
    % Engine Optimization for Interest Rate Curve Fitting
    %
    %   For detailed information on the methodologies implemented
    %   refer to Ken Nyholm's MATLAB lectures on his website entilted
    %   "A short summary on how to fit a yield curve to bond data"
    % ----------------------------------------------------------
    
    % modifying optimization engine for determining optimal fits
    optOptions_  = optimset('TolFun', 1e-12, 'TolX', 1e-12, ...
        'MaxFunEvals', 1e5, 'MaxIter', 1e5, 'Display', 'final');
    
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
        fprintf('\tFitting curve for %s\n', ...
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
            (bonds(:,2) - bonds(:,1) > 365*35);                             % exclude all bonds with greater than thirty year to maturity  
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
        
        % convert datetime maturity from datenum object
        dateX = datetime(bonds(:, 2), 'ConvertFrom', 'datenum');
        
        % actual bond yields from data
        actual_yields = bndyield(bonds(:, 3), bonds(:,4), ...
            bonds(:, 1), bonds(:,2));
        year_group = round(days(dateX - settle_date) / 365);
        
        ind = zeros(numel(actual_yields), 1);
        
        avg_yields = accumarray(year_group, actual_yields, [], @mean);
        std_yields = sqrt(accumarray(year_group, actual_yields, [], @var));
        
        % determine the bounds for inclusion/exclusion
        upper_bounds = avg_yields + 1.5*std_yields;
        lower_bounds = avg_yields - 1.5*std_yields;
        
        itter = 1:max(year_group);
        uMap = containers.Map(itter,upper_bounds);
        lMap = containers.Map(itter,lower_bounds);
        
        % check to see if bonds break bounded conditions
        for i = 1:size(ind,1)
           
            if actual_yields(i, 1) <= uMap(year_group(i, 1)) && ...
                    actual_yields(i, 1) >= lMap(year_group(i, 1))
                ind(i, 1) = 1;
            else
                ind(i, 1) = 0;
            end
            
        end
        
        % filter bonds within standard error bounds
        bonds = bonds.*ind;
        bonds = bonds(~all(bonds == 0, 2),:);
        
        % -----------------------------------------------------
        % Fit Nelson-Siegel or Svensson depending on Maturity
        % -----------------------------------------------------
        
        % if nominal bond, always fit Svensson
        if flag == 0 && sum(ind) >= 6
            
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
            if sum(full_rows) >= 6
                
                % fit Svensson Model on more liquid nominal bonds 
                model = IRFunctionCurve.fitSvensson('Zero', settle_date, ...
                    bonds, 'IRFitOptions', fitOptions_ss);
                
                curves.Bonds{row} = bonds;
                
                % construct the fitted yields under term structure model
                fitted_yields = model.getZeroRates(bonds(:, 2)); 
                
                curves.CurveFit{row} = {model};
                curves.FitType{row} = {'Svensson'};
                
            elseif 4 <= sum(ind) && sum(ind) < 6

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
           fprintf('\n\tNo curve was fit, insufficient number of bonds') 
        end
        
        
%         if  (1 - sse/sst) < 0.95 %mod(row, 25) == 0
%            
%             figure('visible', 'on');                         
%             set(gcf, 'Position', [100, 100, 1250, 650]); 
%             
%             hold on;
%             dateX = datetime(bonds(:, 2), 'ConvertFrom', 'datenum');
%             date_range = min(dateX):caldays(30*3):max(dateX);
%             
%             if flag == 0
%                 title(strcat(cnt{:}, " Nominal ", ...
%                     datestr(price_data.Dates(row)), " ", curves.FitType{row, 1}))
%             elseif flag == 1
%                 title(strcat(cnt{:}, " Real ", ...
%                     datestr(price_data.Dates(row)), " ", curves.FitType{row, 1}))
%             end
% 
%             scatter(dateX, actual_yields*10000, 'DisplayName', 'Yeilds', ...
%                 'MarkerEdgeColor', 'blue')    
%             plot(date_range, model.getZeroRates(date_range)*10000, ...
%                 'DisplayName', 'Zero Curve', 'LineWidth', 1.5)
%             plot(date_range, model.getParYields(date_range)*10000, ...
%                 'DisplayName', 'Par Curve', 'LineWidth', 1.5)
%             
%             ylabel('Yield to Maturity (bps)')
%             xlabel('Residual Maturity (years)')
%             hold off; 
%             legend show; 
%             disp(1)
% %         end
        
    end
    
end
