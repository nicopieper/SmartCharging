function [Prediction, PredictionMat, TargetMat, MAE, mMAPE, RMSE] = TestPred(PredMethod, PredictorMat, TargetDelayedLSQ, TargetDelayedGLM, Target, Time,...
    Range, MaxDelayIndLSQ, MaxDelayIndNARXNET, ForecastIntervalPredInd, Demo, TargetTitle, ActivateWaitbar, Path, Save); % The actual Prediction
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
%   Time.Pred:               A Vector indicating the datetime of each
%                       corresponding Target Value with the same index.
%                       (TimeInd,1)
%   TimeStepIndices:           1/TimeStepIndices equals the Time.Pred in hours between two
%                       consecutive values of all used Time.Pred Series
%   Range.TestPredInd:          Start and end Index of the Testing set. Is
%                       corrected for MaxDelay (1,2)
%   MaxDelay:           The oldest Target value used for the
%                       prediction is MaxDelay values ago. (1,1).
%   ForecastIntervalInd:   The Number of Values of Prediction contains.
%                       ForecastIntervalInd/TimeStepIndices equals the number of
%                       hours the prediction covers. (1,1)
%   TestStartDelay:     A Delay in Values, the Test starts after
%                       Range.TestPredInd(1). (1,1)
%   Demo:               Indicates whether the Demonstration is active. A 1
%                       activates the Demo, a 0 ignores it. (1,1)
%   TargetTitle          A String Label that describes the Target, e.g. 
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
Prediction=zeros(Range.TestPredInd(2)-Range.TrainPredInd(1)+1, NumPredMethod);
% PredictionMat=zeros(ForecastIntervalPredInd, floor((Range.TestPredInd(2)-Range.TestPredInd(1))/(24*Time.StepPredInd)), NumPredMethod);
PredictionMat=zeros(ForecastIntervalPredInd, Range.TestPredInd(2)-Range.TrainPredInd(1)+1, NumPredMethod);
% TargetMat=zeros(ForecastIntervalPredInd, floor((Range.TestPredInd(2)-Range.TrainPredInd(1))/(24*Time.StepPredInd)), NumPredMethod);
TargetMat=zeros(ForecastIntervalPredInd, Range.TestPredInd(2)-Range.TrainPredInd(1)+1, NumPredMethod);
TimeInd=Range.TestPredInd(1);
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
    Time.Pred=[Time.Pred; Time.Pred(Range.TestPredInd(2))+hours(1)/Time.StepPredInd; Time.Pred(Range.TestPredInd(2))+hours(1)/Time.StepPredInd*2; Time.Pred(Range.TestPredInd(2))+hours(1)/Time.StepPredInd*3; Time.Pred(Range.TestPredInd(2))+hours(1)/Time.StepPredInd*4];
    EndCounter=TimeInd;
           
    figure(10)
    cla
    title(strcat(TargetTitle, " Prediction vs. Target at ", datestr(Time.Pred(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
    xlabel('Time.Pred')
    ylabel('Price [MWh/�]')
    grid on   
    hold on    
    
    figReal=plot(Time.Pred(TimeInd-24*Time.StepPredInd+1+i:TimeInd+i), TargetDemo(TimeInd-24*Time.StepPredInd+1+i:TimeInd+i), 'Color', [0.0000, 0.4470, 0.7410]);
    for p=1:NumPredMethod % Create one Figure Property for each model
        figPred{p}=plot(Time.Pred(max(TimeInd-ForecastIntervalPredInd+ForecastDuration, Range.TestPredInd(1)):TimeInd+ForecastDuration), Prediction(max(TimeInd-ForecastIntervalPredInd+ForecastDuration, Range.TestPredInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));        
    end       
        
    legend([strcat("Target ", TargetTitle), LegendVec],'Interpreter','none')
end

%% Start Prediction
if ActivateWaitbar
    h=waitbar(0, 'Berechne Prognose');
end
while TimeInd<=Range.TestPredInd(2)
    for ForecastDuration=0:min(ForecastIntervalPredInd-1, Range.TestPredInd(2)-TimeInd)        
        for p=1:NumPredMethod
            if PredMethod{p,1}==1 % if it is a LSQ Model
                
                if ~isempty(PredictorMat)
                    PredictorMatInput=[PredictorMat(TimeInd+ForecastDuration,:), TargetDelayedLSQ(TimeInd,:)]; % The Predictors 
                else
                    PredictorMatInput=[TargetDelayedLSQ(TimeInd,:)]; % The Predictors 
                end

                Prediction(TimeInd+ForecastDuration,p)=PredMethod{p,3}(PredMethod{p,2}(ForecastDuration+1,:), PredictorMatInput); % The LSQ Prediction, PredMethod{p,2} covers the Model Function, PredMethod{p,1} covers the LSQ Coefficients
                PredictionMat(ForecastDuration+1,TimeInd,p)=Prediction(TimeInd+ForecastDuration,p); % A vector storing all predicted Values

            elseif PredMethod{p,1}==2

                PredictorMatInput=[num2cell(PredictorMat(TimeInd+ForecastDuration,:)',1);{0}]; % Regarding current Values, the ANN uses only the Predictors, hence the target row can be zero. The delayed targets are fed in through the initial state as only one prediction per time is conducted
                PredictorMatDelayedInput=[num2cell(zeros(size(PredictorMat,2), MaxDelayIndNARXNET+ForecastDuration),1); num2cell(Target(TimeInd-MaxDelayIndNARXNET:TimeInd+ForecastDuration-1))']; % Regarding delayed Values, the ANN uses only the delayed Targets, hence the first rows are not used an can by any value
                Prediction(TimeInd+ForecastDuration,p)=cell2mat(PredMethod{p,2}{ForecastDuration+1}(PredictorMatInput, PredictorMatDelayedInput, PredMethod{p,3}))';
                PredictionMat(ForecastDuration+1,TimeInd,p)=Prediction(TimeInd+ForecastDuration,p);
               
            
            elseif PredMethod{p,1}==3
                
                if ~isempty(PredictorMat)
                    PredictorMatInput=[PredictorMat(TimeInd+ForecastDuration,:), TargetDelayedGLM(TimeInd,:)]; % The Predictors 
                else
                    PredictorMatInput=[TargetDelayedGLM(TimeInd,:)]; % The Predictors 
                end

                Prediction(TimeInd+ForecastDuration,p)=glmval(PredMethod{p,2}(ForecastDuration+1,:)', PredictorMatInput, PredMethod{p,3}); % The LSQ Prediction, PredMethod{p,2} covers the Model Function, PredMethod{p,1} covers the LSQ Coefficients
                PredictionMat(ForecastDuration+1,TimeInd,p)=Prediction(TimeInd+ForecastDuration,p); % A vector storing all predicted Values
                
            end
            
            if Demo  
                EndCounter=max(EndCounter,TimeInd+ForecastDuration);                    
                figPred{p}.YDataSource='Prediction(Range.TestPredInd(1):EndCounter,p)';
                figPred{p}.XDataSource='Time.Pred(Range.TestPredInd(1):EndCounter)';                   
                title(strcat(TargetTitle, " Prediction vs. Target at ", datestr(Time.Pred(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
                xlim([Time.Pred(TimeInd-36*Time.StepPredInd+max(0,-ForecastIntervalPredInd+24*Time.StepPredInd+ForecastDuration+1)) Time.Pred(EndCounter+3)]) % Create a moving plot 
                ylim([ymin ymax])        
                refreshdata(figPred{p}, 'caller')                
                pause(0.01/NumPredMethod)
            end
        end
        TargetMat(ForecastDuration+1,TimeInd)=Target(TimeInd+ForecastDuration);
    end    
    if Demo
        for i=0:24*Time.StepPredInd-1
            TargetDemo(TimeInd+i)=Target(TimeInd+i);
            figReal.YDataSource='TargetDemo(Range.TestPredInd(1):TimeInd+i)';
            figReal.XDataSource='Time.Pred(Range.TestPredInd(1):TimeInd+i)';
            title(strcat(TargetTitle, " Prediction vs. Target at ", datestr(Time.Pred(TimeInd+i),'dd.mm.yyyy HH:MM')),'Interpreter','none')
            ylim([ymin ymax])      
            refreshdata(figReal, 'caller')
            pause(0.01)
        end
    end  
    k=k+1;
    TimeInd=TimeInd+min(round(24*Time.StepPredInd),ForecastDuration+1);
    if ActivateWaitbar
        waitbar((TimeInd-Range.TestPredInd(1))/(Range.TestPredInd(2)-Range.TestPredInd(1)))
    end
end
if ActivateWaitbar
    close(h)
end

if Save
    PredcitionTemp=Prediction;
    PredictionMatTemp=PredictionMat;
    PredMethodTemp=PredMethod;
    for p=1:NumPredMethod
        Prediction=PredcitionTemp(:,p);
        PredictionMat=PredictionMatTemp(:,:,p);
        PredMethod=PredMethodTemp(p,:);
        Pred.Data=Prediction;
        Pred.DataMat=PredictionMat;
        Pred.Method=PredMethod;
        Pred.Target=Target;
        Pred.Time=Time;
        Pred.Range=Range;
        Pred.ForecastIntervalInd=ForecastIntervalPredInd;
        Pred.Time.Stamp=datetime('now');
        Pred.FileName=strcat(Path.Prediction, datestr(Pred.Time.Stamp, 'yyyymmdd-HHMM'), Time.IntervalFile, "_", TargetTitle, "_", LegendVec(p), "_", num2str(ForecastIntervalPredInd), "_", "_", num2str(size(PredictorMatInput,2)), "_", ".mat");
        save(Pred.FileName, "Pred", "-v7.3");
    end
Prediction=PredcitionTemp;
PredictionMat=PredictionMatTemp;
end

%% Evaluation
for p=1:NumPredMethod
    
    if PredMethod{p,1}==3
        [Accuracy, Prediction(:,p), PredictionMat(:,:,p)] = GetAccuracy(Prediction, PredictionMat, Target, Range);
        disp(strcat("The prediction accuracy was ", num2str(Accuracy(1))))
        
        figure
        plot(Time.Pred, Target)
        hold on
        plot(Time.Vec, Prediction(:,p))
        ylim([-0.1 1.1])
    end
    
    PredCoulmns=zeros(ForecastIntervalPredInd,1)==PredictionMat(:,:,p);
    PredictionMatEval=PredictionMat(:,~all(PredCoulmns,1),p);
    TargetMatEval=TargetMat(:,~all(PredCoulmns,1),p);
    MAE(:,p)=mean(abs(PredictionMatEval-TargetMatEval),2); % Mean Absolute Error
    mMAPE(:,p)=mean(abs(TargetMatEval-PredictionMatEval)./mean(abs(TargetMatEval),2),2); % Mean Absolute Percentage Error
    RMSE(:,p)=sqrt(mean((PredictionMatEval-TargetMatEval).^2,2)); % Mean Squared Error
    
    MAEConst(1,p)=round(mean(abs(PredictionMatEval-TargetMatEval),'all'),3);
    mMAPEConst(1,p)=round(mean(abs(TargetMatEval-PredictionMatEval),'all')./mean(abs(TargetMatEval),'all'),3);     
    RMSEConst(1,p)=round(sqrt(mean((PredictionMatEval-TargetMatEval).^2,'all')),3);
    MEANConst(1,p)=round(mean(abs(TargetMatEval),'all'),3);
    STDConst(1,p)=round(std(TargetMat, 0, 'all'),3);
    
end
MAESTDConst=round(MAEConst./STDConst,3);
Results=splitvars(table({'MAE'; 'mMAPE'; 'MAE/STD'; 'RMSE'; 'MEAN_ABS'; 'STD'},...
    [MAEConst; mMAPEConst; MAESTDConst; RMSEConst; MEANConst; STDConst]));
Results.Properties.VariableNames=["Metric", LegendVec] % Print the MAE results in a Table. Each column represents one Model

figure(11)
subplot(2,1,1)
title(strcat("Mean predicted vs. real ", TargetTitle),'Interpreter','none')
cla
hold on
plot(Time.Pred(Range.TestPredInd(1):Range.TestPredInd(1)+24*Time.StepPredInd-1),mean(reshape(Target(Range.TestPredInd(1):end-mod(end-Range.TestPredInd(1)+1,24*Time.StepPredInd)),24*Time.StepPredInd,[]),2))
for p=1:NumPredMethod    
    plot(Time.Pred(Range.TestPredInd(1):Range.TestPredInd(1)+24*Time.StepPredInd-1),mean(reshape(Prediction(Range.TestPredInd(1):end-mod(end-Range.TestPredInd(1)+1,24*Time.StepPredInd),p),24*Time.StepPredInd,[]),2))
end
legend([strcat("Target ", TargetTitle), LegendVec],'Interpreter','none')
grid on
xtickformat('HH:mm')

subplot(2,1,2)
cla
hold on
for p=1:NumPredMethod
    plot(Time.Pred(Range.TestPredInd(1):Range.TestPredInd(1)+ForecastIntervalPredInd-1),MAE(:,p), 'Color', PlotColors(p,:))
end    
xtickformat('HH:mm')
title(strcat("Mean Absolute Error predicting 1 to ", num2str(round(ForecastIntervalPredInd/Time.StepPredInd)), " hours of ", TargetTitle),'Interpreter','none')
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
    elseif PredMethod{p,1}==3
        LegendVec(p)="GLM";
    end
end

for p=NumPredMethod:-1:1
    a=sum(strcmp(LegendVec(1:p),LegendVec(p)))-1;
    if a>0
        LegendVec(p)=strcat(LegendVec(p),num2str(a));
    end
end
end


function [Accuracy, Prediction, PredictionMat] = GetAccuracy(Prediction, PredictionMat, Target, Range)
    Accuracy=[0,0];
    for n=0.2:0.01:0.95
        %d=movavg(c,'exponential',1);
        d=Prediction;
        Threshold=n;
        d(d<=Threshold)=0;
        d(d>Threshold)=1;
        %a2=b + [b(2:end); 0] + [0; b(1:end-1)];
        TP=sum(d(Range.TestInd(1):Range.TestInd(2))==1 & Target(Range.TestInd(1):Range.TestInd(2))==1);
        FP=sum(d(Range.TestInd(1):Range.TestInd(2))==1 & Target(Range.TestInd(1):Range.TestInd(2))==0);
        FN=sum(d(Range.TestInd(1):Range.TestInd(2))==0 & Target(Range.TestInd(1):Range.TestInd(2))==1);

        acc=sqrt(TP/(TP+FP)*TP/(TP+FN));
        Accuracy(1)=max([acc, Accuracy]);
        if Accuracy(1)==acc
            Accuracy(2)=n;
        end
    end
    Threshold=Accuracy(2);
    Prediction(Prediction<=Threshold)=0;
    Prediction(Prediction>Threshold)=1;
    PredictionMat(PredictionMat<=Threshold)=0;
    PredictionMat(PredictionMat>Threshold)=1;
end
