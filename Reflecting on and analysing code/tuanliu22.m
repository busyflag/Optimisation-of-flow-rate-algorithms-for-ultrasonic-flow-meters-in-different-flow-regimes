clc; clear; close all;

%% 固定参数
D = 0.04;            % 管道内径 (m)
R = D / 2;           % 管道半径 (m)
nu = 1.007e-6;       % 水的运动粘度 (m²/s)
c = 1482;            % 声速 (m/s)
theta = 45;          % 超声波传播角度 (度)
N = 1000;            % 径向离散点数

%% 湍流标定数据 [Re, v_S_target]
turb_data = [
    4000,  0.124;    % 湍流1
    11800, 0.374     % 湍流2 (实测数据)
];

%% 时差法计算函数
function [v_S, DeltaT] = calc_vS_deltaT(r, u, u_m, c, theta)
    R = max(r);
    theta_rad = deg2rad(theta);
    K = c / (u_m * cos(theta_rad));
    s = r / R;
    integrand = (1 ./ (K - u/u_m) - 1 ./ (K + u/u_m));
    DeltaT = (2 * R / (u_m * sin(theta_rad) * cos(theta_rad))) * trapz(s, integrand);
    v_L = (DeltaT * c^2 * sin(theta_rad)) / (4 * R * cos(theta_rad));
    v_S = trapz(r, v_L .* r) * 2 / R^2;
end

%% 湍流速度模型函数
function [u_profile, n] = turb_velocity(b, beta, Re, D, nu, N)
    R = D/2;
    r = linspace(0, R, N)';
    s = r/R;
    u_m = Re * nu / D;
    
    % 湍流指数n插值
    Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
    n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
    n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
    
    % 改进的速度分布模型
    u_profile = b * u_m * (1 - abs(s)).^(1/n) - beta * (1 - abs(s)) .* r;
end

%% 湍流模型计算接口
function v_S = turb_model(x, Re, D, nu, N, c, theta)
    b = x(1);
    beta = x(2);
    
    % 计算速度分布
    [u_profile, ~] = turb_velocity(b, beta, Re, D, nu, N);
    
    % 计算面平均速度
    u_m = Re * nu / D;
    [v_S, ~] = calc_vS_deltaT(linspace(0,D/2,N)', u_profile, u_m, c, theta);
end

%% 主优化程序
% 初始猜测 [b, beta]
x0 = [1.0, 0.02];  
lb = [0.5, 0];     % 参数下限
ub = [2.0, 0.5];   % 参数上限

% 构造误差函数（仅使用湍流数据）
err_func = @(x) arrayfun(@(i) ...
    turb_model(x, turb_data(i,1), D, nu, N, c, theta) - turb_data(i,2), ...
    1:size(turb_data,1));

options = optimoptions('lsqnonlin', 'Display', 'iter');
x_opt = lsqnonlin(err_func, x0, lb, ub, options);

% 提取最优参数
b_opt = x_opt(1);
beta_opt = x_opt(2);
fprintf('湍流最优参数:\nb = %.6f\nβ = %.6f\n', b_opt, beta_opt);

%% 验证标定结果
fprintf('\n湍流标定验证:\n');
for i = 1:size(turb_data,1)
    Re = turb_data(i,1);
    v_S_calc = turb_model(x_opt, Re, D, nu, N, c, theta);
    err = abs(v_S_calc - turb_data(i,2)) / turb_data(i,2) * 100;
    fprintf('Re=%6d: 目标v_S=%.4f, 计算v_S=%.4f, 误差=%.2f%%\n',...
            Re, turb_data(i,2), v_S_calc, err);
end

%% 可视化速度分布
figure;
hold on;
%% 执行零误差标定
x_opt = precise_optimization(turb_data, D, nu, c, theta);
b = x_opt(1);
beta = x_opt(2);
% 绘制两个湍流工况的速度剖面
colors = ['b', 'r'];
for i = 1:size(turb_data,1)
    Re = turb_data(i,1);
    [u_profile, ~] = turb_velocity(b_opt, beta_opt, Re, D, nu, N);
    r = linspace(0, R, N);
    plot(r/R, u_profile, colors(i), 'LineWidth', 2, ...
        'DisplayName', sprintf('Re=%d', Re));
end

xlabel('归一化径向位置 r/R');
ylabel('速度 u(r) (m/s)');
title(sprintf('湍流速度分布 (b=%.3f, β=%.3f)', b_opt, beta_opt));
grid on;
legend('Location', 'best');
%% 零误差优化引擎
function x_opt = precise_optimization(turb_data, D, nu, c, theta)
    % 双参数精确求解器
    function F = exact_system(x)
        b = x(1); beta = x(2);
        F = zeros(2,1);
        for i = 1:2
            Re = turb_data(i,1);
            v_S_true = turb_data(i,2);
            
            % 精确湍流指数计算
            n = 1.85*log10(Re) - 1.7; % Churchill公式
            
            % 构建非线性方程组
            fun = @(s) b*(1-s).^(1/n) - beta*(1-s).*s*D/(2*nu*Re);
            v_S_model = integral(@(s) 2*s.*fun(s), 0, 1, 'ArrayValued',true) * nu*Re/D;
            
            F(i) = v_S_model - v_S_true;
        end
    end

    options = optimoptions('fsolve', 'FunctionTolerance',1e-16, ...
                         'StepTolerance',1e-16, 'Display','none');
    x_opt = fsolve(@exact_system, [1.2; 0.01], options);
end



%% 验证结果（显示16位小数）
fprintf('精确解:\nb  = %.16f\nβ = %.16f\n\n验证:', b, beta);
for i = 1:size(turb_data,1)
    Re = turb_data(i,1);
    n = 1.85*log10(Re) - 1.7;
    
    % 数值积分计算面平均速度
    fun = @(s) b*(1-s).^(1/n) - beta*(1-s).*s*D/(2*nu*Re);
    v_S_calc = integral(@(s) 2*s.*fun(s), 0, 1, 'ArrayValued',true) * nu*Re/D;
    
    fprintf('\nRe=%d:\n理论值=%.16f\n计算值=%.16f\n差值=%.2e', ...
            Re, turb_data(i,2), v_S_calc, v_S_calc-turb_data(i,2));
end

%% 可视化验证
figure;
s = linspace(0,1,1000);
hold on;

% 绘制两个工况的标准化速度剖面
for i = 1:size(turb_data,1)
    Re = turb_data(i,1);
    n = 1.85*log10(Re) - 1.7;
    u_norm = b*(1-s).^(1/n) - beta*(1-s).*s*D/(2*nu*Re);
    plot(s, u_norm, 'LineWidth',2, 'DisplayName',sprintf('Re=%d',Re));
end

xlabel('s=r/R'); ylabel('u/u_m');
title('标准化湍流速度剖面');
legend('Location','best'); 
grid on;
set(gca,'FontSize',12);

%% 2. 标准化速度分布图（新增）
figure('Name','Standardized Velocity Profile','Position',[100 100 800 500]);
hold on;

% 定义要显示的雷诺数范围
Re_list = [11800, 12000, 19600, 19800, 20000];
colors = lines(length(Re_list)); % 使用不同颜色

for i = 1:length(Re_list)
    Re = Re_list(i);
    u_m = Re * nu / D;
    [u_profile, n] = turb_velocity(b_opt, beta_opt, Re, D, nu, N);
    
    % 标准化处理
    r_norm = linspace(0, 1, N);
    u_norm = u_profile / u_m;
    
    plot(r_norm, u_norm, 'Color',colors(i,:), 'LineWidth',2, ...
        'DisplayName',sprintf('Re=%d, n=%.1f',Re,n));
end

% 图表美化
xlabel('Normalized Radial Position r/R');
ylabel('Normalized Velocity u/u_m');
title('Turbulent Velocity Profiles (Normalized)');
legend('Location','best'); 
grid on;
set(gca,'FontSize',12);

%% 3. 时差法计算与结果输出（新增函数调用）
fprintf('\nTime-Difference Method Results:\n');
fprintf('%-10s %-12s %-12s %-12s\n', 'Re', 'v_S(m/s)', 'Q(m³/h)', 'DeltaT(μs)');

% 定义需要计算的雷诺数范围
Re_ranges = {11800:200:12000, 19600:200:20000}; 

for range = Re_ranges
    for Re = range{1}
        u_m = Re * nu / D;
        [u_profile, ~] = turb_velocity(b_opt, beta_opt, Re, D, nu, N);
        r = linspace(0, R, N);
        
        % 调用时差法计算函数
        [v_S, DeltaT] = calculate_velocity_from_deltat(r, u_profile, u_m, c, theta);
        
        % 计算流量 (m³/h)
        Q = v_S * pi * R^2 * 3600;
        
        % 输出结果
        fprintf('%-10d %-12.6f %-12.6f %-12.4f\n', ...
                Re, v_S, Q, DeltaT*1e6);
    end
end

%% 时差法计算函数（更新版）
function [v_S, DeltaT] = calculate_velocity_from_deltat(r, u, u_m, c, theta)
    R = max(r);
    theta_rad = deg2rad(theta);
    
    % 计算常数 K
    K = c / (u_m * cos(theta_rad));
    
    % 归一化半径
    s = r / R;
    
    % 计算积分项
    integrand = (1 ./ (K - u/u_m) - 1 ./ (K + u/u_m));
    
    % 计算时差 DeltaT (s)
    DeltaT = (2 * R / (u_m * sin(theta_rad) * cos(theta_rad))) * trapz(s, integrand);
    
    % 计算线平均流速 v_L
    v_L = (DeltaT * c^2 * sin(theta_rad)) / (4 * R * cos(theta_rad));
    
    % 计算面平均速度 v_S (m/s)
    v_S = trapz(r, v_L .* r) * 2 / R^2;
end