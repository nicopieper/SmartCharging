if ~UseParallelAvailability
    
    Availability=zeros(ControlPeriodsIt,1,NumUsers);
    VarCounter=0;
    for k=UserNum
        VarCounter=VarCounter+1;
        Availability(:,1,VarCounter)=max(0, ismember(double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,1)), 3:5) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,2))/Time.StepMin) .* double(Users{k}.GridConvenientChargingAvailabilityControlPeriod(end-ControlPeriodsIt+1:end));
    end

else
    CalcLogbooks12;
    GridConvenientChargingAvailabilityControlPeriodIt=GridConvenientChargingAvailabilityControlPeriod(end-ControlPeriodsIt+1:end,1,:);

    Availability1=zeros(ControlPeriodsIt,1,NumUsers);
    parfor VarCounter=1:NumUsers
        Availability1(:,1,VarCounter)=max(0, ismember(Logbooks1(:,1,VarCounter), 3:5) - Logbooks2(:,1,VarCounter)/Time.StepMin) .* GridConvenientChargingAvailabilityControlPeriodIt(:,VarCounter);
    end
    
end