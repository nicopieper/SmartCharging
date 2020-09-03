function [Prediction, MAE, MSE] = TestPred(PredMethod, PredictorMat, TargetDelayed, Target, Time, RangeTest, MaxDelay, ForecastInterval, TestStartDelay, Demo, TargetName, ActivateWaitbar)
%% Description
% This function generates predictions basing on trained LSQ and NARXNET
% models. The predictions can be visualised in a live demonstration.
% Finally the prediction quality is evaluated.
%
% Variable description
%
%  Input
%   PredMethod:         Cell Array of the trained Models. For a LSQ Model,
%                       the first column contains the LSQ Coefficients and 
%                       the second the Model Function. For an ANN Model,
%                       the first column contains the ANNs (one for each
%                       Forecast step, {1, ForecastInterval}) and the 
%                       second one the Ai variable. The third column always
%                       indicates, which type of model this row represents.
%                       A 1 indicates a LSQ Model, a 2 an ANN Model. {P,3}
%   PredictorMat:       A Matrix covering all Predictor Variables and daily
%                       and weekly mean Values (N-MaxDelay,:M+2)
%   TagetDelayed:       A Matrix covering Target Values. Each column
%                       shifts the Value once more. One row represents
%                       all MaxDelay Target Values of the past, with
%                       (1,1) represeting the latest value and
%                       (MaxDelay, MaxDelay) representing the oldest value
%   Time:               A Vector indicating the datetime of each
%                       corresponding Target Value with the same index.
%                       (N,1)
%   RangeTest:          Start and end Index of the Testing set. Is
%                       corrected for MaxDelay (1,2)
%   MaxDelay:           The oldest Target value used for the
%                       prediction is MaxDelay values ago. (1,1).
%   ForecastInterval:   The Number of Values of Prediction contains.
%                       ForecastInterval/TimeStep equals the number of
%                       hours the prediction covers. (1,1)
%   TestStartDelay:     A Delay in Values, the Test starts after
%                       RangeTest(1). (1,1)
%   Demo:               Indicates whether the Demonstration is active. A 1
%                       activates the Demo, a 0 ignores it. (1,1)
%   TargetName          A String Label that describes the Target, e.g. 
%                       "Day Ahead Price 1h". (1,1)
%   ActivateWaitbar     Indicates whether the waitbar is active or not
%
%  Output
%   Prediction          A Matrix that contains the predicted Values of all
%                       Prediction Models. Each Column refers to one Model.
%                       (N,P)
%   MAE                 A Matrix with the Mean Absolute Error of the
%                       Predictions. One Row represents one forecasted
%                       hour. The columns represent the Models.
%                       (ForecastInterval,P)
%   MSE                 Like MAE but Mean Squared Error (ForecastInterval,P)


%% Initialisation
TimeStep=minutes(Time(2)-Time(1))/60; % Hourly:1, Half Hourly: 2, Quater Hourly: 4
NumPredMethod=size(PredMethod,1);
StartTestAt=RangeTest(1)+TestStartDelay; % The index, when the Test shall start
Prediction=zeros(RangeTest(2), NumPredMethod);
PredictionMat=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval), NumPredMethod);
TargetMat=zeros(ForecastInterval, floor((RangeTest(2)-StartTestAt)/ForecastInterval));
n=StartTestAt;
k=1;
ymin=-20; % round(min(Target)*1.1/10)*10;
ymax=60; % round(max(Target)*1.1/10)*10;


LegendVec=GetLegendNames(PredMethod, NumPredMethod);

%% Preconfigure Demo 
if Demo
    TargetDemo=zeros(size(Target,1),1);
    TargetDemo(1:n)=Target(1:n);
    ForecastDuration=0;
    i=0;    
    
    PlotColors= [0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; ...
                 0.4940, 0.1840, 0.5560; 0.4660, 0.6740, 0.1880; ...
                 0.3010, 0.7450, 0.9330; 0.6350, 0.0780, 0.1840];        
    figure(10)
    cla
    title(strcat(TargetName, " Prediction vs. Target at ", datestr(Time(n),'dd.mm.yyyy HH:MM')))
    xlabel('Time')
    ylabel('Price [MWh/€]')
    grid on   
    hold on    
    
    for p=1:NumPredMethod % Create one Figure Property for each model
        figPred{p}=plot(Time(max(n-ForecastInterval+ForecastDuration, StartTestAt):n+ForecastDuration), Prediction(max(n-ForecastInterval+ForecastDuration, StartTestAt):n+ForecastDuration,p), 'Color', PlotColors(p,:));        
    end       
    
    figReal=plot(Time(n-24*TimeStep+1+i:n+i), TargetDemo(n-24*TimeStep+1+i:n+i), 'Color', [0.0000, 0.4470, 0.7410]);
    legend([LegendVec, strcat("Target ", TargetName)])
end

%% Start Prediction
if ActivateWaitbar
    h=waitbar(0, 'Berechne Prognose');
end
while n<=RangeTest(2)
    for ForecastDuration=0:min(ForecastInterval-1, RangeTest(2)-n)        
        for p=1:NumPredMethod
            if PredMethod{p,3}==1 % if it is a LSQ Model
                PredictorMatInput=[PredictorMat(n+ForecastDuration,:), TargetDelayed(n,:)]; % The Predictors 
                Prediction(n+ForecastDuration,p)=PredMethod{p,2}(PredMethod{p,1}(ForecastDuration+1,:), PredictorMatInput); % The LSQ Prediction, PredMethod{p,2} covers the Model Function, PredMethod{p,1} covers the LSQ Coefficients
                PredictionMat(ForecastDuration+1,k,p)=Prediction(n+ForecastDuration,p); % A vector storing all predicted Values
            elseif PredMethod{p,3}==2
                PredictorMatInput=[num2cell(PredictorMat(n+ForecastDuration,:)',1);{0}]; % Regarding current Values, the ANN uses only the Predictors, hence the target row can be zero
                PredictorMatDelayedInput=[num2cell(zeros(size(PredictorMat,2),MaxDelay+ForecastDuration),1); num2cell(TargetDelayed(n-MaxDelay+1:n+ForecastDuration,1))']; % Regarding delayed Values, the ANN uses only the delayed Targets, hence the first rows are not used an can by any value
                Prediction(n+ForecastDuration,p)=cell2mat(PredMethod{p,1}{ForecastDuration+1}(PredictorMatInput, PredictorMatDelayedInput, PredMethod{p,2}))';
                PredictionMat(ForecastDuration+1,k,p)=Prediction(n+ForecastDuration,p);
            end
            if Demo                
                figPred{p}.YDataSource='Prediction(StartTestAt:n+27+max(0,-ForecastInterval+25+ForecastDuration),p)';
                figPred{p}.XDataSource='Time(StartTestAt:n+27+max(0,-ForecastInterval+25+ForecastDuration))';                   
                title(strcat(TargetName, " Prediction vs. Target at ", datestr(Time(n),'dd.mm.yyyy HH:MM')))
                xlim([Time(n-36+max(0,-ForecastInterval+25+ForecastDuration)) Time(n+27+3+max(0,-ForecastInterval+25+ForecastDuration))]) % Create a moving plot 
                ylim([ymin ymax])        
                refreshdata(figPred{p}, 'caller')                
                pause(0.01/NumPredMethod)
            end
        end        
        TargetMat(ForecastDuration+1,k)=Target(n+ForecastDuration);
    end    
    if Demo
        for i=0:24*TimeStep-1
            TargetDemo(n+i)=Target(n+i);
            figReal.YDataSource='TargetDemo(n-24*TimeStep+1+i-48:n+i)';
            figReal.XDataSource='Time(n-24*TimeStep+1+i-48:n+i)';
            title(strcat(TargetName, " Prediction vs. Target at ", datestr(Time(n+i),'dd.mm.yyyy HH:MM')))
            ylim([ymin ymax])      
            refreshdata(figReal, 'caller')
            pause(0.01)
        end
    end  
    k=k+1;
    n=n+min(24*TimeStep,ForecastDuration+1);
    if ActivateWaitbar
        waitbar((n-StartTestAt)/(RangeTest(2)-StartTestAt))
    end
end
close(h)

%% Evaluation
for p=1:NumPredMethod
    MAE(:,p)=mean(abs(PredictionMat(:,:,p)-TargetMat),2); % Mean Absolute Error
    MSE(:,p)=mean((PredictionMat(:,:,p)-TargetMat).^2,2); % Mean Squared Error              
end
MAE_Results=splitvars(table(mean(MAE,1)));
MAE_Results.Properties.VariableNames=LegendVec % Print the MAE results in a Table. Each column represents one Model
end

function LegendVec = GetLegendNames(PredMethod, NumPredMethod)
LegendVec=strings;
for p=1:NumPredMethod        
    if PredMethod{p,3}==1
        LegendVec(p)="LSQ";        
    elseif PredMethod{p,3}==2
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