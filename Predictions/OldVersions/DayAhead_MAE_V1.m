%% Description
% This script predicts the DayAhead Price basing on linear prediction.
%
% The prediction function is: y = a1 + a2*x2 + a3*x3 + a4*x4 + a5*x5 
%                                 + a6*x6 + a7*x7 + a8*x8 + a9*x9 
% for short term prediction:      + a10*x10 + a11*x11 + a12*x12 + a13*x13
%
% x coefficient explanation:  
%   2 LoadPredH(t)          Prediction of the Load
%   3 GenPredH(t,1)         Prediction of Total Generation
%   4 GenPredH(t,2)         Prediction of Wind Offshore Generation
%   5 GenPredH(t,3)         Prediction of Wind Onshore Generation
%   6 GenPredH(t,4)         Prediction of Photovoltaics Generation
%   7 MeanPricesRealTDH     Mean Price of Time of Day (12:00)
%   8 MeanPricesRealWDW     Mean Price of of Weekday (Monday)
%   9 PricesReal(t-168)     Real Price one Week ago at the same time of day
%
%  10 PricesReal(t-1)       Real Price one Hour ago
%  11 PricesReal(t-1)       Real Price two Hour ago
%  12 PricesReal(t-1)       Real Price three Hour ago


%% Initialisation
MaxDelay=168;             % The maximum delay of PricesReal value that are used as input for the prediction. mod(MaxDelay,24) must be 0.

ShareTrain=0.8;                         % Share of the Training Data Set
ShareVal=0.0;                           % Share of the Validation Data Set
ShareTest=1-ShareTrain-ShareVal;        % Share of the Test Data Set

RangeTrain=[1 floor(length(PricesRealH)*ShareTrain/24)*24];
RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(PricesRealH)*ShareVal/24)*24];
RangeTest=[RangeVal(2)+1 length(PricesRealH)];

a=ones(13,1);

for n=1:24                              % Get hourly mean Price for every time of day
    MeanPricesRealTDH(n,1)=mean(PricesRealH(n:24:RangeTrain(2))); % 00:00 in first row, 23:00 in last row
end
for k=1:7                               % Get mean Price for every Weekday
    temp=[];
    for n=1:RangeTrain(2)
      if weekday(TimeH(n))==k
        temp=[temp;PricesRealH(n)];
      end
    end
    MeanPricesRealWDW(mod(k+5,7)+1,1)=mean(temp);    % Monday in first row
end

MeanPricesRealTDHCirc=repmat(MeanPricesRealTDH,ceil((RangeTest(2)-RangeTrain(1)+1)/24),1); % Repeat hourly mean time, thus it is aligned with other Time Series 
MeanPricesRealTDHCirc=MeanPricesRealTDHCirc(1:RangeTest(2)-RangeTrain(1)+1);

MeanPricesRealWDWCirc=circshift(MeanPricesRealWDW, 7-weekday(TimeH(MaxDelay))+2); % Shift, thus Weekday at MaxDelay is in first row.
temp=repmat(MeanPricesRealWDWCirc(1:1:end),1,24)'; %  Now, repeat daily values, thus every 24h of a Day has the same value.
MeanPricesRealWDWCirc=temp(1:end)';
MeanPricesRealWDWCirc=repmat(MeanPricesRealWDWCirc,ceil((RangeTest(2)-RangeTrain(1)+1)/24/7),1); % Repeat daily mean values, thus it is aligned with other Time Series
MeanPricesRealWDWCirc=MeanPricesRealWDWCirc(1:RangeTest(2)-RangeTrain(1)+1);

%% Training
PricesRealDelayedH=zeros(RangeTrain(2)-MaxDelay,MaxDelay);
for n=1:MaxDelay
    PricesRealDelayedH(:,n)=PricesRealH(RangeTrain(1)+MaxDelay-n:RangeTrain(2)-n);    
end

xdataTrain = [LoadPredH(RangeTrain(1)+MaxDelay:RangeTrain(2),:), ...
         GenPredH(RangeTrain(1)+MaxDelay:RangeTrain(2),:), ...
         MeanPricesRealTDHCirc(RangeTrain(1)+MaxDelay:RangeTrain(2)), ... 
         MeanPricesRealWDWCirc(RangeTrain(1)+MaxDelay:RangeTrain(2)), ...         
         PricesRealH(RangeTrain(1):RangeTrain(2)-MaxDelay), ...
         PricesRealH(RangeTrain(1)+MaxDelay-1:RangeTrain(2)-1), ...
         PricesRealH(RangeTrain(1)+MaxDelay-2:RangeTrain(2)-2), ...
         PricesRealH(RangeTrain(1)+MaxDelay-3:RangeTrain(2)-3), ...
         ];

TrainFun = @(a,xdata)...
           a(1) + a(2)*xdata(:,1) + a(3)*xdata(:,2) + a(4)*xdata(:,3) ...
           + a(5)*xdata(:,4) + a(6)*xdata(:,5) + a(7)*xdata(:,6) ...
           + a(8)*xdata(:,7) + a(9)*xdata(:,8) + a(10)*xdata(:,9);% ...
           %+ a(11)*xdata(:,10) + a(12)*xdata(:,11) + a(13)*xdata(:,12);
       
y = lsqcurvefit(TrainFun,a,xdataTrain,PricesRealH(RangeTrain(1)+MaxDelay:RangeTrain(2)));


%% Test
xdataTest = [LoadPredH(RangeTest(1)+MaxDelay:RangeTest(2),:), ...
         GenPredH(RangeTest(1)+MaxDelay:RangeTest(2),:), ...
         MeanPricesRealTDHCirc(RangeTest(1)+MaxDelay:RangeTest(2)), ... 
         MeanPricesRealWDWCirc(RangeTest(1)+MaxDelay:RangeTest(2)), ...         
         PricesRealH(RangeTest(1):RangeTest(2)-MaxDelay), ...
         PricesRealH(RangeTest(1)+MaxDelay-1:RangeTest(2)-1), ...
         PricesRealH(RangeTest(1)+MaxDelay-2:RangeTest(2)-2), ...
         PricesRealH(RangeTest(1)+MaxDelay-3:RangeTest(2)-3), ...
         ];

test=TrainFun(y, xdataTest);

MAE=mean(abs((test-PricesRealH(RangeTest(1)+MaxDelay:RangeTest(2)))))
MSE=mean((test-PricesRealH(RangeTest(1)+MaxDelay:RangeTest(2))).^2)


%clearvars temp ShareTrain ShareVal ShareTest TrainRange ValRange TestRange MaxDelay

