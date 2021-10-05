%
% Author, Rajesh Rao 
% 
% Construct par yield curves from fitted yeild curve model 
% ------------------------------------------------------------------------
% 
% Inputs:
%   :param: cnt (type cell) - cell containing str variable
%       The country code being examined (e.g. UK, US) which corresponds to
%       the country ids stored as sheet names within excel files
%   :param: flag (type int) - 1x1
%       A Boolean flag to determine type of fit (i.e., nominal or real)
%       NOTE: 1 = Real Bond, 0 = Nominal Bon files
% 
% Output:
%   :param: yld (type TimeTable) - M x N matrix
%       The time table corresponding to the curve fit for a given yield 
%       curve model (Nelson-Siegel or Svensson model) 
% 

function [outTable] = get_yields(cnt, flag, type)
    
    assert(flag == 0 | flag == 1, ...
    'Error: Flag must be integer 0 or 1, where 1 = Real and 0 = Nominal.')

    if flag == 0
        DATA = load('FITS.mat', 'fitted_n');
        DATA = DATA.fitted_n;
        fprintf('\nLoading Nominal Bond Data\n')
        
        % determine the maturity range being observed
        maturity = 1:30;
    elseif flag == 1
        DATA = load('FITS.mat', 'fitted_r');
        DATA = DATA.fitted_r;
        fprintf('\nLoading Real Bond Data\n')
        
        maturity = 2:20;
    end
    
    % soveregin curve fit for a given country
    curves = DATA.(cnt{:});
    
    % intantiate an array table for exporting par yield curve
    outTable = array2table(nan(numel(curves.Dates), numel(maturity)+1));
    
    varn = cell(1, numel(maturity)+1);
    varn(1) = {'Date'};
    idx = 2;                % index for itteration
    for i=maturity
        varn(idx) = {strcat(num2str(i), '-year')};
        idx = idx + 1; 
    end
    
    outTable.Properties.VariableNames = varn;
    outTable.Date = curves.Dates;
    outTable = table2timetable(outTable);
    
    M = numel(outTable.Date);      % numel of time series
    
    % iterate through dates and construct par yield curve
    for i=1:M
        
        fprintf('\tPar Yeild for %s\n', datestr(curves.Dates(i)));
        
        % convert today datenum object to dd-MM-yy series
        curr_date = outTable.Date(i);
        start_date = curr_date + caldays(365)*min(maturity);    
        end_date = curr_date + caldays(365)*max(maturity);     
        
        % date range for constructing par yeild curve 
        date_range = start_date:caldays(365):end_date;
        
        % if a bond curve fit was created (cell not empty)
        if ~isempty(curves.CurveFit{i})
            
            % get par yields for input dates for curve fit
            curve = curves.CurveFit{i}{:};
            
            if type == "par"
                yld = curve.getParYields(date_range)';
            elseif type == "zero"
                yld = curve.getZeroRates(date_range)';
            end
                
            % assign the corresponding fitted curve
            outTable{i, :} = yld * 100;
            
        end
        
    end
    
end