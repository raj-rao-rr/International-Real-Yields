% Plot the accompanying sequence of fitted yeilds across tenor

clearvars -except root_dir countries;

load YIELDS yield_r yield_n
load FITS fitted_r fitted_n
load HAVER french_zc_nominal uk_zc_nominal uk_zc_real

%% Yield Curve Fit vs Central Bank fits (UK)

settlement = fitted_n.UK.Dates(200);

figure('visible', 'on');                         
set(gcf, 'Position', [100, 100, 1250, 650]); 

hold on;

title(strcat("UK Settlement ", datestr(settlement)))

bonds = fitted_n.UK{ismember(fitted_n.UK.Dates, settlement), 'Bonds'};
bonds = bonds{:};

model = fitted_n.UK{ismember(fitted_n.UK.Dates, settlement), 'CurveFit'};
model = model{:}{:};

dateX = datetime(bonds(:, 2), 'ConvertFrom', 'datenum');
date_range = min(dateX):caldays(30):max(dateX);

actual_yields = bndyield(bonds(:, 3), bonds(:,4), ...
    bonds(:, 1), bonds(:,2));

scatter(dateX, actual_yields*10000, 'DisplayName', 'Yeilds', ...
    'MarkerEdgeColor', 'blue')    
plot(date_range, model.getZeroRates(date_range)*10000, ...
    'DisplayName', 'Zero Curve', 'LineWidth', 1.5)
plot(date_range, model.getParYields(date_range)*10000, ...
    'DisplayName', 'Par Curve', 'LineWidth', 1.5)

% Central bank generated curve 
X = settlement:caldays(365):settlement+caldays(365*35);
plot(X(2:end), uk_zc_nominal{ismember(uk_zc_nominal.Date, settlement), ...
    [11:12:59, 61:2:119]}*100, 'DisplayName', 'Central Bank', 'Color', ...
    'black', 'LineWidth', 2, 'LineStyle', '--')

ylabel('Yield to Maturity (bps)')
xlabel('Residual Maturity (years)')
hold off; 
legend('show', 'location', 'southeast'); 

%% Yield Curve Fit vs Central Bank fits (FRA)

settlement = fitted_n.FRA.Dates(200);

figure('visible', 'on');                         
set(gcf, 'Position', [100, 100, 1250, 650]); 

hold on;

title(strcat("FRA Settlement ", datestr(settlement)))

bonds = fitted_n.FRA{ismember(fitted_n.FRA.Dates, settlement), 'Bonds'};
bonds = bonds{:};

model = fitted_n.FRA{ismember(fitted_n.FRA.Dates, settlement), 'CurveFit'};
model = model{:}{:};

dateX = datetime(bonds(:, 2), 'ConvertFrom', 'datenum');
date_range = min(dateX):caldays(30):max(dateX);

actual_yields = bndyield(bonds(:, 3), bonds(:,4), ...
    bonds(:, 1), bonds(:,2));

scatter(dateX, actual_yields*10000, 'DisplayName', 'Yeilds', ...
    'MarkerEdgeColor', 'blue')    
plot(date_range, model.getZeroRates(date_range)*10000, ...
    'DisplayName', 'Zero Curve', 'LineWidth', 1.5)
plot(date_range, model.getParYields(date_range)*10000, ...
    'DisplayName', 'Par Curve', 'LineWidth', 1.5)

% Central bank generated curve 
X = [settlement+caldays(365), settlement+caldays(365*2), settlement+caldays(365*3), ...
    settlement+caldays(365*5), settlement+caldays(365*7), settlement+caldays(365*10), ...
    settlement+caldays(365*15), settlement+caldays(365*20), settlement+caldays(365*25), ...
    settlement+caldays(365*30)];

plot(X, french_zc_nominal{ismember(french_zc_nominal.Date, settlement), ...
    2:end}*100, 'DisplayName', 'Central Bank', 'Color', 'black', ...
    'LineWidth', 2, 'LineStyle', '--')

ylabel('Yield to Maturity (bps)')
xlabel('Residual Maturity (years)')
hold off; 
legend('show', 'location', 'southeast'); 

%% UK Yields to Central Bank Rates (bps)

% yeild time series
figure('visible', 'on');                         
set(gcf, 'Position', [100, 100, 1250, 650]); 

title('UK Nominal Bonds')

hold on;
X = yield_n.UKZero(ismember(yield_n.UKZero.Date, uk_zc_nominal.Date), :).Date;
field = '10-year';

y1 = yield_n.UKZero{ismember(yield_n.UKZero.Date, uk_zc_nominal.Date), field};
y2 = yield_n.UKPar{ismember(yield_n.UKPar.Date, uk_zc_nominal.Date), field};
y3 = uk_zc_nominal{ismember(uk_zc_nominal.Date, yield_n.UKZero.Date), '10-year'};

plot(X, y1*100, 'DisplayName', strcat('Zero'))
plot(X, y2*100, 'DisplayName', strcat('Par'))
plot(X, y3*100, 'DisplayName', strcat('Central Bank', " ",field))
hold off; 

ylabel('Yields in bps')
legend show; 

%% French Yields to Central Bank Rates (bps)

% yeild time series
figure('visible', 'on');                         
set(gcf, 'Position', [100, 100, 1250, 650]); 

title('FRA Nominal Bonds')

hold on;
X = yield_n.FRAZero(ismember(yield_n.FRAZero.Date, french_zc_nominal.Date), :).Date;
field = '10-year';

y1 = yield_n.FRAZero{ismember(yield_n.FRAZero.Date, french_zc_nominal.Date), field};
y2 = yield_n.FRAPar{ismember(yield_n.FRAPar.Date, french_zc_nominal.Date), field};
y3 = french_zc_nominal{ismember(french_zc_nominal.Date, yield_n.UKZero.Date), field};

plot(X, y1*100, 'DisplayName', strcat('Zero'))
plot(X, y2*100, 'DisplayName', strcat('Par'))
plot(X, y3*100, 'DisplayName', strcat('Central Bank', " ",field))
hold off; 

ylabel('Yields in bps')
legend show; 

%% French Spread to Central Bank Rates (bps)

% yeild time series
figure('visible', 'on');                         
set(gcf, 'Position', [100, 100, 1250, 650]); 

title('French Nominal Bonds (NSS vs Central Bank)')

hold on;
X = yield_n.FRA(ismember(yield_n.FRA.Date, french_zc_nominal{:, 1}), :).Date;

for name = french_zc_nominal.Properties.VariableNames(7)
    
    y1 = yield_n.FRA{ismember(yield_n.FRA.Date, french_zc_nominal{:, 1}), ...
        name{:}};
    y2 = french_zc_nominal{ismember(french_zc_nominal{:, 1}, ...
        yield_n.FRA.Date), name{:}};
    
    plot(X, (y1-y2)*100, 'DisplayName', name{:})
end

plot(X, zeros(1, numel(X))+20, 'Color', 'black', 'LineStyle', '--', ...
    'DisplayName', '20bps Level', 'LineWidth', 2)
plot(X, zeros(1, numel(X)), 'Color', 'black', 'LineStyle', '--', ...
    'DisplayName', '0bps Level', 'LineWidth', 2)

hold off; 
ylabel('Spread in bps')
legend('show', 'location', 'southwest'); 

%%


