DemoStart=RangeTestInd(1);
DemoStartDay=TimeVec(RangeTestInd(1));
ShowStockmarketPred=true;
ShowPVPred=true;
ShowBaseScenario=true;
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
TimeStepIndDemo=4;

NumPredMethod=1;
SpotmarketLabel=strcat("Dayahead Auction Price");
SpotmarketReal=DayaheadRealH;

if ~exist('Users', 'var') && ShowBaseScenario
    StorageFiles=dir(strcat(PathSimulationData, Dl, "Users_*"));
    [~, StorageInd]=max(datetime({StorageFiles.date}, "InputFormat", "dd-MMM-yyyy HH:mm:ss"));
    load(strcat(PathSimulationData, Dl, StorageFiles(StorageInd).name))
end

DemoUser=2;
while (Users{DemoUser}.PVPlantExists==false && ShowPVPred) || sum(Users{DemoUser}.LogbookSource(:,1)>2)<100
    DemoUser=DemoUser+1;
end

if ~exist("SpotmarketPred", "var") && ShowStockmarketPred
    PredMethodName="LSQ";
    StorageFiles=dir(strcat(PredictionDataPath, "DayaheadRealH_", PredMethodName, "*"));
    PredStart=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    PredEnd=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    FileFits=false(0);
    for n=1:size(StorageFiles,1)
        PredStart(n)=datetime(StorageFiles(n).name(end-37:end-30), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis') + hours(0);
        PredEnd(n)=datetime(StorageFiles(n).name(end-28:end-21), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis')+hours(23)+minutes(45);
        FileFits(n)=PredStart(n) <= TimeVec(DemoStart) & PredEnd(n)>=DateEnd;
    end
    if sum(FileFits)==0
        disp("No matching prediction data could be found")
    else
        load(strcat(PredictionDataPath, StorageFiles(find(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")==max(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")),1)).name))
        SpotmarketPred=interp1(TimeVecPred(ismember(TimeVecPred, TimeVec)),Prediction(ismember(TimeVecPred, TimeVec)), TimeVec);
        SpotmarketPred(end-2:end)=SpotmarketPred(end-3);
%         SpotmarketPredMat=interp1((1:ForecastIntervalPredInd)',PredictionMat(:,:), (1:1/TimeStepInd:ForecastIntervalPredInd+1-1/TimeStepInd));
        SpotmarketPredMat=interp1(1:ForecastIntervalPredInd, upsample(PredictionMat(:,ismember(TimeVecPred, TimeVec))',4)',1:1/TimeStepInd:ForecastIntervalPredInd+(TimeStepInd-1)/TimeStepInd);
        SpotmarketPredMat(end-2:end,:)=ones(3,1)*SpotmarketPredMat(end-3,:);
    end
end
ForecastIntervalInd=ForecastIntervalPredInd*TimeStepInd;
    
if length(SpotmarketReal)~= length(TimeVec) && length(SpotmarketReal) == length(TimeH)
    SpotmarketReal=interp1(TimeH,SpotmarketReal, TimeVec); % DayaheadRealQH
    SpotmarketReal(end-2:end)=SpotmarketReal(end-3);
end

if ShowPVPred
    PredMethodName="LSQ";
    StorageFiles=dir(strcat(PredictionDataPath, "PVPlants_1", "_", PredMethodName, "*"));
    PredStart=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    PredEnd=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    FileFits=false(0);
    for n=1:size(StorageFiles,1)
        PredStart(n)=datetime(StorageFiles(n).name(end-37:end-30), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis') + hours(0);
        PredEnd(n)=datetime(StorageFiles(n).name(end-28:end-21), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis')+hours(23)+minutes(45);
        FileFits(n)=PredStart(n) <= TimeVec(DemoStart) & PredEnd(n)>=DateEnd;
    end
    if sum(FileFits)==0
        disp("No matching prediction data could be found")
    else
        load(strcat(PredictionDataPath, StorageFiles(find(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")==max(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")),1)).name))
        PVPredQH=Prediction(ismember(TimeVecPred, TimeVec));
        PVPredMat=PredictionMat;
    end
end

ResPoDemLabel="Secondary Reserve Capacity Energy Demand";
ResEnPricesLabel="Secondary Reserve Capacity & Energy Price";

SoCPlotLabel=strcat("SoC of the Vehicle of User ", num2str(DemoUser));
PVPlotLabel=strcat("PV Generation Power of User ", num2str(DemoUser));

TimeVecDateNum=datenum(TimeVec);

TimeInd=DemoStart;
SimulationDemoInit;
for TimeInd=DemoStart:TimeStepIndDemo:RangeTestInd(2)
    SimulationDemoLoop;
end

