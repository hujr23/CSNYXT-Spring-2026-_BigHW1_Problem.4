%% 方案二：多级热泵 + 末端压缩机 (0.3MPa / 0.6MPa 可调)
clc; clear;

% --- 1. 基础参数与末端流量平衡 ---
M_total = 100 / 3.6;      
P_flash = 0.1e6;          
P_target = 0.6e6;         % 如需计算0.6MPa，改为 0.6e6
T_makeup = 20 + 273.15;   
eta_comp = 0.8;           

h_g_flash = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_flash, 'Q', 1, 'Water'));
s_g_flash = double(py.CoolProp.CoolProp.PropsSI('S', 'P', P_flash, 'Q', 1, 'Water'));
h_out_s = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'S', s_g_flash, 'Water'));
h_out = h_g_flash + (h_out_s - h_g_flash) / eta_comp;
h_target_sat = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'Q', 1, 'Water'));
h0 = double(py.CoolProp.CoolProp.PropsSI('H', 'T', T_makeup, 'P', P_target, 'Water'));

% 计算耦合补水后的总闪蒸产汽任务 m_steam_1
m_steam_1 = M_total * (h_target_sat - h0) / (h_out - h0);
W2 = m_steam_1 * (h_out - h_g_flash) / 1000; % 末端压缩功耗 (kW)

% --- 2. 方案二：分级热泵计算 (110C 冷凝基准) ---
m_ratio = [0.5, 0.3, 0.2]; % 5:3:2 流量分配
m_i = m_steam_1 * m_ratio; 

T_pc = 110 + 273.15;               
T_l_out = [80, 50, 20];            
T_pe_list = T_l_out - 5 + 273.15;  

% 完善度逻辑：温差越小，完善度越高
epsilon_p_list = [0.90, 0.85, 0.5]; 

W1_list = zeros(1,3);
COP_list = zeros(1,3);

for i = 1:3
    COP_list(i) = epsilon_p_list(i) * (T_pc / (T_pc - T_pe_list(i)));
    Qi = m_i(i) * (h_g_flash - h0); 
    W1_list(i) = (Qi / COP_list(i)) / 1000;
end

W1_total = sum(W1_list);

% --- 3. 简化结果输出 ---
fprintf('--- 方案二 (P_target = %.1f MPa) 计算结果 ---\n', P_target/1e6);
fprintf('【流量分布】\n');
fprintf('分级闪蒸流量 m1: %.3f, m2: %.3f, m3: %.3f (t/h)\n', m_i(1)*3.6, m_i(2)*3.6, m_i(3)*3.6);
fprintf('总闪蒸蒸汽流量 m_steam_1: %.3f t/h\n', m_steam_1 * 3.6);
fprintf('补水减温流量   m_steam_2: %.3f t/h\n', (M_total - m_steam_1) * 3.6);

fprintf('\n【功耗分布】\n');
fprintf('各级 COP: [%.2f, %.2f, %.2f]\n', COP_list);
fprintf('热泵总功耗 W1: %.2f kW\n', W1_total);
fprintf('压缩机功耗 W2: %.2f kW\n', W2);
fprintf('系统总功耗 W_total: %.2f kW\n', W1_total + W2);