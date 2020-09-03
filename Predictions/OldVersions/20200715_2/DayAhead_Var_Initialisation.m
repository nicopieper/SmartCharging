function [PredictorMat, TargetDelayed, TargetCut, TimeCut, RangeTrain, RangeTest]=PredVars(MaxDelay, Target, Time, Predictors)

%% Description
% This function generates the input variables for the DayAhead Price
% predictions.
%
% Variable description
%   TimeStep:           The 1/TimeStep equlas the time in hours between two
%                       consecutive values of all used Time Series
%   MaxDelay:           The oldest Target value used for the
%                       prediction is MaxDelay values ago
%   ShareTrain:         Share of the Data set that is used for Training
%   ShareTest:          Share of the Data set that is used for Testing
%   RangeTrain:         Start and end Index of the Training set. Is
%                       corrected for MaxDelay
%   RangeTrain:         Start and end Index of the Testing set. Is
%                       corrected for MaxDelay
%   MeanTargetD:        Mean hourly Target Value over the Training set
%   MeanPricesWDW:      Mean weekly Target Value over the Training set
%         ...circ:      Circular Repetition of the value, such every Time
%                       Series value is matched with is mean hourly/weekly
%                       value
%   TagetDelayed:       Matrix covering Target Values. Each column
%                       shifts the Value once more. One row represents
%                       all MaxDelay Target Values of the past, with
%                       (1,1) represeting the latest value and
%                       (MaxDelay, MaxDelay) representing the oldest value
%   TargetCut:          Target Values without the first MaxDelay
%                       values, thus it is aligned with other Time Series
%   TimeCut:            Aligned Time vector without the first MaxDelay
%                       values
%   PredictorMat:       Concatenated Prediction variables excluding
%                       TargetDelayed

%% Initialisation

TimeStep=minutes(Time(2)-Time(1))/60; % H:1, HH: 2, QH: 4
MaxDelay=MaxDelay*TimeStep;

ShareTrain=0.8;             	% Share of the Training Data Set
%ShareVal=0.0;                  % Share of the Validation Data Set
ShareTest=1-ShareTrain;         % Share of the Test Data Set

RangeTrain=[1 floor(length(Target)*ShareTrain/(24*TimeStep))*(24*TimeStep)-MaxDelay];
%RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(Target)*ShareVal/24)*24-MaxDelay];
RangeTest=[RangeTrain(2)+1 length(Target)-MaxDelay];

%% Calc Daily and Weekly Mean Values

MeanTargetD=mean(reshape(Target(RangeTrain(1):RangeTrain(2)),TimeStep*24,[]),2); % Get hourly mean Price for every time of day. 00:00 in first row, 23:00 in last row        

for k=1:7                       % Get mean Target value for every Weekday
    temp=[];
    for n=RangeTrain(1):RangeTrain(2)
      if weekday(Time(n))==k
        temp=[temp;Target(n)];
      end
    end
    MeanTargetW(mod(k+5,7)+1,1)=mean(temp);     % Monday in first row
end

MeanTargetDCirc=repmat(MeanTargetD,ceil((RangeTest(2)+MaxDelay-RangeTrain(1)+1)/24),1); % Repeat hourly mean time, thus it is aligned with other Time Series 
MeanTargetDCirc=MeanTargetDCirc(RangeTrain(1):RangeTest(2)+MaxDelay);

MeanTargetWCirc=circshift(MeanTargetW, 7-mod(weekday(Time(RangeTrain(1))+6),7)+1); % Shift, thus Weekday at RangeTrain(1) is in first row.
temp=repmat(MeanTargetWCirc(1:1:end),1,24)'; %  Now, repeat daily values, thus every 24h of a Day has the same value.
MeanTargetWCirc=temp(1:end)';
MeanTargetWCirc=repmat(MeanTargetWCirc,ceil((RangeTest(2)+MaxDelay-RangeTrain(1)+1)/24/7),1); % Repeat daily mean values, thus it is aligned with other Time Series
MeanTargetWCirc=MeanTargetWCirc(RangeTrain(1):RangeTest(2)+MaxDelay);

%% Creating Delayed Target Matrix and other Output Variables
%Tried to use less past values but performance decreased. Investigated
%using last 7 time of day values and last two values but performance was
%worse.
TargetDelayed=zeros(RangeTest(2),MaxDelay);
for n=1:MaxDelay
    TargetDelayed(:,n)=Target(RangeTrain(1)+MaxDelay-n:RangeTest(2)+MaxDelay-n);    
end

TargetCut=Target(RangeTrain(1)+MaxDelay:end,:);
TimeCut=Time(RangeTrain(1)+MaxDelay:end,:);

PredictorMat = [Predictors(RangeTrain(1)+MaxDelay:end,:), ...         
                MeanTargetDCirc(RangeTrain(1)+MaxDelay:end,:), ...
                MeanTargetWCirc(RangeTrain(1)+MaxDelay:end,:), ...         
               ]; 
end