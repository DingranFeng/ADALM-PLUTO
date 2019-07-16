%%%数据传输%%%
%基于BPSK、QPSK、16-QAM、64-QAM的自适应调制技术，采用块衰落瑞利信道模型
clear all,close all,clc
warning off
format compact
%% 绘制四种调制方式星座图
for i = 1:4
    starmap(i);
end
%% 由图片生成数据包
figure
subplot(121)
genresult = GenerateDataPacket('ExamplePicture.jpg');
if genresult == 1
    disp(['二进制基带数据包创建成功!']);
else
    error(['二进制基带数据包创建失败!']);
end
%% 数据导入和参数设定
file = fopen('DataPacket.txt');
mytext = textscan(file, '%s');
fclose(file);
temp = mytext{1};
TrData=[];
for i = 1:length(temp{1})
    TrData(i) = temp{1}(i)-48;
end
DN = length(TrData);    %总数据量
ReData = -1*ones(1,DN); %接收数据矩阵
Ps = 1;   %平均发射功率
T = 0.1*1e-3;   %符号间隔0.1ms
Tc = 100*1e-3;    %相干时间100ms
symnum = Tc/T;    %每段相干时间内的符号数
datanum = (Tc/T)*[1,2,4,6];   %每段相干时间内的数据量（bit）
Tindex = 0;	%时间头指针
Dindex = 1;	%数据头指针
Ttotal = 0; %传输总时间
SER = 0;   %误码率 
%% 信号传输过程，每一次循环代表一段相干时间
hwait = waitbar(0,'数据传输即将开始...');   %设置进度条
while 1
    SNR_dB = round(40*rand()+5);   %信噪比在5~45dB之间满足均匀分布
    method = JudgeModulationMethod(SNR_dB); %判断调制方式
    SNR = 10^(SNR_dB/10); % 线性信噪比
    sigma2 = Ps/SNR;  %噪声方差
    h=sqrt(0.005/2)*(randn+1j*randn);    %瑞利信道衰减系数

    Dindexp = Dindex+datanum(method)-1; %数据尾指针
    if Dindexp >= DN  %防止指针溢出
        Dindexp = DN;
    end
    if method == 4 && Dindexp == DN %防止最后数组不能被6整除
        method = method - 1;
    end
    Tindexp = Tindex+Tc*(Dindexp-Dindex)/datanum(method);   %时间尾指针
    
    %调制、通过信道、解调
    if method == 1
        x = BPSK_modulation(TrData(Dindex:Dindexp));    %发射的信号
        w = sqrt(sigma2/2)*(randn(1,length(x))+1j*randn(1,length(x)));    %生成的噪声
        y = x*(1+h)+w;  %接收的信号
        ReData(Dindex:Dindexp) = BPSK_demodulation(y);  %解调映射到二进制数据
    elseif method == 2
        x = QPSK_modulation(TrData(Dindex:Dindexp));
        w=sqrt(sigma2/2)*(randn(1,length(x))+1j*randn(1,length(x)));
        y = x*(1+h)+w;
        ReData(Dindex:Dindexp) = QPSK_demodulation(y);
    elseif method == 3
        x = QAM16_modulation(TrData(Dindex:Dindexp));
        w = sqrt(sigma2/2)*(randn(1,length(x))+1j*randn(1,length(x)));
        y = x*(1+h)+w;
        ReData(Dindex:Dindexp) = QAM16_demodulation(y);
    else
        x = QAM64_modulation(TrData(Dindex:Dindexp));
        w = sqrt(sigma2/2)*(randn(1,length(x))+1j*randn(1,length(x)));
        y = x*(1+h)+w;
        ReData(Dindex:Dindexp) = QAM64_demodulation(y);
    end
    
    %进度条重置
    ProgressRate = Dindexp/DN;  %传输进度
    if ProgressRate < 0.1
    elseif ProgressRate < 0.9
        waitbar(Dindexp/DN,hwait,['数据已传输 ',num2str(round(100*ProgressRate)),'%, 请稍后...']);
    elseif ProgressRate < 1.0
        waitbar(Dindexp/DN,hwait,'数据传输即将完成...');
    elseif ProgressRate >= 1.0
        close(hwait);
    end
    
    %时间指针与数据指针重置
    Tindex = Tindexp;
    Dindex = Dindexp+1;
    if Dindex > DN  %信号处理结束判断
        Ttotal = Tindex;
        break;
    end
end
%% 检测接收结果
if ReData(DN) ~= -1
    disp('数据传输成功！');
    disp('正在进行图片还原及数据统计......');
else
    error('数据传输失败！请重新传输数据');
end
%% 由接收数据还原图片
ReDataChar = num2str(ReData); %将接收数据矩阵转化为字符串
ReDataChar(find(isspace(ReDataChar))) = []; %将字符串中的所有空格去掉
ImData = imread('myphoto.jpg');
d1 = size(ImData,1);d2 = size(ImData,2);d3 = size(ImData,3);    %图片像素大小
BinMatrix = reshape(ReDataChar,8,length(ReData)/8); %每8bit一组，接收数据矩阵重排
DecMatrix = reshape(bin2dec(BinMatrix'),d1,d2,d3);  %二进制转十进制，RGB灰度矩阵重排
subplot(122)  %由RGB灰度矩阵显示图片
imshow(uint8(DecMatrix));
title('还原的图片','Color','b','FontSize',16);
%% 计算误码率和传输总时间
s = 0; %误码计数变量
for i = 1:DN
    if TrData(i) ~= ReData(i)
        s = s+1;
    end
end
SER = s/DN;
disp(['误码率为  ',num2str(SER*100),'  %']);
disp(['传输总时间为  ',num2str(Ttotal),'  s']);