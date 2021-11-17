% Primary executable file (run all file)

clear; clc;

%% set the primary directory to work in  
root_dir = pwd;

% enter the root directory 
cd(root_dir)            

%% add paths to acess files
addpath([root_dir filesep 'Code'])
addpath([root_dir filesep 'Code/lib'])                                      
addpath([root_dir filesep 'Input'])
addpath([root_dir filesep 'Temp'])
addpath([root_dir filesep 'Output'])

%% determine the countries to perform fit operations (user specified)

countries = {'UK', 'FRA'};

%% running project scripts in synchronous order 

run('data_reader.m')                % gather nominal and real bond data
run('build_term_structures.m')      % fit term structure model
