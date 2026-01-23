% MATLAB script to run Dynare model and check steady state
clear all;
close all;
clc;

% 1) Add Dynare’s MATLAB folder to the path
%dynare_path = 'C:\dynare\6.3\matlab';
%addpath(dynare_path);

% 2) Change to the folder containing .mod files
modelsDir = 'C:\Users\wrgar\OneDrive - UW\04Dissertation\USPPD50x50\tests\olg';
cd(modelsDir);

% Clean up previous Dynare output
%system('rmdir /S /Q us_olg_mortality');

% Run Dynare
%dynare us_olg_mortality.mod

% Run matlab version
run("olg_model_scenario_exogenous_pv.m")
