function y=interpolateTS(x, TimeQH)      
    NaNs=isnan(x(:,1));    
    Start=find(~NaNs,1,'first');
    TimeH=TimeQH(Start:4:end);  
    y=FillMissingValues(downsample(x(Start:end), 4), 4);       
    if Start==1
        y=interp1(TimeH, y, TimeQH(Start:end), 'spline');
    else
        y=[x(1:Start-1); interp1(TimeH, y, TimeQH(Start:end), 'spline')];
    end
end