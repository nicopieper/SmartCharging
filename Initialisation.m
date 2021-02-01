clear

%% Define time parameters

Time.Start=datetime(2019,08,01,0,0,0, 'TimeZone', 'Africa/Tunis');
Time.End=datetime(2020,08,31,23,45,0, 'TimeZone', 'Africa/Tunis');
Time.EndTrain=datetime(2019,08,31,23,45,0, 'TimeZone', 'Africa/Tunis');
Time.Step=minutes(15);
Time.StepMin=minutes(Time.Step);

%% Set data processing options

ProcessDataNew.Smard=0; 
ProcessDataNew.EC=0;
ProcessDataNew.SMAPlant=0;
ProcessDataNew.Regel=0;

%% Set data paths

Path.Database='C:\Users\nicop\Seafile\SmartCharging4EWEGo\ABC\';

Path.Base=pwd;
if ismember('\', pwd)
    Dl='\'; % Windows path delimiter
else
    Dl='/'; % Linux path delimiter
end

Path.Base=pwd;
if strcmp(Path.Base(1:5), '/home')
    Path.Database='/home/ma-student/Seafile/SmartChargingDatabase/';
    Path.SMAPlant='/home/ma-student/Seafile/SMAPlantData/PlantData/';
elseif strcmp(Path.Base(1:14), 'C:\Users\nicop')
    Path.Database='C:\Users\nicop\Seafile\SmartChargingDatabase\';
    Path.SMAPlant='C:\Users\nicop\Seafile\SMAPlantData\PlantData\';
elseif strcmp(Path.Base(1:13), 'C:\Users\Nico')
    Path.Database='C:\Users\Nico\Seafile\SmartChargingDatabase\';
    Path.SMAPlant='C:\Users\Nico\Seafile\SMAPlantData\PlantData\';
end
Path.Smard=strcat(Path.Database, 'SmardData', Dl);
Path.EC=strcat(Path.Database, 'EnergyChartsData', Dl);
Path.Regel=strcat(Path.Database, 'RegelData', Dl);
Path.Vehicle=strcat(Path.Database, 'VehicleData', Dl);
Path.Simulation=strcat(Path.Database, 'SimulationData', Dl);
Path.TrainedModel=strcat(Path.Database, 'TrainedModels', Dl);
Path.Prediction=strcat(Path.Database, 'PredictionData', Dl);
Path.OPS=strcat(Path.Database, 'OPSData', Dl);

%% Calc training and simulation parameters

Range.ShareTrain=0.8;             	% Share of the Training Data Set
Range.ShareTest=1-Range.ShareTrain;         % Share of the Test Data Set

Range.TrainDate=[Time.Start, Time.EndTrain];
Range.TestDate=[dateshift(Time.EndTrain, 'end', 'day')+hours(8), Time.End];
Time.Vec=(Time.Start:Time.Step:Time.End)';
Time.StepInd=hours(1)/Time.Step;
Time.IntervalFile=strcat(datestr(Time.Start, 'yyyymmdd'), "-", datestr(Time.End, 'yyyymmdd'));

Range.TrainInd=[find(Range.TrainDate(1)==Time.Vec,1) find(dateshift(Range.TrainDate(2),'end','day')-Time.Step==Time.Vec,1)];
Range.TestInd=[find(Range.TestDate(1)==Time.Vec,1) find(dateshift(Range.TestDate(2),'end','day')-Time.Step==Time.Vec,1)];


%% Load electricity industry data
GetSmardData;
GetEnergyChartsData;
GetSMAPlantData;
GetRegelData;



