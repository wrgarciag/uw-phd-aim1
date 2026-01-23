% MATLAB script to run Dynare model and check steady state
clear all;
close all;
clc;

% Add Dynare to MATLAB path (adjust path as needed)
addpath('C:\dynare\6.3\matlab'); % Update to your Dynare 6.3 installation path

% Current working directory
working_dir = pwd;
fprintf('Current working directory: %s\n', working_dir);

% Remove existing health_model directory or file to avoid filesystem error
if exist('health_model', 'dir')
    fprintf('Removing directory: health_model\n');
    try
        rmdir('health_model', 's');
    catch e
        fprintf('Error removing directory: %s\n', e.message);
    end
elseif exist('health_model', 'file')
    fprintf('Removing file: health_model\n');
    delete('health_model');
end

% Verify removal
if exist('health_model', 'dir') || exist('health_model', 'file')
    fprintf('Warning: health_model still exists. Attempting to run in a temporary directory.\n');
    temp_dir = fullfile(tempdir, 'dynare_run');
    if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
    end
    copyfile('health_model.mod', temp_dir);
    cd(temp_dir);
    fprintf('Switched to temporary directory: %s\n', temp_dir);
else
    fprintf('health_model directory/file successfully removed.\n');
end

% Pause briefly to ensure filesystem updates
pause(1);

% Run Dynare
try
    dynare health_model.mod noclearall
catch e
    fprintf('Dynare failed: %s\n', e.message);
    % Save and inspect driver.m
    if exist('health_model/driver.m', 'file')
        % Save a copy of driver.m
        copyfile('health_model/driver.m', 'driver_copy.m');
        fprintf('Saved driver.m as driver_copy.m for inspection.\n');
        % Read driver.m and display lines around 560
        fprintf('Inspecting driver.m for errors (lines 550–570)...\n');
        fileID = fopen('health_model/driver.m', 'r');
        lines = textscan(fileID, '%s', 'Delimiter', '\n');
        fclose(fileID);
        start_line = max(1, 560-10);
        end_line = min(length(lines{1}), 560+10);
        for i = start_line:end_line
            fprintf('Line %d: %s\n', i, lines{1}{i});
        end
    else
        fprintf('driver.m not found in health_model directory.\n');
    end
    % Restore original directory if using temp_dir
    if exist('temp_dir', 'var')
        cd(working_dir);
    end
    rethrow(e);
end

% Check if steady-state results exist
if exist('oo_', 'var') && isfield(oo_, 'steady_state')
    fprintf('Steady state computed successfully:\n');
    endo_names = M_.endo_names;
    steady_state = oo_.steady_state;
    for i = 1:length(endo_names)
        fprintf('%s: %.4f\n', endo_names{i}, steady_state(i));
    end
else
    fprintf('No steady-state results found.\n');
end

% Restore original directory if using temp_dir
if exist('temp_dir', 'var')
    cd(working_dir);
    fprintf('Restored original directory: %s\n', working_dir);
end




