








% N=100;
% M=2000;
% a=cell(N,1);
% b=cell(N,1);
% tic
% parfor n=1:N
%     %a{n}.b=rand(M,1);
%     a{n}=[max(rand(M)),1];
%     if a{n}(1)>49.7
%         b{n}=a{n}(1);
%     else
%         b{n}=a{n}(2);
%     end
% end
% toc
% 
% 
% tic
% for n=1:N
%     a{n}=[max(rand(M)),1];
%     if a{n}(1)>49.7
%         b{n}=a{n}(1);
%     else
%         b{n}=a{n}(2);
%     end
% end
% toc

% for n=UserNum
%         if  Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && Users{n}.Logbook(TimeInd+TD.User,1)>=5
%             Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:7));
% %             if Users{n}.Logbook(TimeInd+TD.User, 9)>Users{n}.BatterySize*1.01
% %                 error("Battery over charged")
% %             end
% %             if ~(Users{n}.Logbook(TimeInd+TD.User,9)<(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))+3 && Users{n}.Logbook(TimeInd+TD.User,9)>(Users{n}.Logbook(TimeInd+TD.User-1,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:8)) - Users{n}.Logbook(TimeInd+TD.User,4))-3)
% %                 error("Wrong addition")
% %             end
%         end
%     end
% 










% N=2000;
% M=100;
% a=zeros(N,1);
% tic
% parfor I=1:N
%     a(I)=max(eig(rand(M)));
% end
% toc
% 
% tic
% for I=1:N
%     a(I)=max(eig(rand(M)));
% end
% toc