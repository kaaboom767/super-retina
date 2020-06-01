

inten = q.intensity(1:40);
%x = linspace(.05,1,101);
x = linspace(0.05,max(inten),101);
P.t = 0.75;
bList = QuestBetaAnalysis(q);
figure(1)
clf
%y = zeros(length(bList),length(x));
%for i=1:length(bList)
P.b = bList;

g = 0.5;  %chance performance
e = P.t;  %threshold performance ( ~80%)

%Weibull function
k = (-log( (1-e)/(1-g)))^(1/P.b);
y = 1- (1-g)*exp(- (k*x/P.t).^P.b);

%y = Weibull(P,x);
%end
plot (x,y')
ylim([0,1]);
%xlim([0,max(inten)]);
%logx2raw;
% legend(num2str(bList'),'Location','NorthWest');
% xlabel('Intensity');
% ylabel('Proportion Correct');
% title('Varying b with t=0.3');
%