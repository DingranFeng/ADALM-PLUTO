%%%

clearvars -except times;close all;clc
warning off
format compact
%% 添加相关库至当前文件夹
addpath D:\若干项文件\16021052冯鼎然资料...
    \学习资料\综合创新数字通信\例程\example\library

%% 设置IP地址
ip = '192.168.2.1';
%% 产生基带信号
TrData = round(rand(1,360));
Signaltr = QAM64_modulation(TrData)';
Itr = real(Signaltr)';
Qtr = imag(Signaltr)';
Signal = repmat(Signaltr, 3600, 1); %信号复制
qua = 16;
Signal = round(Signal .* 2^(qua-1)); %待发送数据，进行qua个比特的量化
%% 配置系统对象
SystemObject = iio_sys_obj_matlab; %创建libiio系统对象
SystemObject.ip_address = ip;
SystemObject.dev_name = 'ad9361';
SystemObject.in_ch_no = 2;
SystemObject.out_ch_no = 2;
SystemObject.in_ch_size = length(Signal);  %接收通路
SystemObject.out_ch_size = length(Signal)*qua; %发送通路
SystemObject = SystemObject.setupImpl();  %初始化系统对象（类似构造函数）
IQinput = cell(1, SystemObject.in_ch_no + length(SystemObject.iio_dev_cfg.cfg_ch)); %发送的I、Q路信号
IQoutput = cell(1, SystemObject.out_ch_no + length(SystemObject.iio_dev_cfg.mon_ch)); %接收的I、Q路信号

%% 设置AD9361属性
temp1 = 1.45e7;
temp2 = 40e6;
temp3 = 20e6;

IQinput{SystemObject.getInChannel('RX_LO_FREQ')} = temp1;   %接收端频点
IQinput{SystemObject.getInChannel('RX_SAMPLING_FREQ')} = temp2;   %接收端采样率
IQinput{SystemObject.getInChannel('RX_RF_BANDWIDTH')} = temp3;    %接收端带宽
%增益模式：'manual'、'slow_attack'、'fast_attack'
IQinput{SystemObject.getInChannel('RX1_GAIN_MODE')} = 'manual';  %手动
IQinput{SystemObject.getInChannel('RX1_GAIN')} = 2;  %在单板直连时增益选2dB
%IQinput{SystemObject.getInChannel('RX1_GAIN_MODE')} = 'fast_attack';  %自动增益模式（AGC）
% input{s.getInChannel('RX1_GAIN')} = 0;
IQinput{SystemObject.getInChannel('TX_LO_FREQ')} = temp1;   %发送端频点
IQinput{SystemObject.getInChannel('TX_SAMPLING_FREQ')} = temp2;   %发送端采样率
IQinput{SystemObject.getInChannel('TX_RF_BANDWIDTH')} = temp3;    %发送端带宽

%% 重复发送4次数据
for i=1:4
    fprintf('正在进行第 %i 次数据传输...\n',i);
    IQinput{1} = real(Signal);    %基带数据I路
    IQinput{2} = imag(Signal);    %基带数据Q路
    IQoutput = stepImpl(SystemObject, IQinput); %计算输出并更新对象的状态值，用于数据收发
end
fprintf('数据传输接收完成！\n');
Ire = IQoutput{1};
Qre = IQoutput{2};
Signalre = Ire+1i*Qre;
ReData = QAM64_demodulation(Signalre');


figure
subplot(221);   %发送端的两路信号
title("发送端I、Q信号")
plot(Itr);
hold on;
plot(Qtr);
hold off
subplot(222);   %接收端的两路信号
title("接收端I、Q信号")
plot(Ire);
hold on;
plot(Qre);
hold off
subplot(223);   %星座图
title("星座图")
plot(Ire, Qre, 'b');
axis square;
grid
subplot(224);   %频谱图
title("频谱图")
pwelch(Signalre, [],[],[], 40e6, 'centered', 'psd');
grid
%% 读取接收信号强度指标，用于判断是否应增大发射强度
rssi1 = IQoutput{SystemObject.getOutChannel('RX1_RSSI')}
%rssi2 = output{s.getOutChannel('RX2_RSSI')};
SystemObject.releaseImpl();    %释放系统对象（类似析构函数）



