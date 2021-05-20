%% Description
% This script stores the vehicle status and the driven time per time step
% of all users as double in seperate variables. Hence Logbooks1 stores all
% vehicle status and Logbooks2 stores all driving durations.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   CalcDynOptVars /        This cript is either called by CalcDynOptVars.m
%     CalcAvailability.m      or by CalcAvailability.m 

Logbooks1=zeros(ControlPeriodsIt,1,NumUsers);
Logbooks2=zeros(ControlPeriodsIt,1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    Logbooks1(:,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,1));
    Logbooks2(:,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,2));
end