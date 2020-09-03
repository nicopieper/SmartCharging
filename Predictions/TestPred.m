function [Prediction, PredictionMat, TargetMat, MAEConst, mMAPEConst, RMSEConst] = TestPred(PredMethod, PredictorMat, TargetDelayed, Target, TimeVecPred, TimeStepPredInd, RangeTestPredInd, RangeTestDate, MaxDelayInd, ForecastIntervalPredInd, Demo, TargetName, ActivateWaitbar)
%% Description
% This function generates predictions basing on trained LSQ and NARXNET
% models. The predictions can be visualised in a live demonstration.
% Finally the prediction quality is evaluated.
%
% Variable description
%
%  Input
%   PredMethod:         Cell Array of the trained Models. The third column
%                       always indicates, which type of model this row 
%                       represents. A 1 indicates a LSQ Model, a 2 an ANN 
%                       Model. For a LSQ Model, the second column contains 
%                       the LSQ Coefficients and the third the Model 
%                       Function. For an ANN Model, the second column
%                       contains the ANNs (one for each Forecast step, 
%                       {1, ForecastIntervalInd}) and the third one the Ai 
%                       variable. {P,3}
%   PredictorMat:       A Matrix covering all Predictor Variables and daily
%                       and weekly mean Values (TimeInd-MaxDelay,:M+2)
%   TagetDelayed:       A Matrix covering Target Values. Each column
%                       shifts the Value once more. One row represents
%                       all MaxDelay Target Values of the past, with
%                       (1,1) represeting the latest value and
%                       (MaxDelay, MaxDelay) representing the oldest value
%   TimeVecPred:               A Vector indicating the datetime of each
%                       corresponding Target Value with the same index.
%                       (TimeInd,1)
%   TimeStepIndices:           1/TimeStepIndices equals the TimeVecPred in hours between two
%                       consecutive values of all used TimeVecPred Series
%   RangeTestPredInd:          Start and end Index of the Testing set. Is
%                       corrected for MaxDelay (1,2)
%   MaxDelay:           The oldest Target value used for the
%                       prediction is MaxDelay values ago. (1,1).
%   ForecastIntervalInd:   The Number of Values of Prediction contains.
%                       ForecastIntervalInd/TimeStepIndices equals the number of
%                       hours the prediction covers. (1,1)
%   TestStartDelay:     A Delay in Values, the Test starts after
%                       RangeTestPredInd(1). (1,1)
%   Demo:               Indicates whether the Demonstration is active. A 1
%                       activates the Demo, a 0 ignores it. (1,1)
%   TargetName          A String Label that describes the Target, e.g. 
%                       "Day Ahead Price 1h". (1,1)
%   ActivateWaitbar     Indicates whether the waitbar is active or not
%
%  Output
%   Prediction          A Matrix that contains the predicted Values of all
%                       Prediction Models. Each Column refers to one Model.
%                       (TimeInd,P)
%   MAE                 A Matrix with the Mean Absolute Error of the
%                       Predictions. One Row represents one forecasted
%                       hour. The columns represent the Models.
%                       (ForecastIntervalInd,P)
%   MSE                 Like MAE but Mean Squared Error (ForecastIntervalInd,P)


%% Initialisation
NumPredMethod=size(PredMethod,1);
Prediction=zeros(RangeTestPredInd(2), NumPredMethod);
PredictionMat=zeros(ForecastIntervalPredInd, floor((RangeTestPredInd(2)-RangeTestPredInd(1))/(24*TimeStepPredInd)), NumPredMethod);
TargetMat=zeros(ForecastIntervalPredInd, floor((RangeTestPredInd(2)-RangeTestPredInd(1))/ForecastIntervalPredInd));
TimeInd=RangeTestPredInd(1);
k=1;
ymin=-20; % round(min(Target)*1.1/10)*10;
ymax=60; % round(max(Target)*1.1/10)*10;


LegendVec=GetLegendNames(PredMethod, NumPredMethod);
PlotColors= [0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; ...
                 0.4940, 0.1840, 0.5560; 0.4660, 0.6740, 0.1880; ...
                 0.3010, 0.7450, 0.9330; 0.6350, 0.0780, 0.1840];     

%% Preconfigure Demo 
if Demo
    TargetDemo=zeros(size(Target,1),1);
    TargetDemo(1:TimeInd)=Target(1:TimeInd);
    ForecastDuration=0;
    i=0;
    TimeVecPred=[TimeVecPred; TimeVecPred(RangeTestPredInd(2))+hours(1)/TimeStepPredInd; TimeVecPred(RangeTestPredInd(2))+hours(1)/TimeStepPredInd*2; TimeVecPred(RangeTestPredInd(2))+hours(1)/TimeStepPredInd*3; TimeVecPred(RangeTestPredInd(2))+hours(1)/TimeStepPredInd*4];
    EndCounter=TimeInd;
           
    figure(10)
    cla
    title(strcat(TargetName, " Prediction vs. Target at ", datestr(TimeVecPred(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
    xlabel('TimeVecPred')
    ylabel('Price [MWh/€]')
    grid on   
    hold on    
    
    figReal=plot(TimeVecPred(TimeInd-24*TimeStepPredInd+1+i:TimeInd+i), TargetDemo(TimeInd-24*TimeStepPredInd+1+i:TimeInd+i), 'Color', [0.0000, 0.4470, 0.7410]);
    for p=1:NumPredMethod % Create one Figure Property for each model
        figPred{p}=plot(TimeVecPred(max(TimeInd-ForecastIntervalPredInd+ForecastDuration, RangeTestPredInd(1)):TimeInd+ForecastDuration), Prediction(max(TimeInd-ForecastIntervalPredInd+ForecastDuration, RangeTestPredInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));        
    end       
        
    legend([strcat("Target ", TargetName), LegendVec],'Interpreter','none')
end

%% Start Prediction
if ActivateWaitbar
    h=waitbar(0, 'Berechne Prognose');
end
while TimeInd<=RangeTestPredInd(2)
    for ForecastDuration=0:min(ForecastIntervalPredInd-1, RangeTestPredInd(2)-TimeInd)        
        for p=1:NumPredMethod
            if PredMethod{p,1}==1 % if it is a LSQ Model
                try
                    if ~isempty(PredictorMat)
                        PredictorMatInput=[PredictorMat(TimeInd+ForecastDuration,:), TargetDelayed(TimeInd,:)]; % The Predictors 
                    else
                        PredictorMatInput=[TargetDelayed(TimeInd,:)]; % The Predictors 
                    end
                    
                    Prediction(TimeInd+ForecastDuration,p)=PredMethod{p,3}(PredMethod{p,2}(ForecastDuration+1,:), PredictorMatInput); % The LSQ Prediction, PredMethod{p,2} covers the Model Function, PredMethod{p,1} covers the LSQ Coefficients
                    PredictionMat(ForecastDuration+1,k,p)=Prediction(TimeInd+ForecastDuration,p); % A vector storing all predicted Values
                catch
                    TimeInd
                end
            elseif PredMethod{p,1}==2
                PredictorMatInput=[num2cell(PredictorMat(TimeInd+ForecastDuration,:)',1);{0}]; % Regarding current Values, the ANN uses only the Predictors, hence the target row can be zero
                PredictorMatDelayedInput=[num2cell(zeros(size(PredictorMat,2),MaxDelayInd+ForecastDuration),1); num2cell(TargetDelayed(TimeInd-MaxDelayInd+1:TimeInd+ForecastDuration,1))']; % Regarding delayed Values, the ANN uses only the delayed Targets, hence the first rows are not used an can by any value
                Prediction(TimeInd+ForecastDuration,p)=cell2mat(PredMethod{p,2}{ForecastDuration+1}(PredictorMatInput, PredictorMatDelayedInput, PredMethod{p,3}))';
                PredictionMat(ForecastDuration+1,k,p)=Prediction(TimeInd+ForecastDuration,p);
            end
            if Demo  
                EndCounter=max(EndCounter,TimeInd+ForecastDuration);                    
                figPred{p}.YDataSource='Prediction(RangeTestPredInd(1):EndCounter,p)';
                figPred{p}.XDataSource='TimeVecPred(RangeTestPredInd(1):EndCounter)';                   
                title(strcat(TargetName, " Prediction vs. Target at ", datestr(TimeVecPred(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
                xlim([TimeVecPred(TimeInd-36*TimeStepPredInd+max(0,-ForecastIntervalPredInd+24*TimeStepPredInd+ForecastDuration+1)) TimeVecPred(EndCounter+3)]) % Create a moving plot 
                ylim([ymin ymax])        
                refreshdata(figPred{p}, 'caller')                
                pause(0.01/NumPredMethod)
            end
        end        
        TargetMat(ForecastDuration+1,k)=Target(TimeInd+ForecastDuration);
    end    
    if Demo
        for i=0:24*TimeStepPredInd-1
            TargetDemo(TimeInd+i)=Target(TimeInd+i);
            figReal.YDataSource='TargetDemo(RangeTestPredInd(1):TimeInd+i)';
            figReal.XDataSource='TimeVecPred(RangeTestPredInd(1):TimeInd+i)';
            title(strcat(TargetName, " Prediction vs. Target at ", datestr(TimeVecPred(TimeInd+i),'dd.mm.yyyy HH:MM')),'Interpreter','none')
            ylim([ymin ymax])      
            refreshdata(figReal, 'caller')
            pause(0.01)
        end
    end  
    k=k+1;
    TimeInd=TimeInd+min(round(24*TimeStepPredInd),ForecastDuration+1);
    if ActivateWaitbar
        waitbar((TimeInd-RangeTestPredInd(1))/(RangeTestPredInd(2)-RangeTestPredInd(1)))
    end
end
if ActivateWaitbar
    close(h)
end

if strcmp("PVPlants_1", TargetName)
    Prediction(Prediction<20)=0;
    PredictionMat(PredictionMat<20)=0;
    DayTestVec=RangeTestDate(1):caldays(1):RangeTestDate(2);
    
    SunTab=[1, 8, 17; 2, 7, 18; 3, 6, 20; 4, 6, 21; 5, 5, 22; 6, 5, 22; 7, 5, 22; 8, 6, 21; 9, 7, 20; 10, 7, 19; 11, 8, 17; 12, 8, 16];
    for n=1:size(PredictionMat,2)
        Month=find(month(DayTestVec(n))==SunTab(:,1),1);
        DayVec=mod((hour(RangeTestDate(1))*TimeStepPredInd:1:size(PredictionMat,1)+hour(RangeTestDate(1))*TimeStepPredInd-1)/TimeStepPredInd, 24);
        Sunrise=DayVec<SunTab(Month,2);
        Sunset=DayVec>SunTab(Month,3);
        PredictionMat(Sunrise, n)=0;
        PredictionMat(Sunset, n)=0;
    end
end

%% Evaluation
for p=1:NumPredMethod
    MAE(:,p)=mean(abs(PredictionMat(:,:,p)-TargetMat),2); % Mean Absolute Error
    mMAPE(:,p)=mean(abs(TargetMat-PredictionMat(:,:,p))./mean(abs(TargetMat),2),2); % Mean Absolute Percentage Error
    RMSE(:,p)=sqrt(mean((PredictionMat(:,:,p)-TargetMat).^2,2)); % Mean Squared Error
    
    MAEConst(1,p)=round(mean(abs(PredictionMat(:,:,p)-TargetMat),'all'),3);
    mMAPEConst(1,p)=round(mean(abs(TargetMat-PredictionMat(:,:,p)),'all')./mean(abs(TargetMat),'all'),3);     
    RMSEConst(1,p)=round(sqrt(mean((PredictionMat(:,:,p)-TargetMat).^2,'all')),3);
    MEANConst(1,p)=round(mean(abs(TargetMat),'all'),3);
    STDConst(1,p)=round(std(TargetMat(:)),3);
end
MAESTDConst=round(MAEConst./STDConst,3);
Results=splitvars(table({'MAE'; 'mMAPE'; 'MAE/STD'; 'RMSE'; 'MEAN_ABS'; 'STD'},...
    [MAEConst; mMAPEConst; MAESTDConst; RMSEConst; MEANConst; STDConst]));
Results.Properties.VariableNames=["Metric", LegendVec] % Print the MAE results in a Table. Each column represents one Model

figure(11)
subplot(2,1,1)
title(strcat("Mean predicted vs. real ", TargetName),'Interpreter','none')
cla
hold on
plot(TimeVecPred(RangeTestPredInd(1):RangeTestPredInd(1)+24*TimeStepPredInd-1),mean(reshape(Target(RangeTestPredInd(1):end-mod(end-RangeTestPredInd(1)+1,24*TimeStepPredInd)),24*TimeStepPredInd,[]),2))
for p=1:NumPredMethod    
    plot(TimeVecPred(RangeTestPredInd(1):RangeTestPredInd(1)+24*TimeStepPredInd-1),mean(reshape(Prediction(RangeTestPredInd(1):end-mod(end-RangeTestPredInd(1)+1,24*TimeStepPredInd),p),24*TimeStepPredInd,[]),2))
end
legend([strcat("Target ", TargetName), LegendVec],'Interpreter','none')
grid on
xtickformat('HH:mm')

subplot(2,1,2)
cla
hold on
for p=1:NumPredMethod
    plot(TimeVecPred(RangeTestPredInd(1):RangeTestPredInd(1)+ForecastIntervalPredInd-1),MAE(:,p), 'Color', PlotColors(p,:))
end    
xtickformat('HH:mm')
title(strcat("Mean Absolute Error predicting 1 to ", num2str(round(ForecastIntervalPredInd/TimeStepPredInd)), " hours of ", TargetName),'Interpreter','none')
grid on
legend(LegendVec,'Interpreter','none')

end

function LegendVec = GetLegendNames(PredMethod, NumPredMethod)
LegendVec=strings;
for p=1:NumPredMethod        
    if PredMethod{p,1}==1
        LegendVec(p)="LSQ";        
    elseif PredMethod{p,1}==2
        LegendVec(p)="NARXNET";
    end
end

for p=NumPredMethod:-1:1
    a=sum(strcmp(LegendVec(1:p),LegendVec(p)))-1;
    if a>0
        LegendVec(p)=strcat(LegendVec(p),num2str(a));
    end
end
end