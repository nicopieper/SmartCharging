Temp=circshift(Availability,[ShiftInds,0,0]);
[Temp,AvailabilityOrder]=sort(sum(Temp(1:2*4*Time.StepInd,:,:),1),3, 'descend');
AvailabilityOrder=squeeze(AvailabilityOrder);


for k=1:NumDecissionGroups
%     DecissionGroups{k,1}=AvailabilityOrder((k-1)*NumUsers/NumDecisionGroups+1:k*NumUsers/NumDecisionGroups);
    DecissionGroups{k,1}=UserNum((k-1)*NumUsers/NumDecissionGroups+1:k*NumUsers/NumDecissionGroups)'-1;
    DecissionGroups{k,2}=(DecissionGroups{k,1}-1)*ControlPeriods+(1:ControlPeriods);
    DecissionGroups{k,3}=(DecissionGroups{k,1}-1)*ControlPeriods*NumCostCats+(1:ControlPeriods*NumCostCats);
    DecissionGroups{k,4}=0;
    for l=DecissionGroups{k,1}'
        DecissionGroups{k,4}=DecissionGroups{k,4} + double(Users{l+1}.Logbook(TimeInd+TD.User:4*Time.StepInd/ConstantResPoPowerPeriodsScaling:TimeInd+TD.User+ConsPeriods*length(ResPoBlockedIndices)/ConstantResPoPowerPeriodsScaling*Time.StepInd-1,7));
%         sum(squeeze(OptimalChargingEnergies(24*Time.StepInd+1:4*Time.StepInd:24*Time.StepInd+ConsPeriods*4*Time.StepInd,3,:)), 2);
    end
    DecissionGroups{k,4}=DecissionGroups{k,4}.*(ConseqMatchLastResPoOffers4HbIt>0);
end

