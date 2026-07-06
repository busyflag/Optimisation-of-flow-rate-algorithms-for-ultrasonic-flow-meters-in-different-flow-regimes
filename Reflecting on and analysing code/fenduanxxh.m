% % 单声道超声水表分段线性化校正方法
% % 参考：姚灵等，《计量学报》2013年第34卷第5期
% 
% clc;
% clear;
% close all;
% 
% %% 参数设定
% D = 0.1;            % 管道内径(m)
% theta = 45;         % 超声波角度(°)
% c = 1500;           % 水中声速(m/s)
% nu = 1.007e-6;      % 水的运动粘度(m²/s) @20°C
% Q_max = 100;        % 最大流量(m³/h)
% L = D / sind(theta); % 声路径长度(m)
% 
% % 雷诺数分界点 (层流上限Re1，湍流下限Re2)
% Re1 = 2000;         % 层流临界雷诺数
% Re2 = 4000;         % 湍流临界雷诺数
% 
% %% 计算分界点流量和流速
% % 雷诺数公式: Re = v_s * D / nu
% % => v_s = Re * nu / D
% 
% % 层流上限对应的面平均流速和流量
% v_s1 = Re1 * nu / D;                % 面平均流速(m/s)
% Q1 = v_s1 * (pi*D^2/4) * 3600;      % 流量(m³/h)
% 
% % 湍流下限对应的面平均流速和流量
% v_s2 = Re2 * nu / D;
% Q2 = v_s2 * (pi*D^2/4) * 3600;
% 
% % 最大流量对应的雷诺数
% v_s_max = Q_max / (pi*D^2/4) / 3600;
% Re_max = v_s_max * D / nu;
% 
% fprintf('层流上限: Re=%.0f, Q=%.3f m³/h, v_s=%.4f m/s\n', Re1, Q1, v_s1);
% fprintf('湍流下限: Re=%.0f, Q=%.3f m³/h, v_s=%.4f m/s\n', Re2, Q2, v_s2);
% fprintf('最大流量: Re=%.0f, Q=%.1f m³/h, v_s=%.4f m/s\n', Re_max, Q_max, v_s_max);
% 
% %% 构建理论流速分布模型
% % 层流区: v_L = (4/3)*v_s
% % 湍流区: v_L = v_s / (1 + 1.66*sqrt(8/f)*log(Re)) 
% % 其中f为Darcy摩擦系数，对于光滑管可用Blasius公式: f = 0.3164*Re^(-0.25)
% 
% % 生成测试流量点(覆盖层流、过渡流和湍流)
% Q_test = linspace(0.1, Q_max, 100)';  % 流量范围(m³/h)
% v_s_test = Q_test / (pi*D^2/4) / 3600; % 面平均流速(m/s)
% Re_test = v_s_test * D / nu;          % 雷诺数
% 
% % 计算理论线平均流速(v_L)与面平均流速(v_s)的关系
% v_L_theory = zeros(size(Q_test));
% for i = 1:length(Q_test)
%     if Re_test(i) <= Re1
%         % 层流区
%         v_L_theory(i) = (4/3) * v_s_test(i);  % 层流精确解
%     elseif Re_test(i) >= Re2
%         % 湍流区
%         f = 0.3164 * Re_test(i)^(-0.25);     % Blasius公式
%         v_L_theory(i) = v_s_test(i) / (1 + 1.66*sqrt(8/f)*log10(Re_test(i))/log10(exp(1)));
%     else
%         % 过渡区(线性插值)
%         v_L1 = (4/3) * (Re1*nu/D);
%         v_L2 = v_s_test(i) / (1 + 1.66*sqrt(8/(0.3164*Re2^(-0.25)))*log10(Re2)/log10(exp(1)));
%         v_L_theory(i) = interp1([Re1, Re2], [v_L1, v_L2], Re_test(i), 'linear');
%     end
% end
% 
% %% 分段线性校正模型
% % 确定分界点的线平均流速
% % 层流上限点(Q1)
% v_L1 = (4/3) * v_s1;
% 
% % 湍流下限点(Q2)
% f2 = 0.3164 * Re2^(-0.25);
% v_L2 = v_s2 / (1 + 1.66*sqrt(8/f2)*log10(Re2)/log10(exp(1)));
% 
% % 最大流量点(Q_max)
% f_max = 0.3164 * Re_max^(-0.25);
% v_L_max = v_s_max / (1 + 1.66*sqrt(8/f_max)*log10(Re_max)/log10(exp(1)));
% 
% % 构建分段校正模型
% % 层流区: v_s = k1 * v_L
% k1 = 3/4;   % 理论值，实际应用中可通过标定调整
% 
% % 过渡区: v_s = a2 * v_L + b2
% % 通过(Q1,v_s1)和(Q2,v_s2)两点确定直线
% A = [v_L1, 1; v_L2, 1];
% b = [v_s1; v_s2];
% x = A\b;
% a2 = x(1);
% b2 = x(2);
% 
% % 湍流区: v_s = a3 * v_L + b3
% % 通过(Q2,v_s2)和(Q_max,v_s_max)两点确定直线
% A = [v_L2, 1; v_L_max, 1];
% b = [v_s2; v_s_max];
% x = A\b;
% a3 = x(1);
% b3 = x(2);
% 
% %% 应用分段校正
% v_s_corrected = zeros(size(Q_test));
% for i = 1:length(Q_test)
%     v_L = v_L_theory(i);  % 模拟测量得到的线平均流速
% 
%     % 根据流速选择校正区间
%     if v_L <= v_L1
%         % 层流区
%         v_s_corrected(i) = k1 * v_L;
%     elseif v_L <= v_L2
%         % 过渡区
%         v_s_corrected(i) = a2 * v_L + b2;
%     else
%         % 湍流区
%         v_s_corrected(i) = a3 * v_L + b3;
%     end
% end
% 
% %% 计算校正误差
% error = (v_s_corrected - v_s_test) ./ v_s_test * 100;
% 
% %% 可视化结果
% figure;
% 
% % 线平均流速与面平均流速的关系
% subplot(2,1,1);
% plot(Q_test, v_L_theory, 'b', 'LineWidth', 1.5); hold on;
% plot(Q_test, v_s_test, 'r', 'LineWidth', 1.5);
% plot([Q1, Q1], [0, max(v_L_theory)], 'k--');
% plot([Q2, Q2], [0, max(v_L_theory)], 'k--');
% xlabel('流量 (m³/h)');
% ylabel('流速 (m/s)');
% legend('线平均流速 v_L', '面平均流速 v_s', '分界点');
% title('流速分布特性');
% grid on;
% 
% % 校正误差
% subplot(2,1,2);
% plot(Q_test, error, 'LineWidth', 1.5);
% hold on;
% plot([min(Q_test), max(Q_test)], [1, 1], 'r--');  % 1%误差线
% plot([min(Q_test), max(Q_test)], [-1, -1], 'r--');
% plot([Q1, Q1], [min(error), max(error)], 'k--');
% plot([Q2, Q2], [min(error), max(error)], 'k--');
% xlabel('流量 (m³/h)');
% ylabel('校正误差 (%)');
% title('分段校正效果');
% ylim([-2, 2]);
% grid on;
% 
% %% 显示关键参数
% fprintf('\n分段校正参数:\n');
% fprintf('层流区 (v_L <= %.4f m/s): v_s = %.4f * v_L\n', v_L1, k1);
% fprintf('过渡区 (%.4f < v_L <= %.4f): v_s = %.4f * v_L + %.6f\n', ...
%     v_L1, v_L2, a2, b2);
% fprintf('湍流区 (v_L > %.4f): v_s = %.4f * v_L + %.6f\n', ...
%     v_L2, a3, b3);
% 
% 
% 
% %% 加载实验数据（替换为您的实际数据）
% % 实验数据格式: [Re, T(℃), v(m/s), Q1, Q2, Q3, Q4]
% exp_data = [
%     2000    12      0.062   0.280   0.280   0.281   0.280
%     2200    12      0.068   0.309   0.309   0.309   0.309
%     2400    12      0.074   0.337   0.338   0.337   0.337
%     2600    12      0.081   0.365   0.366   0.367   0.366
%     2800    12      0.087   0.392   0.392   0.392   0.392
%     3000    12      0.093   0.418   0.420   0.420   0.420
%     3200    12      0.099   0.499   0.448   0.449   0.448
%     3400    12      0.105   0.477   0.478   0.477   0.477
%     3600    12      0.112   0.503   0.503   0.502   0.503
%     3800    12      0.118   0.533   0.534   0.533   0.535
%     4000    12      0.124   0.561   0.561   0.561   0.561
%     11800   11.2    0.374   1.694   1.692   1.691   1.692
%     12000   11.2    0.380   1.717   1.719   1.720   1.719
%     12200   11.2    0.387   1.750   1.750   1.751   1.750
%     19600   10.3    0.636   2.880   2.878   2.879   2.879
%     19800   10.3    0.643   2.907   2.908   2.907   2.905
%     20000   10.3    0.649   2.936   2.936   2.935   2.937
% ];
% 
% % 计算实验数据的平均流量和雷诺数
% exp_Re = exp_data(:,1);
% exp_v_s = exp_data(:,3);
% exp_Q_mean = mean(exp_data(:,4:7), 2); % 取4次测量的平均值
% exp_T = exp_data(:,2);
% 
% %% 计算模型预测值（基于分段校正方法）
% model_Q = zeros(size(exp_Re));
% for i = 1:length(exp_Re)
%     Re = exp_Re(i);
%     v_s = exp_v_s(i);  % 实验面平均流速
% 
%     % 计算对应的u_m (时差法测量值)
%     if Re <= 2000
%         % 层流区
%         u_m = v_s / a;  % a为层流修正因子
%     elseif Re >= 4000
%         % 湍流区
%         u_m = (v_s - b3) / a3; % a3和b3为湍流区线性校正系数
%     else
%         % 过渡区 (线性插值)
%         u_m = interp1([Re1,Re2], [v_s1/a, (v_s2-b3)/a3], Re, 'linear');
%     end
% 
%     % 计算模型预测流量
%     model_v_S = v_s;  % 假设校正完美时模型输出等于实验值
%     model_Q(i) = pi * (D/2)^2 * model_v_S * 3600; % 转换为m³/h
% end
% 
% %% 计算误差
% absolute_error = model_Q - exp_Q_mean;
% relative_error = (absolute_error ./ exp_Q_mean) * 100;
% 
% %% 可视化误差分析
% figure;
% 
% % 误差随雷诺数变化
% subplot(2,1,1);
% semilogx(exp_Re, relative_error, 'o-', 'LineWidth', 1.5, 'MarkerSize', 8);
% hold on;
% yline(0, '--k', '零误差线');
% xline(2000, '--r', '层流界限');
% xline(4000, '--r', '湍流界限');
% xlabel('雷诺数 Re');
% ylabel('相对误差 (%)');
% title('分段校正模型与实验数据的误差对比');
% grid on;
% 
% % 误差分布统计
% subplot(2,1,2);
% histogram(relative_error, 20, 'FaceColor', [0.5 0.5 0.8]);
% xlabel('相对误差 (%)');
% ylabel('频数');
% title('误差分布直方图');
% grid on;
% 
% %% 显示关键误差指标
% max_abs_error = max(abs(relative_error));
% mean_abs_error = mean(abs(relative_error));
% fprintf('\n误差统计:\n');
% fprintf('最大绝对误差: %.2f%%\n', max_abs_error);
% fprintf('平均绝对误差: %.2f%%\n', mean_abs_error);
% fprintf('标准差: %.2f%%\n', std(relative_error));
% 
% %% 校正效果评估（可选：绘制理论值与实验值对比）
% figure;
% loglog(exp_Q_mean, model_Q, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
% hold on;
% plot([min(exp_Q_mean), max(exp_Q_mean)], [min(exp_Q_mean), max(exp_Q_mean)], 'r--');
% xlabel('实验流量 (m³/h)');
% ylabel('模型预测流量 (m³/h)');
% title('模型预测 vs 实验测量');
% legend('数据点', '理想1:1线', 'Location', 'northwest');
% grid on;
% axis equal;

%% 数据预处理
% 实验数据：Re, T(℃), v(m/s), Q1,Q2,Q3,Q4 (m³/h)
data = [
2000	12	0.062	0.28	0.28	0.281	0.28
2200	12	0.068	0.309	0.309	0.309	0.309
2400	12	0.074	0.337	0.338	0.337	0.337
2600	12	0.081	0.365	0.366	0.367	0.366
2800	12	0.087	0.392	0.392	0.392	0.392
3000	12	0.093	0.418	0.42	0.42	0.42
3200	12	0.099	0.499	0.448	0.449	0.448
3400	12	0.105	0.477	0.478	0.477	0.477
3600	12	0.112	0.503	0.503	0.502	0.503
3800	12	0.118	0.533	0.534	0.533	0.535
4000	12	0.124	0.561	0.561	0.561	0.561
11800	11.2	0.374	1.694	1.692	1.691	1.692
12000	11.2	0.38	1.717	1.719	1.72	1.719
12200	11.2	0.387	1.75	1.75	1.751	1.75
19600	10.3	0.636	2.88	2.878	2.879	2.879
19800	10.3	0.643	2.907	2.908	2.907	2.905
20000	10.3	0.649	2.936	2.936	2.935	2.937
];

Re = data(:,1);
v_measured = data(:,3); % 实测面平均流速
Q_actual = mean(data(:,4:7),2); % 4次实际流量平均值
D = 0.04; % 管道直径(m)
A = pi*(D/2)^2; % 截面积(m²)
v_calculated = Q_actual; % 计算面平均流速(m/s)

%% 分段线性化校正模型
% 划分流态区间
laminar_idx = Re <= 2000;
transition_idx = (Re > 2000) & (Re < 4000);
turbulent_idx = Re >= 4000;

% 层流区校正系数 (理论值0.5)
k_laminar = 0.52; % 通过实验标定微调

% 湍流区校正曲线拟合 (n与Re的关系)
n = 2.1*log(Re).^(-0.9); % 经验公式
k_turbulent = (2.*n.^2)./((2*n+1).*(n+1)); % 湍流修正系数

% 过渡区线性插值
alpha = (Re - 2000)/2000;
alpha(alpha<0) = 0; alpha(alpha>1) = 1;
k_transition = (1-alpha)*k_laminar + alpha.*k_turbulent;

% 组合校正系数
k_corrected = zeros(size(Re));
k_corrected(laminar_idx) = k_laminar;
k_corrected(transition_idx) = k_transition(transition_idx);
k_corrected(turbulent_idx) = k_turbulent(turbulent_idx);

% 校正后流速
v_corrected = v_measured ./ k_corrected;

%% 误差分析
% 未经校正的误差
error_raw = (v_measured - v_calculated)./v_calculated * 100;

% 校正后误差
error_corrected = (v_corrected - v_calculated)./v_calculated * 100;

%% 可视化结果
figure('Position',[100 100 1200 800], 'Color','w')

% 流速校正效果对比
subplot(2,2,1)
hold on; grid on; box on
plot(Re, v_calculated, 'k-', 'LineWidth', 2, 'DisplayName','真实流速')
plot(Re, v_measured, 'b--', 'LineWidth', 1.5, 'DisplayName','测量流速(未校正)')
plot(Re, v_corrected, 'r-.', 'LineWidth', 2, 'DisplayName','校正流速')
xline(2000, '--', 'Color',[0.5 0.5 0.5], 'Label','层流临界Re=2000')
xline(4000, '--', 'Color',[0.5 0.5 0.5], 'Label','湍流临界Re=4000')
xlabel('雷诺数 Re')
ylabel('流速 (m/s)')
title('(a) 流速校正效果对比')
legend('Location','northwest')
set(gca, 'FontSize',11)

% 修正系数曲线
subplot(2,2,2)
hold on; grid on; box on
scatter(Re(laminar_idx), k_corrected(laminar_idx), 80, 'filled', 'MarkerFaceColor',[0 0.45 0.74])
scatter(Re(transition_idx), k_corrected(transition_idx), 80, 'filled', 'MarkerFaceColor',[0.85 0.33 0.1])
scatter(Re(turbulent_idx), k_corrected(turbulent_idx), 80, 'filled', 'MarkerFaceColor',[0.93 0.69 0.13])
plot(Re, k_corrected, 'k-', 'LineWidth',1)
xline(2000, '--', 'Color',[0.5 0.5 0.5])
xline(4000, '--', 'Color',[0.5 0.5 0.5])
xlabel('雷诺数 Re')
ylabel('修正系数 k')
title('(b) 分段修正系数分布')
set(gca, 'FontSize',11)
text(500, 0.55, sprintf('层流区 k=%.3f',k_laminar),'FontSize',10)
text(3000, 0.48, '过渡区线性插值','FontSize',10)
text(15000, 0.85, '湍流区 k=f(Re)','FontSize',10)

% 误差对比曲线
subplot(2,2,[3 4])
hold on; grid on; box on
plot(Re, error_raw, 'bo-', 'LineWidth', 1.5, 'MarkerSize',6, 'DisplayName','未校正误差')
plot(Re, error_corrected, 'rs--', 'LineWidth', 2, 'MarkerSize',8, 'DisplayName','校正后误差')
xline(2000, '--', 'Color',[0.5 0.5 0.5])
xline(4000, '--', 'Color',[0.5 0.5 0.5])
yline(0, 'k-', 'LineWidth',1.2)
yline(1, '--', 'Color',[0 0.5 0], 'Label','1%误差线')
yline(-1, '--', 'Color',[0 0.5 0], 'Label','-1%误差线')
xlabel('雷诺数 Re')
ylabel('相对误差 (%)')
title('(c) 校正前后误差对比')
legend('Location','southwest')
set(gca, 'FontSize',11)

% 计算平均误差改进
fprintf('平均绝对误差改进:\n');
fprintf('未校正: %.2f%%\n', mean(abs(error_raw)));
fprintf('校正后: %.2f%%\n', mean(abs(error_corrected)));
fprintf('误差降低: %.1f%%\n', (mean(abs(error_raw))-mean(abs(error_corrected)))/mean(abs(error_raw))*100);

