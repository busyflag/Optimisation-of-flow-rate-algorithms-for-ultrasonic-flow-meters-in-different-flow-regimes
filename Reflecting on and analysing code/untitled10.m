clc;
clear;
close all;

%% 参数设置
D = 0.04;            % 管道内径 (m)
R = D / 2;            % 管道半径 (m)
c = 1482;             % 声速 (m/s)
theta = 45;           % 超声波传播角度 (度)
theta_rad = deg2rad(theta);  % 转换为弧度
nu = 1.007e-6;        % 水的运动粘度 (m²/s)
rho = 1000;           % 水密度 (kg/m³)
u_m = 0.3;            % 平均流速 (m/s)
N = 100000;           % 径向离散点数
Re = (u_m * D) / nu; % 雷诺数计算
%% 标定数据拟合 a 和 b
u_m_laminar = 0.05003;  v_S_target_laminar = 0.062;
u_m_turbulent = 0.1006; v_S_target_turbulent = 0.124;

a = fzero(@(a) fit_correction_factor(a, u_m_laminar, v_S_target_laminar, D, nu, N, 'laminar'), 1.0);
b = fzero(@(b) fit_correction_factor(b, u_m_turbulent, v_S_target_turbulent, D, nu, N, 'turbulent'), 1.0);
fprintf('修正因子:\na (层流) = %.6f\nb (湍流) = %.6f\n', a, b);
% 雷诺数分类
if Re <= 2000
    flow_type = 'laminar';
elseif Re >= 4000
    flow_type = 'turbulent';
else
    flow_type = 'transition';  % 过渡流状态
end
fprintf('雷诺数 Re = %.2e, 流动状态: %s\n', Re, flow_type);

%% 生成径向坐标
r = linspace(0, R, N);       % 径向坐标
s = r / R;                   % 归一化半径
dr = R / (N-1);              % 微元厚度

% 计算速度分布
switch flow_type
    case 'laminar'
        % 层流：抛物线分布 (u = u_m * (1 - (r/R)^2))
        u = a*u_m * (1 - s.^2);
        
    case 'turbulent'
        % 湍流：指数分布 (u = u_m * (1 - r/R)^(1/n))
        Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
        n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
        n = interp1(Re_table, n_table, Re, 'linear', 'extrap');  % 根据雷诺数插值计算 n
        u = b*u_m * (1 - s).^(1/n);  % 湍流速度分布
        
    case 'transition'
        % 过渡流：分段线性模型
        Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
        n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
        n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
        u_laminar = a*u_m * (1 - s.^2);  % 层流速度分布
        u_turbulent =b* u_m * (1 - s).^(1/n); % 湍流速度分布
          u = (Re - 2000) / (4000 - 2000) * (u_turbulent - u_laminar) + u_laminar; % 线性插值
end

%% 计算真实流量（基于速度分布）
Q_real = 2 * pi * trapz(r, u .* r) * 3600;  % 积分计算真实流量：Q = ∫u(r) * 2πr dr (m³/h)

%% 传统方法：面平均流速 + 校正因子
v_L = mean(u);  % 传统方法假设线速度为路径平均

switch flow_type
    case 'laminar'
        k = 0.75;  % 层流校正因子
    case 'turbulent'
        k = 2 * n / (2 * n + 1);  % 湍流校正因子
    case 'transition'
        k = 1; % 过渡流状态下的校正因子为1.0
end
v_S_traditional = k * v_L;

% 计算传统方法下的流量
Q_traditional = pi * R^2 * v_S_traditional * 3600;  % 传统方法流量计算

%% 时差法验证（基于论文公式）
[v_S_from_deltat, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta, N);
Q_from_deltat = pi * R^2 * v_S_from_deltat * 3600;

%% 面速度计算：通过积分流速分布计算
v_S_new = trapz(r, u .* r) * 2 / R^2;  % 面速度：v_S = (2/R²)∫u(r) r dr
Q_new = pi * R^2 * v_S_new * 3600;      % 面速度计算的流量

%% 结果对比
fprintf('=== 流量对比 ===\n');
fprintf('真实流量 Q_real = %.4f m³/h\n', Q_real);
fprintf('传统方法 Q_traditional = %.4f m³/h (误差 %.2f%%)\n', Q_traditional, 100 * (Q_traditional - Q_real) / Q_real);
fprintf('面速度方法 Q_new = %.4f m³/h (误差 %.2f%%)\n', Q_new, 100 * (Q_new - Q_real) / Q_real);
fprintf('时差法计算流量 Q_from_deltat = %.4f m³/h (误差 %.2f%%)\n', Q_from_deltat, 100 * (Q_from_deltat - Q_real) / Q_real);

%% 可视化
figure;

% 1. 面速度对比
subplot(3,1,1);
bar([v_S_traditional, v_S_new, v_S_from_deltat]);
set(gca, 'XTickLabel', {'传统方法', '面速度方法', '时差法与修正因子结合'});
title('面速度对比');
ylabel('面速度 (m/s)');

% 2. 流量对比
subplot(3,1,2);
bar([Q_real, Q_traditional, Q_new, Q_from_deltat]);
set(gca, 'XTickLabel', {'面速度法流量', '传统方法', '面速度方法', '时差法与修正因子结合'});
title('流量对比');
ylabel('流量 (m³/h)');

subplot(3,1,3);
plot(u_laminar, r, 'r', 'LineWidth', 1.5); % 层流速度分布
hold on;
plot(u_turbulent, r, 'g', 'LineWidth', 1.5); % 湍流速度分布
hold on;
plot(u_transition, r, 'b', 'LineWidth', 1.5); % 过渡流速分布
title('速度分布：传统方法 vs 过渡函数法');
xlabel('流速 u(m/s)');
ylabel('半径 r(m)');
legend('层流', '湍流', '过渡流');
grid on;
%% 支持函数
function error = fit_correction_factor(factor, u_m, v_S_target, D, nu, N, flow_type)
    R = D / 2;
    r = linspace(0, R, N);
    s = r / R;
    if strcmp(flow_type, 'laminar')
        u = factor * u_m * (1 - s.^2);
    else
        Re = (u_m * D) / nu;
        Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
        n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
        n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
        u = factor * u_m * (1 - s).^(1/n);
    end
    v_S_calc = trapz(r, u .* r) * 2 / R^2;
    error = v_S_calc - v_S_target;
end
%% 时差法函数实现
function [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta)
    % 计算时差法测量流速
    
    % 输入参数:
    % r - 管道的径向坐标
    % u - 对应的流速分布
    % u_m - 平均流速
    % c - 声速
    % theta - 超声波传播角度
    % N - 离散点数
    
    % 计算常数 K
    K = c / (u_m * cos(deg2rad(theta)));  % 声速与流速的比值，结合角度
    
    % 归一化半径
    s = r / max(r);
    
    % 计算时差法的积分项
    integrand = (1 ./ (K - u / u_m) - 1 ./ (K + u / u_m));  % 积分表达式
    
    % 时差计算
    DeltaT = (2 * max(r) / (u_m * sin(deg2rad(theta)) * cos(deg2rad(theta)))) * trapz(s, integrand);  % 时差
    
    % 面平均流速计算（基于时差法）
    v_L = (DeltaT * c^2 * sin(deg2rad(theta))) / (4 * max(r) * cos(deg2rad(theta)));  % 计算平均流速
    
    % 计算面平均速度（使用时差法计算的流速）
    v_S = trapz(r, v_L .* r) * 2 / max(r)^2;  % 面速度：v_S = (2/R²) ∫u(r) r dr
end
