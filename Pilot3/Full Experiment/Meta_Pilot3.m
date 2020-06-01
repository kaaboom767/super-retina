%% This is the meta script for tRNS Pilot 3. It runs the other scripts of the experiment. Pros for this meta script are the
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


%% Visual training single interval
sca;
trainingNeeded = 1;

while trainingNeeded == 1
    run training_visual_one_interval.m
    trainingInput = input('Is further training required? y/n [y]: ', 's');
    if isempty(trainingInput)
        trainingInput = 'y';
    end
    
    if trainingInput == 'n'
        trainingNeeded = 0;
    end  
end


%% Visual Threshold Estimation, Yes/No
sca;
p.SessionNr = 1;
run estimation_threshold_visual_yes_no_with_quest.m

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


%% Final Visual Threshold, YES/NO
sca;
p.SessionNr = 1;
run final_threshold_visual_yes_no_with_quest_20sd.m

qContinue = 0;
while qContinue == 0
    ask = input('Do you want to continue with the dual interval training? y/n/r [y]: ', 's');
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


%% Visual training dual interval
sca;
trainingNeeded = 1;

while trainingNeeded == 1
    run training_visual_two_interval.m
    trainingInput = input('Is further training required? y/n [y]: ', 's');
    if isempty(trainingInput)
        trainingInput = 'y';
    end
    
    if trainingInput == 'n'
        trainingNeeded = 0;
    end  
end


%% Experiment run 1
sca;
p.SessionNr = 1;
run experiment_multiple_intensities.m

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
        run experiment_2sec_interval.m
    end
end


%% Experiment run 2
sca;
p.SessionNr(:) = p.SessionNr(:) + 1;
run experiment_multiple_intensities.m

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
        run experiment_2sec_interval.m
    end
end


%% Experiment run 3
sca;
p.SessionNr(:) = p.SessionNr(:) + 1;
run experiment_multiple_intensities.m

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
        run experiment_2sec_interval.m
    end
end