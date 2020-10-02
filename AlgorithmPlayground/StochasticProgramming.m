d=0:0.1:100;
G=[];
for x=0:0.1:100
    G(end+1,:)=max((1-1.5)*x+1.5*d, (1+0.1)*x-0.1*d);
end
G1=mean(G,2);
plot(d,G1)