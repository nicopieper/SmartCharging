TotalChargingSessionsWeekBase=0;
EmptyBattery=0;
MileageYearKm=0;
EnergyCharged=[];
VehicleNums=[];
for n=1:NumSimUsers
    Users{n}.NumChargingSessionsBase=sum(Users{n}.LogbookBase(2:end,1)==5 & Users{n}.LogbookBase(1:end-1,1)<5);
    TotalChargingSessionsWeekBase=TotalChargingSessionsWeekBase+Users{n}.NumChargingSessionsBase;
    EmptyBattery(n)=sum(Users{n}.LogbookBase(2:end,7)<=0 & Users{n}.LogbookBase(1:end-1,7)>0);
    EnergyCharged(n,1:2)=sum(Users{n}.LogbookBase(1:end,5:6),1);
    MileageYearKm=MileageYearKm+Users{n}.AverageMileageYear_km;
    VehicleNums=[VehicleNums; Users{n}.VehicleNum];
end
TotalChargingSessionsWeekBase=TotalChargingSessionsWeekBase/NumSimUsers/(days(DateEnd-DateStart)/7)
sum(EmptyBattery>0)
EnergyChargedPerDayPerVehicle=mean(EnergyCharged)/days(DateEnd-DateStart)/1000
HomeChargingQuote=EnergyChargedPerDayPerVehicle(1)/sum(EnergyChargedPerDayPerVehicle)
MileageYearKm=MileageYearKm/NumSimUsers
histogram(VehicleNums, length(Vehicles))