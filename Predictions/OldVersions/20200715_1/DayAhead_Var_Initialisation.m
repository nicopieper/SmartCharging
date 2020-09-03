%% Description
% This function generates the input variables for the DayAhead Price
% predictions.
%
% Variable description
%   MaxDelay:           The oldest Real DayAhead price used for the
%                       prediction is MaxDelay hours ago
%   ShareTrain:         Share of the Data set that is used for Training
%   ShareTest:          Share of the Data set that is used for Testing
%   RangeTrain:         Start and end Index of the Training set. Is
%                       corrected for MaxDelay
%   RangeTrain:         Start and end Index of the Testing set. Is
%                       corrected for MaxDelay
%   MeanPricesRealTDH:  Mean hourly DayAheadPrice over the Training set
%   MeanPricesRealWDW:  Mean weekly DayAheadPrice over the Training set
%             ...circ:  Circular Repetition of the value, such every Time
%                       Series value is matched with is mean hourly/weekly
%                       value
%   PricesRealDelayedH: Matrix covering Real DayAhead Prices. Each column
%                       shifts the Prices one hour more. One row represents
%                       all MaxDelay Real DayAhead Prices of the past, with
%                       column 1 represeting the latest value and MaxDelay
%                       representing the oldest value
%   PricesRealCutH:     Real DayAhead Prices without the first MaxDelay
%                       values, thus it is aligned with other Time Series
%   TimeCutH:           Aligned Time vector without the first MaxDelay
%                       values
%   xdata:              Concatenated Prediction variables excluding
%                       PricesRealDelayedH

%% Initialisation
MaxDelay=7*24;             % The maximum delay of PricesReal value that are used as input for the prediction. mod(MaxDelay,24) must be 0.

ShareTrain=0.8;                         % Share of the Training Data Set
%ShareVal=0.0;                           % Share of the Validation Data Set
ShareTest=1-ShareTrain;        % Share of the Test Data Set

RangeTrain=[1 floor(length(PricesRealH)*ShareTrain/24)*24-MaxDelay];
%RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(PricesRealH)*ShareVal/24)*24-MaxDelay];
RangeTest=[RangeTrain(2)+1 length(PricesRealH)-MaxDelay];


for n=1:24                              % Get hourly mean Price for every time of day
    MeanPricesRealTDH(n,1)=mean(PricesRealH(n:24:RangeTrain(2))); % 00:00 in first row, 23:00 in last row
end
for k=1:7                               % Get mean Price for every Weekday
    temp=[];
    for n=1:RangeTrain(2)
      if weekday(TimeH(n))==k
        temp=[temp;PricesRealH(n)];
      end
    end
    MeanPricesRealWDW(mod(k+5,7)+1,1)=mean(temp);    % Monday in first row
end

MeanPricesRealTDHCirc=repmat(MeanPricesRealTDH,ceil((RangeTest(2)+MaxDelay-RangeTrain(1)+1)/24),1); % Repeat hourly mean time, thus it is aligned with other Time Series 
MeanPricesRealTDHCirc=MeanPricesRealTDHCirc(RangeTrain(1):RangeTest(2)+MaxDelay);

MeanPricesRealWDWCirc=circshift(MeanPricesRealWDW, 7-mod(weekday(TimeH(RangeTrain(1))+6),7)+1); % Shift, thus Weekday at RangeTrain(1) is in first row.
temp=repmat(MeanPricesRealWDWCirc(1:1:end),1,24)'; %  Now, repeat daily values, thus every 24h of a Day has the same value.
MeanPricesRealWDWCirc=temp(1:end)';
MeanPricesRealWDWCirc=repmat(MeanPricesRealWDWCirc,ceil((RangeTest(2)+MaxDelay-RangeTrain(1)+1)/24/7),1); % Repeat daily mean values, thus it is aligned with other Time Series
MeanPricesRealWDWCirc=MeanPricesRealWDWCirc(RangeTrain(1):RangeTest(2)+MaxDelay);


%Tried to use less past values but performance decreased. Investigated
%using last 7 time of day values and last two values but performance was
%worse.
PricesRealDelayedH=zeros(RangeTest(2),MaxDelay);
for n=1:MaxDelay
    PricesRealDelayedH(:,n)=PricesRealH(RangeTrain(1)+MaxDelay-n:RangeTest(2)+MaxDelay-n);    
end
% for n=1:size(PricesRealDelayedH,1)
%     PricesRealDelayedH(n,:)=PricesRealDelayedH(floor((n-1)/ForecastInterval)*ForecastInterval+1,:);
% end

PricesRealCutH=PricesRealH(RangeTrain(1)+MaxDelay:end,:);
TimeCutH=TimeH(RangeTrain(1)+MaxDelay:end,:);

xdata = [LoadPredH(RangeTrain(1)+MaxDelay:end,:), ...
         GenPredH(RangeTrain(1)+MaxDelay:end,:), ...
         NetExportH(RangeTrain(1)+MaxDelay:end,:), ...
         MeanPricesRealTDHCirc(RangeTrain(1)+MaxDelay:end,:), ...
         MeanPricesRealWDWCirc(RangeTrain(1)+MaxDelay:end,:), ...         
        ]; 
    
    
clearvars ShareTrain ShareTest MeanPricesRealTDH MeanPricesRealWDW MeanPricesRealTDHCirc MeanPricesRealWDWCirc temp