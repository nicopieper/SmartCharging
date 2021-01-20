if ~strcmp(DemoPlots{n}.YMin{k}, 'dynamic')
    DemoPlots{n}.ymin{k}=DemoPlots{n}.YMin{k};
else    
    ymin=min(DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*2*Time.StepInd:min(length(DemoPlots{n}.Data{k}),TimeInd+DemoPlots{n}.Time.TD{k}+24*2*Time.StepInd)));
    ymin=ymin-abs(ymin)*0.1;
    if ymin~=0
        DemoPlots{n}.ymin{k}=round(ymin-abs(ymin)*0.1, ceil(log10(abs(ymin))));
    else
        DemoPlots{n}.ymin{k}=0;
    end
end

if ~strcmp(DemoPlots{n}.YMax{k}, 'dynamic')
    DemoPlots{n}.ymax{k}=DemoPlots{n}.YMax{k};
else    
    ymax=max(DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*2*Time.StepInd:min(length(DemoPlots{n}.Data{k}),TimeInd+DemoPlots{n}.Time.TD{k}+24*2*Time.StepInd)));
    ymax=ymax+abs(ymax)*0.1;
    if ymax~=0
    	DemoPlots{n}.ymax{k}=round(ymax+abs(ymax)*0.1, ceil(log10(abs(ymax))));
    elseif ymin<0
        DemoPlots{n}.ymax{k}=0;
    else
        DemoPlots{n}.ymax{k}=round(ymax);
    end
end
