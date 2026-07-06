clc;
clear;
close all;

%% 参数设置
D = 0.014;            % 管道内径 (m)
R = D/2;             % 管道半径 (m)
c = 1482;            % 声速 (m/s)
theta = 45;          % 超声波传播角度 (度)
theta_rad = deg2rad(theta);
nu = 1.007e-6;       % 水的运动粘度 (m²/s)
rho = 1000;          % 水密度 (kg/m³)
u_m = 0.25;           % 平均流速 (m/s)
N = 100000;            % 径向离散点数
% 实验数据：雷诺数和对应的流量
Re_data = [2000, 2200, 2400, 2600, 2800, 3000, 3200, 3400, 3600, 3800, 4000];  % 雷诺数
Q_data = [0.28, 0.309, 0.337, 0.366, 0.392, 0.42, 0.449, 0.478, 0.503, 0.534, 0.562];  % 流量 (m³/h)
p2 = polyfit(Re_data, Q_data, 2);  % 2表示二次拟合

% 显示拟合结果
fprintf('二次拟合结果: Q = %.4f * Re^2 + %.4f * Re + %.4f\n', p2(1), p2(2), p2(3));

function [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta, N)
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

%% 计算雷诺数和流动状态
Re = (u_m * D) / nu;
if Re <= 2000
    flow_type = 'laminar';
elseif Re >= 4000
    flow_type = 'turbulent';
else
    flow_type = 'transition';  % 过渡流状态
end
fprintf('雷诺数 Re = %.2e, 流动状态: %s\n', Re, flow_type);

%% 生成速度分布模型
r = linspace(0, R, N);       % 径向坐标
s = r / R;                   % 归一化半径
dr = R / (N-1);              % 微元厚度

% 计算分段线性过渡流速度
switch flow_type
    case 'laminar'
        % 层流：抛物线分布 (u = 2u_m(1 - (r/R)^2))
        u =  2*u_m * (1 - s.^2);
        
    case 'turbulent'
        % 湍流：指数分布 (u = u_m(1 - r/R)^(1/n))
        Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
        n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
        n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
        u = u_m * (1 - s).^(1/n);
        
    case 'transition'
        % 过渡流：分段线性模型
        % 假设在过渡流中，我们线性插值进行校正
             Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
        n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
        n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
        u_laminar = 2*u_m * (1 - s.^2);  % 层流速度分布
        u_turbulent = u_m * (1 - s).^(1/n); % 湍流速度分布
        u = (Re - 2000) / (4000 - 2000) * (u_turbulent - u_laminar) + u_laminar; % 线性插值
end

%% 过渡函数法：根据过渡函数计算流速
% 采用双曲正切过渡函数平滑层流到湍流的过渡
Re_c = 2000; % 层流临界雷诺数
Re_t = 4000; % 湍流临界雷诺数
alpha = 50;  % 过渡函数的控制参数

% 过渡函数：f(Re)
f_Re = (Re - 2000) / (4000 - 2000);
% f_Re=1/(1+exp(Re/alpha-Re_t/alpha));
% f_Re = 0.5 * (1 + tanh(alpha * (Re - Re_c) / (Re_t - Re_c)));

% 过渡流速计算：线性插值层流与湍流
u_laminar = u_m * (1 - s.^2);  % 层流速度分布
u_turbulent = u_m * (1 - s).^(1/n); % 湍流速度分布
u_transition = f_Re * u_turbulent + (1 - f_Re) * u_laminar; % 过渡流速

%% 真实流量计算（积分速度分布）
Q_real = 2*pi * trapz(r, u .* r)*3600;  % 积分: Q = ∫(0到R) u(r) * 2πr dr

%% 传统方法：线速度平均 + 校正因子
v_L = mean(u);  % 传统方法假设线速度为路径平均

switch flow_type
    case 'laminar'
        k = 0.75;  % 层流校正因子
    case 'turbulent'
        k = 2 * n / (2 * n + 1);  % 湍流校正因子
    case 'transition'
        k = 1; % 假设过渡流状态下的校正因子为1.0
end
v_S_traditional = k * v_L;

% 计算流量
Q_traditional = pi * R^2 * v_S_traditional*3600;

%% 新方法：积分速度分布直接计算面平均速度
v_S_new = trapz(r, u .* r) * 2 / R^2;  % v_S = (2/R²)∫u(r) r dr
v_S_transition=trapz(r, u_transition .* r) * 2 / R^2;
Q_new = pi * R^2 * v_S_new*3600;
Q_transition=pi * R^2*v_S_transition*3600;

%% 调用时差法函数计算面速度和流量
[v_S_from_deltat, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta, N);
Q_from_deltat=pi * R^2*v_S_from_deltat*3600;
%% 结果对比
fprintf('=== 流量对比 ===\n');
fprintf('真实流量 Q_real = %.4f m³/s\n', Q_real);
fprintf('传统方法 Q_traditional = %.4f (误差 %.2f%%)\n', Q_traditional, 100*(Q_traditional-Q_real)/Q_real);
fprintf('新方法    Q_new        = %.4f (误差 %.2f%%)\n', Q_new, 100*(Q_new-Q_real)/Q_real);
figure

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

%% 可视化
figure;

% 1. 传统方法与新方法的速度分布对比



% 2. 流量对比图
subplot(4,1,2);
bar([Q_real, Q_traditional, Q_new, Q_transition,Q_from_deltat]);
set(gca, 'XTickLabel', {'真实流量', '传统方法', '新方法', '过渡函数法','时差法'}); 
title('流量对比');
ylabel('流量 (m³/s)');

% 3. 面速度对比
subplot(4,1,3);
bar([v_S_traditional, v_S_new, v_S_transition,v_S_from_deltat]);
set(gca, 'XTickLabel', {'传统方法', '新方法', '过渡函数法','时差法'}); 
title('面速度对比');
ylabel('面速度 (m/s)');

% 4. 新旧方法的流速对比
subplot(4,1,4);
plot(r, u, 'b', 'LineWidth', 1.5);
hold on;
plot(r, u_laminar, 'r--', 'LineWidth', 1.5);
plot(r, u_turbulent, 'g--', 'LineWidth', 1.5);
title('新方法 vs 传统方法流速分布');
xlabel('半径 r(m)');
ylabel('流速 u(m/s)');
legend('新方法流速', '层流流速', '湍流流速');
grid on;

% 3. 新旧方法的流速对比
subplot(3,1,3);
plot(r, u, 'b', 'LineWidth', 1.5);
hold on;
plot(r, u_transition, 'b--', 'LineWidth', 1.5);
plot(r, u_laminar, 'r--', 'LineWidth', 1.5);
plot(r, u_turbulent, 'g--', 'LineWidth', 1.5);
title('新方法 vs 传统方法流速分布');
xlabel('半径 r(m)');
ylabel('流速 u(m/s)');
legend('新方法流速', '层流流速', '湍流流速');
grid on;

%% 误差分析
error_traditional = abs(Q_traditional - Q_real) / Q_real * 100;
error_new = abs(Q_new - Q_real) / Q_real * 100;
fprintf('\n=== 误差分析 ===\n');
fprintf('传统方法误差: %.2f%%\n', error_traditional);
fprintf('新方法误差:    %.2f%%\n', error_new);
