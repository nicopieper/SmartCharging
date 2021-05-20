%% Description
% This script calculates the times when vehicles are expected to be 
% available for charging. A vehicle is available for charging if it parks
% at its private charging point and the DSO does not block the charging. If
% the DSO reduces the charging power by 50%, then charging availability is
% set to 0.5 (instead of 1). The variable UseParallelAvailability controls
% whether parallel computing mehtods are used to calculate the availability
% of all users. It seems that with the used hardware in this case parallel 
% computing does not lead to noticeable performance advantages (though it
% does in case of PreAlgo using the working station with 24 CPUs).
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   PreAlgo                 This script is called by PreAlgo.m
%   LiveAlgo                This script is called by LiveAlgo.m

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

    Availability=zeros(ControlPeriodsIt,1,NumUsers);
    parfor VarCounter=1:NumUsers
        Availability(:,1,VarCounter)=max(0, ismember(Logbooks1(:,1,VarCounter), 3:5) - Logbooks2(:,1,VarCounter)/Time.StepMin) .* GridConvenientChargingAvailabilityControlPeriodIt(:,VarCounter);
    end
    
end