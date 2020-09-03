function [Narxnets, Ai] = TrainNarxnets(Target, PredictorMat, ForecastInterval, MaxDelay, RangeTrain)
%% Description
% tbd

%% Initialisation
tic
PredictorCell=num2cell(PredictorMat(RangeTrain(1):RangeTrain(2),:)',1);
TargetCell=num2cell(Target(RangeTrain(1):RangeTrain(2),:)');
Narxnets=num2cell(zeros(ForecastInterval,1));

%% Training
h=waitbar(0, 'Berechne Narxnet Prognosemodelle');
for ForecastDuration=0:ForecastInterval-1
    Narxnets{ForecastDuration+1} = narxnet(0,1+ForecastDuration:MaxDelay+ForecastDuration,10);   
    %Narxnets{ForecastDuration+1}.inputs{1,1}.processFcns={};
    Narxnets{ForecastDuration+1}.trainParam.showWindow=0;
    [Xs,Xi,Ai,Ts] = preparets(Narxnets{ForecastDuration+1},PredictorCell,{},TargetCell);
    Narxnets{ForecastDuration+1} = train(Narxnets{ForecastDuration+1},Xs,Ts,Xi,Ai);
    nntraintool('close');
    waitbar(ForecastDuration/(ForecastInterval-1))
end
close(h)
disp(['Narxnets successfully trained ' num2str(toc) 's'])