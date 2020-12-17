a1=[];
ResEnVolumen=0;
for n=2:length(Users)
	a1(n-1,:)=sum(Users{n}.LogbookSmart(:,5:8),1);
    
    ResEnVolumen=ResEnVolumen+sum(Users{n}.LogbookSmart(:,7));
end

ResEnVolumen/sum(Users{1}.ChargingMatSmart{5}(96-24*4+1:96-24*4+96,3,:,:),'all')

%%

a5=[];
for k=1:6
    a5(k)=sum(Users{1}.ChargingMatSmart{k}(:,3,:,:),'all')
end


a5(1)=sum(Users{1}.ChargingMatSmart{1}(96-8*4+1:96-8*4+96,3,:,:),'all');
a5(2)=sum(Users{1}.ChargingMatSmart{2}(96-12*4+1:96-12*4+96,3,:,:),'all');
a5(3)=sum(Users{1}.ChargingMatSmart{3}(96-16*4+1:96-16*4+96,3,:,:),'all');
a5(4)=sum(Users{1}.ChargingMatSmart{4}(96-20*4+1:96-20*4+96,3,:,:),'all');
a5(5)=sum(Users{1}.ChargingMatSmart{5}(96-24*4+1:96-24*4+96,3,:,:),'all');
a5(6)=sum(Users{1}.ChargingMatSmart{6}(1:96-28*4+96,3,:,:),'all');
a5(7)=sum(Users{1}.ChargingMatSmart{7}(1:96,3,:,:),'all');

%%

for n=2:length(Users)
	a1(n-1,:)=[sum(Users{n}.LogbookSmart(:,8)), sum(Users{n}.LogbookBase(:,8))];
end