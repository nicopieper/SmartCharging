%% Description
% This script predicts the DayAhead Price using the Neural Net Time Series
% toolbox.
%   ForecastInterval:   Maximum of future hours that are predicted 

%% Initialisation
ExecGetSmardData=0;
if ExecGetSmardData
    GetSmardData;
end

ExecDayAhead_Var_Initialisation=0;
if ExecDayAhead_Var_Initialisation
    DayAhead_Var_Initialisation;
end

ForecastInterval=52; % 52;  % The model must be able to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
%MAE=zeros(ForecastInterval,1);
StartTestAt=RangeTest(1)+10; % Start Test as it was 10:00, so 10:00 will always the time, when the prediction is executed
xdataInput=num2cell(xdata(RangeTrain(1):RangeTrain(2),:)',1);
ydataInput=num2cell(PricesRealCutH(RangeTrain(1):RangeTrain(2),:)');
net={zeros(ForecastInterval)};

%% Training
h=waitbar(0, 'Berechne Prognosemodelle');
for ForecastDuration=0:ForecastInterval-1
    net{ForecastDuration+1} = narxnet(0,1+ForecastDuration:MaxDelay+ForecastDuration,10);   
    net{ForecastDuration+1}.inputs{1,1}.processFcns={};
    [Xs,Xi,Ai,Ts] = preparets(net{ForecastDuration+1},xdataInput,{},ydataInput);
    net{ForecastDuration+1} = train(net{ForecastDuration+1},Xs,Ts,Xi,Ai);
    nntraintool('close');
    waitbar(ForecastDuration/(ForecastInterval-1)
end
close(h)

%% Test
PricesPredNetH=zeros(RangeTest(2), 1);
PricesPredMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
PricesRealMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
n=StartTestAt;
k=1;

h=waitbar(0, 'Berechne Prognose');
while n<=RangeTest(2)
    for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)        
        xdataInput=[num2cell(xdata(n+ForecastDuration,:)',1);{0}];          
        xdataDelayedInput=[num2cell(zeros(size(xdata,2),MaxDelay+ForecastDuration),1); num2cell(PricesRealDelayedH(n-MaxDelay+1:n+ForecastDuration,1))'];        
        [PricesPredNetH(n+ForecastDuration)]=cell2mat(net{ForecastDuration+1}(xdataInput, xdataDelayedInput, Ai))';
        
        PricesPredMatH(ForecastDuration+1,k)=PricesPredNetH(n+ForecastDuration,1);
        PricesRealMatH(ForecastDuration+1,k)=PricesRealCutH(n+ForecastDuration); % Control matrix for comparison with predicted values   
    end
    k=k+1;
    n=n+min(24,ForecastDuration+1);
    waitbar((n-StartTestAt)/(RangeTest(2)-StartTestAt))
end 
close(h)
mean(abs(PricesPredNetH(StartTestAt:RangeTest(2))-PricesRealCutH(StartTestAt:RangeTest(2))))



% Succesive prediction: 
% Predict ForecastInterval in a row. Each prediction bases on the
% prediction before. The first prediction is made totally of xdata. With
% each step into the future, one more predicted values is used for the next
% prediction. MSE(ForecastInterval=1:52)=11.6750 (mean from 1 to 52)
% For Training, ForecastInterval=1 must be used. For Testing
% ForecastInterval=52.
% 
% %% Training
% net=feedforwardnet(10);
% net.numInputs=size(xdata,2)+MaxDelay;
% net.inputConnect(1,:)=1;
% net.divideMode='time';
% net.plotFcns= {'plotperform', 'plottrainstate', 'ploterrhist', ...
%                 'plotregression', 'plotresponse', 'ploterrcorr', ...
%                 'plotinerrcorr'};
% 
% xdataInput=[xdata(RangeTrain(1):RangeTrain(2),:) PricesRealDelayedH(RangeTrain(1):RangeTrain(2),:)];        %[xo,xi,~,to] = preparets(net,num2cell(xdata(RangeTrain(1):RangeTrain(2),:)'),{},num2cell(PricesRealCutH(RangeTrain(1):RangeTrain(2),:)'));
% net = train(net,num2cell(xdataInput'), num2cell(PricesRealCutH(RangeTrain(1):RangeTrain(2))'));
% nntraintool('close');
%         
% %% Test    
%     StartTestAt=RangeTest(1)+10; % Start Test as it was 10:00, so 10:00 will always the time, when the prediction is executed
%     PricesPredNetH=zeros(RangeTest(2), 1);
%     PricesPredNetMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
%     PricesRealMatH=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
%     n=StartTestAt;
% 
%     h=waitbar(0, 'Berechne Prognose');
%     k=1;
%     while n<RangeTest(2)
%         for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)
%             xdataInput=[xdata(n+ForecastDuration,:) PricesPredNetH(n:n+ForecastDuration-1)' PricesRealDelayedH(n+ForecastDuration,ForecastDuration+1:end)]';
%             PricesPredNetH(n+ForecastDuration,1)=cell2mat(sim(net,num2cell(xdataInput)));
%             
%             PricesPredNetMatH(ForecastDuration+1,k)=PricesPredNetH(n+ForecastDuration,1);
%             PricesRealMatH(ForecastDuration+1,k)=PricesRealCutH(n+ForecastDuration); % Control matrix for comparison with predicted values                
%         end
%         k=k+1;
%         n=n+min(24,ForecastDuration+1);
%         waitbar((n-StartTestAt)/(RangeTest(2)-StartTestAt))
%     end
%     close(h)
%      
% MAE=mean(abs(PricesPredNetMatH-PricesRealMatH),2)
% mean(MAE)
% figure(50)    
% plot(TimeCutH(StartTestAt:StartTestAt+ForecastInterval-1),MAE)
% xtickformat('HH:mm')
% title(['Mean Absolute Error forecasting 1 to ' num2str(ForecastInterval) ' hours'])
