%% Initialisation
clear
DateStart=datetime(2019,1,1,0,0,0, 'TimeZone', 'Africa/Tunis');
DateEnd=datetime(2020,05,31,23,45,0, 'TimeZone', 'Africa/Tunis');
DateEndTrain=datetime(2019,08,31,23,45,0, 'TimeZone', 'Africa/Tunis');
TimeStep=minutes(15);
TimeStepMin=minutes(TimeStep);

ProcessDataNewSmard=0;
ProcessDataNewEC=0;
ProcessDataNewSMAPlant=0;
ProcessDataNewRegel=0;

ShareTrain=0.8;             	% Share of the Training Data Set
%ShareVal=0.0;                  % Share of the Validation Data Set
ShareTest=1-ShareTrain;         % Share of the Test Data Set

RangeTrainDate=[DateStart, DateEndTrain];
RangeTestDate=[dateshift(DateEndTrain, 'end', 'day')+hours(8), DateEnd];
TimeVec=(DateStart:TimeStep:DateEnd)';
TimeStepInd=hours(1)/TimeStep;

if exist('RangeTrainDate', 'var') && exist('RangeTestDate', 'var')
    RangeTrainInd=[find(RangeTrainDate(1)==TimeVec,1) find(dateshift(RangeTrainDate(2),'end','day')-TimeStep==TimeVec,1)];
    %RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(Target)*ShareVal/24)*24-MaxDelayInd];
    RangeTestInd=[find(RangeTestDate(1)==TimeVec,1) find(dateshift(RangeTestDate(2),'end','day')-TimeStep==TimeVec,1)];
else
    RangeTrainInd=[1 floor(length(Target)*ShareTrain/(24*TimeStepInd))*(24*TimeStepInd)];
    %RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(Target)*ShareVal/24)*24-MaxDelayInd];
    RangeTestInd=[RangeTrainInd(2)+1 length(Target)];
end

Path=pwd;
if strcmp(Path(1:5), '/home')
    Path='/home/ma-student/Dropbox/Uni/Masterarbeit/Matlab/';
    Dl='/';
elseif strcmp(Path(1:14), 'C:\Users\nicop')
    Path='C:\Users\nicop\MATLAB\SmartCharging\';
    Dl='\';
elseif strcmp(Path(1:13), 'C:\Users\Nico')
    Path='C:\Users\Nico\Seafile\SmartCharging\';
    Dl='\';
end

%% Get Data
GetSmardData;
GetEnergyChartsData;
GetSMAPlantData;
GetRegelData;

%GetNordpoolData;
%ProcessDataNewIntraday=0;


