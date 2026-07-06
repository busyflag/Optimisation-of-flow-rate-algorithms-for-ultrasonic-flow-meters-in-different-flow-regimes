clc
clear
% 模拟实验数据（实际应用时替换为真实称重法数据）
Re_exp = [2000, 2200, 2400, 2600, 2800, 3000, 3200,3400,3600,3800,4000,11800,12000,12200,19600,19800,20000]; % 测试点雷诺数
Q_exp = [0.281, 0.309, 0.337, 0.365, 0.392, 0.418, 0.449,0.477,0.503,0.534,0.562,1.692,1.721,1.75,2.877,2.907,2.936]; % 称重法流量(m³/s)
R=0.04;
theta = 45; 
c = 1482; 
% 对应流速分布函数（真实物理情况）
r = linspace(0, R, 100); % 径向坐标
u_laminar_real = @(r) 2*mean(Q_exp(1:2))/(pi*R^2) * (1 - (r/R).^2); % 层流实测分布
u_turb_real = @(r) 1.1*mean(Q_exp(end-2:end))/(pi*R^2) * (1 - r/R).^(1/7); % 湍流实测分布
function [k, u_fit] = fit_correction_factor(Re, Q_exp, theta, c, R)
    if Re < 2000
        % 层流拟合
        fun = @(k) abs(integral(@(r) 2./(c - k*2*Q_exp/(pi*R^2)*(1-(r/R).^2)*cos(theta)), 0, R) - ...
                      integral(@(r) 2./(c + k*2*Q_exp/(pi*R^2)*(1-(r/R).^2)*cos(theta)), 0, R));
        k0 = 0.75;
        u_fit = @(r) k * 2*Q_exp/(pi*R^2) * (1 - (r/R).^2); % 注意层流平均流速是umax/2
    else
        % 湍流拟合
        n = interp1([4e3, 1e5], [6, 8.8], Re);
        fun = @(k) abs(integral(@(r) 2./(c - k*(n+1)/(2*n)*Q_exp/(pi*R^2)*(1-r/R).^(1/n)*cos(theta)), 0, R) - ...
                      integral(@(r) 2./(c + k*(n+1)/(2*n)*Q_exp/(pi*R^2)*(1-r/R).^(1/n)*cos(theta)), 0, R));
        k0 = 0.85;
        u_fit = @(r) k * (n+1)/(2*n)*Q_exp/(pi*R^2) * (1 - r/R).^(1/n); % 湍流平均流速系数(n+1)/2n
    end
    k = fminsearch(fun, k0);
end
% 对每个实验点拟合修正因子
k_values = zeros(size(Re_exp));
for i = 1:length(Re_exp)
    [k_values(i), ~] = fit_correction_factor(Re_exp(i), Q_exp(i), theta, c, R);
end

% 生成修正因子函数
Re_all = linspace(500, 1e5, 100);
k_smooth = interp1(Re_exp, k_values, Re_all, 'pchip', 'extrap');

% 完整积分时差法计算
function Q = full_integral_method(Re, k, theta, c, R,Q_exp)
    if Re < 2000
        u = @(r) k * (2*mean(Q_exp(1:2))/(pi*R^2)) * (1 - (r/R).^2);
    elseif Re > 4000
        n = interp1([4e3, 1e5], [6, 8.8], Re);
        u = @(r) k * (1.1*mean(Q_exp(end-2:end))/(pi*R^2)) * (1 - r/R).^(1/n);
    else
        alpha = (Re - 2000)/2000;
        u_l = @(r) 0.75 * (2*mean(Q_exp(1:2))/(pi*R^2)) * (1 - (r/R).^2);
        u_t = @(r) 0.86 * (1.1*mean(Q_exp(end-2:end))/(pi*R^2)) * (1 - r/R).^(1/7);
        u = @(r) (1-alpha)*u_l(r) + alpha*u_t(r);
    end
    
    % 数值积分传播时间
    T1 = integral(@(r) 2./(c + u(r)*cos(theta)), 0, R);
    T2 = integral(@(r) 2./(c - u(r)*cos(theta)), 0, R);
    deltaT = T2 - T1;
    
    % 计算流量
    Q = integral(@(r) 2*pi*r.*u(r), 0, R);
end

% 计算全范围流量
Q_calc = arrayfun(@(Re,k) full_integral_method(Re,k,theta,c,R,Q_exp), Re_all, k_smooth);
% 理论流量（用于误差计算）
Q_theory = interp1(Re_exp, Q_exp, Re_all, 'pchip');

figure;
subplot(3,1,1);
plot(Re_all, k_smooth, 'LineWidth', 2);
xlabel('Reynolds Number'); ylabel('Correction Factor k');
title('Fitted Correction Factor');

subplot(3,1,2);
semilogx(Re_all, Q_theory, 'b-', Re_all, Q_calc, 'r--');
legend('Truth (Weighing)', 'Calculated');
xlabel('Re'); ylabel('Flow Rate');

subplot(3,1,3);
semilogx(Re_all, abs(Q_calc-Q_theory)./Q_theory*100);
yline(1.0, 'r--'); % 1%误差线
xlabel('Re'); ylabel('Error (%)');
