function x=DeleteDST(x, DSTChanges, Length) % Clean up time series, thus DST values are replaced. In October estimations of missing hour are inserted, in March the extra hour becomes deleted.
    for n=size(DSTChanges,1):-1:1
%         try
        if DSTChanges(n,2)==10
            x(DSTChanges(n,1)+1:DSTChanges(n,1)+Length,:)=[];
        else            
            if Length==1
                FillMat=mean([x(DSTChanges(n,1),:); x(DSTChanges(n,1)+1,:)],1);
            else
                if isdatetime(x(1,1))
                    FillMat=x(DSTChanges(n,1),:) + transpose(1/(Length):1/(Length):1).*hours(1); % Vector of four values which increments at 15 min
                else
                    FillMat=x(DSTChanges(n,1),:) + transpose(1/(Length+1):1/(Length+1):1-1/(Length+1)).*(x(DSTChanges(n,1)+1,:)-x(DSTChanges(n,1),:)); % Vector of four values which grows linearly such that there is a smooth transition from adjacent values
                end
            end    
            x=[x(1:DSTChanges(n,1),:); FillMat; x(DSTChanges(n,1)+1:end,:)];
        end
%         catch
%             x(1:DSTChanges(n),:)
%         end
    end
end