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

Target=Smard.DayaheadRealH; % double(PVPlants{1}.Profile); %Smard.DayaheadRealH; Availability1 ResEnPricesRealQH(:,7)
TargetTitle="DayaheadRealH";  % "DayaheadRealH"; "PVPlants_1"
Time.Pred=Time.H;%Users{1}.Time.Vec;
Predictors=[Smard.LoadPredH(1:end), Smard.GenPredH(1:end,:)];% [Smard.GenPredQH(:,4)]; [Smard.LoadPredH, Smard.GenPredH]; [SoC1, Weekday]
PredMethod={2};
TrainModelNew=0;
Save=true;

DelayIndsLSQ=[1:224];
%DelayIndsNARXNET=[1:72+24];
DelayIndsNARXNET=[1:52, 68:76, 92:100, 116:124]; % [1:52, 68:76, 92:100, 116:124]
DelayIndsGLM=[1:8, 9:2:18, 48, 95:97, 2*96-1:2*96+1, 3*96-1:3*96+1];
DelayIndsGLM=[1:24*4];
GLMDistribution='binomial';
GLMDistribution='normal';
GLMLinkFunction='logit';

Time.HourPred=8;
DelayPredictionMarketData=round(Time.HourPred*1/(hours(Time.Pred(2)-Time.Pred(1))));
ForecastIntervalHours=52-(Time.HourPred-hour(Range.TestDate(1))); % 52h  % The model must be able %to predict the value of Wednesday 12:00 at Monday 8:00 --> 52 forecast interval
Demo=0;
ActivateWaitbar=1;

if ~exist('PredVarsInput', 'var') || ~isequaln(PredVarsInput,{Target, Time.Pred, Predictors, DelayIndsLSQ, DelayIndsNARXNET, Time.HourPred, DelayPredictionMarketData})
    disp('Calculate Predictor Variables')
    %%
    [PredictorMat, TargetDelayedLSQ, TargetDelayedNARXNET, TargetDelayedGLM, MaxDelayIndLSQ, NumDelayIndsLSQ, MaxDelayIndNARXNET, NumDelayIndsNARXNET, MaxDelayIndGLM, NumDelayIndsGLM, Time, Range]=PredVars(ForecastIntervalHours, DelayIndsLSQ, DelayIndsNARXNET, DelayIndsGLM, DelayPredictionMarketData, Target, Predictors, Time, Range);
    PredVarsInput={Target, Time.Pred, Predictors, DelayIndsLSQ, DelayIndsNARXNET, Time.HourPred, DelayPredictionMarketData};
    disp('Successfully calculated Predictor Variables')
end
ForecastIntervalPredInd=ForecastIntervalHours*Time.StepPredInd;

StorageFileLSQ=strcat(Path.TrainedModel,     TargetTitle, Dl, 'LSQ_*_',     datestr(Range.TrainDate(1), 'yyyymmdd'), "-", datestr(Range.TrainDate(2), 'yyyymmdd'), '_', num2str(ForecastIntervalPredInd), "h", '_', num2str(NumDelayIndsLSQ+size(PredictorMat,2)), "Preds", num2str(Time.HourPred), "hr", '.mat'); % Path where the LSQ model shall be stored
StorageFileNarxnet=strcat(Path.TrainedModel, TargetTitle, Dl, 'Narxnet_*_', datestr(Range.TrainDate(1), 'yyyymmdd'), "-", datestr(Range.TrainDate(2), 'yyyymmdd'), '_', num2str(ForecastIntervalPredInd), "h", '_', num2str(NumDelayIndsNARXNET+size(PredictorMat,2)), "Preds", num2str(Time.HourPred), "hr", '.mat'); % Path where the LSQ model shall be stored
StorageFileGLM=strcat(Path.TrainedModel,     TargetTitle, Dl, 'GLM_*_',     datestr(Range.TrainDate(1), 'yyyymmdd'), "-", datestr(Range.TrainDate(2), 'yyyymmdd'), '_', num2str(ForecastIntervalPredInd), "h", '_', num2str(NumDelayIndsGLM+size(PredictorMat,2)), "Preds", num2str(Time.HourPred), "hr", '.mat'); % Path where the LSQ model shall be stored

%% Load trained Models or if they do not exist train them
LSQFiles=dir(StorageFileLSQ);
if sum(ismember(cell2mat(PredMethod(:,1)),1)) && (TrainModelNew || isempty(LSQFiles))
    disp('Start LSQ Training')
    [LSQCoeffs, TrainFun] = TrainLSQ(Target, TargetDelayedLSQ, PredictorMat, ForecastIntervalPredInd, Range.TrainPredInd, MaxDelayIndLSQ);
    if Save
        StorageFileLSQ=strrep(StorageFileLSQ, '*', datestr(datetime('now'), 'yyyymmdd'));
        if ~isfolder(strcat(Path.TrainedModel, TargetTitle))
            mkdir(strcat(Path.TrainedModel, TargetTitle))
        end
        save(StorageFileLSQ, 'LSQCoeffs', 'TrainFun', '-v7.3')
    end
    disp('LSQ Training successfully finished')
elseif any(ismember(cell2mat(PredMethod(:,1)),1))
    [~,newest]=sort([LSQFiles.datenum], 'descend');
    load(strcat(LSQFiles(newest(1)).folder, Dl, LSQFiles(newest(1)).name))
end

NarxnetFiles=dir(StorageFileNarxnet);
if sum(ismember(cell2mat(PredMethod(:,1)),2)) && (TrainModelNew || isempty(NarxnetFiles))
    disp('Start Narxnet Training')
    [Narxnets, Ai] = TrainNarxnets(Target, PredictorMat, ForecastIntervalPredInd, DelayIndsNARXNET, DelayPredictionMarketData, Range, Time);
    if Save
        StorageFileNarxnet=strrep(StorageFileNarxnet, '*', datestr(datetime('now'), 'yyyymmdd'));
        if ~isfolder(strcat(Path.TrainedModel, TargetTitle))
            mkdir(strcat(Path.TrainedModel, TargetTitle))
        end
        save(StorageFileNarxnet, 'Narxnets', 'Ai', '-v7.3')
    end
    disp('Narxnet Training successfully finished')
elseif any(ismember(cell2mat(PredMethod(:,1)),2))
    [~,newest]=sort([NarxnetFiles.datenum], 'descend');
    load(strcat(NarxnetFiles(newest(1)).folder, Dl, NarxnetFiles(newest(1)).name));
end

GLMFiles=dir(StorageFileGLM);
if sum(ismember(cell2mat(PredMethod(:,1)),3)) && (TrainModelNew || isempty(GLMFiles))
    disp('Start GLM Training')
    [GLMCoeffs] = TrainGLM(Target, TargetDelayedGLM, PredictorMat, ForecastIntervalPredInd, Range.TrainPredInd, MaxDelayIndGLM, GLMDistribution);
    if Save
        StorageFileGLM=strrep(StorageFileGLM, '*', datestr(datetime('now'), 'yyyymmdd'));
        if ~isfolder(strcat(Path.TrainedModel, TargetTitle))
            mkdir(strcat(Path.TrainedModel, TargetTitle))
        end
        save(StorageFileGLM, 'GLMCoeffs', '-v7.3')
    end
    disp('GLM Training successfully finished')
elseif any(ismember(cell2mat(PredMethod(:,1)),3))
    [~,newest]=sort([GLMFiles.datenum], 'descend');
    load(strcat(GLMFiles(newest(1)).folder, Dl, GLMFiles(newest(1)).name));
end
    

%% Prediction
disp('Start Prediction')

for n=1:size(PredMethod,1)  % Fill the Matrix with the Model
    if PredMethod{n,1}==1
        PredMethod(n,2:4)=[{LSQCoeffs}, {TrainFun}, {NumDelayIndsLSQ+size(PredictorMat,2)}];
    elseif PredMethod{n,1}==2
        PredMethod(n,2:4)=[{Narxnets}, {Ai}, {NumDelayIndsNARXNET+size(PredictorMat,2)}];
    elseif PredMethod{n,1}==3
        PredMethod(n,2:4)=[{GLMCoeffs}, {GLMLinkFunction}, {NumDelayIndsGLM+size(PredictorMat,2)}];
    end
end   
[Prediction, PredictionMat, TargetMat, MAE, mMAPE, RMSE, Accuracy] = TestPred(PredMethod, PredictorMat, TargetDelayedLSQ, TargetDelayedGLM, Target, Time,...
    Range, MaxDelayIndLSQ, MaxDelayIndNARXNET, ForecastIntervalPredInd, Demo, TargetTitle, ActivateWaitbar, Path, Dl, Save); % The actual Prediction

clearvars StorageFileNarxnet Demo TargetTitle ActivateWaitbar PredMethod TrainFun LSQCoeffs Ai StorageFileLSQ ForecastIntervalPredInd


toc

