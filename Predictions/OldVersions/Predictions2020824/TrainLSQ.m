function [LSQCoeffs, TrainFun] = TrainLSQ(Target, TargetDelayed, PredictorMat, ForecastInterval, RangeTrain)
%% Description
% Tbd

%% Training
tic
opts = optimset('Display','off', 'UseParallel', 0); % Suppress disp output of lsqcurvefit function

%TrainFun = @(a,x) sum(a(1:size(a,2)/3).*x + a(size(a,2)/3+1:size(a,2)/3*2).*x.^2 + a(size(a,2)/3*2+1:end).*x.^3, 2);
TrainFun = @(a,x) sum(a(1:size(a,2)/2).*x + a(size(a,2)/2+1:end).*x.^2, 2);
TrainFun = @(a,x) sum(a.*x, 2);
LSQCoeffs=ones(1,(size(PredictorMat,2) + size(TargetDelayed,2)));

h=waitbar(0, 'Berechne LSQ Prognosemodelle');
for ForecastDuration=0:ForecastInterval-1 % For each hour of ForecastInterval one prediction model is trained. That means there is one model for a one hour prediction, one for a two hour prediction etc.
    PredictorMatInput=[PredictorMat(RangeTrain(1)+ForecastDuration:1:RangeTrain(2),:), TargetDelayed(RangeTrain(1):1:RangeTrain(2)-ForecastDuration,:)];  % Shift the Real Prices such that it fits to the given ForecastDuration.
    LSQCoeffs(ForecastDuration+1,:) = lsqcurvefit(TrainFun,LSQCoeffs(end,:),PredictorMatInput,Target(RangeTrain(1)+ForecastDuration:1:RangeTrain(2),:), [], [], opts); % If ForecastDuration==0, then the model for a 1h prediction is trained
    waitbar(ForecastDuration/(ForecastInterval-1));
end
close(h)
disp(['LSQ Coefficients successfully calculated ' num2str(toc) 's'])