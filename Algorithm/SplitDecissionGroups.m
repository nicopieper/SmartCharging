%% Description
% This script splits the users into NumDecissionGroups groups. Hence in the
% following not one optimisation problem is solved but NumDecissionGroups
% problems. In this version the users are split by their user number and
% the groups remain constant during the simulation. This would change if
% the commented lines would be uncommented and the line 
% "DecissionGroups{k,1}=..." would be commented.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   PreAlgo                 This script is called by PreAlgo.m


%% Apply split each optimisation by availability

% Temp=circshift(Availability,[ShiftInds,0,0]);
% [Temp,AvailabilityOrder]=sort(sum(Temp(1:2*4*Time.StepInd,:,:),1),3, 'descend');
% AvailabilityOrder=squeeze(AvailabilityOrder);


%% Split users in groups

for k=1:NumDecissionGroups
%    DecissionGroups{k,1}=AvailabilityOrder((k-1)*NumUsers/NumDecissionGroups+1:k*NumUsers/NumDecissionGroups);
    DecissionGroups{k,1}=UserNum((k-1)*NumUsers/NumDecissionGroups+1:k*NumUsers/NumDecissionGroups)'-1;
    DecissionGroups{k,2}=(DecissionGroups{k,1}-1)*ControlPeriods+(1:ControlPeriods);
    DecissionGroups{k,3}=(DecissionGroups{k,1}-1)*ControlPeriods*NumCostCats+(1:ControlPeriods*NumCostCats);
    DecissionGroups{k,4}=0;
    for l=DecissionGroups{k,1}'
        DecissionGroups{k,4}=DecissionGroups{k,4} + double(Users{l+1}.Logbook(TimeInd+TD.User:4*Time.StepInd/ConstantResPoPowerPeriodsScaling:TimeInd+TD.User+ConsPeriods*length(ResPoBlockedIndices)/ConstantResPoPowerPeriodsScaling*Time.StepInd-1,7));
    end
    DecissionGroups{k,4}=DecissionGroups{k,4}.*(ConseqMatchLastResPoOffers4HbIt>0);
end

