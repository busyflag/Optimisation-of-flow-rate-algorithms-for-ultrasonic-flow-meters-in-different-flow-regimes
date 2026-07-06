clc;
clear;
close all;

%% 固定参数
D = 0.04;            % 管道内径 (m)
R = D / 2;           % 管道半径 (m)
nu = 1.007e-6;       % 水的运动粘度 (m²/s)
N = 1000;            % 径向离散点数（优化速度）

%% 标定数据
u_m_laminar = 0.05003;  v_S_target_laminar = 0.062;   % 层流标定
u_m_turbulent = 0.1006; v_S_target_turbulent = 0.124; % 湍流标定

%% 拟合 a (层流修正因子)
a_guess = 1.0;  % 初始猜测值
a = fzero(@(a) fit_correction_factor(a, u_m_laminar, v_S_target_laminar, D, nu, N, 'laminar'), a_guess);

%% 拟合 b (湍流修正因子)
b_guess = 1.0;  % 初始猜测值
b = fzero(@(b) fit_correction_factor(b, u_m_turbulent, v_S_target_turbulent, D, nu, N, 'turbulent'), b_guess);

fprintf('拟合结果:\na (层流) = %.6f\nb (湍流) = %.6f\n', a, b);

%% 验证拟合结果
% 层流验证
v_S_calc_laminar = calculate_v_S(a, u_m_laminar, D, nu, N, 'laminar');
fprintf('层流验证:\n目标 v_S = %.6f, 计算 v_S = %.6f, 误差 = %.6f\n', ...
    v_S_target_laminar, v_S_calc_laminar, abs(v_S_target_laminar - v_S_calc_laminar));

% 湍流验证
v_S_calc_turbulent = calculate_v_S(b, u_m_turbulent, D, nu, N, 'turbulent');
fprintf('湍流验证:\n目标 v_S = %.6f, 计算 v_S = %.6f, 误差 = %.6f\n', ...
    v_S_target_turbulent, v_S_calc_turbulent, abs(v_S_target_turbulent - v_S_calc_turbulent));

%% 定义支持函数
function error = fit_correction_factor(factor, u_m, v_S_target, D, nu, N, flow_type)
    % 计算给定修正因子下的 v_S，返回与目标值的误差
    R = D / 2;
    r = linspace(0, R, N);
    s = r / R;
    
    switch flow_type
        case 'laminar'
            u = factor * u_m * (1 - s.^2);
        case 'turbulent'
            Re = (u_m * D) / nu;
            Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
            n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
            n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
            u = factor * u_m * (1 - s).^(1/n);
    end
    
    v_S_calc = trapz(r, u .* r) * 2 / R^2;
    error = v_S_calc - v_S_target;
end

function v_S = calculate_v_S(factor, u_m, D, nu, N, flow_type)
    % 计算给定修正因子下的面平均速度 v_S
    R = D / 2;
    r = linspace(0, R, N);
    s = r / R;
    
    switch flow_type
        case 'laminar'
            u = factor * u_m * (1 - s.^2);
        case 'turbulent'
            Re = (u_m * D) / nu;
            Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
            n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
            n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
            u = factor * u_m * (1 - s).^(1/n);
    end
    
    v_S = trapz(r, u .* r) * 2 / R^2;
end
