%% Description
% This Script predicts Time Series Values using a LSQ Method oder a
% Narxnet. First, Source Variables are initialised form the Initialisation
% Script. Basing on those, further Variables are calculated that are used
% for the Prediction in the PredVars Function. Depending on which
% Prediction Method shall be used, LSQ Coefficients are calculated or a 
% Narxnet is trained using a Training Data Set. A Test Data Set ist then
% used to predict the Time Series Values. The Prediction can be
% demonstrated in a rolling Plot.
%
% Variable description
%
%   Target:             The time series whose Values are to be predicted.
%                       (N,1)
%   TargetTile:         A short String Label that describes what is used as
%                       Target. (1,1)
%   Time:               A Vector indicating the datetime of each
%                       corresponding Target Value with the same index.
%                       (N,1)
%   Predictors          A Matrix covering all Predictor Variables that
%                       shall be included in PredictorMat (N,M)
%   PredMethod:         Cell Array of the trained Models. The third column
%                       always indicates, which type of model this row 
%                       represents. A 1 indicates a LSQ Model, a 2 an ANN 
%                       Model. For a LSQ Model, the second column contains 
%                       the LSQ Coefficients and the third the Model 
%                       Function. For an ANN Model, the second column
%                       contains the ANNs (one for each Forecast step, 
%                       {1, ForecastInterval}) and the third one the Ai 
%                       variable. {P,3}
%   MaxDelayHours:      The oldest Target Value used for the
%                       prediction is MaxDelayInd Hours ago. (1,1).
%   ForecastIntervalHours: The number of Hours that Values are predicted
%                       for. (1,1)
%   ForecastInterval:   The Number of Values of Prediction contains.
%                       ForecastInterval/TimeStepIndices equals the number of
%                       hours the prediction covers. (1,1)
%   Demo:               Indicates whether the Demonstration is active. A 1
%                       activates the Demo, a 0 ignores it. (1,1)
%   ActivateWaitbar     Indicates whether the waitbar is active or not
%
%                                                   mMAPE                                                       mMAPE
%                               Pr�diktoren     LSQ     Narxnet                             Pr�diktoren     LSQ     Narxnet
%   
%   ResPoPricesReal4H(:,3)      []              0.736   0.832       ResEnPricesRealQH(:,3)  []              0.746   0.838
%   ResPoPricesReal4H(:,3)      [Load, Gen]     0.803   0.792       ResEnPricesRealQH(:,3)  [Load, Gen]     0.790   0.919
%   ResPoPricesReal4H(:,4)      []              0.410   0.644       ResEnPricesRealQH(:,4)  []              0.189   0.275
%   ResPoPricesReal4H(:,4)      [Load, Gen]     0.614   0.746       ResEnPricesRealQH(:,4)  [Load, Gen]     0.194   0.251
%   ResPoPricesReal4H(:,5)      []              0.770   0.881       ResPoDemRealQH(:,1)     []              0.994   1.010
%   ResPoPricesReal4H(:,5)      [Load, Gen]     0.841   0.747       ResPoDemRealQH(:,1)     [Load, Gen]     0.994   1.012
%   ResPoPricesReal4H(:,6)      []              0.563   0.729       ResPoDemRealQH(:,2)     []              1.318   1.331
%   ResPoPricesReal4H(:,6)      [Load, Gen]     0.871   1.089       ResPoDemRealQH(:,2)     [Load, Gen]     1.327   1.345
%
%   IntradayRealH(:,1)          []              0.286   0.289       IntradayRealH(:,3)      []              0.286   0.289 
%   IntradayRealH(:,1)          [Load, Gen]     0.230   0.212       IntradayRealH(:,3)      [Load, Gen]     0.230   0.212
%   IntradayRealH(:,2)          []              0.296   0.298       DayaheadRealH           []              0.324   0.334
%   IntradayRealH(:,2)          [Load, Gen]     0.243   0.229       DayaheadRealH           [Load, Gen]     0.279   0.266

%   Erh�hung von MaxDelayHours von 1 Tag auf 3 Tage senkte mMAPE bei
%   DayaheadRealH signifikant. Tests wurden mit geringen MaxDelayHours 
%   (meistens 1 Tag) durchgef�hrt und teils mit verminderten 
%   ForecastIntervalHours


%% Initialisation
tic

if ~exist('Smard', 'var') || ~exist('ResPoPricesReal4H', 'var')
    disp('Start Initialisation')
    Initialisation;    
    disp('Successfully initialised')
end

Target=double(Availability); % double(PVPlants{1}.Profile); %DayaheadRealH; Availability1 ResEnPricesRealQH(:,7)
TargetTitle="Availability";  % "DayaheadRealH"; "PVPlants_1"
Time.Pred=Users{1}.Time.Sim.Vec;
Predictors=[SoC1];% [Smard.GenPredQH(:,4)]; [Smard.LoadPredH, Smard.GenPredH]; [SoC1, Weekday]
PredMethod={2};
TrainModelNew=1;
Save=false;

% DelayIndsLSQ=[1:47, 48:24:49+24*5];
DelayIndsNARXNET={[1:3], [96,96*2]};
% MaxDelayHours=7*24/7*3;
ForecastIntervalHours=52; % 52h  % The model must be able %to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
Demo=0;
ActivateWaitbar=1;

if ~exist('PredVarsInput', 'var') || ~isequaln(PredVarsInput,{Target, Time.Pred, Predictors, DelayIndsLSQ, DelayIndsNARXNET})
    disp('Calculate Predictor Variables')
    %%
    [PredictorMat, TargetDelayed, MaxDelayInd, NumDelayIndsLSQ, NumDelayIndsNARXNET, Time, Range]=PredVars(DelayIndsLSQ, Target, Predictors, Time, Range);
    PredVarsInput={Target, Time.Pred, Predictors, DelayInds};
    disp('Successfully calculated Predictor Variables')
end
ForecastIntervalPredInd=ForecastIntervalHours*Time.StepPredInd;

StorageFileLSQ=strcat(Path.TrainedModel, 'LSQ_', TargetTitle, '_', num2str(ForecastIntervalPredInd), '_', num2str(NumDelayIndsLSQ+size(PredictorMat,2)), '_', Time.IntervalFile, '.mat'); % Path where the LSQ model shall be stored
StorageFileNarxnet=strcat(Path.TrainedModel, 'Narxnet_', TargetTitle, '_', num2str(ForecastIntervalPredInd), '_', num2str(NumDelayIndsNARXNET+size(PredictorMat,2)), '_', Time.IntervalFile, '.mat'); % Path where the LSQ model shall be stored

%% Load trained Models or if they do not exist train them
if sum(ismember(cell2mat(PredMethod(:,1)),1)) && (TrainModelNew || ~isfile(StorageFileLSQ))
    disp('Start LSQ Training')
    [LSQCoeffs, TrainFun] = TrainLSQ(Target, TargetDelayed, PredictorMat, ForecastIntervalPredInd, Range.TrainPredInd, MaxDelayInd);
    if Save
        save(StorageFileLSQ, 'LSQCoeffs', 'TrainFun', '-v7.3')
    end
    disp('LSQ Training successfully finished')
elseif any(ismember(cell2mat(PredMethod(:,1)),1))
    load(StorageFileLSQ)
end

if sum(ismember(cell2mat(PredMethod(:,1)),2)) && (TrainModelNew || ~isfile(StorageFileNarxnet))
    disp('Start Narxnet Training')
    [Narxnets, Ai] = TrainNarxnets(Target, PredictorMat, ForecastIntervalPredInd, DelayIndsNARXNET, Range.TrainPredInd);
    if Save
        save(StorageFileNarxnet, 'Narxnets', 'Ai', '-v7.3')
    end
    disp('Narxnet Training successfully finished')
elseif any(ismember(cell2mat(PredMethod(:,1)),2))
    load(StorageFileNarxnet)    
end
    

%% Prediction
disp('Start Prediction')
close hidden
for n=1:size(PredMethod,1)  % Fill the Matrix with the Model
    if PredMethod{n,1}==1
        PredMethod(n,2:3)=[{LSQCoeffs}, {TrainFun}];
    elseif PredMethod{n,1}==2
        PredMethod(n,2:3)=[{Narxnets}, {Ai}];
    end
end   
[Prediction, PredictionMat, TargetMat, MAE, mMAPE, RMSE] = TestPred(PredMethod, PredictorMat, TargetDelayed, Target, Time,...
    Range, MaxDelayInd, ForecastIntervalPredInd, Demo, TargetTitle, ActivateWaitbar, Path, Save); % The actual Prediction

clearvars StorageFileNarxnet ForecastIntervalPredInd Demo TargetTitle ActivateWaitbar PredMethod TrainFun LSQCoeffs Narxnets Ai StorageFileLSQ


toc
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
