% olg_model_scenario.m
% Overlapping Generations (OLG) Model with CRRA Utility in MATLAB
% Simulates a linear reduction in young mortality probability from 0.2 in 2025 to 0.1 in 2050
% Save this file as 'olg_model_scenario.m' and run with: run olg_model_scenario or olg_model_scenario
% Can be called from a wrapper script like run_us_olg_mortality.m

clear all;
close all;

% Parameters
alpha = 0.33;     % Capital share
beta = 0.95;      % Discount factor
n = 0.01;         % Population growth rate
delta = 0.05;     % Depreciation rate
theta = 2.0;      % CRRA coefficient
mu_initial = 0.2; % Initial mortality probability (2025)
mu_final = 0.1;   % Final mortality probability (2050)
T_reduction = 25; % Years for linear reduction (2025 to 2050)

% Linear reduction slope
slope = (mu_initial - mu_final) / T_reduction; % 0.004 per year

% Mortality probability function
mu_t = @(t) max(mu_final, mu_initial - slope * t); % Linear decrease, then constant at mu_final

% Production function (per worker, element-wise for vectors)
production = @(k) k.^alpha;

% Wage
wage = @(k) (1 - alpha) * production(k);

% Interest rate
interest_rate = @(k) alpha * k.^(alpha - 1) - delta;

% Psi function (fully element-wise for vectors)
psi = @(mu, r) ((1 - mu) .* beta .* (1 + r).^(2 - theta)).^(1/theta);

% Savings function
savings = @(w, mu, r) (psi(mu, r) .* w) ./ (1 + psi(mu, r));

% Capital dynamics
capital_dynamics = @(k, mu) savings(wage(k), mu, interest_rate(k)) / (1 + n);

% Steady-state equation for k
steady_state_eq = @(k, mu) k - capital_dynamics(k, mu);

% Solve for steady state
find_steady_state = @(mu) fsolve(@(k) steady_state_eq(k, mu), 1.0, optimoptions('fsolve', 'Display', 'off'));

% Compute initial and final steady states
k_star_initial = find_steady_state(mu_initial);
k_star_final = find_steady_state(mu_final);

% Compute steady-state variables
compute_vars = @(k, mu) deal(...
    k, ... % k
    production(k), ... % y
    wage(k), ... % w
    interest_rate(k), ... % r
    psi(mu, interest_rate(k)), ... % psi
    wage(k) ./ (1 + psi(mu, interest_rate(k))), ... % c_y
    savings(wage(k), mu, interest_rate(k)), ... % s
    (1 + interest_rate(k)) * savings(wage(k), mu, interest_rate(k))); % c_o

[k_initial, y_initial, w_initial, r_initial, psi_initial, c_y_initial, s_initial, c_o_initial] = compute_vars(k_star_initial, mu_initial);
[k_final, y_final, w_final, r_final, psi_final, c_y_final, s_final, c_o_final] = compute_vars(k_star_final, mu_final);

% Simulate transition
T = 27; % Number of periods
k_path = zeros(T+1, 1);
mu_path = zeros(T+1, 1);
k_path(1) = k_star_initial; % Start at initial steady state
mu_path(1) = mu_initial;

for t = 1:T
    mu_path(t+1) = mu_t(t);
    k_path(t+1) = capital_dynamics(k_path(t), mu_path(t+1));
end

% Compute paths for other variables
y_path = production(k_path);
w_path = wage(k_path);
r_path = interest_rate(k_path);
psi_path = psi(mu_path, r_path);
c_y_path = w_path ./ (1 + psi_path);
s_path = w_path - c_y_path;
c_o_path = (1 + r_path) .* [s_initial; s_path(1:end-1)]; % Lagged savings

% Plot results
figure('Position', [100, 100, 1200, 1000]);

% Capital
subplot(3, 2, 1);
plot(2025:2025+T, k_path, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [k_star_initial k_star_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [k_star_final k_star_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Capital per worker (k_t)');
title('Capital Transition');
legend('k_t', 'Initial Steady State', 'Final Steady State', 'Location', 'best');
grid on;

% Output
subplot(3, 2, 2);
plot(2025:2025+T, y_path, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [y_initial y_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [y_final y_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Output per worker (y_t)');
title('Output Transition');
legend('y_t', 'Initial Steady State', 'Final Steady State', 'Location', 'best');
grid on;

% Young consumption
subplot(3, 2, 3);
plot(2025:2025+T, c_y_path, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [c_y_initial c_y_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [c_y_final c_y_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Young consumption (c_y_t)');
title('Young Consumption Transition');
legend('c_y_t', 'Initial Steady State', 'Final Steady State', 'Location', 'best');
grid on;

% Old consumption
subplot(3, 2, 4);
plot(2025:2025+T, c_o_path, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [c_o_initial c_o_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [c_o_final c_o_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Old consumption (c_o_t)');
title('Old Consumption Transition');
legend('c_o_t', 'Initial Steady State', 'Final Steady State', 'Location', 'best');
grid on;

% Mortality probability
subplot(3, 2, 5);
plot(2025:2025+T, mu_path, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [mu_initial mu_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [mu_final mu_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Mortality probability (\mu_t)');
title('Mortality Probability Transition');
legend('\mu_t', 'Initial \mu', 'Final \mu', 'Location', 'best');
grid on;

% Save figure with error handling
try
    saveas(gcf, 'olg_transition_progressive.png');
catch e
    warning('Failed to save figure: %s', e.message);
end

% Save results with error handling
try
    save('olg_results_progressive.mat', 'k_path', 'y_path', 'w_path', 'c_y_path', 'c_o_path', 'mu_path', 'k_star_initial', 'k_star_final', 'y_initial', 'y_final');
catch e
    warning('Failed to save results: %s', e.message);
end

% Display steady-state results
disp('Steady State Results:');
disp(['Initial k* (mu = 0.2, 2025): ', num2str(k_star_initial)]);
disp(['Final k* (mu = 0.1, 2050+): ', num2str(k_star_final)]);
disp(['Initial y* (mu = 0.2, 2025): ', num2str(y_initial)]);
disp(['Final y* (mu = 0.1, 2050+): ', num2str(y_final)]);