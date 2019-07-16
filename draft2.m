%%%

clearvars -except times;close all;clc
warning off
format compact
%% �����ؿ�����ǰ�ļ���
addpath D:\�������ļ�\16021052�붦Ȼ����...
    \ѧϰ����\�ۺϴ�������ͨ��\����\example\library

%% ����IP��ַ
ip = '192.168.2.1';
%% ���������ź�
TrData = round(rand(1,360));
Signaltr = QAM64_modulation(TrData)';
Itr = real(Signaltr)';
Qtr = imag(Signaltr)';
Signal = repmat(Signaltr, 3600, 1); %�źŸ���
qua = 16;
Signal = round(Signal .* 2^(qua-1)); %���������ݣ�����qua�����ص�����
%% ����ϵͳ����
SystemObject = iio_sys_obj_matlab; %����libiioϵͳ����
SystemObject.ip_address = ip;
SystemObject.dev_name = 'ad9361';
SystemObject.in_ch_no = 2;
SystemObject.out_ch_no = 2;
SystemObject.in_ch_size = length(Signal);  %����ͨ·
SystemObject.out_ch_size = length(Signal)*qua; %����ͨ·
SystemObject = SystemObject.setupImpl();  %��ʼ��ϵͳ�������ƹ��캯����
IQinput = cell(1, SystemObject.in_ch_no + length(SystemObject.iio_dev_cfg.cfg_ch)); %���͵�I��Q·�ź�
IQoutput = cell(1, SystemObject.out_ch_no + length(SystemObject.iio_dev_cfg.mon_ch)); %���յ�I��Q·�ź�

%% ����AD9361����
temp1 = 1.45e7;
temp2 = 40e6;
temp3 = 20e6;

IQinput{SystemObject.getInChannel('RX_LO_FREQ')} = temp1;   %���ն�Ƶ��
IQinput{SystemObject.getInChannel('RX_SAMPLING_FREQ')} = temp2;   %���ն˲�����
IQinput{SystemObject.getInChannel('RX_RF_BANDWIDTH')} = temp3;    %���ն˴���
%����ģʽ��'manual'��'slow_attack'��'fast_attack'
IQinput{SystemObject.getInChannel('RX1_GAIN_MODE')} = 'manual';  %�ֶ�
IQinput{SystemObject.getInChannel('RX1_GAIN')} = 2;  %�ڵ���ֱ��ʱ����ѡ2dB
%IQinput{SystemObject.getInChannel('RX1_GAIN_MODE')} = 'fast_attack';  %�Զ�����ģʽ��AGC��
% input{s.getInChannel('RX1_GAIN')} = 0;
IQinput{SystemObject.getInChannel('TX_LO_FREQ')} = temp1;   %���Ͷ�Ƶ��
IQinput{SystemObject.getInChannel('TX_SAMPLING_FREQ')} = temp2;   %���Ͷ˲�����
IQinput{SystemObject.getInChannel('TX_RF_BANDWIDTH')} = temp3;    %���Ͷ˴���

%% �ظ�����4������
for i=1:4
    fprintf('���ڽ��е� %i �����ݴ���...\n',i);
    IQinput{1} = real(Signal);    %��������I·
    IQinput{2} = imag(Signal);    %��������Q·
    IQoutput = stepImpl(SystemObject, IQinput); %������������¶����״ֵ̬�����������շ�
end
fprintf('���ݴ��������ɣ�\n');
Ire = IQoutput{1};
Qre = IQoutput{2};
Signalre = Ire+1i*Qre;
ReData = QAM64_demodulation(Signalre');


figure
subplot(221);   %���Ͷ˵���·�ź�
title("���Ͷ�I��Q�ź�")
plot(Itr);
hold on;
plot(Qtr);
hold off
subplot(222);   %���ն˵���·�ź�
title("���ն�I��Q�ź�")
plot(Ire);
hold on;
plot(Qre);
hold off
subplot(223);   %����ͼ
title("����ͼ")
plot(Ire, Qre, 'b');
axis square;
grid
subplot(224);   %Ƶ��ͼ
title("Ƶ��ͼ")
pwelch(Signalre, [],[],[], 40e6, 'centered', 'psd');
grid
%% ��ȡ�����ź�ǿ��ָ�꣬�����ж��Ƿ�Ӧ������ǿ��
rssi1 = IQoutput{SystemObject.getOutChannel('RX1_RSSI')}
%rssi2 = output{s.getOutChannel('RX2_RSSI')};
SystemObject.releaseImpl();    %�ͷ�ϵͳ������������������



