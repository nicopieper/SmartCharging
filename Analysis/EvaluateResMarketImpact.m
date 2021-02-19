% [StorageFile, StoragePath]=uigetfile(Path.Simualtion), 'Select the Simulation');
StoragePath=Path.Simulation;
StorageFile="Users_20210214-1050_20190801-20200831_20000_1_";
if ~exist("Users", 'var')
    load(strcat(StoragePath, StorageFile))
end

TD.Main=find(ismember(Time.Vec,Users{1}.Time.Start),1)-1;
ResPoOffers=[Users{1}.ResPoOffers(:,1,:)*1000, Users{1}.ResPoOffers(:,2,:)/1000]; % [�/MW, MW]
ResEnOffers=Users{1}.ResEnOffers(:,1,:)*1000;  % [�/MWh]

ResPoCosts=[];
ResEnCosts=[];
ResEnActivated=[];

for AddOwnOffers=[2,1]
    ResOfferListsSim4H=ResOfferLists4H;
     
    for TimeInd=Users{1}.Time.VecInd(1:end-Users{1}.ControlPeriods)
        
        if mod(TimeInd-1,16)==0

            ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}=[ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}, zeros(length(ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}),1)];
            
            if AddOwnOffers==1 && ResPoOffers(floor(mod(TimeInd-1,96)/16)+1,1,floor((TimeInd-1)/96)+1)<max(ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,1)) && ResPoOffers(floor(mod(TimeInd-1,96)/16)+1,2,floor((TimeInd-1)/96)+1)>0

                ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(end+1,:)=[ResPoOffers(floor(mod(TimeInd-1,96)/16)+1,1,floor((TimeInd-1)/96)+1), ResEnOffers(floor(mod(TimeInd-1,96)/16)+1,1,floor((TimeInd-1)/96)+1), ResPoOffers(floor(mod(TimeInd-1,96)/16)+1,2,floor((TimeInd-1)/96)+1), 1];

                [~, SortedOrder]=sort(ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,1),1,'ascend');
                ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}=ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(SortedOrder,:);

                DemandOverfulfill=ResPoOffers(floor(mod(TimeInd-1,96)/16)+1,2,floor((TimeInd-1)/96)+1);
                while DemandOverfulfill>0
                    if ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(end,3)>DemandOverfulfill
                        ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(end,3)=ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(end,3)-DemandOverfulfill;
                        DemandOverfulfill=0;
                    else
                        DemandOverfulfill=DemandOverfulfill-ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(end,3);
                        ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(end,:)=[];
                    end
                end

                [~, SortedOrder]=sort(ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,2),1,'ascend');
                ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}=ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(SortedOrder,:);
            end

            
            %% Eval ResPo Costs
            
            ResPoCosts(floor((TimeInd-1)/16+1),AddOwnOffers)=sum(ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,1).*ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,3));
        
        end
        
        %% Eval ResEn Costs
        
        Demand=ResPoDemRealQH(TimeInd+TD.Main,1); % [MW]
        Costs=0;
        if AddOwnOffers==1
            ResEnActivated(TimeInd,1:3)=[0, ResPoOffers(floor(mod(TimeInd-1,96)/16)+1,2,floor((TimeInd-1)/96)+1), max([0, find(ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,4))])];
        end
        
        ResEnInd=0;
        while Demand>0
            ResEnInd=ResEnInd+1;
            if ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,3)>Demand
                Costs=Costs+ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,2)*Demand/4;
                if ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,4)==1 && AddOwnOffers==1
                    ResEnActivated(TimeInd,1)=Demand;
                end
                Demand=0;
            else
                Costs=Costs+ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,2)*ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,3)/4;
                if ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,4)==1  && AddOwnOffers==1
                    ResEnActivated(TimeInd,1)=ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,3);
                end
                Demand=Demand-ResOfferListsSim4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(ResEnInd,3);
            end
        end
        
        ResEnCosts(TimeInd,AddOwnOffers)=Costs;
        
    end
end
ResEnActivated(ResEnActivated(:,2)<0.001,:)=0;