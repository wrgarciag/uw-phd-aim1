% olg_model_scenario.m
% Overlapping Generations (OLG) Model with CRRA Utility in MATLAB
% Simulates a linear reduction in young mortality probability from 0.2 in 2025 to 0.1 in 2050
% Computes discounted present value (2025) of differences between base (mu=0.2) and reduction scenarios
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
T = 25;          % Number of periods

% Linear reduction slope
slope = (mu_initial - mu_final) / T_reduction; % 0.004 per year

% Mortality probability functions
mu_base_t = @(t) mu_initial; % Base scenario: constant mu
mu_reduction_t = @(t) max(mu_final, mu_initial - slope * t); % Reduction scenario

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

% Simulate base scenario (mu = 0.2 constant)
k_base = zeros(T+1, 1);
mu_base = zeros(T+1, 1);
k_base(1) = k_star_initial;
mu_base(1) = mu_initial;

for t = 1:T
    mu_base(t+1) = mu_base_t(t);
    k_base(t+1) = capital_dynamics(k_base(t), mu_base(t+1));
end

y_base = production(k_base);
w_base = wage(k_base);
r_base = interest_rate(k_base);
psi_base = psi(mu_base, r_base);
c_y_base = w_base ./ (1 + psi_base);
s_base = w_base - c_y_base;
c_o_base = (1 + r_base) .* [s_initial; s_base(1:end-1)];

% Simulate reduction scenario (mu = 0.2 to 0.1)
k_reduction = zeros(T+1, 1);
mu_reduction = zeros(T+1, 1);
k_reduction(1) = k_star_initial;
mu_reduction(1) = mu_initial;

for t = 1:T
    mu_reduction(t+1) = mu_reduction_t(t);
    k_reduction(t+1) = capital_dynamics(k_reduction(t), mu_reduction(t+1));
end

y_reduction = production(k_reduction);
w_reduction = wage(k_reduction);
r_reduction = interest_rate(k_reduction);
psi_reduction = psi(mu_reduction, r_reduction);
c_y_reduction = w_reduction ./ (1 + psi_reduction);
s_reduction = w_reduction - c_y_reduction;
c_o_reduction = (1 + r_reduction) .* [s_initial; s_reduction(1:end-1)];

% Compute differences
delta_k = k_reduction - k_base;
delta_y = y_reduction - y_base;
delta_w = w_reduction - w_base;
delta_r = r_reduction - r_base;
delta_c_y = c_y_reduction - c_y_base;
delta_c_o = c_o_reduction - c_o_base;

% Total consumption
c_total_base = c_y_base + c_o_base;
c_total_reduction = c_y_reduction + c_o_reduction;
delta_c_total = c_total_reduction - c_total_base;

% Compute DPV (use base scenario steady-state interest rate for discounting)
r_discount = r_initial; % Steady-state interest rate
discount_factor = 1 / (1 + r_discount);
dpv = @(delta) sum(delta .* (discount_factor .^ (0:T)));

dpv_k = dpv(delta_k);
dpv_y = dpv(delta_y);
dpv_w = dpv(delta_w);
dpv_r = dpv(delta_r);
dpv_c_y = dpv(delta_c_y);
dpv_c_o = dpv(delta_c_o);
dpv_c_total = dpv(delta_c_total);

% Display DPV results
disp('Discounted Present Value (2025) of Differences (Reduction - Base):');
fprintf('Capital (k): %.4f\n', dpv_k);
fprintf('Output (y): %.4f\n', dpv_y);
fprintf('Wage (w): %.4f\n', dpv_w);
fprintf('Interest rate (r): %.4f\n', dpv_r);
fprintf('Young consumption (c_y): %.4f\n', dpv_c_y);
fprintf('Old consumption (c_o): %.4f\n', dpv_c_o);
fprintf('Total consumption (c_y + c_o): %.4f\n', dpv_c_total);

% Plot differences
figure('Position', [100, 100, 1200, 1000]);

% Capital difference
subplot(3, 2, 1);
plot(2025:2025+T, delta_k, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [0 0], 'k--', 'LineWidth', 1);
xlabel('Year');
ylabel('\Delta k_t');
title('Difference in Capital (Reduction - Base)');
grid on;

% Output difference
subplot(3, 2, 2);
plot(2025:2025+T, delta_y, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [0 0], 'k--', 'LineWidth', 1);
xlabel('Year');
ylabel('\Delta y_t');
title('Difference in Output (Reduction - Base)');
grid on;

% Young consumption difference
subplot(3, 2, 3);
plot(2025:2025+T, delta_c_y, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [0 0], 'k--', 'LineWidth', 1);
xlabel('Year');
ylabel('\Delta c_{y,t}');
title('Difference in Young Consumption');
grid on;

% Old consumption difference
subplot(3, 2, 4);
plot(2025:2025+T, delta_c_o, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [0 0], 'k--', 'LineWidth', 1);
xlabel('Year');
ylabel('\Delta c_{o,t}');
title('Difference in Old Consumption');
grid on;

% Total consumption difference
subplot(3, 2, 5);
plot(2025:2025+T, delta_c_total, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [0 0], 'k--', 'LineWidth', 1);
xlabel('Year');
ylabel('\Delta c_{total,t}');
title('Difference in Total Consumption');
grid on;

% Save figure with error handling
try
    saveas(gcf, 'olg_differences_dpv.png');
catch e
    warning('Failed to save figure: %s', e.message);
end

% Save results with error handling
try
    save('olg_dpv_results.mat', ...
        'k_base', 'y_base', 'w_base', 'r_base', 'c_y_base', 'c_o_base', 'c_total_base', ...
        'k_reduction', 'y_reduction', 'w_reduction', 'r_reduction', 'c_y_reduction', 'c_o_reduction', 'c_total_reduction', ...
        'mu_base', 'mu_reduction', 'delta_k', 'delta_y', 'delta_w', 'delta_r', 'delta_c_y', 'delta_c_o', 'delta_c_total', ...
        'dpv_k', 'dpv_y', 'dpv_w', 'dpv_r', 'dpv_c_y', 'dpv_c_o', 'dpv_c_total', ...
        'k_star_initial', 'k_star_final', 'y_initial', 'y_final');
catch e
    warning('Failed to save results: %s', e.message);
end

% Plot original reduction scenario paths (for reference)
figure('Position', [100, 100, 1200, 1000]);

% Capital
subplot(3, 2, 1);
plot(2025:2025+T, k_reduction, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [k_star_initial k_star_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [k_star_final k_star_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Capital per worker (k_t)');
title('Capital Transition (Reduction Scenario)');
legend('k_t', 'Initial Steady State', 'Final Steady State', 'Location', 'best');
grid on;

% Output
subplot(3, 2, 2);
plot(2025:2025+T, y_reduction, 'b-', 'LineWidth', 2);
hold on;
plot([2025 2025+T], [y_initial y_initial], 'r--', 'LineWidth', 1.5);
plot([2025 2025+T], [y_final y_final], 'g--', 'LineWidth', 1.5);
xlabel('Year');
ylabel('Output per worker (y_t)');
title('Output Transition (Reduction Scenario)');
legend('y_t', 'Initial Steady State', 'Final Steady State', 'Location', 'best');
grid on;

% Young consumption
subplot(3, 2, 3);
plot(2025:2025+T, c_y_reduction, 'b-', 'LineWidth', 2);
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
plot(2025:2025+T, c_o_reduction, 'b-', 'LineWidth', 2);
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
plot(2025:2025+T, mu_reduction, 'b-', 'LineWidth', 2);
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

% Display steady-state results
disp('Steady State Results:');
disp(['Initial k* (mu = 0.2, 2025): ', num2str(k_star_initial)]);
disp(['Final k* (mu = 0.1, 2050+): ', num2str(k_star_final)]);
disp(['Initial y* (mu = 0.2, 2025): ', num2str(y_initial)]);
disp(['Final y* (mu = 0.1, 2050+): ', num2str(y_final)]);