%% Description
% This script predicts the DayAhead Price using linear prediction.
%
% The prediction function is: y = sum(a.*x, 2)
%
% x coefficient explanation:  
%       1 LoadPredH(t)          Prediction of the Load
%       2 GenPredH(t,1)         Prediction of Total Generation
%       3 GenPredH(t,2)         Prediction of Wind Offshore Generation
%       4 GenPredH(t,3)         Prediction of Wind Onshore Generation
%       5 GenPredH(t,4)         Prediction of Photovoltaics Generation
%       6 MeanPricesRealTDH     Mean Price of Time of Day (12:00)
%       7 MeanPricesRealWDW     Mean Price of of Weekday (Monday)
%     8-? RealPrices(t-?)       Real DayAhead Price ? hours ago
%
%   ForecastInterval:   Maximum of future hours that are predicted 



%% Initialisation
tic

ExecGetSmardData=0;
if ExecGetSmardData
    GetSmardData;
end

ExecDayAhead_Var_Initialisation=1;
if ExecDayAhead_Var_Initialisation
    DayAhead_Var_Initialisation;
end

ForecastInterval=52; % 52;  % The model must be able to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
opts = optimset('Display','off'); % Suppress disp output of lsqcurvefit function
Demonstration=1;

%% Training
TrainFun = @(a,x) sum(a.*x, 2);
LSQCoeffs=ones(1,size(xdata,2) + size(PricesRealDelayedH,2));    

h=waitbar(0, 'Berechne Prognosemodelle');
for ForecastDuration=0:ForecastInterval-1 % For each hour of ForecastInterval one prediction model is trained. That means there is one model for a one hour prediction, one for a two hour prediction etc.
    xdataInput=[xdata(RangeTrain(1)+ForecastDuration:1:RangeTrain(2),:), PricesRealDelayedH(RangeTrain(1):1:RangeTrain(2)-ForecastDuration,:)]; % Shift the Real Prices such that it fits to the given ForecastDuration
    LSQCoeffs(ForecastDuration+1,:) = lsqcurvefit(TrainFun,LSQCoeffs(end,:),xdataInput,PricesRealCutH(RangeTrain(1)+ForecastDuration:1:RangeTrain(2),:), [], [], opts); % If ForecastDuration==0, then the model for a 1h prediction is trained
    waitbar(ForecastDuration/(ForecastInterval-1));
end
close(h)

%% Test
StartTestAt=RangeTest(1)+10; % Start Test as it was 10:00, so 10:00 will always the time, when the prediction is executed
PricesPredH=zeros(RangeTest(2), 1);
PricesPredMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
PricesRealMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
n=StartTestAt;
k=1;

PricesPredNetH=zeros(RangeTest(2), 1);

if Demonstration
    PricesRealDemoH=zeros(size(PricesRealCutH,1),1);
    PricesRealDemoH(1:n)=PricesRealCutH(1:n);
    ForecastDuration=0;
    i=0;
    
    figure(10)
    cla
    title(['DayAhead Electricity Price ' datestr(TimeCutH(n),'dd.mm.yyyy HH:MM')])
    xlabel('Time')
    ylabel('Price [MWh/€]')
    grid on    
    figPredMAE=plot(TimeCutH(n-ForecastInterval+ForecastDuration:n+ForecastDuration), PricesPredH(n-ForecastInterval+ForecastDuration:n+ForecastDuration), 'Color', 'b');
    hold on
    figPredANN=plot(TimeCutH(n-ForecastInterval+ForecastDuration:n+ForecastDuration), PricesPredNetH(n-ForecastInterval+ForecastDuration:n+ForecastDuration), 'Color', 'g');
    figReal=plot(TimeCutH(n-23+i:n+i), PricesRealDemoH(n-23+i:n+i), 'Color', 'r');
    legend('Prediction', 'Real Price')
end

h=waitbar(0, 'Berechne Prognose');
while n<=RangeTest(2)
    for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)
        xdataInput=[xdata(n+ForecastDuration,:), PricesRealDelayedH(n,:)];  
        PricesPredH(n+ForecastDuration,1)=TrainFun(LSQCoeffs(ForecastDuration+1,:), xdataInput);
        
        xdataInput=[num2cell(xdata(n+ForecastDuration,:)',1);{0}];          
        xdataDelayedInput=[num2cell(zeros(size(xdata,2),MaxDelay+ForecastDuration),1); num2cell(PricesRealDelayedH(n-MaxDelay+1:n+ForecastDuration,1))'];        
        [PricesPredNetH(n+ForecastDuration)]=cell2mat(net{ForecastDuration+1}(xdataInput, xdataDelayedInput, Ai))';
        
        PricesPredMatH(ForecastDuration+1,k)=PricesPredH(n+ForecastDuration,1);
        PricesRealMatH(ForecastDuration+1,k)=PricesRealCutH(n+ForecastDuration); % Control matrix for comparison with predicted values   
        
        PricesPredNetDemoH(n+ForecastDuration,1)=PricesPredNetH(n+ForecastDuration,1);
        
        if Demonstration    
            figPredMAE.YDataSource='PricesPredH';        
            figPredMAE.XDataSource='TimeCutH';   
            figPredANN.YDataSource='PricesPredNetH';        
            figPredANN.XDataSource='TimeCutH';  
            title(['DayAhead Electricity Price & Prediction at ' datestr(TimeCutH(n),'dd.mm.yyyy HH:MM')])
            xlim([TimeCutH(n-36+max(0,-ForecastInterval+25+ForecastDuration)) TimeCutH(n+27+max(0,-ForecastInterval+25+ForecastDuration))])
            ylim([0 80])        
            refreshdata(figPredMAE)
            refreshdata(PricesPredNetH)
            pause(0.1)
        end
    end
    if Demonstration
        for i=0:23
            PricesRealDemoH(n+i)=PricesRealCutH(n+i);
            figReal.YDataSource='PricesRealDemoH';
            figReal.XDataSource='TimeCutH';
            title(['DayAhead Electricity Price & Prediction at ' datestr(TimeCutH(n+i),'dd.mm.yyyy HH:MM')])
            ylim([0 80])        
            refreshdata(figReal)
            pause(0.1)
        end
    end        
    k=k+1;
    n=n+min(24,ForecastDuration+1);
    waitbar((n-StartTestAt)/(RangeTest(2)-StartTestAt))
end 
close(h)

MAE=mean(abs(PricesPredMatH-PricesRealMatH),2); % Mean Absolute Error
MSE=mean((PricesPredMatH-PricesRealMatH).^2,2); % Mean Absolute Error
temp=corrcoef(PricesPredH(StartTestAt:RangeTest(2)), PricesRealCutH(StartTestAt:RangeTest(2))); 
Corrs=temp(1,2);
% LSQCoeffsStand=LSQCoeffs.*std(xdataInput,1)./std(PricesPredH(StartTestAt:RangeTest(2)));
mean(MAE)

figure(100)
plot(TimeCutH(StartTestAt:StartTestAt+ForecastInterval-1),MAE)
xtickformat('HH:mm')
title(['Mean Absolute Error forecasting 1 to ' num2str(ForecastInterval) ' hours'])



% Succesive prediction: 
% Predict ForecastInterval in a row. Each prediction bases on the
% prediction before. The first prediction is made totally of xdata. With
% each step into the future, one more predicted values is used for the next
% prediction. MSE(ForecastInterval=1:52)=11.6750 (mean from 1 to 52)
% For Training, ForecastInterval=1 must be used. For Testing
% ForecastInterval=52.
%
% while n<RangeTest(2)
%     for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)
%         xdataInput=[xdata(n+ForecastDuration,:) PricesPredH(n:n+ForecastDuration-1)' PricesRealDelayedH(n+ForecastDuration,ForecastDuration+1:end)]';%         
%         PricesPredH(n+ForecastDuration,1)=TrainFun(LSQCoeffs, xdataInput);
%
%         PricesPredMatH(ForecastDuration+1,k)=PricesPredH(n+ForecastDuration,1);
%         PricesRealMatH(ForecastDuration+1,k)=PricesRealCutH(n+ForecastDuration); % Control matrix for comparison with predicted values   
%	  end
%     k=k+1;
%     n=n+min(24,ForecastDuration+1);
%     waitbar((n-StartTestAt)/(RangeTest(2)-StartTestAt))
% end

%clearvars opts ForecastDuration k n GetSmardData GetVariables
toc