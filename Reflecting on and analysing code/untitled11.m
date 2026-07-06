% 超声波流量计修正因子仿真
% 参考文献：Effects of Velocity Profiles on Measuring Accuracy of Transit-Time Ultrasonic Flowmeter

clc;
clear;
close all;

%% 常量定义
c = 1480;          % 声速(m/s)，假设为水中的声速
R = 0.014/2;       % 管道半径(m)，根据论文实验设置(Page 7)
theta_deg = 45;    % 超声波传播角度(度)
theta = deg2rad(theta_deg);

%% 表1: Re与n的关系(论文Table 1)
Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];

%% 定义插值函数获取n值(线性插值)
get_n = @(Re) interp1(Re_table, n_table, Re, 'linear', 'extrap');

%% 流量计算函数
% 计算修正后的流量Q
calculate_Q = @(DeltaT, Re, flow_type) ...
    calculate_flow(DeltaT, Re, flow_type, R, theta, c, get_n);

%% 实验数据验证(论文表2和表3)
% --- 表2: 层流数据验证 ---
fprintf('===== 层流验证(表2) =====\n');
DeltaT_laminar = [0.378e-9, 0.462e-9, 0.632e-9, 1.002e-9, 1.121e-9, 1.310e-9, 1.317e-9, 1.553e-9];
Re_laminar = [652, 795, 1094, 1757, 1954, 2286, 2318, 2774];
Q1_laminar = [0.970e-5, 1.185e-5, 1.622e-5, 2.572e-5, 2.877e-5, 3.363e-5, 3.380e-5, 3.987e-5];
Q2_laminar = [0.717e-5, 0.873e-5, 1.202e-5, 1.930e-5, 2.147e-5, 2.512e-5, 2.548e-5, 3.048e-5];

for i = 1:length(DeltaT_laminar)
    Q_corrected = calculate_Q(DeltaT_laminar(i), Re_laminar(i), 'laminar');
    beta_sim = Q_corrected / Q1_laminar(i); % 仿真修正因子
    beta_real = Q2_laminar(i)/Q1_laminar(i); % 实际修正因子
    error = abs(0.75 - beta_real)/0.75 * 100; % 理论误差
    fprintf('样本%d: 理论k=0.75, 仿真k=%.3f, 实际k=%.3f, 误差=%.2f%%\n',...
        i, beta_sim, beta_real, error);
end

% --- 表3: 湍流数据验证 ---
fprintf('\n===== 湍流验证(表3) =====\n');
DeltaT_turbulent = [7.270e-9, 17.714e-9, 36.956e-9, 43.889e-9, 76.663e-9, 112.156e-9, 143.424e-9,...
                    171.690e-9, 241.767e-9, 312.871e-9, 341.571e-9, 440.921e-9, 532.958e-9,...
                    597.541e-9, 629.177e-9, 662.113e-9, 694.919e-9];
Re_turbulent = [4311, 10619, 22099, 26310, 46084, 67518, 86223, 103127, 147156, 188385,...
                207057, 267854, 323193, 362942, 382256, 401906, 422102];
Q1_turbulent = [0.186e-4, 0.454e-4, 0.948e-4, 1.125e-4, 1.966e-4, 2.876e-4, 3.677e-4,...
                4.402e-4, 6.276e-4, 8.022e-4, 8.758e-4, 11.305e-4, 13.664e-4, 15.320e-4,...
                16.131e-4, 16.976e-4, 17.817e-4];
Q2_turbulent = [0.172e-4, 0.424e-4, 0.881e-4, 1.049e-4, 1.838e-4, 2.693e-4, 3.438e-4,...
                4.113e-4, 5.868e-4, 7.513e-4, 8.257e-4, 10.681e-4, 12.888e-4, 14.473e-4,...
                15.244e-4, 16.027e-4, 16.833e-4];

for i = 1:length(DeltaT_turbulent)
    Q_corrected = calculate_Q(DeltaT_turbulent(i), Re_turbulent(i), 'turbulent');
    beta_sim = Q_corrected / Q1_turbulent(i);   % 仿真修正因子
    beta_real = Q2_turbulent(i)/Q1_turbulent(i);% 实际修正因子
    n = get_n(Re_turbulent(i));
    kt_theory = 2*n/(2*n+1);                   % 理论修正因子
    error = abs(kt_theory - beta_real)/kt_theory * 100; % 理论误差
    fprintf('样本%d: Re=%.1e, 理论k=%.3f, 仿真k=%.3f, 实际k=%.3f, 误差=%.2f%%\n',...
        i, Re_turbulent(i), kt_theory, beta_sim, beta_real, error);
end

%% 流量计算核心函数
function Q = calculate_flow(DeltaT, Re, flow_type, R, theta, c, get_n)
    % 计算未修正流量Q0
    L = 2*R / sin(theta);
    Q0 = (pi * R * c^2 * tan(theta) / 4) * DeltaT;
    
    % 根据流型应用修正因子
    if strcmpi(flow_type, 'laminar')
        k = 0.75; % 层流修正因子
    else
        n = get_n(Re);     % 获取n值
        k = 2*n/(2*n + 1); % 湍流修正因子
    end
    
    Q = k * Q0; % 修正后的流量
end