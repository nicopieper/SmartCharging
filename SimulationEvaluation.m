%% Description
% This script visualises the simulated charging behaviour of the fleet.
% Several different metrices are subject of the evaluation. It is possible 
% to evaluate the metrices with respect to specific user characteristics.
% In the definition of TargetNum, choose the user variable the
% metrices shall be investigated in dependence of. TargetLabels specifies
% the characterstics of this user variable. Some fleet metrices can be
% compared to measurement of real EV charging processes conducted by
% ELaadNL. Subject of the evaluation are the charging frequency, energy
% charged per charging process, energy charged per day per user, share of
% energy that was charged privately, arrival and Connection time at 
% charging point, load profile, mileage and energy consumption. Many of the
% metrices are calculated for private charging and public charging
% seperately.
% This script evaluates user variable that is present in the workspace. If
% no user data was loaded yet, it loads the most recent one from the 
% Path.Simulation.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script


%% Set Evaluation options

ShowTargetLabels=false; % split fleet into subfleet dependend on user characteristics
ShowAll=true; % plot the metrices in sum of all subfleets
ShowELaad=true; % compare metrices to measurement data from ELaadNL
ClearWorkspace=false; % clear the workspace from all temporary variables at the end


%% Load user data

if ~exist("Users", "var") % if a user variable is present, do not load it newly
    StorageFiles=dir(strcat(Path.Simulation, Dl, "Users*")); % else choose the one with the latest date
    [~, StorageInd]=max(datetime([StorageFiles.datenum],'ConvertFrom','datenum'));
    load(strcat(Path.Simulation, Dl, StorageFiles(StorageInd).name))
end


%% Define target groups

% Chose the user variable characteristics the fleet shall be split with
% respect to

TargetLabels=["small"; "medium"; "large"; "transporter"]; % use this if the fleet shall be splitted with respect to the vehicle size
%TargetLabels=["one user"; "only one user"; "several users"; "undefined"];  % split with respect to the number of users of the vehicle
%TargetLabels=["company car"; "fleet vehicle"; "undefined"]; % split with  respect to the vehicle utilisation
%TargetLabels=[0.5; 1; 3; 1000]; % split with respect to the distance between home charging point and company
%TargetLabels=[hours(10); hours(12); hours(14); hours(24)]; % split with respect to the average parking time at the private charger

% Chose the user variable

TargetGroups=cell(length(TargetLabels),1);
for n=2:length(Users)
     TargetNum=find(strcmp(Users{n}.VehicleSize,TargetLabels),1); % use this if the fleet shall be splitted with respect to the vehicle size
%     TargetNum=find(strcmp(Users{n}.NumUsers,TargetLabels),1); % split with respect to the number of users of the vehicle
%     TargetNum=find(strcmp(Users{n}.VehicleUtilisation,TargetLabels),1); % split with  respect to the vehicle utilisation
%     TargetNum=find(Users{n}.DistanceCompanyToHome<TargetLabels,1); % split with respect to the distance between home charging point and company
%     TargetNum=find(Users{n}.AvgHomeParkingTime<TargetLabels,1); % split with respect to the average parking time at the private charger

    TargetGroups{TargetNum}=[TargetGroups{TargetNum} n];
end
ExistingTargetLabels=find(cellfun('length', TargetGroups)>0)';
NumExistingTargetLabels=numel(ExistingTargetLabels);


%% Auxillary variable initialisation 

DataTable=table(TargetLabels(ExistingTargetLabels));
Location=["Home"; "Other"];

if ShowELaad && ~exist('ELaad', 'var')
    GetELaadData;
end

DayVecHourly=datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis');
DayVecQuaterly=datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):minutes(15):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis')-minutes(15);


%% Charging frequency

ChargeProcesses=cell(length(TargetLabels),2);
ChargeProcessesPerWeek=cell(length(TargetLabels),2);
for k=ExistingTargetLabels
    for n=TargetGroups{k}
        Users{n}.ChargeProcessesHomeBase=sum(ismember(Users{n}.Logbook(2:end,1),4:5) & ~ismember(Users{n}.Logbook(1:end-1,1), 4:5));
        Users{n}.ChargeProcessesOtherBase=sum(ismember(Users{n}.Logbook(2:end,1),6:7) & ~ismember(Users{n}.Logbook(1:end-1,1),6:7));
        Users{n}.ChargeProcessesOtherBase1=sum(Users{n}.Logbook(2:end,8)>0 & Users{n}.Logbook(1:end-1,8)==0);
        ChargeProcesses{k,1}(n)=Users{n}.ChargeProcessesHomeBase;
        ChargeProcesses{k,2}(n)=Users{n}.ChargeProcessesOtherBase;
    end
    ChargeProcessesPerWeek{k,1}=sum(ChargeProcesses{k,1})/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))*7/length(TargetGroups{k});
    ChargeProcessesPerWeek{k,2}=sum(ChargeProcesses{k,2})/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))*7/length(TargetGroups{k});
end
ChargeProcessesPerWeek=ChargeProcessesPerWeek(ExistingTargetLabels,:);
DataTable.ChargingPorcessesPerWeek=round(cell2mat(ChargeProcessesPerWeek)*100)/100;
disp(strcat("The users charge in average ", num2str(mean(cell2mat(ChargeProcessesPerWeek(:,1)))), " times per week at home and ", num2str(mean(cell2mat(ChargeProcessesPerWeek(:,2))))," times per week at ohter locations"))
disp(strcat(num2str(sum(cellfun(@sum, ChargeProcesses(:,1)))/(sum(cellfun(@sum, ChargeProcesses(:,1))) + sum(cellfun(@sum, ChargeProcesses(:,2))))*100), " % of all charging processes took place at home"))


%% Energy charged per charging process

EnergyPerChargingProcess=cell(length(TargetLabels),2);
for k=ExistingTargetLabels
    EnergyPerChargingProcess{k,1}=-ones(length(Users)-1*1000,1);
    EnergyPerChargingProcess{k,2}=-ones(length(Users)-1*1000,1);
    cols=[(5:7)', [8;0;0]];
    for col=cols
        col=col(col~=0);
        counter=1;
        for n=TargetGroups{k}
            ChargingBlocks=[find(sum(Users{n}.Logbook(1:end,col),2)>0 & [0; sum(Users{n}.Logbook(1:end-1,col),2)]<=0), find(sum(Users{n}.Logbook(1:end,col),2)>0 & [sum(Users{n}.Logbook(2:end,col),2);0]<=0)];
            for h=1:size(ChargingBlocks,1)
                % Target 2, other last two rows have way too high energy
                % charged. needs to be fixed!
                EnergyPerChargingProcess{k,find(sum(col==cols,1))}(counter,1)=sum(Users{n}.Logbook(ChargingBlocks(h,1):ChargingBlocks(h,2),col), 'all');
                counter=counter+1;
            end
        end
        EnergyPerChargingProcess{k,find(sum(col==cols,1))}=EnergyPerChargingProcess{k,find(sum(col==cols,1))}(EnergyPerChargingProcess{k,find(sum(col==cols,1))}~=-1);
    end
end

EnergyPerChargingProcess=EnergyPerChargingProcess(ExistingTargetLabels,:);
figure(10)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        [counts, centers]=hist(cat(1, EnergyPerChargingProcess{:,col})/1000, 0:4:100);
        plot(centers, counts./sum(counts))
        legappend(l, "Simulation");
    end
    if ShowTargetLabels
        for k=1:NumExistingTargetLabels
            [counts, centers]=hist(EnergyPerChargingProcess{k, col}/1000, 0:4:100);
            plot(centers, counts./sum(counts))
            legappend(l, TargetLabels(ExistingTargetLabels(k)));
        end
    end
    if ShowELaad
        [counts, centers]=hist(ELaad.EnergyDemand(:,col+1), 0:4:100);
        plot(centers, counts./sum(counts))
        legappend(l, "ELaad");
    end
    title(strcat("Energy per charging event in kWh ", Location(col)))
    xlabel("Energy in kWh")
    ylabel("Probability")
end

disp(strcat("In average per charging event, ", num2str(mean(cell2mat(EnergyPerChargingProcess(:,1))/1000)), " kWh were charged at home and ", num2str(mean(cell2mat(EnergyPerChargingProcess(:,2))/1000)), " kWh at other places"))

DataTable.EnergyPerChargingProcess=round(cellfun(@mean,EnergyPerChargingProcess)/1000*100)/100;


%% Energy charged per User

EnergyCharged=cell(length(TargetLabels),2);
for k=ExistingTargetLabels
    for n=TargetGroups{k}
        EnergyCharged{k,1}(end+1)=sum(Users{n}.Logbook(1:end,5:7),'all');
        EnergyCharged{k,2}(end+1)=sum(Users{n}.Logbook(1:end,8));
    end
end
EnergyCharged=EnergyCharged(ExistingTargetLabels,:);
EnergyChargedPerDayPerVehicle=cellfun(@sum,EnergyCharged)/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))/1000./cellfun(@length, TargetGroups(ExistingTargetLabels));
HomeChargingQuote=sum(EnergyChargedPerDayPerVehicle(:,1))/sum(EnergyChargedPerDayPerVehicle,'all');
disp(strcat("The users charged in average ", num2str(sum(cellfun(@sum, EnergyCharged), 'all')/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1))/1000/length(Users)-1), " kWh per day"))
disp(strcat(num2str(HomeChargingQuote*100), " % of all energy was charged at home"))


%% Arrival and Connection time at charging point

ConnectionTime=cell(length(TargetLabels),2);
ArrivalTimes=cell(length(TargetLabels),2);
AvailabilityTimes=zeros(length(Users{2}.Logbook),2,length(TargetLabels));
for k=ExistingTargetLabels
    ConnectionTime{k,1}=[];
    ConnectionTime{k,2}=[];
    ArrivalTimes{k,1}=NaT(0,0, 'TimeZone', 'Africa/Tunis');
    ArrivalTimes{k,2}=NaT(0,0, 'TimeZone', 'Africa/Tunis');
    for n=TargetGroups{k}
        ConnectionBlocksHome=[find(ismember(Users{n}.Logbook(1:end,1),4:5) & ~ismember([0;Users{n}.Logbook(1:end-1,1)],4:5)), find(ismember(Users{n}.Logbook(1:end,1),4:5) & ~ismember([Users{n}.Logbook(2:end,1);0],4:5))];
        ConnectionBlocksOther=[find(ismember(Users{n}.Logbook(1:end,1),6:7) & ~ismember([0;Users{n}.Logbook(1:end-1,1)],6:7)), find(ismember(Users{n}.Logbook(1:end,1),6:7) & ~ismember([Users{n}.Logbook(2:end,1);0],6:7))];
        ConnectionTime{k,1}=[ConnectionTime{k,1}; (ConnectionBlocksHome(:,2)-ConnectionBlocksHome(:,1)+1)*Time.StepMin];
        ConnectionTime{k,2}=[ConnectionTime{k,2}; (ConnectionBlocksOther(:,2)-ConnectionBlocksOther(:,1)+1)*Time.StepMin];
        ArrivalTimes{k,1}=[ArrivalTimes{k,1}; datetime(ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1), hour(Users{1}.Time.Vec(ConnectionBlocksHome(:,1)))', minute((Users{1}.Time.Vec(ConnectionBlocksHome(:,1))))',zeros(length(ConnectionBlocksHome),1), 'TimeZone', 'Africa/Tunis')];
        ArrivalTimes{k,2}=[ArrivalTimes{k,2}; datetime(ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1), hour(Users{1}.Time.Vec(ConnectionBlocksOther(:,1)))', minute((Users{1}.Time.Vec(ConnectionBlocksOther(:,1))))',zeros(length(ConnectionBlocksOther),1), 'TimeZone', 'Africa/Tunis')];
        AvailabilityTimes(:,1,k)=AvailabilityTimes(:,1,k)+ismember(Users{n}.Logbook(1:end,1),4:5);
        AvailabilityTimes(:,2,k)=AvailabilityTimes(:,2,k)+ismember(Users{n}.Logbook(1:end,1),6:7);
    end
end
ConnectionTime=ConnectionTime(ExistingTargetLabels,:);
ArrivalTimes=ArrivalTimes(ExistingTargetLabels,:);
AvailabilityTimes=AvailabilityTimes(:,:,ExistingTargetLabels)./permute((ones(1,1,1).*cellfun(@numel, TargetGroups(ExistingTargetLabels))), [2,3,1]);
if isfield(Users{1}.Time, 'StepInd')
    AvailabilityTimes=squeeze(mean(reshape(AvailabilityTimes(1:floor(size(AvailabilityTimes,1)/(24*Users{1}.Time.StepInd))*24*Users{1}.Time.StepInd, :, :), 24*Users{1}.Time.StepInd, [], 2, NumExistingTargetLabels), 2));
else
    AvailabilityTimes=squeeze(mean(reshape(AvailabilityTimes(1:floor(size(AvailabilityTimes,1)/(24*4))*24*4, :, :), 24*4, [], 2, NumExistingTargetLabels), 2));
end

figure(11)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        [counts, centers]=hist(cat(1, ConnectionTime{:,col}), (0:2:48)*60);
        plot(centers/60, counts./sum(counts))
        legappend(l, "Simulation");
    end
    if ShowTargetLabels
        for k=1:NumExistingTargetLabels
            [counts, centers]=hist(ConnectionTime{k,col}, (0:2:48)*60);
            plot(centers/60, counts./sum(counts))
            legappend(l, TargetLabels(ExistingTargetLabels(k)));
        end
    end
    if ShowELaad
        [counts, centers]=hist(ELaad.ConnectionTime(:,col+1), (0:2:48));
        plot(centers, counts./sum(counts))
        legappend(l, "ELaad");
    end
    title(strcat("Connection to charging point duration at ", Location(col)))
    xlabel("Duration in hours")
    ylabel("Probability")
end

figure(12)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        [counts, edges]=histcounts(cat(1, ArrivalTimes{:,col}), DayVecQuaterly);
        centers=edges(1:end-1)+(edges(2)-edges(1))/2;
        plot(centers, counts./sum(counts))
        legappend(l, "Simulation");
    end
    if ShowTargetLabels
        [nrows,~] = cellfun(@size, ArrivalTimes(:,col));
        for k=find(nrows>0)'
            [counts, edges]=histcounts(ArrivalTimes{k,col}, DayVecHourly);
            centers=edges(1:end-1)+(edges(2)-edges(1))/2;
            plot(centers, counts./sum(counts))
            legappend(l, TargetLabels(ExistingTargetLabels(k)));
        end
    end
    if ShowELaad
        plot(datetime(1,1,1,0,30,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,1,23,30,0, 'TimeZone', 'Africa/Tunis'), sum(reshape(ELaad.ArrivalTimes(:,col), 4, []))/100)
        legappend(l, "ELaad");
    end
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    xlabel("Time of date")
    ylabel("Probability")
    title(strcat("Arrival time at charging point at ", Location(col)))
end


figure(13)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        plot(DayVecQuaterly, squeeze(mean(AvailabilityTimes(:,col,:),3)))
        legappend(l, "Simulation");
    end
    if ShowTargetLabels
        for k=1:size(AvailabilityTimes, 3)
            plot(DayVecQuaterly, AvailabilityTimes(:,col,k))
            legappend(l, TargetLabels(ExistingTargetLabels(k)));
        end
    end
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    xlabel("Time of date")
    ylabel("Probability")
    title(strcat("Availability time at charging point at ", Location(col)))
end

%% Load Profile

Load=cell(length(TargetLabels),2);
for k=ExistingTargetLabels
    Load{k,1}=zeros(96,1);
    Load{k,2}=zeros(96,1);
    for n=TargetGroups{k}
        Load{k,1}=Load{k,1}+sum(reshape(sum(Users{n}.Logbook(:,5:7), 2), 96, []),2)*4/1e3/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1));
        Load{k,2}=Load{k,2}+sum(reshape(Users{n}.Logbook(:,8), 96, []),2)*4/1e3/days(Users{1}.Time.Vec(end)-Users{1}.Time.Vec(1));
    end
    Load{k,1}=Load{k,1};
    Load{k,2}=Load{k,2};
end
Load=Load(ExistingTargetLabels,:);

figure(14)
clf
for col=1:2
    subplot(2,1,col)
    hold on
    l=legend;
    if ShowAll
        plot(DayVecQuaterly, sum(cat(2, Load{:,col}),2)/numel(cat(2,TargetGroups{:})))
        legappend(l, "Simulation");
    end
    if ShowTargetLabels
        for k=1:NumExistingTargetLabels
            plot(DayVecQuaterly, Load{k,col}/numel(TargetGroups{ExistingTargetLabels(k)}))
            legappend(l, TargetLabels(ExistingTargetLabels(k)));
        end
    end
    title(strcat("Load profile of fleet at ", Location(col)))
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
    xlabel("Time of date")
    ylabel("Load per user in kW")
end

%% Mileage and Consumption

MileageYearKm=0;
AvgConsumption=[];
l=0;
for n=2:length(Users)
    %if strcmp(Users{n}.ModelName, "VW e-Golf") || strcmp(Users{n}.ModelName, "VW e-Golf")
        MileageYearKm=MileageYearKm+Users{n}.AverageMileageYear_km;
        AvgConsumption=[AvgConsumption; Users{n}.Logbook(Users{n}.Logbook(:,4)>0, 4)/Users{n}.ChargingEfficiency, Users{n}.Logbook(Users{n}.Logbook(:,4)>0, 3)];
        %l=l+1;
    %end
end
MileageYearKm=MileageYearKm/length(Users)-1;
disp(strcat("The users drove in average ", num2str(MileageYearKm), " km per year"))
disp(strcat("The average consumption was ", num2str(sum(AvgConsumption(:,1))/sum(AvgConsumption(:,2))*100), " kWh/100km (only here charging losses included)"))

%% Coverage of VehicleNumbers

VehicleNums=[];
for k=ExistingTargetLabels
    for n=TargetGroups{k}
        VehicleNums=[VehicleNums; Users{n}.VehicleNum];
    end
end

figure(15)
clf
histogram(VehicleNums, 1:1:max(VehicleNums))
disp(strcat(num2str(length(unique(VehicleNums))), " unique Vehicles are covered by this TargetLabels"))

%% Empty Batteries

EmptyBattery=0;
for n=2:length(Users)
    EmptyBattery(n)=sum(Users{n}.Logbook(2:end,9)<=0 & Users{n}.Logbook(1:end-1,9)>0);
end
disp(strcat(num2str(sum(EmptyBattery>0)), " users experienced empty batteries"))
if sum(EmptyBattery>0)==0
    clearvars EmptyBattery
end

%% Clear Workspace

if ClearWorkspace
    clearvars ArrivalTimes centers ChargeProcesses ChargeProcessesPerWeek ChargingBlocks ChargingEfficiency col ConnectionBlocksHome ConnectionBlocksOther 
    clearvars ConnectionTime counter counts edges EnergyCharged EnergyChargedPerDayPerVehicle EnergyPerChargingProcess ExistingTargetLabels HomeChargingQuote k l 
    clearvars Location MileageYearKm n nrows NumExistingTargetLabels ShowAll ShowELaad ShowTargetLabels TargetGroups TargetNum TargetLabels
    clearvars VehicleNums StorageInd StorageFiles Load h DayVecQuaterly DayVecHourly
    clearvars AvgConsumption ClearWorkspace
end