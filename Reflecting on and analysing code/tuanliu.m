clc;
clear;
close all;

%% 固定参数
D = 0.04;            % 管道内径 (m)
R = D / 2;           % 管道半径 (m)
nu = 1.007e-6;       % 水的运动粘度 (m²/s)
c = 1482;            % 声速 (m/s)
theta = 45;          % 超声波传播角度 (度)
N = 1000;            % 径向离散点数
beta = 0.025;          % 湍流中心线斜率修正系数

%% 确保所有函数在调用前已定义（将函数移到文件开头）
function [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta)
    % 时差法计算面平均速度 v_S
    R = max(r);
    theta_rad = deg2rad(theta);

    K = c / (u_m * cos(theta_rad));
    s = r / R;

    integrand = (1 ./ (K - u/u_m) - 1 ./ (K + u/u_m));
    DeltaT = (2 * R / (u_m * sin(theta_rad) * cos(theta_rad))) * trapz(s, integrand);
    v_L = (DeltaT * c^2 * sin(theta_rad)) / (4 * max(r) * cos(theta_rad));
    v_S = trapz(r, v_L .* r) * 2 / R^2;
end

function [v_S, DeltaT] = calculate_v_S(factor, u_m, D, nu, N, flow_type, c, theta, beta)
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
            u = factor * u_m * (1 - s).^(1/n) - beta * (1 - s) .* r;
    end

    [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta);
end

function error = fit_correction_factor(factor, u_m, v_S_target, D, nu, N, flow_type, c, theta, beta)
    [v_S_calc, ~] = calculate_v_S(factor, u_m, D, nu, N, flow_type, c, theta, beta);
    error = v_S_calc - v_S_target;
end

%% 主程序
% 标定数据拟合
u_m_laminar = (2000 * nu) / D;  v_S_target_laminar = 0.062;
u_m_turbulent = (4000 * nu) / D; v_S_target_turbulent = 0.124;
u_m_turbulent1=(11800*nu)/D;v_S_target_turbulent1=0.374;
% 层流修正因子 a（注意：层流不传beta参数）
a = fzero(@(a) fit_correction_factor(a, u_m_laminar, v_S_target_laminar, D, nu, N, 'laminar', c, theta, 0), 1.0);
% 湍流修正因子 b
b = fzero(@(b) fit_correction_factor(b, u_m_turbulent, v_S_target_turbulent, D, nu, N, 'turbulent', c, theta, beta), 1.0);
fprintf('修正因子:\na (层流) = %.6f\nb (湍流) = %.6f\n', a, b);

%% 剩余可视化代码（保持原样）...


%% 可视化改进后的湍流速度分布（示例）
figure;
Re_target_turbulent = 5300;
u_m_target = (Re_target_turbulent * nu) / D;

% 计算原始和改进后的速度分布
[r, u_original, u_improved] = calculate_improved_profile(b, u_m_target, D, nu, N, beta);

% 绘制对比
plot(r/R, u_original, 'b-', 'LineWidth', 2, 'DisplayName', '原始幂律分布');
hold on;
plot(r/R, u_improved, 'r--', 'LineWidth', 2, 'DisplayName', '改进分布');
xlabel('归一化径向位置 r/R');
ylabel('线速度 u(r) (m/s)');
title(sprintf('湍流速度分布对比 (Re=%d, β=%.2f)', Re_target_turbulent, beta));
grid on;
legend('Location','best');

%% 改进速度分布计算函数
function [r, u_original, u_improved] = calculate_improved_profile(factor, u_m, D, nu, N, beta)
    R = D / 2;
    r = linspace(0, R, N);
    s = r / R;

    % 计算湍流参数
    Re = (u_m * D) / nu;
    Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
    n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
    n = interp1(Re_table, n_table, Re, 'linear', 'extrap');

    % 原始幂律分布
    u_original = factor * u_m * (1 - s).^(1/n);

    % 改进分布
    u_improved = u_original - beta * (1 - s) ;
end


% clc; clear; close all;
% 
% %% 固定参数
% D = 0.04;            % 管道内径 (m)
% R = D / 2;           % 管道半径 (m)
% nu = 1.007e-6;       % 水的运动粘度 (m²/s)
% c = 1482;            % 声速 (m/s)
% theta = 45;          % 超声波传播角度 (度)
% N = 1000;            % 径向离散点数
% 
% %% 实验数据 (Re=11800工况)
% Re_exp = 11800;          % 实验雷诺数
% v_exp = 0.374;            % 实验线速度 (m/s)
% Q_exp = mean([1.694, 1.692, 1.691, 1.692]);  % 平均流量 (m³/h)
% v_S_target = Q_exp / (pi*R^2*3600);          % 换算面平均速度 (m/s)
% 
% %% 初始化湍流修正参数
% % 初始猜测值 [b, beta]
% x0 = [1.0, 0.1];  
% 
% %% 最小二乘法标定双参数
% options = optimset('Display','iter', 'TolX',1e-6);
% x_opt = lsqnonlin(@(x) turb_correction_error(x, Re_exp, v_S_target, D, nu, N, c, theta),...
%                  x0, [0.5, 0], [2.0, 1.0], options);
% 
% b_opt = x_opt(1);
% beta_opt = x_opt(2);
% fprintf('最优参数:\nb = %.6f\nβ = %.6f\n', b_opt, beta_opt);
% 
% %% 验证标定结果
% [u_r, r] = calculate_turbulent_profile(b_opt, beta_opt, Re_exp, D, nu, N);
% v_S_calc = trapz(r, u_r.*r) * 2 / R^2;
% Q_calc = v_S_calc * pi * R^2 * 3600;
% 
% fprintf('验证结果:\n实验Q=%.3f m³/h, 计算Q=%.3f m³/h, 误差=%.2f%%\n',...
%         Q_exp, Q_calc, abs(Q_calc-Q_exp)/Q_exp*100);
% 
% %% 可视化速度分布
% figure;
% plot(r/R, u_r, 'LineWidth',2);
% xlabel('归一化径向位置 r/R'); 
% ylabel('速度 u(r) (m/s)');
% title(sprintf('Re=%d: b=%.3f, β=%.3f', Re_exp, b_opt, beta_opt));
% grid on;
% 
% %% 支持函数
% function error = turb_correction_error(x, Re, v_S_target, D, nu, N, c, theta)
%     % 计算湍流模型误差
%     b = x(1);
%     beta = x(2);
% 
%     % 获取速度分布
%     [u_r, r] = calculate_turbulent_profile(b, beta, Re, D, nu, N);
% 
%     % 计算面平均速度
%     R = D/2;
%     v_S_calc = trapz(r, u_r.*r) * 2 / R^2;
% 
%     % 返回误差
%     error = v_S_calc - v_S_target;
% end
% 
% function [u_r, r] = calculate_turbulent_profile(b, beta, Re, D, nu, N)
%     % 计算带修正的湍流速度分布
%     R = D/2;
%     r = linspace(0, R, N);
%     s = r/R;
%     u_m = Re * nu / D;  % 平均流速
% 
%     % 查表获取n值
%     Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
%     n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
%     n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
% 
%     % 改进的速度分布公式
%     u_r = b * u_m * (1 - s).^(1/n) - beta * (1 - s) .* r;
% end
