% clear; clc; close all;
% 
% % 管道参数
% R = 0.2;      % 管道半径 (m)
% r = linspace(-R, R, 1000);  % 径向坐标
% 
% % 定义流速分布函数
% u_laminar = @(r, v) 2*v*(1 - (r/R).^2);                          % 层流抛物线分布
% u_turbulent = @(r, v, n) v*(n+1)/n .* (1 - abs(r)/R).^(1/n);     % 湍流幂律分布
% 
% % 示例雷诺数
% Re_laminar = 1000;    % 层流
% Re_transition = 3000; % 过渡流
% Re_turbulent = 10000; % 湍流
% 
% % 计算平均面流速 (假设固定运动黏度 nu=1e-6 m²/s)
% nu = 1e-6;
% v_laminar = Re_laminar * nu / (2*R);
% v_transition = Re_transition * nu / (2*R);
% v_turbulent = Re_turbulent * nu / (2*R);
% 
% % 湍流幂律指数 n (根据雷诺数经验公式)
% n_turbulent = 1.66 * log(Re_turbulent) - 3.93;  % 适用于Re>4000
% 
% % 过渡流线性混合 (简化模型)
% alpha = (Re_transition - 2000) / 2000;  % 过渡系数
% 
% % 计算流速分布
% u_l = u_laminar(r, v_laminar);
% u_t = u_turbulent(r, v_turbulent, n_turbulent);
% u_tr = alpha * u_t + (1-alpha) * u_l;  % 过渡流混合分布
% 
% % 绘制图形
% figure('Color', 'white');
% hold on;
% 
% % 层流分布
% plot(r, u_l, 'b-', 'LineWidth', 2, 'DisplayName', sprintf('层流 (Re=%d)', Re_laminar));
% 
% % 过渡流分布
% plot(r, u_tr, 'g--', 'LineWidth', 2, 'DisplayName', sprintf('过渡流 (Re=%d)', Re_transition));
% 
% % 湍流分布
% plot(r, u_t, 'r-.', 'LineWidth', 2, 'DisplayName', sprintf('湍流 (Re=%d, n=%.2f)', Re_turbulent, n_turbulent));
% 
% % 标注极值
% [~, idx] = max(u_l);
% text(0, u_l(idx), sprintf('u_{max}=%.2f', u_l(idx)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
% 
% % 图形美化
% xlabel('径向位置 r (m)');
% ylabel('流速 u(r) (m/s)');
% title('层流/过渡流/湍流未修正线速度分布');
% legend('Location', 'northeast');
% grid on;
% box on;
% set(gca, 'FontSize', 12);
% 
% % 显示管道边界
% yline(0, 'k-', 'LineWidth', 1.5);
% xline(-R, 'k-', 'LineWidth', 1.5);
% xline(R, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');


% % 湍流和层流速度分布对比图
% clear all;
% close all;
% clc;
% 
% % 设置参数
% R = 0.2;          % 管道半径
% r = linspace(-R, R, 100);   % 径向位置
% U_max = 0.0503;      % 最大速度
% 
% % 层流速度分布 (抛物线分布)
% U_laminar = U_max * (1 - (r/R).^2);
% 
% % 湍流速度分布 (1/7次幂律，近似)
% U_turbulent = U_max * (1 - abs(r/R)).^(1/7);
% 
% % 绘制图形
% figure('Position', [100, 100, 800, 600]);
% plot(U_laminar, r, 'b-', 'LineWidth', 2);
% hold on;
% plot(U_turbulent, r, 'r--', 'LineWidth', 2);
% grid on;
% 
% % 添加标题和标签
% title('湍流和层流速度分布对比', 'FontSize', 14);
% xlabel('速度 u/U_{max}', 'FontSize', 12);
% ylabel('径向位置 r/R', 'FontSize', 12);
% legend('层流 (抛物线分布)', '湍流 (1/7次幂律)', 'Location', 'northeast');
% xlim([0, 1.1]);
% 
% % 添加注释
% text(0.6, 0.15, 'u/U_{max} = 1 - (r/R)^2', 'FontSize', 10, 'Color', 'b');
% text(0.6, -0.15, 'u/U_{max} = (1 - |r/R|)^{1/7}', 'FontSize', 10, 'Color', 'r');
% 
% % 美观设置
% set(gca, 'FontSize', 12, 'LineWidth', 1.5);


% 湍流和层流速度分布对比图（指定最大速度）
clear all;
close all;
clc;

% 设置参数
R = 1;                 % 管道半径
r = linspace(-R, R, 100);  % 径向位置
U_max_laminar = 0.0503;   % 层流最大速度
U_max_turbulent = 0.1006; % 湍流最大速度

% 层流速度分布 (抛物线分布)
U_laminar = U_max_laminar * (1 - (r/R).^2);

% 湍流速度分布 (1/7次幂律，近似)
U_turbulent = U_max_turbulent * (1 - abs(r/R)).^(1/7);

% 绘制图形
figure('Position', [100, 100, 800, 600]);
plot(U_laminar, r, 'b-', 'LineWidth', 2);
hold on;
plot(U_turbulent, r, 'r--', 'LineWidth', 2);
grid on;

% 添加标题和标签
title({'湍流和层流速度分布对比'}, ...
      'FontSize', 14);
xlabel('速度 u [m/s]', 'FontSize', 12);
ylabel('径向位置 r/R', 'FontSize', 12);
legend('层流 ', '湍流 ', 'Location', 'northeast');
xlim([0, max(U_max_turbulent)*1.1]);

% 添加最大速度标记
% line([U_max_laminar U_max_laminar], [min(r) max(r)], ...
%      'LineStyle', ':', 'Color', 'b');
% line([U_max_turbulent U_max_turbulent], [min(r) max(r)], ...
%      'LineStyle', ':', 'Color', 'r');
% text(U_max_laminar+0.005, 0.8, sprintf('U_{max,laminar}=%.4f', U_max_laminar), ...
%      'Color', 'b', 'FontSize', 10);
% text(U_max_turbulent+0.005, 0.6, sprintf('U_{max,turbulent}=%.4f', U_max_turbulent), ...
%      'Color', 'r', 'FontSize', 10);

% 美观设置
set(gca, 'FontSize', 12, 'LineWidth', 1.5);



