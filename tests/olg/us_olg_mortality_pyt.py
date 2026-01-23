# -*- coding: utf-8 -*-
"""
Created on Sun Apr 27 14:34:01 2025

@author: wrgar
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import fsolve

# Parameters
alpha = 0.33  # Capital share
beta = 0.95   # Discount factor
n = 0.01      # Population growth
delta = 0.05  # Depreciation rate
theta = 2.0   # CRRA coefficient
mu = 0.2      # Baseline mortality probability
mu_prime = 0.1  # Reduced mortality (50%)

# Production function (per worker)
def production(k):
    return k**alpha

# Wage and interest rate
def wage(k):
    return (1 - alpha) * production(k)

def interest_rate(k):
    return alpha * k**(alpha - 1) - delta

# Psi function (depends on mu and r)
def psi(mu, r):
    return ((1 - mu) * beta * (1 + r)**(2 - theta))**(1/theta)

# Savings function
def savings(w, mu, r):
    psi_val = psi(mu, r)
    return (psi_val * w) / (1 + psi_val)

# Capital dynamics
def capital_dynamics(k, mu):
    w = wage(k)
    r_next = interest_rate(k)  # Approximation: use current k for r_{t+1}
    s = savings(w, mu, r_next)
    return s / (1 + n)

# Steady-state equation
def steady_state_eq(k, mu):
    return k - capital_dynamics(k, mu)

# Solve for steady state
def find_steady_state(mu, k_guess=1.0):
    k_star = fsolve(steady_state_eq, k_guess, args=(mu,))[0]
    return k_star

# Simulate transition
def simulate_transition(k0, mu, T=100):
    k_path = [k0]
    for t in range(T):
        k_next = capital_dynamics(k_path[-1], mu)
        k_path.append(k_next)
    return np.array(k_path)

# Compute steady states
k_star_initial = find_steady_state(mu)
k_star_new = find_steady_state(mu_prime)

# Simulate transition from initial steady state after mortality shock
k0 = k_star_initial
T = 100
k_path = simulate_transition(k0, mu_prime, T)

# Compute output path
y_path = k_path**alpha

# Plot results
plt.figure(figsize=(10, 6))
plt.plot(range(T+1), y_path, label='Output per worker (y_t)')
plt.axhline(y=k_star_initial**alpha, color='r', linestyle='--', label='Initial steady state')
plt.axhline(y=k_star_new**alpha, color='g', linestyle='--', label='New steady state')
plt.xlabel('Time')
plt.ylabel('Output per worker')
plt.title('Effect of 50% Mortality Reduction on Economic Growth (CRRA Utility)')
plt.legend()
plt.grid(True)
plt.savefig('olg_crra_output.png')
