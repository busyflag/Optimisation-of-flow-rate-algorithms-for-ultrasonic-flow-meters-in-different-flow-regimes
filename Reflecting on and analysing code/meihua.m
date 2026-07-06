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
u_m_laminar = 0.0503;  v_S_target_laminar = 0.062;
u_m_turbulent = 0.1006; v_S_target_turbulent = 0.124;

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

%% ==================== 专业可视化部分 ====================
% 设置全局图形参数
set(groot, 'DefaultAxesFontSize', 10, 'DefaultAxesFontWeight', 'bold',...
    'DefaultAxesLineWidth', 1.2, 'DefaultFigureColor', [1 1 1]);

% 创建统一配色方案
colorScheme = struct(...
    'laminar', [0.2 0.4 0.8],...    % 蓝色系-层流
    'turbulent', [0.8 0.2 0.4],...  % 红色系-湍流
    'transition', [0.4 0.6 0.2],... % 绿色系-过渡区
    'reference', [0.5 0.5 0.5],...  % 灰色-参考线
    'text', [0.2 0.2 0.2],...       % 文字颜色
    'background', [0.95 0.95 0.95]);% 背景色

%% 图1: 流速与流量特性
fig1 = figure('Name','Flow Characteristics','Position', [100 100 900 700]);
set(fig1, 'Color', colorScheme.background);

% 子图1: 面平均流速 vs 雷诺数
subplot(2,1,1);
hold on;
grid on;
set(gca, 'Color', 'w');

% 绘制不同流态区域背景
area([min(Re_values) 2000], [max(v_S) max(v_S)],...
    'FaceColor', colorScheme.laminar, 'FaceAlpha', 0.1, 'EdgeColor','none');
area([2000 4000], [max(v_S) max(v_S)],...
    'FaceColor', colorScheme.transition, 'FaceAlpha', 0.1, 'EdgeColor','none');
area([4000 max(Re_values)], [max(v_S) max(v_S)],...
    'FaceColor', colorScheme.turbulent, 'FaceAlpha', 0.1, 'EdgeColor','none');

% 主曲线 (带流态颜色分段)
plot(Re_values(Re_values<=2000), v_S(Re_values<=2000),...
    'Color', colorScheme.laminar, 'LineWidth', 2.5);
plot(Re_values(Re_values>=2000 & Re_values<=4000), v_S(Re_values>=2000 & Re_values<=4000),...
    'Color', colorScheme.transition, 'LineWidth', 2.5);
plot(Re_values(Re_values>=4000), v_S(Re_values>=4000),...
    'Color', colorScheme.turbulent, 'LineWidth', 2.5);

% 关键标注线
xline(2000, '--', 'Color', colorScheme.reference, 'LineWidth', 1.5,...
    'Alpha', 0.7, 'Label', '层流界限', 'LabelOrientation', 'horizontal',...
    'FontSize', 9, 'LabelVerticalAlignment', 'bottom');
xline(4000, '--', 'Color', colorScheme.reference, 'LineWidth', 1.5,...
    'Alpha', 0.7, 'Label', '湍流界限', 'LabelOrientation', 'horizontal',...
    'FontSize', 9);

% 标定数据点
scatter((u_m_laminar * D)/nu, v_S_target_laminar, 120,...
    'MarkerFaceColor', colorScheme.laminar, 'MarkerEdgeColor', 'k',...
    'LineWidth', 1.5, 'DisplayName', '层流标定点');
scatter((u_m_turbulent * D)/nu, v_S_target_turbulent, 120,...
    'MarkerFaceColor', colorScheme.turbulent, 'MarkerEdgeColor', 'k',...
    'LineWidth', 1.5, 'DisplayName', '湍流标定点');

% 图表美化
set(gca, 'XScale', 'log', 'YGrid', 'on', 'XGrid', 'on',...
    'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);
xlabel('雷诺数 Re', 'FontSize', 11, 'Color', colorScheme.text);
ylabel('面平均流速 v_S (m/s)', 'FontSize', 11, 'Color', colorScheme.text);
title('\bf 时差法流速特性曲线', 'FontSize', 12, 'Color', colorScheme.text);
legend({'','','','层流区','过渡区','湍流区'}, 'Location', 'northwest',...
    'FontSize', 9, 'Box', 'off');
xlim([min(Re_values) max(Re_values)]);
ylim([0 max(v_S)*1.05]);

% 子图2: 流量 vs 雷诺数
subplot(2,1,2);
hold on;
grid on;
set(gca, 'Color', 'w');

% 流量曲线 (颜色与流速图一致)
h(1) = plot(Re_values(Re_values<=2000), Q(Re_values<=2000),...
    'Color', colorScheme.laminar, 'LineWidth', 2.5, 'DisplayName', '层流区');
h(2) = plot(Re_values(Re_values>=2000 & Re_values<=4000), Q(Re_values>=2000 & Re_values<=4000),...
    'Color', colorScheme.transition, 'LineWidth', 2.5, 'DisplayName', '过渡区');
h(3) = plot(Re_values(Re_values>=4000), Q(Re_values>=4000),...
    'Color', colorScheme.turbulent, 'LineWidth', 2.5, 'DisplayName', '湍流区');

% 关键标注
xline(2000, '--', 'Color', colorScheme.reference, 'LineWidth', 1.5,...
    'Alpha', 0.7, 'HandleVisibility', 'off');
xline(4000, '--', 'Color', colorScheme.reference, 'LineWidth', 1.5,...
    'Alpha', 0.7, 'HandleVisibility', 'off');

% 标记典型值 (湍流区)
Re_markers = [11800, 12000, 19600, 20000];
marker_colors = winter(length(Re_markers));
for k = 1:length(Re_markers)
    re = Re_markers(k);
    idx = find(Re_values >= re, 1);
    scatter(Re_values(idx), Q(idx), 80, 'MarkerEdgeColor', marker_colors(k,:),...
        'MarkerFaceColor', 'w', 'LineWidth', 1.5);
    text(Re_values(idx), Q(idx)*0.97, sprintf('Re=%d\n%.1f m³/h', re, Q(idx)),...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top',...
        'FontSize', 8, 'Color', marker_colors(k,:), 'FontWeight', 'bold');
end

% 图表美化
set(gca, 'XScale', 'log', 'YGrid', 'on', 'XGrid', 'on',...
    'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);
xlabel('雷诺数 Re', 'FontSize', 11, 'Color', colorScheme.text);
ylabel('流量 Q (m³/h)', 'FontSize', 11, 'Color', colorScheme.text);
title('\bf 流量-雷诺数特性曲线', 'FontSize', 12, 'Color', colorScheme.text);
legend(h(1:3), 'Location', 'northwest', 'FontSize', 9, 'Box', 'off');
xlim([min(Re_values) max(Re_values)]);
ylim([0 max(Q)*1.05]);

%% ==================== 图2: 速度分布 ====================
% 设置雷诺数
Re_target = 2000;           % 层流临界
Re_target_turbulent = 4000; % 湍流临界

% 计算对应参数
u_m_target = (Re_target * nu) / D;
u_m_target_turbulent = (Re_target_turbulent * nu) / D;

% 计算速度分布
r = linspace(0, R, N);
s = r / R;
u = a * u_m_target * (1 - s.^2); % 层流速度分布

% 湍流速度分布
Re_table = [4e3, 2.56e4, 1.05e5, 2.06e5, 3.2e5, 3.84e5, 4.28e5];
n_table = [6.0, 7.0, 7.3, 8.0, 8.3, 8.5, 8.6];
n = interp1(Re_table, n_table, Re_target_turbulent, 'linear', 'extrap');
u_turbulent = b * u_m_target_turbulent * (1 - s).^(1/n);
[umax, idx_max] = max(u_turbulent);

% 创建图形
fig2 = figure('Name','Velocity Profiles','Position', [200 200 850 400]);
set(fig2, 'Color', colorScheme.background);

% 使用tiledlayout布局
t = tiledlayout(1,2, 'TileSpacing','compact', 'Padding','compact');

% 子图1: 层流分布
nexttile;
hold on;
grid on;
set(gca, 'Color', 'w');

% 绘制层流曲线
hL = plot(s, u, 'Color', colorScheme.laminar, 'LineWidth', 2.5,...
    'DisplayName', '抛物线分布');

% 填充曲线下面积
area(s, u, 'FaceColor', colorScheme.laminar, 'FaceAlpha', 0.2,...
    'EdgeColor', 'none');

% 关键参数标注
text(0.5, max(u)*0.5, {sprintf('\\bullet 抛物线分布'),...
    sprintf('u(r) = %.3f(1-r^2/R^2)', a*u_m_target),...
    sprintf('\\bf 最大速度: %.3f m/s', max(u))},...
    'FontSize', 9, 'FontWeight', 'bold', 'Color', colorScheme.laminar,...
    'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');

% 图表美化
xlabel('归一化径向位置 r/R', 'FontSize', 10, 'Color', colorScheme.text);
ylabel('轴向速度 u(r) [m/s]', 'FontSize', 10, 'Color', colorScheme.text);
title(sprintf('\\bf 层流速度分布 (Re=%d)', Re_target), 'FontSize', 11);
legend(hL, 'Location', 'southwest', 'FontSize', 8, 'Box', 'off');
xlim([0 1]);
ylim([0 max(u)*1.1]);
set(gca, 'Layer', 'top');

% 子图2: 湍流分布
nexttile;
hold on;
grid on;
set(gca, 'Color', 'w');

% 绘制湍流曲线
hT = plot(s, u_turbulent, 'Color', colorScheme.turbulent,...
    'LineWidth', 2.5, 'DisplayName', '1/n幂律分布');

% 湍流核心区标记
rectangle('Position', [0 umax*0.9 0.2 umax*0.1],...
    'FaceColor', [0.9 0.9 0.9 0.5], 'EdgeColor', 'none');
plot([0 0.2], [umax*0.9 umax*0.9], 'k-', 'LineWidth', 1);
text(0.1, umax*0.95, '湍流核心区', 'FontSize', 8,...
    'HorizontalAlignment', 'center');

% 标定关键参数
text(0.6, max(u_turbulent)*0.5, {sprintf('\\bullet 幂律指数 n=%.1f',n),...
    sprintf('u(r) ≈ %.3f(1-r/R)^{1/%.1f}', b*u_m_target_turbulent,n),...
    sprintf('\\bf 最大速度: %.3f m/s', umax)},...
    'FontSize', 9, 'FontWeight', 'bold', 'Color', colorScheme.turbulent,...
    'VerticalAlignment', 'middle');

% 图表美化
xlabel('归一化径向位置 r/R', 'FontSize', 10, 'Color', colorScheme.text);
ylabel('轴向速度 u(r) [m/s]', 'FontSize', 10, 'Color', colorScheme.text);
title(sprintf('\\bf 湍流速度分布 (Re=%d)', Re_target_turbulent), 'FontSize', 11);
legend(hT, 'Location', 'southwest', 'FontSize', 8, 'Box', 'off');
xlim([0 1]);
ylim([0 max(u_turbulent)*1.1]);
set(gca, 'Layer', 'top');

%% ==================== 函数定义 ====================
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
