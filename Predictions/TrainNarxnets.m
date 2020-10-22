function [Narxnets, Ai] = TrainNarxnets(Target, PredictorMat, ForecastIntervalPredInd, DelayIndsNARXNET, Range, Time)
%% Description
% tbd

%% Initialisation
tic
PredictorCell=num2cell(PredictorMat(Range.TrainPredInd(1):Range.TrainPredInd(2),:)',1); % Changed TargetCut to Target. Hence, normally it should be Range.TrainPredInd(1) + MaxDelayInd but I thin preparets does it by itself
TargetCell=num2cell(Target(Range.TrainPredInd(1):Range.TrainPredInd(2),:)'); % Same as comment above
%PredictorCell=num2cell([PredictorMat(Range.TrainPredInd(1):Range.TrainPredInd(2),:), TargetDelayedNARXNET(Range.TrainPredInd(1):Range.TrainPredInd(2),:)]',1); % Changed TargetCut to Target. Hence, normally it should be Range.TrainPredInd(1) + MaxDelayInd but I thin preparets does it by itself
Narxnets=num2cell(zeros(ForecastIntervalPredInd,1));


%% Training 
h=waitbar(0, 'Berechne Narxnet Prognosemodelle');
for ForecastDuration=1:ForecastIntervalPredInd
    Narxnets{ForecastDuration} = narxnet(0, DelayIndsNARXNET+ForecastDuration-1,10);
    Narxnets{ForecastDuration}.trainParam.showWindow=0;
    [Xs,Xi,Ai,Ts] = preparets(Narxnets{ForecastDuration},PredictorCell,{},TargetCell);
    Narxnets{ForecastDuration} = train(Narxnets{ForecastDuration},Xs,Ts,Xi,Ai);
    nntraintool('close');
    waitbar(ForecastDuration/(ForecastIntervalPredInd))
end
close(h)
disp(['Narxnets successfully trained ' num2str(toc) 's'])


% h=waitbar(0, 'Berechne Narxnet Prognosemodelle');
% for ForecastDuration=1:ForecastIntervalPredInd
%     Narxnets{ForecastDuration} = narxnet(0,DelayIndsNARXNETMat(ForecastDuration,:),10);
%     %Narxnets{ForecastDuration+1}.inputs{1,1}.processFcns={};
%     Narxnets{ForecastDuration}.trainParam.showWindow=0;
%     [Xs,Xi,Ai,Ts] = preparets(Narxnets{ForecastDuration},PredictorCell,{},TargetCell);
%     Narxnets{ForecastDuration} = train(Narxnets{ForecastDuration},Xs,Ts,Xi,Ai);
%     nntraintool('close');
%     waitbar(ForecastDuration/(ForecastIntervalPredInd))
% end
% close(h)
% disp(['Narxnets successfully trained ' num2str(toc) 's'])



% %% Training
% h=waitbar(0, 'Berechne Narxnet Prognosemodelle');temp
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






% TargetCell=num2cell(Target(Range.TrainPredInd(1):Range.TrainPredInd(2),:)'); % Same as comment above
% PredictorCell=num2cell([PredictorMat(Range.TrainPredInd(1):Range.TrainPredInd(2),:), TargetDelayedNARXNET(Range.TrainPredInd(1):Range.TrainPredInd(2),:)]',1); % Changed TargetCut to Target. Hence, normally it should be Range.TrainPredInd(1) + MaxDelayInd but I thin preparets does it by itself
% Narxnets=num2cell(zeros(ForecastIntervalPredInd,1));
% 
% %% Training
% 
% for n=1:1%ceil(ForecastIntervalPredInd/(24*Time.StepPredInd)
%     Narxnets{n}=narxnet(0, DelayIndsNARXNET{1},10);
%     [Xs,Xi,Ai,Ts] = preparets(Narxnets{n},PredictorCell,{},TargetCell);
%     net.trainParam.epochs=300;
%     Narxnets{n}.trainParam.showWindow=1;
%     Narxnets{n} = train(Narxnets{n},Xs,Ts,Xi,Ai);
% end
% 
% TargetCell=num2cell(Target(Range.TrainPredInd(1):Range.TestPredInd(2),:)'); % Same as comment above
% PredictorCell=num2cell([PredictorMat(Range.TrainPredInd(1):Range.TestPredInd(2),:), TargetDelayedNARXNET(Range.TrainPredInd(1):Range.TestPredInd(2),:)]',1); % Changed TargetCut to Target. Hence, normally it should be Range.TrainPredInd(1) + MaxDelayInd but I thin preparets does it by itself
% 
% 
% %%
% Narxnets{n}=closeloop(Narxnets{n});
% for k=Range.TestPredInd(1):96:Range.TestPredInd(2)-96
%     Prediction(k:k+95) = cell2mat(Narxnets{n}(PredictorCell(k:k+95), {}, {}));
% end
% figure 
% hold on
% plot(Time.Vec(1:length(Prediction)), Prediction)
% plot(Time.Vec, Target(1:length(Time.Vec)))


%end