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

%% 标定数据拟合 a 和 b
% u_m_laminar = (2000 * nu) / D;
u_m_laminar = (2000 * nu) / D;  v_S_target_laminar = 0.062;
u_m_turbulent = (4000 * nu) / D; v_S_target_turbulent = 0.124;

% 层流修正因子 a
a = fzero(@(a) fit_correction_factor(a, u_m_laminar, v_S_target_laminar, D, nu, N, 'laminar', c, theta), 1.0);
% 湍流修正因子 b
b = fzero(@(b) fit_correction_factor(b, u_m_turbulent, v_S_target_turbulent, D, nu, N, 'turbulent', c, theta), 1.0);
fprintf('修正因子:\na (层流) = %.6f\nb (湍流) = %.6f\n', a, b);

%% 验证拟合结果
% 层流验证
[v_S_calc_laminar, ~] = calculate_v_S(a, u_m_laminar, D, nu, N, 'laminar', c, theta);
fprintf('层流验证:\n目标 v_S = %.6f, 计算 v_S = %.6f, 误差 = %.6f\n', ...
    v_S_target_laminar, v_S_calc_laminar, abs(v_S_target_laminar - v_S_calc_laminar));

% 湍流验证
[v_S_calc_turbulent, ~] = calculate_v_S(b, u_m_turbulent, D, nu, N, 'turbulent', c, theta);
fprintf('湍流验证:\n目标 v_S = %.6f, 计算 v_S = %.6f, 误差 = %.6f\n', ...
    v_S_target_turbulent, v_S_calc_turbulent, abs(v_S_target_turbulent - v_S_calc_turbulent));

%% 生成不同 u_m 的雷诺数范围
u_m_values = logspace(log10(0.01), log10(2), 50); % 0.01~2 m/s（对数均匀分布）
Re_values = (u_m_values * D) / nu;               % 对应雷诺数

%% 预计算 v_S 和 Q
v_S = zeros(size(u_m_values));
Q = zeros(size(u_m_values));
flow_types = cell(size(u_m_values));

for i = 1:length(u_m_values)
    Re = Re_values(i);
    u_m = u_m_values(i);
    
    % 判断流动状态
    if Re <= 2000
        flow_types{i} = 'laminar';
        [v_S(i), ~] = calculate_v_S(a, u_m, D, nu, N, 'laminar', c, theta);
    elseif Re >= 4000
        flow_types{i} = 'turbulent';
        [v_S(i), ~] = calculate_v_S(b, u_m, D, nu, N, 'turbulent', c, theta);
    else
        flow_types{i} = 'transition';
        % 过渡流：层流和湍流混合
        [v_S_laminar, ~] = calculate_v_S(a, u_m, D, nu, N, 'laminar', c, theta);
        [v_S_turbulent, ~] = calculate_v_S(b, u_m, D, nu, N, 'turbulent', c, theta);
        weight = (Re - 2000) / (4000 - 2000);
        v_S(i) = (1 - weight) * v_S_laminar + weight * v_S_turbulent;
    end
    
    % 计算流量 (m³/h)
    Q(i) = pi * R^2 * v_S(i) * 3600;
end

%% 可视化结果
figure;

% 图1: v_S 随 Re 变化
subplot(2, 1, 1);
semilogx(Re_values, v_S, 'LineWidth', 2);
hold on;
xline(2000, '--r', '层流界限 (Re=2000)');
xline(4000, '--r', '湍流界限 (Re=4000)');
xlabel('雷诺数 Re');
ylabel('面平均流速 v_S (m/s)');
title('面平均流速 vs 雷诺数（时差法计算）');
grid on;

% 标定数据点标注
scatter((u_m_laminar * D)/nu, v_S_target_laminar, 100, 'ro', 'filled', 'DisplayName', '层流标定点');
scatter((u_m_turbulent * D)/nu, v_S_target_turbulent, 100, 'bo', 'filled', 'DisplayName', '湍流标定点');
legend;

% 图2: 流量 Q 随 Re 变化
subplot(2, 1, 2);
semilogx(Re_values, Q, 'LineWidth', 2);
hold on;
xline(2000, '--r', '层流界限 (Re=2000)');
xline(4000, '--r', '湍流界限 (Re=4000)');
xlabel('雷诺数 Re');
ylabel('流量 Q (m³/h)');
title('流量 vs 雷诺数');
grid on;
%% 打印高雷诺数数据（湍流区）
fprintf('\n高雷诺数湍流区数据:\n');
fprintf('%-10s %-15s %-15s\n', 'Re', 'v_S (m/s)', 'Q (m³/h)'); 

% 定义需要计算的雷诺数
Re_high = [4200,4400,4600,4800,5000,5200,5400,5600,5800,6000,6200,6400,6600,6800,7000,7200,7400,7600,7800,8000, 8200,8400,8600,8800,9000,9200,9400,9600,9800,10000,10200,10400,10600,10800,11000,11200,11400,11600,11800,12000,12200,12400,12600,12800,13000,13200,13400,13600,13800,14000,14200,14400,14600,14800,15000,15200,15400,15600,15800,16000,16200,16400,16600,16800,17000,17200,17400,17600,17800,18000,18200,18400,18600,18800,19000,19200,19400, 19600, 19800, 20000];

for Re = Re_high
    u_m = (Re * nu) / D; % 根据雷诺数计算 u_m
    
    % 使用湍流模型计算
    [v_S, ~] = calculate_v_S(b, u_m, D, nu, N, 'turbulent', c, theta);
    Q = pi * R^2 * v_S * 3600;
    
    % 打印结果
    fprintf('%-10d %-15.6f %-15.6f\n', Re, v_S, Q);
end

%% 打印过渡区数据（Re=2000~4000，间隔200）
fprintf('\n过渡区数据（Re=2000~4000，间隔200）:\n');
fprintf('%-10s %-15s %-15s\n', 'Re', 'v_S (m/s)', 'Q (m³/h)'); 

% 生成过渡区雷诺数
Re_transition = 2000:200:4000;

for Re = Re_transition
    u_m = (Re * nu) / D; % 根据雷诺数计算 u_m
    
    % 判断流动状态（强制设为过渡流，加权计算）
    [v_S_laminar, ~] = calculate_v_S(a, u_m, D, nu, N, 'laminar', c, theta);
    [v_S_turbulent, ~] = calculate_v_S(b, u_m, D, nu, N, 'turbulent', c, theta);
    weight = (Re - 2000) / (4000 - 2000);
    v_S = (1 - weight) * v_S_laminar + weight * v_S_turbulent;
    Q = pi * R^2 * v_S * 3600;
    
    % 打印结果
    fprintf('%-10d %-15.6f %-15.6f\n', Re, v_S, Q);
end
%% 可视化 r/R 与 u(r) 的关系（雷诺数2000）
figure;

% 设置雷诺数 Re=2000（层流临界）
Re_target = 2000;
u_m_target = (Re_target * nu) / D;  % 计算对应 u_m

% 使用层流模型计算 u(r)
r = linspace(0, R, N);  % 径向位置 (m)
s = r / R;              % 归一化径向位置 r/R
u = a * u_m_target * (1 - s.^2); % 层流速度分布

% 绘制速度分布
plot(s, u, 'LineWidth', 2, 'Color', 'b');
hold on;

% 标定数据点（如果需要的话，可添加实验点）
% scatter(s_exp, u_exp, 'ro', 'filled');

% 格式化和标注
xlabel('归一化径向位置 r/R');
ylabel('线速度 u(r) (m/s)');
title(sprintf('层流速度分布 (Re=%d, D=%.2f m)', Re_target, D));
grid on;
xlim([0 1]);
%% 可视化 r/R 与 u(r) 的关系（雷诺数4000，湍流）
figure;

% 设置雷诺数 Re=4000（湍流临界）
Re_target_turbulent = 4000;
u_m_target_turbulent = (Re_target_turbulent * nu) / D;  % 计算对应 u_m

% 使用湍流模型计算 u(r)
r_turbulent = linspace(0, R, N);  % 径向位置 (m)
s_turbulent = r_turbulent / R;    % 归一化径向位置 r/R

% 计算湍流速度分布（调用您的 calculate_velocity_profile 或直接计算）
if exist('calculate_velocity_profile', 'file')
    % 如果之前已定义 calculate_velocity_profile 函数
    [~, u_turbulent] = calculate_velocity_profile(b, u_m_target_turbulent, D, nu, N, 'turbulent', c, theta);
else
    % 直接复用原代码的湍流计算公式
    Re = (u_m_target_turbulent * D) / nu;
    Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
    n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
    n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
    % n = 1.85*log10(Re) - 1.7;
    % n = 1.66*log10(Re) ;
    u_turbulent = b * u_m_target_turbulent * (1 - s_turbulent).^(1/n);
end

% 绘制湍流速度分布
plot(s_turbulent, u_turbulent, 'LineWidth', 2, 'Color', 'r');
hold on;

% 标记湍流核心区最大速度点（可选）
% [umax, idx_max] = max(u_turbulent);
% scatter(s_turbulent(idx_max), umax, 100, 'ro', 'filled', 'DisplayName', sprintf('u_{max}=%.3f m/s', umax));

% 格式化和标注
xlabel('归一化径向位置 r/R');
ylabel('线速度 u(r) (m/s)');
title(sprintf('湍流速度分布 (Re=%d, D=%.2f m)', Re_target_turbulent, D));
grid on;
xlim([0 1]);
legend('速度分布', 'u_{max}', 'Location', 'northeast');

%% 支持函数
function error = fit_correction_factor(factor, u_m, v_S_target, D, nu, N, flow_type, c, theta)
    % 计算给定修正因子下的 v_S 与标定值的误差
    [v_S_calc, ~] = calculate_v_S(factor, u_m, D, nu, N, flow_type, c, theta);
    error = v_S_calc - v_S_target;
end

function [v_S, DeltaT] = calculate_v_S(factor, u_m, D, nu, N, flow_type, c, theta)
    % 使用时差法计算面平均速度 v_S
    R = D / 2;
    r = linspace(0, R, N);
    s = r / R;
    
    % 生成速度分布
    switch flow_type
        case 'laminar'
            u = factor * u_m * (1 - s.^2);
        case 'turbulent'
            Re = (u_m * D) / nu;
            Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
            n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
            n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
            %  n = 1.66*log10(Re) ;
             n = 1.85*log10(Re) - 1.7;
            u = factor * u_m * (1 - s).^(1/n);
    end
    
    % 调用时差法计算函数
    [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta);
end

function [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta)
    % 时差法计算面平均速度 v_S
    R = max(r);
    theta_rad = deg2rad(theta);
    
    % 计算常数 K
    K = c / (u_m * cos(theta_rad));
    
    % 归一化半径
    s = r / R;
    
    % 计算积分项
    integrand = (1 ./ (K - u/u_m) - 1 ./ (K + u/u_m));
    
    % 计算时差 DeltaT
    DeltaT = (2 * R / (u_m * sin(theta_rad) * cos(theta_rad))) * trapz(s, integrand);
    
    % 计算线平均流速 v_L
    v_L = (DeltaT * c^2 * sin(theta_rad)) / (4 * max(r) *cos(theta_rad));
    
    % 计算面平均速度 v_S
    v_S = trapz(r, v_L .* r) * 2 / R^2;
    % v_S=2*pi*v_L*max(r)*max(r);
end
%% 添加标准化速度分布图（u/um vs r/R）
figure('Position', [100 100 800 600]);

% 定义典型雷诺数案例
cases = [ 
    struct('Re', 2000,  'type', 'laminar', 'color', 'b', 'name', '层流 (Re=2000)');
    struct('Re', 4000,  'type', 'turbulent', 'color', 'r', 'name', '湍流临界 (Re=4000)');
    struct('Re', 11800, 'type', 'turbulent', 'color', [0.8 0.2 0], 'name', '湍流发展 (Re=11800)');
    struct('Re', 50000, 'type', 'turbulent', 'color', [0.5 0 0.5], 'name', '完全湍流 (Re=50000)')
];

% 绘制各工况速度分布
hold on;
for k = 1:length(cases)
    case_data = cases(k);
    u_m = (case_data.Re * nu) / D;
    r = linspace(0, R, 1000);
    s = r/R;
    
    % 计算速度分布
    if strcmp(case_data.type, 'laminar')
        u = a * u_m * (1 - s.^2); % 层流解析解
    else
        Re = case_data.Re;
        n = 1.85*log10(Re) - 1.7; % Churchill湍流公式
        u = b * u_m * (1 - s).^(1/n); % 湍流分布
    end
    
    % 绘制标准化速度
    plot(s, u/u_m, 'Color', case_data.color, 'LineWidth', 2.5,...
         'DisplayName', case_data.name);
end

% 添加理论参考线
plot([0 1], [1 1], 'k--', 'LineWidth', 1, 'DisplayName', '核心区参考');
plot(1, 0, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', '壁面边界条件');

% 图形美化
xlabel('归一化径向位置 r/R', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('标准化速度 u/u_m', 'FontSize', 12, 'FontWeight', 'bold');
title('不同雷诺数下的标准化速度分布', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10);
grid on;
axis([0 1 0 1.2]);
set(gca, 'FontSize', 11, 'LineWidth', 1.5);

% 添加流动状态标注
text(0.15, 0.45, '层流抛物线分布', 'Color', 'b', 'FontSize', 12);
text(0.6, 0.85, '湍流核心区', 'Color', 'r', 'FontSize', 12);
text(0.05, 1.1, '速度峰值', 'Color', [0.5 0 0.5], 'FontSize', 10);


%% 添加过渡流速度分布可视化（Re=3000）
figure('Position', [100 100 900 500]);
hold on;

% 定义比较案例：层流(Re=2000)、过渡流(Re=3000)、湍流(Re=4000)
cases = [
    struct('Re', 2000, 'type', 'laminar', 'color', 'b', 'style', '-', 'name', '层流 Re=2000');
    struct('Re', 3000, 'type', 'transition', 'color', [0 0.7 0], 'style', '--', 'name', '过渡流 Re=3000');
    struct('Re', 4000, 'type', 'turbulent', 'color', 'r', 'style', ':', 'name', '湍流 Re=4000')
];

% 计算各工况速度分布
for k = 1:length(cases)
    case_data = cases(k);
    Re = case_data.Re;
    u_m = (Re * nu) / D;
    r = linspace(0, R, 1000);
    s = r/R;
    
    % 速度分布计算
    if strcmp(case_data.type, 'laminar')
        u = a * u_m * (1 - s.^2);  % 层流精确解
    elseif strcmp(case_data.type, 'turbulent')
        n = 1.85*log10(Re) - 1.7;  % Churchill公式
        
        u = b * u_m * (1 - s).^(1/n); % 湍流分布
    else % 过渡流
        % 加权混合层流和湍流分布
        [u_laminar, ~] = calculate_v_S(a, u_m, D, nu, N, 'laminar', c, theta);
        [u_turbulent, ~] = calculate_v_S(b, u_m, D, nu, N, 'turbulent', c, theta);
        weight = (Re - 2000) / (4000 - 2000);
        n = 1.85*log10(Re) - 1.7;
        u = (1-weight)*a*u_m*(1-s.^2) + weight*b*u_m*(1-s).^(1/n);
    end
    
    % 绘制速度剖面
    plot(s, u/u_m, 'LineWidth', 3, 'LineStyle', case_data.style, ...
        'Color', case_data.color, 'DisplayName', case_data.name);
end

% 标注关键特征
% text(0.2, 0.25, '层流区', 'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
% text(0.5, 0.65, '过渡区', 'Color', [0 0.7 0], 'FontSize', 12, 'FontWeight', 'bold');
% text(0.7, 0.85, '湍流区', 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
% plot(0.82, 1.03, '^', 'Color', [0.5 0 0.5], 'MarkerSize', 10, 'MarkerFaceColor', [0.5 0 0.5]);
% text(0.84, 1.05, '速度峰值', 'Color', [0.5 0 0.5], 'FontSize', 10);

% 图形美化
xlabel('归一化径向位置 r/R', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('标准化速度 u/u_m', 'FontSize', 12, 'FontWeight', 'bold');
title('过渡流速度分布特性 (Re=3000)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11, 'LineWidth', 1.5);
axis([0 1 0 1.2]);

%% 过渡流速度分布可视化 (Re=3000) - 严格统一风格版本
figure('Position', [100 100 800 500]);
hold on;

% 设置参数（与湍流案例完全相同的变量名格式）
Re_target_transition = 3000;
u_m_target_transition = (Re_target_transition * nu) / D;
r_transition = linspace(0, R, N);
s_transition = r_transition / R;

% 计算过渡流速度（保持湍流案例的计算结构）
if exist('calculate_velocity_profile', 'file')
    [~, u_transition] = calculate_velocity_profile(b, u_m_target_transition, D, nu, N, 'transition', c, theta);
else
    % 过渡流特有的混合模型计算
    Re = Re_target_transition;
    Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
    n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
    n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
    u_laminar = a * u_m_target_transition * (1 - s_transition.^2);
    % n = 1.85*log10(Re) - 1.7;
    u_turb = b * u_m_target_transition * (1 - s_transition).^(1/n);
    weight = (Re - 2000) / (4000 - 2000);
    u_transition = (1-weight)*u_laminar + weight*u_turb;
end

% 绘图（完全匹配湍流案例的绘图参数）
plot(s_transition, u_transition, 'LineWidth', 2, 'Color', 'g');

% 标记最大速度点（与湍流案例相同格式）
% [umax, idx_max] = max(u_transition);
% scatter(s_transition(idx_max), umax, 100, 'go', 'filled',...
%     'DisplayName', sprintf('u_{max}=%.3f m/s', umax));

% 完全一致的格式化和标注
xlabel('归一化径向位置 r/R');
ylabel('线速度 u(r) (m/s)');
title(sprintf('过渡流速度分布 (Re=%d, D=%.2f m)', Re_target_transition, D));
grid on;
xlim([0 1]);
legend('速度分布', 'u_{max}', 'Location', 'northeast');
set(gca, 'FontSize', 11, 'LineWidth', 1.5); % 相同的坐标轴样式
