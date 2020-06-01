%% Preparation script for ANOVA, whole group version

%% The usual necessities
sca;
close all;
clear;
clearvars;

subjectNr = 19;

rowNr = 4*subjectNr;

%% Read the source table
originalTable = readtable('Pilot 4 all blocks.csv');
originalTableArray = table2array(originalTable(:,2:6));

%% Create the columns for the new table
subject     = [];

trns0_1     = [];
trns70_1    = [];
trns90_1    = [];
trns110_1   = [];
trns130_1   = [];

trns0_2     = [];
trns70_2    = [];
trns90_2    = [];
trns110_2   = [];
trns130_2   = [];

trns0_3     = [];
trns70_3    = [];
trns90_3    = [];
trns110_3   = [];
trns130_3   = [];

trns0_4     = [];
trns70_4    = [];
trns90_4    = [];
trns110_4   = [];
trns130_4   = [];


%% Set the subject column
for a = 1:subjectNr
    thisSubject = a;
    subject = [subject, thisSubject];
end

subject = transpose(subject);

% %% Create help arrays for the data transfer
% array1    = (1:4:73);
% array2    = (2:4:74);
% array3    = (3:4:75);
% array4    = (4:4:76);

%% Do the data transposing and moving and whatever
for b = 1:subjectNr

    i       = 1+(4*(b - 1));
    ii      = 2+(4*(b - 1));
    iii     = 3+(4*(b - 1));
    iiii    = 4+(4*(b - 1));
    
    %% First block
    trns0_1     = [trns0_1, originalTableArray(i,1)];
    trns70_1    = [trns70_1, originalTableArray(i,2)];
    trns90_1    = [trns90_1, originalTableArray(i,3)];
    trns110_1   = [trns110_1, originalTableArray(i,4)];
    trns130_1   = [trns130_1, originalTableArray(i,5)];

    %% Second block
    trns0_2     = [trns0_2, originalTableArray(ii,1)];
    trns70_2    = [trns70_2, originalTableArray(ii,2)];
    trns90_2    = [trns90_2, originalTableArray(ii,3)];
    trns110_2   = [trns110_2, originalTableArray(ii,4)];
    trns130_2   = [trns130_2, originalTableArray(ii,5)];

    %% Third block
    trns0_3     = [trns0_3, originalTableArray(iii,1)];
    trns70_3    = [trns70_3, originalTableArray(iii,2)];
    trns90_3    = [trns90_3, originalTableArray(iii,3)];
    trns110_3   = [trns110_3, originalTableArray(iii,4)];
    trns130_3  = [trns130_3, originalTableArray(iii,5)];

    %% Fourth block
    trns0_4     = [trns0_4, originalTableArray(iiii,1)];
    trns70_4    = [trns70_4, originalTableArray(iiii,2)];
    trns90_4    = [trns90_4, originalTableArray(iiii,3)];
    trns110_4   = [trns110_4, originalTableArray(iiii,4)];
    trns130_4  = [trns130_4, originalTableArray(iiii,5)];

end

%% Transpose all the arrays
trns0_1     = transpose(trns0_1);
trns70_1    = transpose(trns70_1);
trns90_1    = transpose(trns90_1);
trns110_1   = transpose(trns110_1);
trns130_1   = transpose(trns130_1);

trns0_2     = transpose(trns0_2);
trns70_2    = transpose(trns70_2);
trns90_2    = transpose(trns90_2);
trns110_2   = transpose(trns110_2);
trns130_2   = transpose(trns130_2);

trns0_3     = transpose(trns0_3);
trns70_3    = transpose(trns70_3);
trns90_3    = transpose(trns90_3);
trns110_3   = transpose(trns110_3);
trns130_3   = transpose(trns130_3);

trns0_4     = transpose(trns0_4);
trns70_4    = transpose(trns70_4);
trns90_4    = transpose(trns90_4);
trns110_4   = transpose(trns110_4);
trns130_4   = transpose(trns130_4);


%% Put the whole thing together
A = [subject, trns0_1, trns70_1, trns90_1, trns110_1, trns130_1, trns0_2, trns70_2, trns90_2, trns110_2, trns130_2,...
    trns0_3, trns70_3, trns90_3, trns110_3, trns130_3, trns0_4, trns70_4, trns90_4, trns110_4, trns130_4,];

newTable = array2table(A,'VariableNames',{'Subject Number', '0%tRNS 1', '70%tRNS 1', '90%tRNS 1', '110%tRNS 1','130%tRNS 1',...
                                                            '0%tRNS 2', '70%tRNS 2', '90%tRNS 2', '110%tRNS 2','130%tRNS 2',...
                                                            '0%tRNS 3', '70%tRNS 3', '90%tRNS 3', '110%tRNS 3','130%tRNS 3',...
                                                            '0%tRNS 4', '70%tRNS 4', '90%tRNS 4', '110%tRNS 4','130%tRNS 4'});
                                                  

writetable(newTable, 'Pilot4_LearningEffect.csv');
                                  
