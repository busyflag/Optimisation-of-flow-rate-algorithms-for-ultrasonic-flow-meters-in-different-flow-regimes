clc;
clear;
close all;

%% 参数设置
D = 0.05;            % 管道内径 (m)
R = D/2;             % 管道半径 (m)
c = 1482;            % 声速 (m/s)
theta = 45;          % 超声波传播角度 (度)
theta_rad = deg2rad(theta);
nu = 1.007e-6;       % 水的运动粘度 (m²/s)
rho = 1000;          % 水密度 (kg/m³)
u_m = 1.5;           % 平均流速 (m/s)
N = 1000;            % 径向离散点数

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

switch flow_type
    case 'laminar'
        % 层流：抛物线分布 (u = 2u_m(1 - (r/R)^2))
        u = 2 * u_m * (1 - s.^2);
        
    case 'turbulent'
        % 湍流：指数分布 (u = u_m(1 - r/R)^(1/n))
        % 根据Re插值获取n（论文表1数据）
        Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
        n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
        n = interp1(Re_table, n_table, Re, 'linear', 'extrap');
        u = u_m * (1 - s).^(1/n);
        
    case 'transition'
        % 过渡流：分段线性模型
        % 假设在过渡流中，我们线性插值进行校正
        % 在过渡流区段内（Re介于2000和4000之间）：
        Re_table_transition = [2000, 4000];
        u_table_transition = [2 * u_m * (1 - (Re_table_transition(1)/D)^2), u_m * (1 - R/D)^(1/n)]; % 可以根据实际情况进行修改
        u = interp1(Re_table_transition, u_table_transition, Re, 'linear', 'extrap');
        
    otherwise
        error('流动状态未实现');
end

%% 真实流量计算（积分速度分布）
Q_real = 2*pi * trapz(r, u .* r);  % 积分: Q = ∫(0到R) u(r) * 2πr dr

%% 传统方法：线速度平均 + 校正因子
% 步骤1：计算线平均速度v_L（假设超声波路径为直径）
v_L = mean(u);  % 传统方法假设线速度为路径平均

% 步骤2：应用校正因子得到面平均速度v_S
switch flow_type
    case 'laminar'
        k = 0.75;  % 层流校正因子
    case 'turbulent'
        k = 2*n / (2*n + 1);  % 湍流校正因子
    case 'transition'
        k = 1.0; % 假设过渡流状态下的校正因子为1.0（可以根据实际情况进行调整）
end
v_S_traditional = k * v_L;

% 步骤3：计算流量
Q_traditional = pi * R^2 * v_S_traditional;

%% 新方法：积分速度分布直接计算面平均速度
% 步骤1：计算每个微元的传播时间差dΔT
% 时差法公式：ΔT = (2R/(u_m sinθ cosθ)) * ∫[1/(K - u/u_m) - 1/(K + u/u_m)] ds
K = c / (u_m * cos(theta_rad));
integrand = (1./(K - u/u_m) - 1./(K + u/u_m));
DeltaT = (2*R/(u_m * sin(theta_rad)*cos(theta_rad))) * trapz(s, integrand);

% 步骤2：根据ΔT计算线平均速度v_L_new（传统方法假设的ΔT） 
% v_L_new = (DeltaT * c^2 * sin(theta_rad)) / (4 * R * cos(theta_rad));

% 步骤3：直接积分速度分布得到面平均速度v_S_new
v_S_new = trapz(r, u .* r) * 2 / R^2;  % v_S = (2/R²)∫u(r) r dr

% 步骤4：计算流量
Q_new = pi * R^2 * v_S_new;

%% 结果对比
fprintf('=== 流量对比 ===\n');
fprintf('真实流量 Q_real = %.4f m³/s\n', Q_real);
fprintf('传统方法 Q_traditional = %.4f (误差 %.2f%%)\n', Q_traditional, 100*(Q_traditional-Q_real)/Q_real);
fprintf('新方法    Q_new        = %.4f (误差 %.2f%%)\n', Q_new, 100*(Q_new-Q_real)/Q_real);

%% 可视化

% 1. 传统方法与新方法的速度分布对比
figure;
subplot(3,1,1);
% 传统方法的速度分布
v_L_traditional = mean(u); % 传统方法的线速度
u_traditional = v_L_traditional * (1 - s.^2); % 近似传统方法速度分布
plot(u_traditional, r, 'r', 'LineWidth', 1.5);
hold on;
% 新方法的速度分布
plot(u, r, 'b', 'LineWidth', 1.5);
title('速度分布对比：传统方法 vs 新方法');
xlabel('流速 u(m/s)');
ylabel('半径 r(m)');
legend('传统方法', '新方法');
grid on;

% 2. 流量对比图
subplot(3,1,2);
bar([Q_real, Q_traditional, Q_new]);
set(gca, 'XTickLabel', {'真实流量', '传统方法', '新方法'}); 
title('流量对比');
ylabel('流量 (m³/s)');

% 3. 新旧方法的流速对比
subplot(3,1,3);
plot(r, u, 'b', 'LineWidth', 1.5);
hold on;
plot(r, u_traditional, 'r--', 'LineWidth', 1.5);
title('新旧方法的流速分布');
xlabel('半径 r(m)');
ylabel('流速 u(m/s)');
legend('新方法', '传统方法');
grid on;

%% 误差分析
error_traditional = abs(Q_traditional - Q_real) / Q_real * 100;
error_new = abs(Q_new - Q_real) / Q_real * 100;
fprintf('\n=== 误差分析 ===\n');
fprintf('传统方法误差: %.2f%%\n', error_traditional);
fprintf('新方法误差:    %.2f%%\n', error_new);
