% %% Description
% % This script predicts the DayAhead Price basing on linear prediction.
% %
% % The prediction function is: y = a2*x2 + a3*x3 + a4*x4 + a5*x5 
% %                                 + a6*x6 + a7*x7 + a8*x8 + a9*x9 
% % for short term prediction:      + a10*x10 + a11*x11 + a12*x12 + a13*x13
% %
% % x coefficient explanation:  
% %   2 LoadPredH(t)          Prediction of the Load
% %   3 GenPredH(t,1)         Prediction of Total Generation
% %   4 GenPredH(t,2)         Prediction of Wind Offshore Generation
% %   5 GenPredH(t,3)         Prediction of Wind Onshore Generation
% %   6 GenPredH(t,4)         Prediction of Photovoltaics Generation
% %   7 MeanPricesRealTDH     Mean Price of Time of Day (12:00)
% %   8 MeanPricesRealWDW     Mean Price of of Weekday (Monday)
% %   9 PricesReal(t-168)     Real Price one Week ago at the same time of day
% %
% %  10 PricesReal(t-1)       Real Price one Hour ago
% %  11 PricesReal(t-1)       Real Price two Hour ago
% %  12 PricesReal(t-1)       Real Price three Hour ago
% 
% 
% %% Initialisation
% MaxDelay=7*24;             % The maximum delay of PricesReal value that are used as input for the prediction. mod(MaxDelay,24) must be 0.
% 
% ShareTrain=0.8;                         % Share of the Training Data Set
% ShareVal=0.0;                           % Share of the Validation Data Set
% ShareTest=1-ShareTrain-ShareVal;        % Share of the Test Data Set
% 
% RangeTrain=[1 floor(length(PricesRealH)*ShareTrain/24)*24];
% RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(PricesRealH)*ShareVal/24)*24];
% RangeTest=[RangeVal(2)+1 length(PricesRealH)];
% 
% for n=1:24                              % Get hourly mean Price for every time of day
%     MeanPricesRealTDH(n,1)=mean(PricesRealH(n:24:RangeTrain(2))); % 00:00 in first row, 23:00 in last row
% end
% for k=1:7                               % Get mean Price for every Weekday
%     temp=[];
%     for n=1:RangeTrain(2)
%       if weekday(TimeH(n))==k
%         temp=[temp;PricesRealH(n)];
%       end
%     end
%     MeanPricesRealWDW(mod(k+5,7)+1,1)=mean(temp);    % Monday in first row
% end
% 
% MeanPricesRealTDHCirc=repmat(MeanPricesRealTDH,ceil((RangeTest(2)-RangeTrain(1)+1)/24),1); % Repeat hourly mean time, thus it is aligned with other Time Series 
% MeanPricesRealTDHCirc=MeanPricesRealTDHCirc(1:RangeTest(2)-RangeTrain(1)+1);
% 
% MeanPricesRealWDWCirc=circshift(MeanPricesRealWDW, 7-weekday(TimeH(MaxDelay))+2); % Shift, thus Weekday at MaxDelay is in first row.
% temp=repmat(MeanPricesRealWDWCirc(1:1:end),1,24)'; %  Now, repeat daily values, thus every 24h of a Day has the same value.
% MeanPricesRealWDWCirc=temp(1:end)';
% MeanPricesRealWDWCirc=repmat(MeanPricesRealWDWCirc,ceil((RangeTest(2)-RangeTrain(1)+1)/24/7),1); % Repeat daily mean values, thus it is aligned with other Time Series
% MeanPricesRealWDWCirc=MeanPricesRealWDWCirc(1:RangeTest(2)-RangeTrain(1)+1);
% 
% 
% %Tried to use less past values but performance decreased. Investigated
% %using last 7 time of day values and last two values but performance was
% %worse.
% ForecastInterval=52;  % The model must be abel to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
% PricesRealDelayedH=zeros(RangeTest(2)-MaxDelay,MaxDelay);
% for n=1:MaxDelay
%     PricesRealDelayedH(:,n)=PricesRealH(RangeTrain(1)+MaxDelay-n:RangeTest(2)-n);    
% end
% for n=1:size(PricesRealDelayedH,1)
%     PricesRealDelayedH(n,:)=PricesRealDelayedH(floor((n-1)/ForecastInterval)*ForecastInterval+1,:);
% end
% 
% xdata  = [LoadPredH(RangeTrain(1)+MaxDelay:end,:), ...
%          GenPredH(RangeTrain(1)+MaxDelay:end,:), ...
%          MeanPricesRealTDHCirc(RangeTrain(1)+MaxDelay:end), ...
%          MeanPricesRealWDWCirc(RangeTrain(1)+MaxDelay:end), ...
%          PricesRealDelayedH(RangeTrain(1):end,:)
%          ];     
% 
% %% Training
% TrainFun = @(a,xdata) sum(a.*xdata, 2);
% LSQCoeffs=ones(1,size(xdata,2));    
% 
% h=waitbar(0, 'Berechne Prognosemodelle');
% for ForecastDuration=0:ForecastInterval-1     % Use evalc to suppress disp of lsqcurvefit
%     LSQCoeffs(ForecastDuration+1,:) = lsqcurvefit(TrainFun,LSQCoeffs(end,:),xdata(RangeTrain(1):RangeTrain(2)-MaxDelay-ForecastDuration,:),PricesRealH(RangeTrain(1)+MaxDelay+ForecastDuration:RangeTrain(2)));
%     waitbar(ForecastDuration/(ForecastInterval-1));
% end

%% Test
PricesPredH=zeros(size(xdata,1)-(RangeTest(1)-MaxDelay)+1,1);
n=RangeTest(1)-MaxDelay;

h=waitbar(0, 'Berechne Prognose');
while n<RangeTest(2)-ForecastInterval-MaxDelay
    xdataInput=xdata(n,:);
    for i=0:ForecastInterval-1        
        PricesPredH(n-RangeTest(1)+MaxDelay+i+1,1)=TrainFun(LSQCoeffs(i+1,:), xdataInput);
    end
    n=n+i+1;    
    waitbar(n/size(xdata1,2))
end 
close(h)

MAE=mean(abs((PricesPredH-PricesRealH(RangeTest(1):RangeTest(2)))));
MSE=mean((PricesPredH-PricesRealH(RangeTest(1):RangeTest(2))).^2);
temp=corrcoef(PricesPredH, PricesRealH(RangeTest(1):RangeTest(2))); 
Corrs=temp(1,2);
LSQCoeffsStand=LSQCoeffs.*std(xdata,1)./std(PricesPredH);



% Succesive prediction: 
% Predict ForecastInterval in a row. Each prediction bases on the
% prediction before. The first prediction is made totally of xdata. With
% each step into the future, one more predicted values is used for the next
% prediction. MSE(ForecastInterval==52)=11.6750 (mean from 1 to 52)

%Tried to use less past values but performance decreased. Investigated
%using last 7 time of day values and last two values but performance was
%worse.
% PricesRealDelayedH=zeros(RangeTest(2)-MaxDelay,MaxDelay);
% for n=1:MaxDelay
%     PricesRealDelayedH(:,n)=PricesRealH(RangeTrain(1)+MaxDelay-n:RangeTest(2)-n);    
% end
% 
% xdata  = [LoadPredH(RangeTrain(1)+MaxDelay:end,:), ...
%          GenPredH(RangeTrain(1)+MaxDelay:end,:), ...
%          MeanPricesRealTDHCirc(RangeTrain(1)+MaxDelay:end), ...
%          MeanPricesRealWDWCirc(RangeTrain(1)+MaxDelay:end), ...
%          PricesRealDelayedH(RangeTrain(1):end,:)
%          ];  

%  ForecastInterval=52;  % The model must be abel to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
%  h=waitbar(0, 'Berechne Prognosemodelle'); 
%  
% %% Training
% TrainFun = @(a,xdata) sum(a.*xdata, 2);
% LSQCoeffs=ones(1,size(xdata,2));    
% 
% LSQCoeffs = lsqcurvefit(TrainFun,LSQCoeffs,xdata(RangeTrain(1):RangeTrain(2)-MaxDelay,:),PricesRealH(RangeTrain(1)+MaxDelay:RangeTrain(2)));
% 
% 
% %% Test
% PricesPredH=zeros(size(xdata,1)-(RangeTest(1)-MaxDelay)+1,1);
% n=RangeTest(1)-MaxDelay;
% while n<RangeTest(2)-ForecastInterval-MaxDelay
%     for i=0:ForecastInterval-1
%         if i>0
%             xdataInput=[xdata(n+i,1:8) PricesPredH(n-RangeTest(1)+MaxDelay+1:n-RangeTest(1)+MaxDelay+i)' xdata(n+i,9+i:end)];
%         else
%             xdataInput=xdata(n,:);
%         end
%         PricesPredH(n-RangeTest(1)+MaxDelay+i+1,1)=TrainFun(LSQCoeffs, xdataInput);
%     end
%     n=n+i+1;
%     waitbar((n-RangeTest(1))/(RangeTest(2)-RangeTest(1)-ForecastInterval))
% end
% 
% MAE(n)=mean(abs((PricesPredH-PricesRealH(RangeTest(1):RangeTest(2)))));
% MSE(n)=mean((PricesPredH-PricesRealH(RangeTest(1):RangeTest(2))).^2);
% temp=corrcoef(PricesPredH, PricesRealH(RangeTest(1):RangeTest(2)));
% Corrs(n)=temp(1,2);
%        
% LSQCoeffsStand=LSQCoeffs.*std(xdata,1)./std(PricesPredH);
% 
% close(h)

