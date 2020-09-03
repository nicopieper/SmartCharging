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

%% Initialisation
tic

if ~exist('GenRealQH', 'var') || ~exist('IntradayRealQH', 'var') || ~exist('ResPoPricesReal4H', 'var')
    disp('Start Initialisation')
    Initialisation;    
    disp('Successfully initialised')
end

Target=DayaheadRealH; %PricesRealH;
TargetTitle="DayaheadRealH";  % "DayAheadPrice_H";
TimeVecPred=TimeH;
Predictors=[LoadPredH, GenPredH];
PredMethod={1};
TrainModelNew=0;

MaxDelayHours=7*24/7*3;
ForecastIntervalHours=52; % 52h  % The model must be able to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
Demo=1;
ActivateWaitbar=1;


if ~exist('PredVarsInput', 'var') || ~isequal(PredVarsInput,{MaxDelayHours, Target, TimeVecPred, Predictors})
    disp('Calculate Predictor Variables')
    [PredictorMat, TargetDelayed, TargetCut, TimeVecPredCut, TimeStepPred, TimeStepPredInd, MaxDelayInd, RangeTrainPredInd, RangeTestPredInd]=PredVars(MaxDelayHours, Target, TimeVecPred, Predictors, DateStart, DateEnd, ShareTrain, ShareTest, RangeTrainDate, RangeTestDate);
    PredVarsInput={MaxDelayHours, Target, TimeVecPred, Predictors};
    disp('Successfully calculated Predictor Variables')
end
ForecastIntervalInd=ForecastIntervalHours*TimeStepPredInd;

TimeIntervalFile=strcat(datestr(DateStart, 'yyyymmdd'), "_", datestr(DateEnd, 'yyyymmdd'));
StorageFileLSQ=strcat(Path, 'Predictions', Dl, 'TrainedModels', Dl, 'LSQ_', TargetTitle, '_', num2str(ForecastIntervalInd), '_', num2str(MaxDelayHours*TimeStepInd+size(PredictorMat,2)), '_', TimeIntervalFile, '.mat'); % Path where the LSQ model shall be stored
StorageFileNarxnet=strcat(Path, 'Predictions', Dl, 'TrainedModels', Dl, 'Narxnet_', TargetTitle, '_', num2str(ForecastIntervalInd), '_', TimeIntervalFile, '.mat'); % Path where the LSQ model shall be stored

%% Load trained Models or if they do not exist train them
if sum(ismember(cell2mat(PredMethod(:,1)),1)) && (TrainModelNew || ~isfile(StorageFileLSQ))
    disp('Start LSQ Training')
    [LSQCoeffs, TrainFun] = TrainLSQ(TargetCut, TargetDelayed, PredictorMat, ForecastIntervalInd, RangeTrainPredInd);
    save(StorageFileLSQ, 'LSQCoeffs', 'TrainFun', '-v7.3')
    disp('LSQ Training successfully finished')
elseif ismember(cell2mat(PredMethod(:,1)),1)
    load(StorageFileLSQ)
end

if sum(ismember(cell2mat(PredMethod(:,1)),2)) && (TrainModelNew || ~isfile(StorageFileNarxnet))
    disp('Start Narxnet Training')
    [Narxnets, Ai] = TrainNarxnets(TargetCut, PredictorMat, ForecastIntervalInd, MaxDelayInd, RangeTrainPredInd);
    save(StorageFileNarxnet, 'Narxnets', 'Ai', '-v7.3')
    disp('Narxnet Training successfully finished')
elseif ismember(cell2mat(PredMethod(:,1)),2)
    load(StorageFileNarxnet)    
end
    

%% Prediction
disp('Start Prediction')
for n=1:size(PredMethod,1)  % Fill the Matrix with the Model
    if PredMethod{n,1}==1
        PredMethod(n,2:3)=[{LSQCoeffs}, {TrainFun}];
    elseif PredMethod{n,1}==2
        PredMethod(n,2:3)=[{Narxnets}, {Ai}];
    end
end   
[Prediction, PredictionMat, TargetMat, MAE, mMAPE, RMSE] = TestPred(PredMethod, PredictorMat, TargetDelayed, TargetCut, TimeVecPredCut,...
    TimeStepPredInd, RangeTestPredInd, MaxDelayInd, ForecastIntervalInd, Demo, TargetTitle, ActivateWaitbar); % The actual Prediction

clearvars TimeIntervalFile


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
