%% 水物性参数查找脚本 (基于 CoolProp)
% 适用环境：已安装 Python 及 CoolProp 库
clc; clear;

fprintf('==============================================\n');
fprintf('       水/水蒸气物性参数查找工具 (IAPWS-IF97)\n');
fprintf('==============================================\n\n');

% --- 1. 设置查找参数 (示例：0.1 MPa 饱和蒸汽) ---
% 单位说明：压力 [Pa], 温度 [K], 焓 [J/kg], 熵 [J/kg.K]
P_target = 0.1e6; % 0.1 MPa
Q_target = 1;     % 干度 (0: 饱和液, 1: 饱和蒸汽)

try
    % --- 2. 调用 CoolProp 进行查找 ---
    % 查找温度 (K)
    T = double(py.CoolProp.CoolProp.PropsSI('T', 'P', P_target, 'Q', Q_target, 'Water'));
    
    % 查找比焓 (J/kg) -> 换算为 kJ/kg
    h = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P_target, 'Q', Q_target, 'Water')) / 1000;
    
    % 查找比熵 (J/kg.K) -> 换算为 kJ/(kg.K)
    s = double(py.CoolProp.CoolProp.PropsSI('S', 'P', P_target, 'Q', Q_target, 'Water')) / 1000;
    
    % 查找密度 (kg/m3)
    rho = double(py.CoolProp.CoolProp.PropsSI('D', 'P', P_target, 'Q', Q_target, 'Water'));

    % --- 3. 输出结果 ---
    fprintf('输入参数：压力 P = %.3f MPa, 干度 Q = %.1f\n', P_target/1e6, Q_target);
    fprintf('----------------------------------------------\n');
    fprintf('饱和温度 T:   %10.2f °C  (%10.2f K)\n', T - 273.15, T);
    fprintf('比焓 h:       %10.2f kJ/kg\n', h);
    fprintf('比熵 s:       %10.4f kJ/(kg.K)\n', s);
    fprintf('密度 rho:     %10.2f kg/m^3\n', rho);
    fprintf('----------------------------------------------\n');

catch ME
    error('CoolProp 调用失败，请检查 Python 路径或库安装情况。错误信息：%s', ME.message);
end

%% --- 4. 常用物性查询函数封装 (可直接复制到其他脚本末尾) ---
% 使用方法示例：h = get_h_PT(0.3e6, 200); % 查 0.3MPa, 200C 的焓

function h = get_h_PT(P, T_cel)
    % 输入压力(Pa)和温度(摄氏度)，返回比焓(kJ/kg)
    h = double(py.CoolProp.CoolProp.PropsSI('H', 'P', P, 'T', T_cel + 273.15, 'Water')) / 1000;
end

function s = get_s_PQ(P, Q)
    % 输入压力(Pa)和干度(0-1)，返回比熵(kJ/kg.K)
    s = double(py.CoolProp.CoolProp.PropsSI('S', 'P', P, 'Q', Q, 'Water')) / 1000;
end

function T = get_T_sat(P)
    % 输入压力(Pa)，返回饱和温度(摄氏度)
    T = double(py.CoolProp.CoolProp.PropsSI('T', 'P', P, 'Q', 1, 'Water')) - 273.15;
end