TGLM=tic;
h1=waitbar(0, 'Berechne GLM Prognosemodelle');
AccL=[];
for n=2:5
    TargetTitle=strcat("Availability_User", num2str(n)); 
    Availability=ismember(Users{n}.LogbookBase(:,1), 4:5);

    SoC=double(Users{n}.LogbookBase(:,9))/double(Users{n}.BatterySize);
    SoC1=repelem(SoC(1:24*Time.StepInd:end), 24*Time.StepInd);
    
    GeneratePrediction;
    ACF=autocorr(Availability, 110);
    [MaxACFLate, MaxACFLateInd]=max(ACF(71:110));
    AccL=[AccL; [Accuracy(1), ACF(96:98)', double(ACF(97)>ACF(86)), MaxACFLate, MaxACFLateInd+69, mean(Availability)]];
    
    waitbar((n-1)/100, h1);
end
AccL
disp(strcat("Calculated GLM Models within ", num2str(toc(TGLM)), "seconds"))
close(h1);

%% 
% Weekday=mod(weekday(Time.Vec)+5, 7)+1<=5;
% 
% figure
% plot(ACFs(:,n-1))
% 
% [TopACFCs, order]=sort(ACFs(:,n-1), 'descend');
% 
% DelayIndsNARXNET={1:90, [95:97, 96*2-1:96*2+1, 96*3-1:96*3+1]};
% 
% %%
% 
% %     Availability1=[0;double(Availability(2:end)==1 & Availability(1:end-1)==0)];
% %     Availability2=Availability1 + [Availability1(2:end); 0] + [0; Availability1(1:end-1)];
% 
% %     ACFs(:,n-1)=autocorr(Availability,96*3);
% tic
% for k=1:1
%     b = glmfit([TargetDelayedLSQ(MaxDelayIndLSQ-k:Range.TrainPredInd(2)-k,:), SoC1(MaxDelayIndLSQ-k:Range.TrainPredInd(2)-k)],Target(MaxDelayIndLSQ:Range.TrainPredInd(2)),'normal');
% end
% c=zeros(Range.TrainPredInd(2),1);
% c(Range.TestPredInd(1):Range.TestPredInd(2)) = glmval(b, [TargetDelayedLSQ(Range.TestPredInd(1)-k:Range.TestPredInd(2)-k,:), SoC1(Range.TestPredInd(1)-k:Range.TestPredInd(2)-k)], 'logit');
% toc
% 
% 
% 
% 
% %%
% figure
% plot(Time.Vec, c)
% hold on
% plot(Time.Vec, Availability(1:length(c)))
% ylim([-0.1 1.1])
% 
% l=[0,0];
% for k=0.2:0.01:0.95
% %d=movavg(c,'exponential',1);
% d=c;
% T=k;
% d(d<=T)=0;
% d(d>T)=1;
% %a2=b + [b(2:end); 0] + [0; b(1:end-1)];
% TP=sum(d(Range.TestInd(1):Range.TestInd(2))==1 & Availability(Range.TestInd(1):Range.TestInd(2))==1);
% FP=sum(d(Range.TestInd(1):Range.TestInd(2))==1 & Availability(Range.TestInd(1):Range.TestInd(2))==0);
% FN=sum(d(Range.TestInd(1):Range.TestInd(2))==0 & Availability(Range.TestInd(1):Range.TestInd(2))==1);
% 
% accuracy=sqrt(TP/(TP+FP)*TP/(TP+FN));
% l(1)=max([accuracy, l]);
% if l(1)==accuracy
%     l(2)=k;
% end
% end
% l
% 
% d=movavg(c,'exponential',10);
% T=l(2);
% d(d<=T)=0;
% d(d>T)=1;
% 
% figure
% plot(Time.Vec, d)
% hold on
% plot(Time.Vec, Availability(1:length(d)))
% ylim([-0.1 1.1])