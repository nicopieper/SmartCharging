ShareTrain=0.65;                         % Share of the Training Data Set
ShareVal=0.15;                           % Share of the Validation Data Set
ShareTest=1-ShareTrain-ShareVal;        % Share of the Test Data Set

RangeTrain=[1 floor(length(PricesRealH)*ShareTrain/24)*24-MaxDelay];
RangeVal=[RangeTrain(2)+1 RangeTrain(2)+floor(length(PricesRealH)*ShareVal/24)*24-MaxDelay];
RangeTest=[RangeVal(2)+1 length(PricesRealH)-MaxDelay];

xdataInput=[xdata(RangeTrain(1):RangeTrain(2),:) PricesRealDelayedH(RangeTrain(1):RangeTrain(2),:)];
xdataInput=mapminmax(xdataInput')';
xdataInputCellTrain={};
ydataInputTrain=num2cell(PricesRealCutH(RangeTrain(1):RangeTrain(2),:),2);
for n=RangeTrain(1):RangeTrain(2)
    xdataInputCellTrain{n,1}=xdataInput(n,:)';
end

xdataInput=[xdata(RangeVal(1):RangeVal(2),:) PricesRealDelayedH(RangeVal(1):RangeVal(2),:)];
xdataInput=mapminmax(xdataInput')';
xdataInputCellVal={};
ydataInputVal=num2cell(PricesRealCutH(RangeVal(1):RangeVal(2),:),2);
for n=1:RangeVal(2)-RangeVal(1)+1
    xdataInputCellVal{n,1}=xdataInput(n,:)';
end

options = trainingOptions('sgdm', ...
'MaxEpochs',20, ...
'Plots','training-progress',...
'ValidationData', {xdataInputCellVal, ydataInputVal},...
'ValidationPatience',6,...
'ValidationFrequency', 4)
%'MiniBatchSize',48, ...
%'LearnRateSchedule','piecewise', ...
%'LearnRateDropFactor',0.2, ...
%'LearnRateDropPeriod',5, ...

xdataInput=[xdata(RangeTest(1):RangeTest(2),:) PricesRealDelayedH(RangeTest(1):RangeTest(2),:)];
xdataInput=mapminmax(xdataInput')';
xdataInputCellTest={};
ydataInputTest=num2cell(PricesRealCutH(RangeTest(1):RangeTest(2),:),2);
for n=1:RangeTest(2)-RangeTest(1)+1
    xdataInputCellTest{n,1}=xdataInput(n,:)';
end


layers_1=[sequenceInputLayer(size(xdataInput,2)),  fullyConnectedLayer(32), tanhLayer, fullyConnectedLayer(1), regressionLayer];
net=trainNetwork(xdataInputCellTrain, ydataInputTrain, layers_1, options);
PredTest=predict(net,xdataInputCellTest);

mean(abs(cell2mat(PredTest)-PricesRealCutH(RangeTest(1):RangeTest(2))))