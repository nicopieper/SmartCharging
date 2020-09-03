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

TimeStep=minutes(TimeH(2)-TimeH(1))/60; % H:1, HH: 2, QH: 4
MaxDelay=7*24*TimeStep;
ForecastInterval=52; % 52h  % The model must be able to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
Demonstration=1;

ExecGetSmardData=0;
if ExecGetSmardData
    GetSmardData;
end

ExecDayAhead_Var_Initialisation=1;
if ExecDayAhead_Var_Initialisation
    [PredictorMat, TargetDelayed, TargetCut, TimeCut, RangeTrain, RangeTest]=PredVars(MaxDelay, PricesRealH, TimeH, [LoadPredH, GenPredH, NetExportH]);
end

%% Test function
[Prediction, MAE, MSE] = TestPred({LSQCoeffs, TrainFun, 1; net, Ai, 2}, PredictorMat, TargetDelayed, TargetCut, TimeCut, RangeTest, MaxDelay, ForecastInterval, 10, 1, "Day Ahead Price 1h", 0);

%% Training
[LSQCoeffs, TrainFun] = TrainLSQ(RangeTrain, TargetCut, TargetDelayed, PredictorMat);

%% Test
StartTestAt=RangeTest(1)+10; % Start Test as it was 10:00, so 10:00 will always the time, when the prediction is executed
PricesPredH=zeros(RangeTest(2), 1);
PricesPredMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
PricesRealMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
n=StartTestAt;
k=1;

PricesPredNetH=zeros(RangeTest(2), 1);

if Demonstration
    PricesRealDemoH=-1000*ones(size(TargetCut,1),1);
    PricesRealDemoH(1:n)=TargetCut(1:n);
    ForecastDuration=0;
    i=0;
    
    figure(10)
    cla
    title(['DayAhead Electricity Price ' datestr(TimeCut(n),'dd.mm.yyyy HH:MM')])
    xlabel('Time')
    ylabel('Price [MWh/€]')
    grid on    
    figPredMAE=plot(TimeCut(n-ForecastInterval+ForecastDuration:n+ForecastDuration), PricesPredH(n-ForecastInterval+ForecastDuration:n+ForecastDuration), 'Color', 'b');
    hold on
    figPredANN=plot(TimeCut(n-ForecastInterval+ForecastDuration:n+ForecastDuration), PricesPredNetH(n-ForecastInterval+ForecastDuration:n+ForecastDuration), 'Color', 'g');
    figReal=plot(TimeCut(n-23+i:n+i), PricesRealDemoH(n-23+i:n+i), 'Color', 'r');
    legend('Prediction', 'Real Price')
end

h=waitbar(0, 'Berechne Prognose');
while n<=RangeTest(2)
    for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)
        PredictorMatInput=[PredictorMat(n+ForecastDuration,:), TargetDelayed(n,:)];  
        PricesPredH(n+ForecastDuration,1)=TrainFun(LSQCoeffs(ForecastDuration+1,:), PredictorMatInput);
        
        PredictorMatInput=[num2cell(PredictorMat(n+ForecastDuration,:)',1);{0}];          
        PredictorMatDelayedInput=[num2cell(zeros(size(PredictorMat,2),MaxDelay+ForecastDuration),1); num2cell(TargetDelayed(n-MaxDelay+1:n+ForecastDuration,1))'];        
        [PricesPredNetH(n+ForecastDuration)]=cell2mat(net{ForecastDuration+1}(PredictorMatInput, PredictorMatDelayedInput, Ai))';
        
        PricesPredMatH(ForecastDuration+1,k)=PricesPredH(n+ForecastDuration,1);
        PricesRealMatH(ForecastDuration+1,k)=TargetCut(n+ForecastDuration); % Control matrix for comparison with predicted values   
        
        PricesPredNetDemoH(n+ForecastDuration,1)=PricesPredNetH(n+ForecastDuration,1);
        
        if Demonstration    
            figPredMAE.YDataSource='PricesPredH';        
            figPredMAE.XDataSource='TimeCut';   
            figPredANN.YDataSource='PricesPredNetH';        
            figPredANN.XDataSource='TimeCut';  
            title(['DayAhead Electricity Price & Prediction at ' datestr(TimeCut(n),'dd.mm.yyyy HH:MM')])
            xlim([TimeCut(n-36+max(0,-ForecastInterval+25+ForecastDuration)) TimeCut(n+27+max(0,-ForecastInterval+25+ForecastDuration))])
            ylim([0 80])        
            refreshdata(figPredMAE)
            refreshdata(PricesPredNetH)
            pause(0.1)
        end
    end
    if Demonstration
        for i=0:23
            PricesRealDemoH(n+i)=TargetCut(n+i);
            figReal.YDataSource='PricesRealDemoH';
            figReal.XDataSource='TimeCut';
            title(['DayAhead Electricity Price & Prediction at ' datestr(TimeCut(n+i),'dd.mm.yyyy HH:MM')])
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
temp=corrcoef(PricesPredH(StartTestAt:RangeTest(2)), TargetCut(StartTestAt:RangeTest(2))); 
Corrs=temp(1,2);
% LSQCoeffsStand=LSQCoeffs.*std(PredictorMatInput,1)./std(PricesPredH(StartTestAt:RangeTest(2)));
mean(MAE)

figure(100)
plot(TimeCut(StartTestAt:StartTestAt+ForecastInterval-1),MAE)
xtickformat('HH:mm')
title(['Mean Absolute Error forecasting 1 to ' num2str(ForecastInterval) ' hours'])



% Succesive prediction: 
% Predict ForecastInterval in a row. Each prediction bases on the
% prediction before. The first prediction is made totally of PredictorMat. With
% each step into the future, one more predicted values is used for the next
% prediction. MSE(ForecastInterval=1:52)=11.6750 (mean from 1 to 52)
% For Training, ForecastInterval=1 must be used. For Testing
% ForecastInterval=52.
%
% while n<RangeTest(2)
%     for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)
%         PredictorMatInput=[PredictorMat(n+ForecastDuration,:) PricesPredH(n:n+ForecastDuration-1)' TargetDelayed(n+ForecastDuration,ForecastDuration+1:end)]';%         
%         PricesPredH(n+ForecastDuration,1)=TrainFun(LSQCoeffs, PredictorMatInput);
%
%         PricesPredMatH(ForecastDuration+1,k)=PricesPredH(n+ForecastDuration,1);
%         PricesRealMatH(ForecastDuration+1,k)=TargetCut(n+ForecastDuration); % Control matrix for comparison with predicted values   
%	  end
%     k=k+1;
%     n=n+min(24,ForecastDuration+1);
%     waitbar((n-StartTestAt)/(RangeTest(2)-StartTestAt))
% end

%clearvars opts ForecastDuration k n GetSmardData GetVariables
toc