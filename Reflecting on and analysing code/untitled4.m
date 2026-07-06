%% 超声波流量计修正因子仿真程序
% 作者：Hui Zhang等（根据论文内容编写）
% 功能：模拟层流与湍流下的流量测量，应用修正因子优化精度

clc;
clear;
close all;

%% 参数设置
R = 0.007;          % 管道半径 (m) [示例值]
u_m = 1.0;          % 平均流速 (m/s)
c = 1480;           % 声速 (水中的声速, m/s)
theta = 45;         % 超声波传播角度 (度)
theta_rad = deg2rad(theta);
Re = 10000;         % 雷诺数（湍流时需根据Re选择n）

%% 层流仿真
disp('===== 层流仿真 =====');
% 理论修正因子
k_laminar = 0.75;

% 理论真实流量
Q_true_laminar = pi * R^2 * u_m / 2; % 层流流量公式 Q = πR²(u_m/2)

% 未修正的超声波测量流量 (根据论文式18)
L = 2*R / sin(theta_rad);
DeltaT_unadjusted = (4 * R * u_m * cos(theta_rad)) / (c^2 * sin(theta_rad));
Q0_laminar = (pi * R * c^2 * tan(theta_rad) / 4) * DeltaT_unadjusted;

% 修正后流量
Q_corrected_laminar = k_laminar * Q0_laminar;

% 显示结果
fprintf('理论真实流量: %.6f m³/s\n', Q_true_laminar);
fprintf('未修正测量值: %.6f m³/s (误差: %.2f%%)\n', Q0_laminar, 100*(Q0_laminar/Q_true_laminar-1));
fprintf('修正后测量值: %.6f m³/s (误差: %.2f%%)\n\n', Q_corrected_laminar, 100*(Q_corrected_laminar/Q_true_laminar-1));

%% 湍流仿真
disp('===== 湍流仿真 =====');
% 根据雷诺数Re选择n值（论文表1数据）
Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
n = interp1(Re_table, n_table, Re, 'linear', 'extrap'); % 线性插值

% 理论修正因子
k_turbulent = 2*n / (2*n + 1);

% 理论真实流量
Q_true_turbulent = pi * R^2 * u_m; % 湍流流量公式 Q = πR²u_m

% 数值积分计算DeltaT（论文式21）
s = linspace(0, 1, 1000); % 无量纲半径
integrand = (1 - s).^(1/n);
integral_value = trapz(s, integrand);
DeltaT_turbulent = (n / (n + 1)) * (4 * R * u_m * cos(theta_rad)) / (c^2 * sin(theta_rad));

% 未修正的超声波测量流量 (论文式25)
Q0_turbulent = (pi * R * c^2 * tan(theta_rad) / 4) * DeltaT_turbulent;

% 修正后流量
Q_corrected_turbulent = k_turbulent * Q0_turbulent;

% 显示结果
fprintf('雷诺数Re: %.1f\n', Re);
fprintf('幂律指数n: %.2f\n', n);
fprintf('理论真实流量: %.6f m³/s\n', Q_true_turbulent);
fprintf('未修正测量值: %.6f m³/s (误差: %.2f%%)\n', Q0_turbulent, 100*(Q0_turbulent/Q_true_turbulent-1));
fprintf('修正后测量值: %.6f m³/s (误差: %.2f%%)\n\n', Q_corrected_turbulent, 100*(Q_corrected_turbulent/Q_true_turbulent-1));

%% 速度分布可视化
figure;
r = linspace(0, R, 100);

% 层流速度分布
u_laminar = u_m * (1 - (r/R).^2);
subplot(1,2,1);
plot(u_laminar, r, 'b', 'LineWidth', 1.5);
title('层流速度分布');
xlabel('流速 u(m/s)');
ylabel('径向位置 r(m)');
grid on;

% 湍流速度分布
u_turbulent = u_m * (1 - r/R).^(1/n);
subplot(1,2,2);
plot(u_turbulent, r, 'r', 'LineWidth', 1.5);
title('湍流速度分布');
xlabel('流速 u(m/s)');
ylabel('径向位置 r(m)');
grid on;

%% 误差对比图
figure;
error_unadjusted = [100*(Q0_laminar/Q_true_laminar-1), 100*(Q0_turbulent/Q_true_turbulent-1)];
error_corrected = [100*(Q_corrected_laminar/Q_true_laminar-1), 100*(Q_corrected_turbulent/Q_true_turbulent-1)];
bar([error_unadjusted; error_corrected]');
legend('未修正误差', '修正后误差', 'Location', 'northoutside');
set(gca, 'XTickLabel', {'层流', '湍流'});
ylabel('相对误差 (%)');
title('修正因子应用效果对比');
ylim([-2, 2]);
grid on;