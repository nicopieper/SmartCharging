tic
Availability=zeros(ControlPeriodsIt,1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    Availability(:,1,VarCounter)=max(0, ismember(double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,1)), 3:5) - double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,2))/Time.StepMin) .* double(Users{k}.GridConvenientChargingAvailabilityControlPeriod(end-ControlPeriodsIt+1:end));
end
toc

GCCA=zeros(ControlPeriodsIt,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    GCCA(:,VarCounter)=double(Users{k}.GridConvenientChargingAvailabilityControlPeriod(end-ControlPeriodsIt+1:end));
end

tic
Availability1=zeros(ControlPeriodsIt,1,NumUsers);
Logbooks=zeros(ControlPeriodsIt,7,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    Logbooks(:,:,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,[1,2,4:7,9]));
end

parfor VarCounter=1:NumUsers
    Availability1(:,1,VarCounter)=max(0, ismember(Logbooks(:,1,VarCounter), 3:5) - Logbooks(:,2,VarCounter)/Time.StepMin) .* GCCA(:,VarCounter);
end
toc