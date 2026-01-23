% olg_model.m
% Overlapping Generations (OLG) Model with CRRA Utility in MATLAB
% Solves for steady state and simulates a 50% reduction in young mortality probability
% Save this file as 'olg_model.m' and run with: run olg_model or olg_model

clear all;
close all;

% Parameters
alpha = 0.33;     % Capital share
beta = 0.95;      % Discount factor
n = 0.01;         % Population growth rate
delta = 0.05;     % Depreciation rate
theta = 2.0;      % CRRA coefficient
mu_initial = 0.2; % Initial mortality probability
mu_new = 0.1;     % New mortality probability (50% reduction)

% Production function (per worker, element-wise for vectors)
production = @(k) k.^alpha;

% Wage
wage = @(k) (1 - alpha) * production(k);

% Interest rate
interest_rate = @(k) alpha * k.^(alpha - 1) - delta;

% Psi function
psi = @(mu, r) ((1 - mu) * beta * (1 + r).^(2 - theta)).^(1/theta);

% Savings function
savings = @(w, mu, r) (psi(mu, r) .* w) ./ (1 + psi(mu, r));

% Capital dynamics
capital_dynamics = @(k, mu) savings(wage(k), mu, interest_rate(k)) / (1 + n);

% Steady-state equation for k
steady_state_eq = @(k, mu) k - capital_dynamics(k, mu);

% Solve for steady state
find_steady_state = @(mu) fsolve(@(k) steady_state_eq(k, mu), 1.0, optimoptions('fsolve', 'Display', 'off'));

% Compute initial and new steady states
k_star_initial = find_steady_state(mu_initial);
k_star_new = find_steady_state(mu_new);

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
[k_new, y_new, w_new, r_new, psi_new, c_y_new, s_new, c_o_new] = compute_vars(k_star_new, mu_new);

% Simulate transition
T = 100; % Number of periods
k_path = zeros(T+1, 1);
k_path(1) = k_star_initial; % Start at initial steady state

for t = 1:T
    k_path(t+1) = capital_dynamics(k_path(t), mu_new);
end

% Compute paths for other variables
y_path = production(k_path);
w_path = wage(k_path);
r_path = interest_rate(k_path);
psi_path = psi(mu_new, r_path);
c_y_path = w_path ./ (1 + psi_path);
s_path = w_path - c_y_path;
c_o_path = (1 + r_path) .* [s_initial; s_path(1:end-1)]; % Lagged savings

% Plot results
figure('Position', [100, 100, 1200, 800]);

% Capital
subplot(2, 2, 1);
plot(0:T, k_path, 'b-', 'LineWidth', 2);
hold on;
plot([0 T], [k_star_initial k_star_initial], 'r--', 'LineWidth', 1.5);
plot([0 T], [k_star_new k_star_new], 'g--', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Capital per worker (k_t)');
title('Capital Transition');
legend('k_t', 'Initial Steady State', 'New Steady State', 'Location', 'best');
grid on;

% Output
subplot(2, 2, 2);
plot(0:T, y_path, 'b-', 'LineWidth', 2);
hold on;
plot([0 T], [y_initial y_initial], 'r--', 'LineWidth', 1.5);
plot([0 T], [y_new y_new], 'g--', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Output per worker (y_t)');
title('Output Transition');
legend('y_t', 'Initial Steady State', 'New Steady State', 'Location', 'best');
grid on;

% Young consumption
subplot(2, 2, 3);
plot(0:T, c_y_path, 'b-', 'LineWidth', 2);
hold on;
plot([0 T], [c_y_initial c_y_initial], 'r--', 'LineWidth', 1.5);
plot([0 T], [c_y_new c_y_new], 'g--', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Young consumption (c_y_t)');
title('Young Consumption Transition');
legend('c_y_t', 'Initial Steady State', 'New Steady State', 'Location', 'best');
grid on;

% Old consumption
subplot(2, 2, 4);
plot(0:T, c_o_path, 'b-', 'LineWidth', 2);
hold on;
plot([0 T], [c_o_initial c_o_initial], 'r--', 'LineWidth', 1.5);
plot([0 T], [c_o_new c_o_new], 'g--', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Old consumption (c_o_t)');
title('Old Consumption Transition');
legend('c_o_t', 'Initial Steady State', 'New Steady State', 'Location', 'best');
grid on;

% Save figure with error handling
try
    saveas(gcf, 'olg_transition.png');
catch e
    warning('Failed to save figure: %s', e.message);
end

% Save results with error handling
try
    save('olg_results.mat', 'k_path', 'y_path', 'w_path', 'c_y_path', 'c_o_path', 'k_star_initial', 'k_star_new', 'y_initial', 'y_new');
catch e
    warning('Failed to save results: %s', e.message);
end

% Display steady-state results
disp('Steady State Results:');
disp(['Initial k* (mu = 0.2): ', num2str(k_star_initial)]);
disp(['New k* (mu = 0.1): ', num2str(k_star_new)]);
disp(['Initial y* (mu = 0.2): ', num2str(y_initial)]);
disp(['New y* (mu = 0.1): ', num2str(y_new)]);