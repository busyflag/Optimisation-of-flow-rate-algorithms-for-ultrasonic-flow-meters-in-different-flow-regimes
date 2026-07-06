% 设定参数
rho = 1000;            % 流体密度 (kg/m^3)
mu = 1e-3;             % 流体粘度 (Pa·s)
D = 0.1;               % 管道直径 (m)
L = 10;                % 超声波传播路径长度 (m)
v_max = 3;             % 最大流速 (m/s)
R = D / 2;             % 管道半径 (m)
v_avg = 2;             % 平均流速 (m/s)

% 雷诺数计算
Re = (rho * v_avg * D) / mu; % 计算雷诺数

% 雷诺数判断流动状态
if Re < 2000
    flow_state = 'Laminar';  % 层流
elseif Re > 4000
    flow_state = 'Turbulent'; % 湍流
else
    flow_state = 'Transitional'; % 过渡流
end

% 选择流速分布模型
r = linspace(1e-6, R, 100);  % 防止 r=0，设置最小值为 1e-6，避免 log(0) 错误
v = zeros(size(r));

switch flow_state
    case 'Laminar'  % 层流
        v = v_max * (1 - (r / R).^2);
    case 'Turbulent' % 湍流
        kappa = 0.41;       % Karman常数
        u_tau = 0.2;        % 假设摩擦速度 (m/s)
        v = (u_tau / kappa) * log(R ./ r);
    case 'Transitional' % 过渡流
        v_laminar = v_max * (1 - (r / R).^2);  % 层流模型
        v_turbulent = (u_tau / kappa) * log(R ./ r);  % 湍流模型
        v = v_laminar .* (r <= R / 2) + v_turbulent .* (r > R / 2);  % 混合
end

% 计算流量（通过积分法计算）
Q_integral = trapz(r, v .* r * 2 * pi);  % 通过积分计算流量

% 计算流速（通过流量除以管道横截面积）
v_integral = Q_integral / (pi * R^2);  % 计算平均流速

% 传统方法：已知线速度求平均面速度
v_avg_traditional = trapz(r, v .* r) / trapz(r, r);  % 计算平均速度
Q_traditional = pi * trapz(r, v .* r);  % 传统方法计算流量

% 误差计算
error_integral = abs(Q_integral - Q_traditional) / Q_traditional * 100; % 计算积分方法与传统方法流量的误差

% 可视化结果
figure;
subplot(1, 2, 1);
plot(r, v, 'LineWidth', 2);
title(['Flow Velocity Distribution: ', flow_state]);
xlabel('Radial Position (m)');
ylabel('Velocity (m/s)');
legend(flow_state);
grid on;

subplot(1, 2, 2);
bar([Q_traditional, Q_integral]);
title('Flow Rate Comparison');
xticks([1, 2]);
xticklabels({'Traditional Method', 'Integral Method'});
ylabel('Flow Rate (m^3/s)');
grid on;

% 输出误差
disp(['Flow rate error between integral method and traditional method: ', num2str(error_integral), '%']);
disp(['Calculated flow rate (Integral Method): ', num2str(Q_integral), ' m^3/s']);
disp(['Calculated flow rate (Traditional Method): ', num2str(Q_traditional), ' m^3/s']);
disp(['Calculated average speed (Integral Method): ', num2str(v_integral), ' m/s']);
disp(['Calculated average speed (Traditional Method): ', num2str(v_avg_traditional), ' m/s']);
