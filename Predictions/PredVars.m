function [PredictorMat, TargetDelayed, MaxDelayInd, Time, Range]=PredVars(MaxDelayHours, Target, Predictors, Time, Range)
%% Description
% This function generates the input variables for the DayAhead Price
% predictions.
%
% Variable description
%
%  Input
%   MaxDelayHours:      The oldest Target Value used for the
%                       prediction is MaxDelayInd Hours ago. (1,1).
%   Target:             The Time Series, Predictor Variables shall be
%                       created for. (N,1)
%   Time.Pred:          A Vector indicating the datetime of each
%                       corresponding Target Value with the same index.
%                       (N,1)
%   Predictors          A Matrix covering all Predictor Variables that
%                       shall be included in PredictorMat (N,M)
%
%  Output
%   PredictorMat:       A Matrix covering all Predictor Variables and daily
%                       and weekly mean Values (N-MaxDelayInd,:M+2)
%   TagetDelayed:       A Matrix covering Target Values. Each column
%                       shifts the Value once more. One row represents
%                       all MaxDelayInd Target Values of the past, with
%                       (1,1) represeting the latest value and
%                       (MaxDelayInd, MaxDelayInd) representing the oldest value
%   TargetCut:          Target Values without the first MaxDelayInd
%                       values, thus it is aligned with other Time Series
%   TimeCut:            Aligned Time vector without the first MaxDelayInd
%                       values
%   Range.TrainInd:     Start and end Index of the Training set. Is
%                       corrected for MaxDelayInd
%   Range.TestInd:      Start and end Index of the Testing set. Is
%                       corrected for MaxDelayInd
%   Time.StepInd:       1/Time.StepInd equals the time in hours between two
%                       consecutive values of all used Time Series
%   MaxDelayInd:        The oldest Target Value used for the
%                       prediction is MaxDelayInd values ago. (1,1).
%
%  Used in Function

%   Range.ShareTrain:	Share of the Data set that is used for Training
%   Range.ShareTest:	Share of the Data set that is used for Testing
%   MeanTargetD:        Mean hourly Target Value over the Training set
%   MeanPricesWDW:      Mean weekly Target Value over the Training set
%         ...circ:      Circular Repetition of the value, such every Time
%                       Series value is matched with is mean hourly/weekly
%                       value

%% Initialisation

Time.StepPred=Time.Pred(2)-Time.Pred(1);
Time.StepPredInd=1/(minutes(Time.Pred(2)-Time.Pred(1))/60); % H:1, HH: 2, QH: 4
MaxDelayInd=MaxDelayHours*Time.StepPredInd;

% TimeVecTrainPred=Range.TrainDate(1):
% if exist('Range.TrainDate', 'var') && exist('Range.TestDate', 'var')
TimeVecPred=Time.Start:Time.StepPred:Time.End;
Range.TrainPredInd=[max([find(Range.TrainDate(1)==TimeVecPred,1), find(~isnan(Target),1)])  find(dateshift(Range.TrainDate(2),'end','day')-Time.StepPred==TimeVecPred,1)];
%RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(Target)*ShareVal/24)*24-MaxDelayInd];
Range.TestPredInd=[find(Range.TestDate(1)==TimeVecPred,1) find(dateshift(Range.TestDate(2),'end','day')-Time.StepPred==TimeVecPred,1)];
% else
%     Range.TrainPredInd=[1 floor(length(Target)*Range.ShareTrain/(24*Time.StepInd))*(24*Time.StepInd)];
%     %RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(Target)*ShareVal/24)*24-MaxDelayInd];
%     Range.TestPredInd=[Range.TrainPredInd(2)+1 length(Target)];
% end

%% Calc Daily and Weekly Mean Values

MeanTargetD=mean(reshape(Target(Range.TrainPredInd(1):Range.TrainPredInd(2)),Time.StepPredInd*24,[]),2); % Get hourly mean Price for every time of day. 00:00 in first row, 23:00 in last row        

for k=1:7                       % Get mean Target value for every Weekday
    temp=[];
    for n=Range.TrainPredInd(1):Range.TrainPredInd(2)
        if weekday(Time.Pred(n))==k
            temp=[temp;Target(n)];
        end
    end
    MeanTargetW(mod(k+5,7)+1,1)=mean(temp);     % Monday in first row
end

MeanTargetDCirc=repmat(MeanTargetD,ceil((Range.TestPredInd(2)+MaxDelayInd)/(24*Time.StepPredInd)),1); % Repeat hourly mean time, thus it is aligned with other Time Series 
MeanTargetDCirc=MeanTargetDCirc(1:Range.TestPredInd(2)+MaxDelayInd);

MeanTargetWCirc=circshift(MeanTargetW, 7-mod(weekday(Time.Pred(Range.TrainPredInd(1))+6),7)+1); % Shift, thus Weekday at Range.TrainInd(1) is in first row.
temp=repmat(MeanTargetWCirc(1:1:end),1,24*Time.StepPredInd)'; %  Now, repeat daily values, thus every 24h of a Day has the same value.
MeanTargetWCirc=temp(1:end)';
MeanTargetWCirc=repmat(MeanTargetWCirc,ceil((Range.TestPredInd(2)+MaxDelayInd)/(24*Time.StepPredInd)/7),1); % Repeat daily mean values, thus it is aligned with other Time Series
MeanTargetWCirc=MeanTargetWCirc(1:Range.TestPredInd(2)+MaxDelayInd);

%% Creating Delayed Target Matrix and other Output Variables
%Tried to use less past values but performance decreased. Investigated
%using last 7 time of day values and last two values but performance was
%worse.
TargetDelayed=zeros(length(1:Range.TestPredInd(2)),MaxDelayInd);
for n=1:MaxDelayInd
    TargetDelayed(MaxDelayInd+1:end,n)=Target(1+MaxDelayInd-n:Range.TestPredInd(2)-n);
end

if ~isempty(Predictors)
    PredictorMat = [Predictors(1:Range.TestPredInd(2),:), ...         
                    MeanTargetDCirc(1:Range.TestPredInd(2),:), ...
                    MeanTargetWCirc(1:Range.TestPredInd(2),:), ...         
                   ]; 
else
    PredictorMat = [MeanTargetDCirc(1:Range.TestPredInd(2),:), ...
                    MeanTargetWCirc(1:Range.TestPredInd(2),:)];
end
end