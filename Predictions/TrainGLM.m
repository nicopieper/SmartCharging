function [GLMCoeffs] = TrainGLM(Target, TargetDelayed, PredictorMat, ForecastIntervalPredInd, RangeTrain, MaxDelayInd, GLMDistribution)
%% Description
% Tbd

%% Training
tic
opts = statset('glmfit');
opts.MaxIter = 300; % default value for glmfit is 100.

GLMCoeffs=ones(1,(size(PredictorMat,2) + size(TargetDelayed,2))+1);

h=waitbar(0, 'Berechne GLM Prognosemodelle');
for ForecastDuration=0:ForecastIntervalPredInd-1 % For each hour of ForecastInterval one prediction model is trained. That means there is one model for a one hour prediction, one for a two hour prediction etc.
    if ~isempty(PredictorMat)
        PredictorMatInput=[PredictorMat(RangeTrain(1)+MaxDelayInd+ForecastDuration:1:RangeTrain(2),:), TargetDelayed(RangeTrain(1)+MaxDelayInd:1:RangeTrain(2)-ForecastDuration,:)];  % Shift the Real Prices such that it fits to the given ForecastDuration.
    else
        PredictorMatInput=[TargetDelayed(RangeTrain(1)+MaxDelayInd:1:RangeTrain(2)-ForecastDuration,:)];  % Shift the Real Prices such that it fits to the given ForecastDuration.
    end
    
    GLMCoeffs(ForecastDuration+1,:) = glmfit(PredictorMatInput, Target(RangeTrain(1)+MaxDelayInd+ForecastDuration:1:RangeTrain(2),:),GLMDistribution, 'options', opts)';
    
    waitbar(ForecastDuration/(ForecastIntervalPredInd-1));
end
close(h)
disp(['LSQ Coefficients successfully calculated ' num2str(toc) 's'])