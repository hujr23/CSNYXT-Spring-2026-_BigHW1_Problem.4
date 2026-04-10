%% 方案一：全系统耦合计算脚本 (基于 CoolProp)
clc; clear;

% --- 1. 基础参数定义 ---
M_total = 100 / 3.6;      % 目标总产量 kg/s
P_flash = 0.1e6;          % 闪蒸压力 (0.1 MPa)
P_target = 0.3e6;         % 目标压力 (0.3 MPa)
T_makeup = 20 + 273.15;   % 补水温度 (20 C)
eta_comp = 0.8;           % 压缩机等熵效率
epsilon_p = 0.8;          % 热泵热力完善度

% --- 2. 末端压缩机与流量平衡计算 ---
% 入口饱和蒸汽 (0.1MPa)
h_g_flash = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_flash, 'Q', 1, 'Water'));
s_g_flash = double(py.CoolProp.CoolProp.PropsSI('S', 'P', P_flash, 'Q', 1, 'Water'));

% 理想等熵出口状态 (0.3MPa)
h_out_s = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'S', s_g_flash, 'Water'));

% 实际出口状态 (过热)
h_out = h_g_flash + (h_out_s - h_g_flash) / eta_comp;

% 目标饱和蒸汽 (0.3MPa) 与 补水状态
h_target_sat = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'Q', 1, 'Water'));
h0 = double(py.CoolProp.CoolProp.PropsSI('H', 'T', T_makeup, 'P', P_target, 'Water'));

% 解约束方程: m1 * h_out + (M_total - m1) * h0 = M_total * h_target_sat
m_steam_1 = M_total * (h_target_sat - h0) / (h_out - h0);
m_steam_2 = M_total - m_steam_1;

% 计算末端功耗 W2 (kW)
W2 = m_steam_1 * (h_out - h_g_flash) / 1000;

% --- 3. 前端热泵计算 (基于 m_steam_1) ---
% 闪蒸罐所需热量 Qc (J/s)
% 注意: 这里假设进入闪蒸罐的补水也是 20C 的水
Qc = m_steam_1 * (h_g_flash - h0); 

% 计算 COP (根据你的推导公式)
% Tpc 为冷凝温度(对应闪蒸压力), Tpe 为蒸发温度(这里取30C)
T_pc = double(py.CoolProp.CoolProp.PropsSI('T', 'P', P_flash, 'Q', 1, 'Water')); % 约 373.15 K
T_pe = 30 + 273.15; % 303.15 K
COP = epsilon_p * (T_pc / (T_pc - T_pe));

% 计算热泵功耗 W1 (kW)
W1 = (Qc / COP) / 1000;

% --- 4. 结果汇总显示 ---
fprintf('--- 流量平衡结果 ---\n');
fprintf('闪蒸蒸汽流量 m_steam_1: %.3f t/h\n', m_steam_1 * 3.6);
fprintf('补水减温流量 m_steam_2: %.3f t/h\n', m_steam_2 * 3.6);
fprintf('--- 功耗计算结果 ---\n');
fprintf('热泵功耗 W1: %.2f kW (COP = %.2f)\n', W1, COP);
fprintf('压缩机功耗 W2: %.2f kW\n', W2);
fprintf('系统总功耗 W_total: %.2f kW\n', W1 + W2);

