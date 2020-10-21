function DelayIndsNARXNETMat=GetDelayInds(DelayIndsNARXNET, ForecastIntervalPredInd, Time)
    DelayIndsNARXNETMat=[repmat(DelayIndsNARXNET{1}, ForecastIntervalPredInd,1) + (0:(ForecastIntervalPredInd-1)*~isempty(DelayIndsNARXNET{1}))', repmat(DelayIndsNARXNET{2}, ForecastIntervalPredInd, 1) + 24*Time.StepPredInd*floor((1:ForecastIntervalPredInd*(~isempty(DelayIndsNARXNET{2})))'/(24*Time.StepPredInd))];
    for n=2:size(DelayIndsNARXNETMat,2)
        rows=any(DelayIndsNARXNETMat(:,n)==DelayIndsNARXNETMat(:,1:n-1),2);
        DelayIndsNARXNETMat(rows, n) = DelayIndsNARXNETMat(rows, n)+24*Time.StepPredInd;
    end
end