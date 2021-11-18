% Reads in bond and price data from the excel sheets from both real and 
% nominal sovereign bond releases from countries

clearvars -except root_dir countries;

%% Save extracted yeilds from HAVER

french_zc_nominal = readtable(strcat(root_dir, '/Input/yields_clean_haver.xlsx'), ...
      'Sheet', 'FRE_ZC', 'PreserveVariableNames', true);
  
uk_zc_nominal = readtable(strcat(root_dir, '/Input/yields_clean_haver.xlsx'), ...
      'Sheet', 'UK_Nominal_Spot', 'PreserveVariableNames', true);
uk_zc_real = readtable(strcat(root_dir, '/Input/yields_clean_haver.xlsx'), ...
      'Sheet', 'UK_Real_Spot', 'PreserveVariableNames', true);

save('Temp/HAVER.mat', 'french_zc_nominal', 'uk_zc_nominal', 'uk_zc_real') 

%% Save contents of real bond overview to .mat file

[~, sheet_names]=xlsfinfo(strcat(root_dir, ...
    '/Input/real_bond_overview.xlsx'));

% iterate through sheets retrieving accompanying bond data 
for k=1:numel(sheet_names)
    export_tb=readtable(strcat(root_dir, '/Input/real_bond_overview.xlsx'), ...
      'Sheet', sheet_names{k}, 'PreserveVariableNames', true);
    
    % export the accompanying bond overview to .mat file  
    export_name = strcat(sheet_names{k}, '_Bonds');
    S.(export_name) = export_tb;
    save(strcat(root_dir, '/Temp/REAL.mat'), '-struct', 'S') 
end

%% Save contents of real bond prices to .mat file

[~, sheet_names]=xlsfinfo(strcat(root_dir, ...
    '/Input/real_bond_prices.xlsx'));

% iterate through sheets retrieving accompanying bond data 
for k=1:numel(sheet_names)
    export_tb=readtable(strcat(root_dir, '/Input/real_bond_prices.xlsx'), ...
      'Sheet', sheet_names{k}, 'PreserveVariableNames', true);
    
    % export the accompanying bond overview to .mat file  
    export_name = strcat(sheet_names{k}, '_Prices');
    S.(export_name) = table2timetable(export_tb);
    save(strcat(root_dir, '/Temp/REAL.mat'), '-struct', 'S') 
end

%% Save contents of nominal bond overview to .mat file

[~, sheet_names]=xlsfinfo(strcat(root_dir, ...
    '/Input/nominal_bond_overview.xlsx'));

% iterate through sheets retrieving accompanying bond data 
for k=1:numel(sheet_names)
    export_tb=readtable(strcat(root_dir, '/Input/nominal_bond_overview.xlsx'), ...
      'Sheet', sheet_names{k}, 'PreserveVariableNames', true);
    
    % export the accompanying bond overview to .mat file  
    export_name = strcat(sheet_names{k}, '_Bonds');
    S.(export_name) = export_tb;
    save(strcat(root_dir, '/Temp/NOMINAL.mat'), '-struct', 'S') 
end

%% Save contents of nominal bond prices to .mat file

[~, sheet_names]=xlsfinfo(strcat(root_dir, ...
    '/Input/nominal_bond_prices.xlsx'));

% iterate through sheets retrieving accompanying bond data 
for k=1:numel(sheet_names)
    export_tb=readtable(strcat(root_dir, '/Input/nominal_bond_prices.xlsx'), ...
      'Sheet', sheet_names{k}, 'PreserveVariableNames', true);
    
    % export the accompanying bond overview to .mat file  
    export_name = strcat(sheet_names{k}, '_Prices');
    S.(export_name) = table2timetable(export_tb);
    save(strcat(root_dir, '/Temp/NOMINAL.mat'), '-struct', 'S') 
end

%% face value conventions for securities (refer to links below)

% AUS: https://www2.asx.com.au/content/dam/asx/participants/cash-market/bonds/ASX-42301-AGB-Fact-Sheet.pdf
% CAN:
% FRA: https://www.aft.gouv.fr/en/oat-characteristics
% GER:
% KOR:
% JPN: https://www.mof.go.jp/english/policy/jgbs/debt_management/guide.htm
% SWE:
% UK: https://www.dmo.gov.uk/responsibilities/gilt-market/about-gilts/
% ITA:
% US: https://www.treasurydirect.gov/indiv/research/indepth/tbills/res_tbill.htm

keySet = {'AUS', 'CAN', 'FRA', 'GER', 'KOR', 'JPN', 'SWE', 'UK', ...
    'ITA', 'US'};
valueSet = [100, 100, 1, 100, 100, 100, 100, 100, 100, 100];
FaceValue = containers.Map(keySet,valueSet);

fprintf('\n1. All data has been cleaned and processed.')
