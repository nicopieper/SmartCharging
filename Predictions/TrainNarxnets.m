function [Narxnets, Ai] = TrainNarxnets(Target, PredictorMat, ForecastIntervalPredInd, DelayIndsNARXNET, RangeTrain, Time)
%% Description
% tbd

%% Initialisation
tic
PredictorCell=num2cell(PredictorMat(RangeTrain(1):RangeTrain(2),:)',1); % Changed TargetCut to Target. Hence, normally it should be RangeTrain(1) + MaxDelayInd but I thin preparets does it by itself
TargetCell=num2cell(Target(RangeTrain(1):RangeTrain(2),:)'); % Same as comment above
Narxnets=num2cell(zeros(ForecastIntervalPredInd,1));
DelayIndsNARXNETMat=[repmat(DelayIndsNARXNET{1}, ForecastIntervalPredInd,1) + (0:ForecastIntervalPredInd-1)', repmat(DelayIndsNARXNET{2}, ForecastIntervalPredInd, 1) + 24*Time.StepPredInd*floor((1:ForecastIntervalPredInd)'/(24*Time.StepPredInd))];

%% Training
h=waitbar(0, 'Berechne Narxnet Prognosemodelle');
for ForecastDuration=1:ForecastIntervalPredInd
    Narxnets{ForecastDuration} = narxnet(0,DelayIndsNARXNETMat(ForecastDuration,:),10);
    %Narxnets{ForecastDuration+1}.inputs{1,1}.processFcns={};
    Narxnets{ForecastDuration}.trainParam.showWindow=0;
    [Xs,Xi,Ai,Ts] = preparets(Narxnets{ForecastDuration},PredictorCell,{},TargetCell);
    Narxnets{ForecastDuration} = train(Narxnets{ForecastDuration},Xs,Ts,Xi,Ai);
    nntraintool('close');
    waitbar(ForecastDuration/(ForecastIntervalPredInd))
end
close(h)
disp(['Narxnets successfully trained ' num2str(toc) 's'])



% %% Training
% h=waitbar(0, 'Berechne Narxnet Prognosemodelle');
% for ForecastDuration=0:ForecastIntervalPredInd-1
%     Narxnets{ForecastDuration+1} = narxnet(0,1+ForecastDuration:MaxDelayInd+ForecastDuration,10);   
%     %Narxnets{ForecastDuration+1}.inputs{1,1}.processFcns={};
%     Narxnets{ForecastDuration+1}.trainParam.showWindow=0;
%     [Xs,Xi,Ai,Ts] = preparets(Narxnets{ForecastDuration+1},PredictorCell,{},TargetCell);
%     Narxnets{ForecastDuration+1} = train(Narxnets{ForecastDuration+1},Xs,Ts,Xi,Ai);
%     nntraintool('close');
%     waitbar(ForecastDuration/(ForecastIntervalPredInd-1))
% end
% close(h)
% disp(['Narxnets successfully trained ' num2str(toc) 's'])