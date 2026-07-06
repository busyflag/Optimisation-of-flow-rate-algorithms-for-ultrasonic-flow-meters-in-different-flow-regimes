%% 超声波流量计测量校正仿真程序
% 参考文献：Effects of Velocity Profiles on Measuring Accuracy of Transit-Time Ultrasonic Flowmeter

clc; clear;

%% 参数设置
R = 0.0254;        % 管道半径 (m) - 对应论文实验中的50.8mm内径
c = 1482;          % 水中声速 (m/s) @20℃
theta = 45;        % 超声波传播角度 (度)
nu = 1.007e-6;     % 水的运动粘度 (m²/s) @20℃
rho = 1000;        % 水密度 (kg/m³)

%% 流动状态参数
flow_type = 'turbulent';  % 'laminar' 或 'turbulent'
u_m = 2.0;                % 平均流速 (m/s)

%% 雷诺数计算
Re = (2 * rho * u_m * R) / nu;
fprintf('雷诺数 Re = %.2e\n', Re);

%% 获取湍流指数n（论文表1数据）
Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
n = interp1(Re_table, n_table, Re, 'linear', 'extrap');

%% 计算传播时间差ΔT和流量Q
theta_rad = deg2rad(theta);
L = 2*R / sin(theta_rad);  % 超声波传播路径长度

switch flow_type
    case 'laminar'
        % 层流：抛物线速度分布
        DeltaT = (8 * R * u_m * cos(theta_rad)) / (3 * c^2 * sin(theta_rad));
        Q0 = pi * R^2 * u_m;           % 未校正流量
        Q = 0.75 * Q0;                 % 应用层流校正因子0.75
        
    case 'turbulent'
        % 湍流：指数速度分布
        DeltaT = (n/(n+1)) * (4 * R * u_m * cos(theta_rad)) / (c^2 * sin(theta_rad));
        Q0 = pi * R^2 * u_m;           % 未校正流量
        k_t = 2*n/(2*n + 1);           % 湍流校正因子
        Q = k_t * Q0;                  % 应用湍流校正
        
    otherwise
        error('未知流动类型');
end

%% 显示结果
fprintf('=== %s流动仿真结果 ===\n', flow_type);
fprintf('传播时间差 ΔT = %.3e s\n', DeltaT);
fprintf('未校正流量 Q0 = %.4f m³/s\n', Q0);
fprintf('校正后流量 Q  = %.4f m³/s\n', Q);
fprintf('校正因子 k   = %.4f\n', Q/Q0);

%% 流速分布可视化
s = linspace(0, 1, 100);  % 归一化半径 s = r/R

figure;
switch flow_type
    case 'laminar'
        u = u_m * (1 - s.^2);  % 抛物线分布
        title('层流速度分布 (抛物线)');
        
    case 'turbulent'
        u = u_m * (1 - s).^(1/n);  % 指数分布
        title(sprintf('湍流速度分布 (n=%.1f)', n));
end

plot(u, s, 'LineWidth', 1.5);
xlabel('流速 u(m/s)');
ylabel('归一化半径 r/R');
grid on;
set(gca, 'YDir', 'reverse');