%% This script is used to concatenate csv files from participants of pilot 3


%% The usual necessities
sca;
close all;
clear;
clearvars;

subjectCount = 15; % number of subjects

for i = 1:subjectCount
    ii = sprintf('%1d', i);
    %% Directory stuff for data storage
    WorkingDir = ['\Pilot3\1.3-WP3-' ii '\']; %set directory for windows to save data
    WorkingDir = convertCharsToStrings(WorkingDir);


    %% Concatenate all csv files into a "full experiment" file
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


    allCsv = [csv1;csv2;csv3]; % Concatenate vertically
    allCsvFileName = [WorkingDir '1.3-WP3-' ii '_full_experiment'];
    allCsvFileName = [allCsvFileName, '.csv']; %#ok<AGROW>
    allCsvFileName = [allCsvFileName{:}]; %some conversion magic going on in order to make it readable by fopen()
    allCsvFileName = convertCharsToStrings(allCsvFileName); %dito
    writetable(allCsv, allCsvFileName);

end
