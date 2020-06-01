%% This is the meta script for tRNS Pilot 4. It runs the other scripts of the experiment. Pros for this meta script are the
%% reduced need for manual input during the experiment.


%% The usual necessities
sca;
close all;
clear;
clearvars;


%% Activate meta script in all other scripts
metaScript = 1;


%% Participant Information
start_input = inputdlg({'Subject Number','Age','Gender'},'tRNS Threshold',[1 40]);
p.SubjectsNumber = start_input(1,1);
p.Age = start_input(2,1); % ppn age
p.Gender = start_input(3,1);


%% tRNS Threshold
p.SessionNr = 1;
run threshold_tRNS_with_quest.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the visual training? y/n/r [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask =='r'
        
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run threshold_tRNS_with_quest.m
    end
end


%% Visual training quadrant stuff
sca;
trainingNeeded = 1;

while trainingNeeded == 1
    run training_visual_4.m
    trainingInput = input('Is further training required? y/n [y]: ', 's');
    if isempty(trainingInput)
        trainingInput = 'y';
    end
    
    if trainingInput == 'n'
        trainingNeeded = 0;
    end  
end


%% Visual Threshold Estimation Quadrant
sca;
p.SessionNr = 1;
run estimation_threshold_visual_4.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the final visual threshold? y/n/r [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask == 'r'
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run estimation_threshold_visual_with_quest.m
    end
end


%% Final Visual Threshold Quadrant
sca;
p.SessionNr = 1;
run final_threshold_visual_4.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the first run? y/n/r [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask == 'r'
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run final_threshold_visual_with_quest_20sd.m
    end
end


%% Experiment run 1
sca;
p.SessionNr = 1;
run experiment_4.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the second run? y/n [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask == 'r'
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run experiment_4.m
    end
end


%% Experiment run 2
sca;
p.SessionNr(:) = p.SessionNr(:) + 1;
run experiment_4.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the third run? y/n [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask == 'r'
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run experiment_4.m
    end
end


%% Experiment run 3
sca;
p.SessionNr(:) = p.SessionNr(:) + 1;
run experiment_4.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the fourth run? y/n [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask == 'r'
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run experiment_4.m
    end
end


%% Experiment run 4
sca;
p.SessionNr(:) = p.SessionNr(:) + 1;
run experiment_4.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to finish the experiment? y/n [y]: ', 's');
    if isempty(ask)
        qContinue = 1;
    end
    if ask == 'y'
        qContinue = 1;
    elseif ask == 'n'
         return
    elseif ask == 'r'
        p.SessionNr(:) = p.SessionNr(:) + 1;
        run experiment_4.m
    end
end


%% Concatenate all csv files into one single file. Helps with analysis
%% Find all the csv files
csv1dir = [WorkingDir '*_Run_1_experiment.csv'];
csv1dir = convertCharsToStrings([csv1dir{:}]);
csv1dir = dir(csv1dir);
csv1 = readtable([csv1dir.folder '\' csv1dir.name]);

csv2dir = [WorkingDir '*_Run_2_experiment.csv'];
csv2dir = convertCharsToStrings([csv2dir{:}]);
csv2dir = dir(csv2dir);
csv2 = readtable([csv2dir.folder '\' csv2dir.name]);

csv3dir = [WorkingDir '*_Run_3_experiment.csv'];
csv3dir = convertCharsToStrings([csv3dir{:}]);
csv3dir = dir(csv3dir);
csv3 = readtable([csv3dir.folder '\' csv3dir.name]);

csv4dir = [WorkingDir '*_Run_4_experiment.csv'];
csv4dir = convertCharsToStrings([csv4dir{:}]);
csv4dir = dir(csv4dir);
csv4 = readtable([csv4dir.folder '\' csv4dir.name]);


%% Concatenate all csv files into a "full experiment" file
allCsv = [csv1;csv2;csv3;csv4]; % Concatenate vertically
allCsvFileName = [WorkingDir '1.3-WP4-' p.SubjectsNumber '_full_experiment'];
allCsvFileName = [allCsvFileName, '.csv'];
allCsvFileName = [allCsvFileName{:}]; %some conversion magic going on in order to make it readable by fopen()
allCsvFileName = convertCharsToStrings(allCsvFileName); %dito
writetable(allCsv, allCsvFileName);

