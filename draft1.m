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
figure
subplot(121)
genresult = GenerateDataPacket('ExamplePicture4.jpg');
if genresult == 1
    disp(['�����ƻ������ݰ������ɹ�!']);
else
    error(['�����ƻ������ݰ�����ʧ��!']);
end
file = fopen('DataPacket.txt');
mytext = textscan(file, '%s');
fclose(file);
temp = mytext{1};
TrData=zeros(1,length(temp{1}));
for i = 1:length(temp{1})
    TrData(i) = temp{1}(i)-48;
end
Signaltr = QAM64_modulation(TrData)';
Itr = real(Signaltr)';
Qtr = imag(Signaltr)';
Signal = repmat(Signaltr, 1600, 1); %�źŸ���
qua = 6;
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
IQinput{SystemObject.getInChannel('RX_LO_FREQ')} = 1.45e9;   %���ն�Ƶ��
IQinput{SystemObject.getInChannel('RX_SAMPLING_FREQ')} = 13e6;   %���ն˲�����
IQinput{SystemObject.getInChannel('RX_RF_BANDWIDTH')} = 20e6;    %���ն˴���
%����ģʽ��'manual'��'slow_attack'��'fast_attack'
IQinput{SystemObject.getInChannel('RX1_GAIN_MODE')} = 'manual';  %�ֶ�
IQinput{SystemObject.getInChannel('RX1_GAIN')} = 2;  %�ڵ���ֱ��ʱ����ѡ2dB
%IQinput{SystemObject.getInChannel('RX1_GAIN_MODE')} = 'fast_attack';  %�Զ�����ģʽ��AGC��
% input{s.getInChannel('RX1_GAIN')} = 0;
IQinput{SystemObject.getInChannel('TX_LO_FREQ')} = 1.45e9;   %���Ͷ�Ƶ��
IQinput{SystemObject.getInChannel('TX_SAMPLING_FREQ')} = 13e6;   %���Ͷ˲�����
IQinput{SystemObject.getInChannel('TX_RF_BANDWIDTH')} = 20e6;    %���Ͷ˴���

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
ReDataChar = num2str(ReData); %���������ݾ���ת��Ϊ�ַ���
ReDataChar(find(isspace(ReDataChar))) = []; %���ַ����е����пո�ȥ��
ImData = imread('myphoto.jpg');
d1 = size(ImData,1);d2 = size(ImData,2);d3 = size(ImData,3);    %ͼƬ���ش�С
BinMatrix = reshape(ReDataChar,8,length(ReData)/8); %ÿ8bitһ�飬�������ݾ�������
DecMatrix = reshape(bin2dec(BinMatrix'),d1,d2,d3);  %������תʮ���ƣ�RGB�ҶȾ�������
subplot(122)  %��RGB�ҶȾ�����ʾͼƬ
imshow(uint8(DecMatrix));
title('��ԭ��ͼƬ','Color','b','FontSize',16);

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



