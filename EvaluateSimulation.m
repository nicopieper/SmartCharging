%% Energy charged per week

ChargeProcessesHome=zeros(NumSimUsers,1);
ChargeProcessesOther=zeros(NumSimUsers,1);
for n=1:NumSimUsers
    Users{n}.ChargeProcessesHomeBase=sum(Users{n}.LogbookBase(2:end,5)>0 & Users{n}.LogbookBase(1:end-1,5)==0);
    Users{n}.ChargeProcessesOtherBase=sum(Users{n}.LogbookBase(2:end,6)>0 & Users{n}.LogbookBase(1:end-1,6)==0);
    ChargeProcessesHome(n)=Users{n}.ChargeProcessesHomeBase;
    ChargeProcessesOther(n)=Users{n}.ChargeProcessesOtherBase;
end
ChargePorcessesHomePerWeek=sum(ChargeProcessesHome)/days(DateEnd-DateStart)*7/NumSimUsers;
ChargePorcessesOtherPerWeek=sum(ChargeProcessesOther)/days(DateEnd-DateStart)*7/NumSimUsers;
disp(strcat("The users charge in average ", num2str(ChargePorcessesHomePerWeek), " times per week at home"))
disp(strcat("The users charge in average ", num2str(ChargePorcessesOtherPerWeek), " times per week at ohter locations"))

%% Energy charged per charging process

EnergyPerChargingProcessHome=[];
EnergyPerChargingProcessOther=[];
for n=1:NumSimUsers
    ChargingBlocksHome=[find(Users{n}.LogbookBase(2:end,5)>0 & Users{n}.LogbookBase(1:end-1,5)==0)+1, find(Users{n}.LogbookBase(1:end-1,5)>0 & Users{n}.LogbookBase(2:end,5)==0)];
    ChargingBlocksOther=[find(Users{n}.LogbookBase(2:end,6)>0 & Users{n}.LogbookBase(1:end-1,6)==0)+1, find(Users{n}.LogbookBase(1:end-1,6)>0 & Users{n}.LogbookBase(2:end,6)==0)];
    for k=1:size(ChargingBlocksHome,1)
        EnergyPerChargingProcessHome=[EnergyPerChargingProcessHome;sum(Users{n}.LogbookBase(ChargingBlocksHome(k,1):ChargingBlocksHome(k,2),5))];
    end
    for k=1:size(ChargingBlocksOther,1)
        EnergyPerChargingProcessOther=[EnergyPerChargingProcessOther;sum(Users{n}.LogbookBase(ChargingBlocksOther(k,1):ChargingBlocksOther(k,2),6))];
    end
end
close(figure(10))
figure(10)
histogram(EnergyPerChargingProcessHome/1000, 0:4:100, 'Normalization', 'Probability')
hold on
histogram(EnergyPerChargingProcessOther/1000, 0:4:100, 'Normalization', 'Probability')
title("Energy per charging event in kWh")
legend(["Home" "Other"])
disp(strcat("The users charge in average ", num2str(mean(EnergyPerChargingProcessHome/1000)), " kWh per charging event at home"))
disp(strcat("The users charge in average ", num2str(mean(EnergyPerChargingProcessHome/1000)), " kWh per charging event at other places"))


%% Energy charged per User

EnergyCharged=[];
for n=1:NumSimUsers
    EnergyCharged(n,1:2)=sum(Users{n}.LogbookBase(1:end,5:6),1);
end
EnergyChargedPerDayPerVehicle=mean(EnergyCharged)/days(DateEnd-DateStart)/1000;
HomeChargingQuote=EnergyChargedPerDayPerVehicle(1)/sum(EnergyChargedPerDayPerVehicle);
disp(strcat("The users charged in average ", num2str(sum(EnergyChargedPerDayPerVehicle)), " kWh per day"))
disp(strcat(num2str(HomeChargingQuote*100), " % of all charging events took place at home"))

%% Arrival and Connection time at charging point

ConnectionTimeHome=[];
ConnectionTimeOther=[];
ArrivalTimesHome=NaT(0,0, 'TimeZone', 'Africa/Tunis');
ArrivalTimesOther=NaT(0,0, 'TimeZone', 'Africa/Tunis');
for n=1:NumSimUsers
    ConnectionBlocksHome=[find(ismember(Users{n}.LogbookBase(1:end,1),4:5) & ~ismember([0;Users{n}.LogbookBase(1:end-1,1)],4:5)), find(ismember(Users{n}.LogbookBase(1:end,1),4:5) & ~ismember([Users{n}.LogbookBase(2:end,1);0],4:5))];
    ConnectionBlocksOther=[find(ismember(Users{n}.LogbookBase(1:end,1),6) & ~ismember([0;Users{n}.LogbookBase(1:end-1,1)],6)), find(ismember(Users{n}.LogbookBase(1:end,1),6) & ~ismember([Users{n}.LogbookBase(2:end,1);0],6))];
    ConnectionTimeHome=[ConnectionTimeHome; (ConnectionBlocksHome(:,2)-ConnectionBlocksHome(:,1)+1)*TimeStepMin];
    ConnectionTimeOther=[ConnectionTimeOther; (ConnectionBlocksOther(:,2)-ConnectionBlocksOther(:,1)+1)*TimeStepMin];
    ArrivalTimesHome=[ArrivalTimesHome; datetime(ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1),ones(length(ConnectionBlocksHome),1), hour(TimeVec(ConnectionBlocksHome(:,1))), minute((TimeVec(ConnectionBlocksHome(:,1)))),zeros(length(ConnectionBlocksHome),1), 'TimeZone', 'Africa/Tunis')];
    ArrivalTimesOther=[ArrivalTimesOther; datetime(ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1),ones(length(ConnectionBlocksOther),1), hour(TimeVec(ConnectionBlocksOther(:,1))), minute((TimeVec(ConnectionBlocksOther(:,1)))),zeros(length(ConnectionBlocksOther),1), 'TimeZone', 'Africa/Tunis')];
end
close(figure(11))
figure(11)
histogram(ConnectionTimeHome/60, 0:2:48, 'Normalization', 'Probability')
hold on
histogram(ConnectionTimeOther/60, 0:2:48, 'Normalization', 'Probability')
title("Connection to charging point duration")
legend(["Home" "Other"])

close(figure(12))
figure(12)
histogram(ArrivalTimesHome, datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), 'Normalization', 'Probability')
hold on
histogram(ArrivalTimesOther, datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(1):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), 'Normalization', 'Probability')
xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
title("Arrival time at charging point")
legend(["Home" "Other"])


%% Mileage

MileageYearKm=0;
for n=1:NumSimUsers
    MileageYearKm=MileageYearKm+Users{n}.AverageMileageYear_km;
end
MileageYearKm=MileageYearKm/NumSimUsers;
disp(strcat("The users drove in average ", num2str(MileageYearKm), " km per year"))

%% Coverage of VehicleNumbers

VehicleNums=[];
for n=1:NumSimUsers
    VehicleNums=[VehicleNums; Users{n}.VehicleNum];
end
close(figure(13))
figure(13)
histogram(VehicleNums, length(Vehicles))

%% Empty Batteries

EmptyBattery=0;
for n=1:NumSimUsers
    EmptyBattery(n)=sum(Users{n}.LogbookBase(2:end,7)<=0 & Users{n}.LogbookBase(1:end-1,7)>0);
end
disp(strcat(num2str(sum(EmptyBattery>0)), " users experienced empty battery"))

    