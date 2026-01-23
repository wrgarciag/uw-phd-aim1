

% MATLAB script to run Dynare model and check steady state
clear all;
close all;
clc;

% 1) Add Dynare’s MATLAB folder to the path
dynare_path = 'C:\dynare\6.3\matlab';
addpath(dynare_path);

% 2) Change to the folder containing .mod files
modelsDir = 'C:\Users\wrgar\OneDrive - UW\04Dissertation\USPPD50x50\code\turnovsky';
cd(modelsDir);

% Clean up previous Dynare output
system('rmdir /S /Q health_model');

% Run Dynare
dynare health_model.mod

% Load Dynare results
load dynare_results.mat

% Time periods
T = 100;
t = 1:T;

% Plot IRFs for key variables
figure('Name', 'Impulse Response Functions');

subplot(3,2,1);
plot(t, oo_.endo_simul(find(strcmp(M_.endo_names, 'c')), 1:T), 'b', 'LineWidth', 2);
title('Consumption (c)');
xlabel('Periods');
ylabel('Deviation');
grid on;

subplot(3,2,2);
plot(t, oo_.endo_simul(find(strcmp(M_.endo_names, 'h')), 1:T), 'b', 'LineWidth', 2);
title('Health (h)');
xlabel('Periods');
ylabel('Deviation');
grid on;

subplot(3,2,3);
plot(t, oo_.endo_simul(find(strcmp(M_.endo_names, 'k')), 1:T), 'b', 'LineWidth', 2);
title('Physical Capital (k)');
xlabel('Periods');
ylabel('Deviation');
grid on;

subplot(3,2,4);
plot(t, oo_.endo_simul(find(strcmp(M_.endo_names, 'm')), 1:T), 'b', 'LineWidth', 2);
title('Health Capital (m)');
xlabel('Periods');
ylabel('Deviation');
grid on;

subplot(3,2,5);
plot(t, oo_.endo_simul(find(strcmp(M_.endo_names, 'l')), 1:T), 'b', 'LineWidth', 2);
title('Leisure (l)');
xlabel('Periods');
ylabel('Deviation');
grid on;

subplot(3,2,6);
plot(t, oo_.endo_simul(find(strcmp(M_.endo_names, 'y')), 1:T), 'b', 'LineWidth', 2);
title('Output (y)');
xlabel('Periods');
ylabel('Deviation');
grid on;

% Adjust layout
set(gcf, 'Position', [100, 100, 1200, 800]);
sgtitle('Impulse Responses to 1% Increase in Health Investment (g)');

% Save plot
saveas(gcf, 'IRFs_health_model.png');
