% Primary executable file (run all file)

clear; clc;

%% set the primary directory to work in  
root_dir = pwd;

% enter the root directory 
cd(root_dir)            

%% add paths to acess files
addpath([root_dir filesep 'Code'])
addpath([root_dir filesep 'Code/library'])                                      
addpath([root_dir filesep 'Input'])
addpath([root_dir filesep 'Temp'])
addpath([root_dir filesep 'Output'])

%% face value conventions for securities (refer to links below)

% UK: https://www.dmo.gov.uk/responsibilities/gilt-market/about-gilts/
% FRA: https://www.aft.gouv.fr/en/oat-characteristics

keySet = {'UK','FRA'};
valueSet = [100, 1];
FaceValue = containers.Map(keySet,valueSet);

%% determine the countries to perform fit operations (user specified)

countries = {'UK', 'FRA'};

%% running project scripts in synchronous order 
% run('data_reader.m')  
run('build_term_structures.m')
