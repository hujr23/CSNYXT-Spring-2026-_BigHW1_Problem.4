%% 最佳闪蒸压力寻优 - 坐标修正与数值标注版
clc; clear;

M_total_kg_s = 100 / 3.6; 
T0 = 20 + 273.15;    
dT_sub = 5;          

P_f_range = linspace(0.2e5, 2.8e5, 100); 

% 热力完善度拟合
dT_pts = [35, 65, 80, 95];
eps_pts = [0.9, 0.85, 0.8, 0.5];
p_eps = polyfit(dT_pts, eps_pts, 2);
get_eps = @(dT) min(0.9, max(0.1, polyval(p_eps, dT)));

P_targets = [0.3e6, 0.6e6];
results = cell(2,2); 

for pt_idx = 1:2
    Pt = P_targets(pt_idx);
    hg_t = double(py.CoolProp.CoolProp.PropsSI('H', 'P', Pt, 'Q', 1, 'Water'));
    h0_t = double(py.CoolProp.CoolProp.PropsSI('H', 'T', T0, 'P', Pt, 'Water'));
    
    for scheme = 1:2
        W_vec = NaN(size(P_f_range));
        for i = 1:length(P_f_range)
            Pf = P_f_range(i);
            try
                % 引入压比相关的效率衰减
                pr = Pt / Pf;
                eta_eff = max(0.45, 0.85 - 0.025 * pr); 
                
                Tf = double(py.CoolProp.CoolProp.PropsSI('T', 'P', Pf, 'Q', 1, 'Water'));
                hg_f = double(py.CoolProp.CoolProp.PropsSI('H', 'P', Pf, 'Q', 1, 'Water'));
                sg_f = double(py.CoolProp.CoolProp.PropsSI('S', 'P', Pf, 'Q', 1, 'Water'));
                
                h2s = double(py.CoolProp.CoolProp.PropsSI('H', 'P', Pt, 'S', sg_f, 'Water'));
                h_out = hg_f + (h2s - hg_f) / eta_eff;
                
                m1 = M_total_kg_s * (hg_t - h0_t) / (h_out - h0_t);
                W2 = m1 * (h_out - hg_f);
                
                Tpc = Tf + dT_sub;
                h0_f = double(py.CoolProp.CoolProp.PropsSI('H', 'T', T0, 'P', Pf, 'Water'));
                Q_h = m1 * (hg_f - h0_f);
                
                if scheme == 1
                    dT = Tpc - (30+273.15);
                    W1 = Q_h / (get_eps(dT) * Tpc / dT);
                else
                    % 方案2：增加 COP 物理上限限制 (10.0) 以防数值虚高
                    Tpe_list = [75, 45, 15] + 273.15;
                    m_r = [0.5, 0.3, 0.2]; W1 = 0;
                    for k = 1:3
                        dTk = Tpc - Tpe_list(k);
                        COP_k = min(10.0, get_eps(dTk) * Tpc / dTk);
                        W1 = W1 + (Q_h * m_r(k)) / COP_k;
                    end
                end
                W_vec(i) = (W1 + W2) / 1000;
            catch
            end
        end
        results{pt_idx, scheme} = W_vec;
    end
end

% --- 绘图逻辑 ---
figure('Color', 'w', 'Position', [100, 100, 900, 650]);
hold on; grid on; box on;

line_styles = {'-', '--'}; % 实线:0.3MPa, 虚线:0.6MPa
scheme_colors = {'r', 'b'}; % 红色:方案1, 蓝色:方案2
labels = {'方案1-0.3MPa', '方案2-0.3MPa', '方案1-0.6MPa', '方案2-0.6MPa'};
h_lines = [];

for pt_i = 1:2
    for sc_i = 1:2
        y_data = results{pt_i, sc_i};
        h = plot(P_f_range/1e5, y_data, 'Color', scheme_colors{sc_i}, ...
                 'LineStyle', line_styles{pt_i}, 'LineWidth', 2);
        h_lines = [h_lines, h];
        
        % 寻找并标注最小值
        [minW, minIdx] = min(y_data);
        if ~isnan(minW)
            plot(P_f_range(minIdx)/1e5, minW, 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 6);
            text(P_f_range(minIdx)/1e5, minW + 800, sprintf('%.1f kW', minW), ...
                 'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
        end
    end
end

% 强制 Y 轴从 0 开始
ylim([0, 45000]); 
xlim([0.2, 2.8]);

xlabel('闪蒸压力 P_{flash} (bar)', 'FontSize', 12);
ylabel('总功耗 W_{total} (kW)', 'FontSize', 12);
title('系统总功耗与闪蒸压力的关系', 'FontSize', 14);
legend(h_lines, labels, 'Location', 'northeast');

