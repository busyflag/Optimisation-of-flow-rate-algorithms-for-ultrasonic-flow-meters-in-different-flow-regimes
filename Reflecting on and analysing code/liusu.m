% exp_data = [
%     11800  11.2 0.374   1.694   1.692   1.691   1.692;
%     12000  11.2 0.380   1.717   1.719   1.720   1.719;
%     12200  11.2 0.387   1.750   1.750   1.751   1.750;
%     % 19600  10.3 0.636   2.880   2.878   2.879   2.879;
%     % 19800  10.3 0.643   2.907   2.908   2.907   2.905;
%     % 20000  10.3 0.649   2.936   2.936   2.935   2.937
%   % 2000   12  0.062    0.280   0.280   0.281   0.280;
%   %   2200   12  0.068    0.309   0.309   0.309   0.309;
%   %   2400   12  0.074    0.337   0.338   0.337   0.337;
%   %   2600   12  0.081    0.365   0.366   0.367   0.366;
%   %   2800   12  0.087    0.392   0.392   0.392   0.392;
%   %   3000   12  0.093    0.418   0.420   0.420   0.420;
%   %   3200   12  0.099    0.448   0.448   0.449   0.448;
%   %   3400   12  0.105    0.477   0.478   0.477   0.477;
%   %   3600   12  0.112    0.503   0.503   0.502   0.503;
%   %   3800   12  0.118    0.533   0.534   0.533   0.535;
%   %   4000   12  0.124    0.561   0.561   0.561   0.561;
% ];
% 
% %% 理论计算结果（您提供的过渡区数据）
% theory_data = [
% 11800      0.369155        1.670019       
% 12000      0.375486        1.698659       
% 12200      0.381819        1.727310       
% % 19600      0.617674        2.794293       
% % 19800      0.624088        2.823309       
% % 20000      0.630504        2.852333  
% % 2000       0.062062        0.280760       
% % 2200       0.068254        0.308774       
% % 2400       0.074448        0.336793       
% % 2600       0.080643        0.364818       
% % 2800       0.086840        0.392856       
% % 3000       0.093041        0.420908       
% % 3200       0.099246        0.448979       
% % 3400       0.105456        0.477072       
% % 3600       0.111672        0.505192       
% % 3800       0.117894        0.533341       
% % 4000       0.124124        0.561523
% ];
% 
% %% 数据提取
% % 实验数据（仅过渡区2000-4000）
% exp_Re = exp_data(1:11, 1);                    % 雷诺数
% exp_Q_mean = mean(exp_data(1:11, 4:7), 2);     % 实验流量均值
% exp_Q_std = std(exp_data(1:11, 4:7), 0, 2);    % 实验流量标准差
% 
% % 理论数据
% theory_Re = theory_data(:, 1);
% theory_Q = theory_data(:, 3);                  % 理论流量
% 
% %% 精确误差计算（保留6位小数）
% sim_Q = interp1(theory_Re, theory_Q, exp_Re, 'pchip');
% abs_error = sim_Q - exp_Q_mean;
% rel_error = (abs_error ./ exp_Q_mean) * 100;   % 相对误差(%)
% figure('Position',[100 100 1000 400], 'Color','w')
% 
% % 从实验数据提取测量流速
% exp_v_measured = exp_data(:,3);  % 实验测量的线平均流速（时差法直接测得）
% 
% % 从理论数据获取面平均流速（需要转换）
% D = 0.04; % 管道直径(m)
% A = pi*(D/2)^2; % 截面积(m²)
% theory_v_surface = theory_Q/3600/A; % 理论面平均流速(m/s)
% 
% % 计算时差法直接将线平均流速作为面平均流速的误差
% error_v = (exp_v_measured - theory_v_surface)./theory_v_surface*100;
% 
% % 绘制误差对比图
% subplot(1,2,1)
% hold on; grid on; box on
% plot(exp_Re, exp_v_measured, 'bo-', 'LineWidth',1.5, 'MarkerSize',8, 'MarkerFaceColor','b', 'DisplayName','测量值')
% plot(exp_Re, theory_v_surface, 'rs--', 'LineWidth',2, 'MarkerSize',8, 'DisplayName','理论流速')
% xlabel('雷诺数 Re', 'FontSize',11)
% ylabel('流速 (m/s)', 'FontSize',11)
% title('(a) 流速测量值对比', 'FontSize',12)
% legend('Location','northwest')
% set(gca, 'FontSize',10)
% 
% subplot(1,2,2)
% hold on; grid on; box on
% bar(exp_Re, error_v, 0.6, 'FaceColor',[0.8 0.2 0.2])
% for i = 1:length(exp_Re)
%     text(exp_Re(i), error_v(i)+sign(error_v(i))*0.1, sprintf('%.2f%%',error_v(i)),...
%         'HorizontalAlignment','center', 'FontSize',10)
% end
% yline(0, 'k-', 'LineWidth',1.2)
% xlabel('雷诺数 Re', 'FontSize',11)
% ylabel('相对误差 (%)', 'FontSize',11)
% title('(b) 流速相对误差', 'FontSize',12)
% ylim([min(error_v)-0.5 max(error_v)+0.5])
% set(gca, 'FontSize',10)
% 
% % 误差统计
% fprintf('\n====== 流速测量误差分析 ======\n');
% fprintf('平均绝对误差: %.2f%%\n', mean(abs(error_v)));
% fprintf('最大误差: %.2f%% @ Re=%d\n', max(abs(error_v)), exp_Re(find(abs(error_v)==max(abs(error_v)),1)));
% 
% 
% 


%% 整合三个数据集的流速误差对比图
figure('Position',[100 100 1200 900], 'Color','w')

% ------------------------------
% 数据集1：过渡区(2000-4000)
% ------------------------------
exp_data1 = [
    2000   12  0.062    0.280   0.280   0.281   0.280;
    2200   12  0.068    0.309   0.309   0.309   0.309;
    2400   12  0.074    0.337   0.338   0.337   0.337;
    2600   12  0.081    0.365   0.366   0.367   0.366;
    2800   12  0.087    0.392   0.392   0.392   0.392;
    3000   12  0.093    0.418   0.420   0.420   0.420;
    3200   12  0.099    0.448   0.448   0.449   0.448;
    3400   12  0.105    0.477   0.478   0.477   0.477;
    3600   12  0.112    0.503   0.503   0.502   0.503;
    3800   12  0.118    0.533   0.534   0.533   0.535;
    4000   12  0.124    0.561   0.561   0.561   0.561;
];

theory_data1 = [
 2000       0.062000        0.280481;     
2200       0.068186        0.308468  ;     
2400       0.074374        0.336458   ;    
2600       0.080562        0.364456    ;   
2800       0.086754        0.392465     ;  
3000       0.092948        0.420489      ; 
3200       0.099147        0.448532       ;
3400       0.105351        0.476597       ;
3600       0.111561        0.504688       ;
3800       0.117777        0.532809       ;
4000       0.124000        0.560963   ;
];

% 数据提取与处理
exp_Re1 = exp_data1(:, 1);                    
exp_v_measured1 = exp_data1(:,3);  
D = 0.04; A = pi*(D/2)^2;
theory_v_surface1 = theory_data1(:, 3)/3600/A; 
error_v1 = (exp_v_measured1 - theory_v_surface1)./theory_v_surface1*100;

% ------------------------------
% 数据集2：湍流区(11800-12200)
% ------------------------------
exp_data2 = [
    11800  11.2 0.374   1.694   1.692   1.691   1.692;
    12000  11.2 0.380   1.717   1.719   1.720   1.719;
    12200  11.2 0.387   1.750   1.750   1.751   1.750;
];

theory_data2 = [
 11800      0.375164        1.697200       
12000      0.381651        1.726549       
12200      0.388140        1.755906       

];

exp_Re2 = exp_data2(:, 1);                    
exp_v_measured2 = exp_data2(:,3);  
theory_v_surface2 = theory_data2(:, 3)/3600/A; 
error_v2 = (exp_v_measured2 - theory_v_surface2)./theory_v_surface2*100;

% ------------------------------
% 数据集3：高湍流区(19600-20000)
% ------------------------------
exp_data3 = [
    19600  10.3 0.636   2.880   2.878   2.879   2.879;
    19800  10.3 0.643   2.907   2.908   2.907   2.905;
    20000  10.3 0.649   2.936   2.936   2.935   2.937;
];

theory_data3 = [
    % 19600      0.617674        2.794293;       
    % 19800      0.624088        2.823309;       
    % 20000      0.630504        2.852333;  
    19600      0.629161        2.846257       
19800      0.635695        2.875818       
20000      0.642231        2.905383 
];

exp_Re3 = exp_data3(:, 1);                    
exp_v_measured3 = exp_data3(:,3);  
theory_v_surface3 = theory_data3(:, 3)/3600/A; 
error_v3 = (exp_v_measured3 - theory_v_surface3)./theory_v_surface3*100;

%% 绘制三区域对比图
% 第一行：流速测量值与理论值对比
subplot(2,2,1)
hold on; grid on; box on
p1 = plot(exp_Re1, exp_v_measured1, 'bo-', 'LineWidth',1.5, 'MarkerSize',8, 'MarkerFaceColor','b');
p2 = plot(exp_Re1, theory_v_surface1, 'r--', 'LineWidth',2);
p3 = plot(exp_Re2, exp_v_measured2, 'g^:', 'LineWidth',1.5, 'MarkerSize',8, 'MarkerFaceColor','g');
p4 = plot(exp_Re2, theory_v_surface2, 'm--', 'LineWidth',2);
p5 = plot(exp_Re3, exp_v_measured3, 'ks-.', 'LineWidth',1.5, 'MarkerSize',8, 'MarkerFaceColor','k');
p6 = plot(exp_Re3, theory_v_surface3, 'c--', 'LineWidth',2);
xlabel('雷诺数 Re', 'FontSize',11)
ylabel('流速 (m/s)', 'FontSize',11)
title('(a) 不同流态区流速对比', 'FontSize',12)
legend([p1 p2 p3 p5], {'过渡区测量值','理论值','湍流区测量值','高湍流区测量值'}, 'Location','northwest')

% 第二行：误差分布对比
subplot(2,2,2)
hold on; grid on; box on
bar(exp_Re1, error_v1, 0.6, 'FaceColor',[0.2 0.4 0.8])
bar(exp_Re2, error_v2, 0.6, 'FaceColor',[0.4 0.8 0.2])
bar(exp_Re3, error_v3, 0.6, 'FaceColor',[0.8 0.2 0.4])
yline(0, 'k-', 'LineWidth',1.2)
xlabel('雷诺数 Re', 'FontSize',11)
ylabel('相对误差 (%)', 'FontSize',11)
title('(b) 分区域误差分布', 'FontSize',12)
legend('过渡区','湍流区','高湍流区', 'Location','northwest')
ylim([-4 8])

% 第三行：误差统计箱线图
subplot(2,2,3)
group = [ones(size(error_v1)); 2*ones(size(error_v2)); 3*ones(size(error_v3))];
boxplot([error_v1; error_v2; error_v3], group, 'Labels',{'过渡区','湍流区','高湍流区'})
ylabel('相对误差 (%)', 'FontSize',11)
title('(c) 误差分布统计', 'FontSize',12)
grid on

% 第四行：误差趋势线
subplot(2,2,4)
hold on; grid on; box on
plot(exp_Re1, smooth(error_v1), 'b-', 'LineWidth',2)
plot(exp_Re2, smooth(error_v2), 'g-', 'LineWidth',2)
plot(exp_Re3, smooth(error_v3), 'r-', 'LineWidth',2)
xlabel('雷诺数 Re', 'FontSize',11)
ylabel('平滑误差 (%)', 'FontSize',11)
title('(d) 误差趋势分析', 'FontSize',12)
legend('过渡区','湍流区','高湍流区', 'Location','northwest')
yline(0, 'k--')

%% 输出统计结果
fprintf('=== 各流态区误差统计分析 ===\n');
fprintf('区域       数据点数   平均误差   最大误差\n');
fprintf('----------------------------------------\n');
fprintf('过渡区     %2d        %5.2f%%    %5.2f%%\n', length(error_v1), mean(abs(error_v1)), max(abs(error_v1)));
fprintf('湍流区     %2d        %5.2f%%    %5.2f%%\n', length(error_v2), mean(abs(error_v2)), max(abs(error_v2)));
fprintf('高湍流区   %2d        %5.2f%%    %5.2f%%\n', length(error_v3), mean(abs(error_v3)), max(abs(error_v3)));
fprintf('----------------------------------------\n');
fprintf('综合       %2d        %5.2f%%    %5.2f%%\n', length([error_v1;error_v2;error_v3]), ...
    mean(abs([error_v1;error_v2;error_v3])), max(abs([error_v1;error_v2;error_v3])));
