%% 方案一：0.6 MPa 目标工质全系统耦合计算
clc; clear;

% --- 1. 基础参数定义 ---
M_total = 100 / 3.6;      % 目标总产量 kg/s (100 t/h)
P_flash = 0.1e6;          % 闪蒸压力 (0.1 MPa 绝压)
P_target = 0.6e6;         % 目标压力 (修改为 0.6 MPa)
T_makeup = 20 + 273.15;   % 补水温度 (20 C)
eta_comp = 0.8;           % 压缩机等熵效率
epsilon_p = 0.8;          % 热泵热力完善度

% --- 2. 物性查询 (0.1MPa & 0.6MPa) ---
% 0.1MPa 饱和蒸汽 (入口)
h_g_flash = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_flash, 'Q', 1, 'Water'));
s_g_flash = double(py.CoolProp.CoolProp.PropsSI('S', 'P', P_flash, 'Q', 1, 'Water'));

% 0.6MPa 等熵出口与实际出口
h_out_s = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'S', s_g_flash, 'Water'));
h_out = h_g_flash + (h_out_s - h_g_flash) / eta_comp;

% 0.6MPa 目标饱和蒸汽与补水
h_target_sat = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'Q', 1, 'Water'));
h0 = double(py.CoolProp.CoolProp.PropsSI('H', 'T', T_makeup, 'P', P_target, 'Water'));

% --- 3. 流量平衡求解 (关键：补水量会随 P_target 增大而增大) ---
% 方程: m1*h_out + (M_total - m1)*h0 = M_total * h_target_sat
m_steam_1 = M_total * (h_target_sat - h0) / (h_out - h0);
m_steam_2 = M_total - m_steam_1;

% --- 4. 功耗计算 ---
% 末端压缩机功耗 W2 (kW)
W2 = m_steam_1 * (h_out - h_g_flash) / 1000;

% 前端热泵功耗 W1 (kW)
Qc = m_steam_1 * (h_g_flash - h0); 
T_pc = double(py.CoolProp.CoolProp.PropsSI('T', 'P', P_flash, 'Q', 1, 'Water')); 
T_pe = 30 + 273.15; 
COP = epsilon_p * (T_pc / (T_pc - T_pe));
W1 = (Qc / COP) / 1000;

% --- 5. 打印结果给 LaTeX 使用 ---
fprintf('--- 0.6 MPa 流量平衡结果 --\n');
fprintf('闪蒸蒸汽流量 m_steam_1: %.3f t/h\n', m_steam_1 * 3.6);
fprintf('补水减温流量 m_steam_2: %.3f t/h\n', m_steam_2 * 3.6);
fprintf('--- 功耗计算结果 ---\n');
fprintf('热泵功耗 W1: %.2f kW (COP = %.2f)\n', W1, COP);
fprintf('压缩机功耗 W2: %.2f kW\n', W2);
fprintf('系统总功耗 W_total: %.2f kW\n', W1 + W2);