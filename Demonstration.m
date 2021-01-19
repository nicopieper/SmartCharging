%% Intitialisation 
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
Time.Demo.Step=minutes(60);
Time.Demo.StepInd=1;
ForecastIntervalInd=48*Time.StepInd;
ChargingMatNumber=1;

%clearvars DemoPlots
tic


%% Plot #1

n=1;
DemoPlots{n}.Title=strcat("Dayahead auction price");
DemoPlots{n}.LegendLocation="northwest";

k=1;
DemoPlots{n}.Data{k}=repelem(Smard.DayaheadRealH, 4);
DemoPlots{n}.Time.Vec{k}=Time.Vec;
DemoPlots{n}.Label{k}="Price";
DemoPlots{n}.YLabel{k}="Price in €/MWh";
DemoPlots{n}.YMin{k}='dynamic';
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=2;
DemoPlots{n}.Label{k}="Prediction LSQ";
DemoPlots{n}.YLabel{k}="Price in €/MWh";
if length(DemoPlots{n}.Data)<=1
    StoragePath=strcat(Path.Prediction, "DayaheadRealH", Dl);
    %[StorageFile, StoragePath]=uigetfile(StoragePath, strcat("Select ", DemoPlots{n}.Title, " ", DemoPlots{n}.Label{k}));
    StorageFile="LSQ_20210119-1138_20180101-20200831_52h_80Preds_8hr.mat";
    load(strcat(StoragePath, StorageFile))
    DemoPlots{n}.Data{k}=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
end

DemoPlots{n}.DataMat{k}=repelem(Pred.DataMat(:,find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd, Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{n}.Time.Vec{k}=repelem(Pred.Time.Pred(find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd, Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{n}.YMin{k}='dynamic';
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=3;
DemoPlots{n}.Label{k}="Prediction NARXNET";
DemoPlots{n}.YLabel{k}="Price in €/MWh";
if length(DemoPlots{n}.Data)<=2
    StoragePath=strcat(Path.Prediction, "DayaheadRealH", Dl);
    %[StorageFile, StoragePath]=uigetfile(StoragePath, strcat("Select ", DemoPlots{n}.Title, " ", DemoPlots{n}.Label{k}));
    StorageFile="NARXNET_20210119-1036_20180901-20200831_52h_1Preds_8hr.mat";
    load(strcat(StoragePath, StorageFile))
    DemoPlots{n}.Data{k}=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
end

DemoPlots{n}.DataMat{k}=repelem(Pred.DataMat(:,find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd,Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{n}.Time.Vec{k}=repelem(Pred.Time.Pred(find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd, Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{n}.YMin{k}='dynamic';
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

toc

%% Plot #2

n=2;
if length(DemoPlots)<n || isempty(DemoPlots{n}) || ~isfield(DemoPlots{n}, "Data") || isempty(DemoPlots{n}.Data)
    %StorageFile=uigetfile(Path.Simulation, "Select the user data"');
    StorageFile="Users_20201223-0401_20180901-20200831_600_1_1.mat";
    load(strcat(Path.Simulation, StorageFile))
    Users{1}.ShiftInds=32;
end

%DemoUser=5;
DemoUser=2;
while sum(Users{DemoUser}.LogbookSource(:,4)>0)/length(Users{DemoUser}.LogbookSource(:,4))<0.03 || sum(Users{DemoUser}.LogbookSource(:,4)>0)/length(Users{DemoUser}.LogbookSource(:,4))<0.13 || sum(Users{DemoUser}.LogbookSmart(:,8)>0)/length(Users{DemoUser}.LogbookSource(:,4))>0.03  || ~Users{DemoUser}.PVPlantExists
    DemoUser=DemoUser+1;
end

DemoPlots{n}.Title=strcat("PV Power of user ", num2str(DemoUser));
DemoPlots{n}.LegendLocation="nortwest";

k=1;
DemoPlots{n}.Data{k}=double(PVPlants{Users{DemoUser}.PVPlant}.ProfileQH)/1000;
DemoPlots{n}.Time.Vec{k}=Time.Vec;
DemoPlots{n}.Label{k}=strcat("Generation");
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=-0.1;
DemoPlots{n}.YMax{k}=max(DemoPlots{n}.Data{k});
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=2;
DemoPlots{n}.Data{k}=double(PVPlants{Users{DemoUser}.PVPlant}.PredictionQH)/1000;
temp=reshape(PVPlants{Users{DemoUser}.PVPlant}.PredictionQH(Users{1}.ShiftInds+1:end-96+Users{1}.ShiftInds), 96,[]);
temp1=[temp(:,2:end), zeros(96,1)];
DemoPlots{n}.DataMat{k}=repelem(double([temp;temp1]),1,Time.StepInd*24)/1000;
DemoPlots{n}.Time.Vec{k}=Time.Vec;
DemoPlots{n}.Label{k}=strcat("Prediction");
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=-0.1;
DemoPlots{n}.YMax{k}=max(DemoPlots{n}.Data{k});
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

toc


%% Plot #3

n=3;
DemoPlots{n}.Title=strcat("Vehicle properties of user ", num2str(DemoUser));
DemoPlots{n}.LegendLocation="nortwestt";

k=1;
% DemoPlots{n}.Data{k}=double(Users{DemoUser}.LogbookSmart(:,9))/1000;
DemoPlots{n}.Data{k}=double(Users{DemoUser}.LogbookSmart(:,9))/double(Users{DemoUser}.BatterySize)*100;
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="SoC";
DemoPlots{n}.YLabel{k}="SoC in %";
DemoPlots{n}.YMin{k}=-1;
% DemoPlots{n}.YMax{k}=ceil(double(Users{DemoUser}.BatterySize)/1000/10*1.1)*10;
DemoPlots{n}.YMax{k}=115;
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=2;
DemandForecastMat=zeros(ForecastIntervalInd,length(Users{DemoUser}.LogbookSmart));
for l=1:length(Users{DemoUser}.LogbookSmart)-ForecastIntervalInd
    DemandForecastMat(:,l)=double(Users{DemoUser}.LogbookSmart(l:l+ForecastIntervalInd-1,4));
end
Demand=double(Users{DemoUser}.LogbookSmart(:,4));
DemoPlots{n}.Data{k}=Demand/1000;
DemoPlots{n}.DataSource{k}=Users{DemoUser}.LogbookSmart(:,4)/1000;
DemoPlots{n}.DataMat{k}=DemandForecastMat/1000;
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec(1:length(Users{DemoUser}.LogbookSmart)-ForecastIntervalInd);
DemoPlots{n}.Label{k}="Demand prediction";
DemoPlots{n}.YLabel{k}="Energy in kWh";
DemoPlots{n}.YMin{k}=0.01;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=2;
DemoPlots{n}.PlotColor{k}=k;

k=3;
ChargingDemoUser=squeeze(sum(Users{1}.ChargingMatSmart{ChargingMatNumber,1}(:,:,DemoUser,:),2));
ChargingDemoUserMat=[zeros(ForecastIntervalInd, Users{1}.ChargingMatSmart{ChargingMatNumber,2}),  repelem(ChargingDemoUser, 1, 24*Time.StepInd)];
ChargingDemoUser=[zeros(Users{1}.ChargingMatSmart{ChargingMatNumber,2},1); reshape(ChargingDemoUser(1:96,:), [], 1)];

% ChargingDemoUserMat=reshape(ChargingDemoUser(:), [], size(Users{1}.ChargingMatSmart,2))/1000;

DemoPlots{n}.Data{k}=sum(Users{DemoUser}.LogbookSmart(:,5:7), 2)/1000;
DemoPlots{n}.DataSource{k}=sum(Users{DemoUser}.LogbookSmart(:,5:7), 2)/1000;
DemoPlots{n}.DataMat{k}=ChargingDemoUserMat/1000;
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Assigned charging";
DemoPlots{n}.YLabel{k}="Energy in kWh";
DemoPlots{n}.YMin{k}=0.01;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=2;
DemoPlots{n}.PlotColor{k}=k;


% k=4;
% 
% 
% ChargingLiveDemoUser=squeeze(sum(Users{1}.ChargingMatSmart{7,1}(:,:,DemoUser,:),2));
% 
% DemoPlots{n}.Data{k}=ChargingLiveDemoUser(:)/1000;
% DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
% DemoPlots{n}.Label{k}="Live-assigned charging";
% DemoPlots{n}.YLabel{k}="Energy in kWh";
% DemoPlots{n}.YMin{k}=0.01;
% DemoPlots{n}.YMax{k}='dynamic';
% DemoPlots{n}.YAxis{k}=2;
% DemoPlots{n}.PlotColor{k}=k;

toc

%% Plot #4

n=4;
DemoPlots{n}.Title=strcat("Load curve of the fleet");
DemoPlots{n}.LegendLocation="northeast";

ChargingType=[zeros(Users{1}.ChargingMatSmart{ChargingMatNumber,2}, size(Users{1}.ChargingMatSmart{ChargingMatNumber,1},2)); reshape(permute(squeeze(sum(Users{1}.ChargingMatSmart{ChargingMatNumber,1}(1:96,:,:,:),3)), [1,3,2]), [], Users{1}.NumCostCats)]/1000*4;
ChargingTypeMat=repelem(permute(squeeze(sum(Users{1}.ChargingMatSmart{ChargingMatNumber,1},3)),[1,3,2]), 1,24*Time.StepInd,1)/1000*4;
ChargingTypeLive=[zeros(Users{1}.ChargingMatSmart{7,2}, size(Users{1}.ChargingMatSmart{7,1},2)); reshape(permute(squeeze(sum(Users{1}.ChargingMatSmart{7,1}(1:96,:,:,:),3)), [1,3,2]), [], Users{1}.NumCostCats)]/1000*4;

k=1;
DemoPlots{n}.Data{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataSource{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataMat{k}=squeeze(ChargingTypeMat(:,:,k));
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Spotmarket";
DemoPlots{n}.YLabel{k}="Charging Power in kW";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=8;

k=2;
DemoPlots{n}.Data{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataSource{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataMat{k}=squeeze(ChargingTypeMat(:,:,k));
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="PV";
DemoPlots{n}.YLabel{k}="Charging Power in kW";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=9;

k=3;
DemoPlots{n}.Data{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataSource{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataMat{k}=squeeze(ChargingTypeMat(:,:,k));
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Reserve energy";
DemoPlots{n}.YLabel{k}="Charging Power in kW";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=10;


toc

%% Resolve Time issues

Time.Demo.Start=max([Time.Vec(1), Range.TestDate(1)]);
Time.Demo.End=min([Time.Vec(end), Range.TestDate(2)]);
for n=1:length(DemoPlots)
    for k=1:length(DemoPlots{n}.Data)
        Time.Demo.Start=max([Time.Demo.Start, DemoPlots{n}.Time.Vec{k}(1)]);
        Time.Demo.End=min([Time.Demo.End, DemoPlots{n}.Time.Vec{k}(end)]);
    end
end

Time.Demo.Vec=(Time.Demo.Start:Time.Step:Time.Demo.End)';
Time.Demo.VecDateNum=datenum(Time.Demo.Vec);
Time.Demo.StartInd=48*Time.StepInd+1;

for n=1:length(DemoPlots)
    for k=1:length(DemoPlots{n}.Data)
        DemoPlots{n}.Time.TD{k}=find(ismember(DemoPlots{n}.Time.Vec{k}, Time.Demo.Start),1)-1;
    end
end

TimesOfPreAlgo=find(hour(TimeOfForecast)*Time.StepInd + minute(TimeOfForecast)/60*Time.StepInd==hour(Time.Demo.Vec)*Time.StepInd + minute(Time.Demo.Vec)/60*Time.StepInd);

%% DemoInit

TimeInd=Time.Demo.StartInd;
DemoInit;

%% Start Demo

for TimeInd=Time.Demo.StartInd:Time.Demo.StepInd:length(Time.Demo.Vec)
    DemoLoop;
end

clearvars DemoUser EndCounter figPVPlot figPVPred figResPoDemRealNeg figResPoDemRealPos figSoCPlot figDemoPlots{n}.Data{k} figDemoPlots{n}.Data{k}
clearvars ForcastLength ForecastDuration ForecastIntervalInd NumPredMethod p PlotColors Pred DemoPlots{n}.Label{k} PVPredQH PVQH DemoPlots{n}.Label{k} 
clearvars DemoPlots{n}.Label{k} ShowBaseScenario ShowPVPred ShowStockmarketPred DemoPlots{n}.Label{k} PlotLabel{k} DemoPlots{n}.Data{k} DemoPlots{n}.DataMat{k}
clearvars DemoPlots{n}.Data{k} StorageFile TimeDiffs TimeInd TimeOfForecast ymaxResPoDem ymaxSpotmarket yminResPoDem yminSpotmarket

