%% This script is for preparing the data of Pilot 4 (and maybe 3) in order to conduct a bootstrapping analysis.

%% The usual necessities
sca;
close all;
clear;
clearvars;

subjects = 19;

for i = 1:subjects


    %% Directory stuff for data retrieval
    p.SubjectsNumber = sprintf('%d', i);
    WorkingDir = ['D:\Hyperion Cloud\ETH\Master Thesis\Data\Pilot4\1.3-WP4-' p.SubjectsNumber '\']; %set directory for windows to save data
    %WorkingDir = [WorkingDir{:}];
    WorkingDir = convertCharsToStrings(WorkingDir);

    Data = [WorkingDir '1.3-WP4-' p.SubjectsNumber '_full_experiment.csv']; %set experimental file per subject
    Data = [Data{:}];
    Data = convertCharsToStrings(Data);

    DataFile = [WorkingDir '1.3-WP4-' p.SubjectsNumber '_bootstrapping_table']; %set folders per subject
    DataFileCSV = [DataFile '.csv'];
    DataFileCSV = [DataFileCSV{:}];
    DataFileCSV = convertCharsToStrings(DataFileCSV);

    CSVFile = readtable(Data);


    %% Change "correct" to 1 and "incorrect" to 0
    CSVFile.Correctness(strcmpi(CSVFile.Correctness,'Correct')) = {1};
    CSVFile.Correctness(strcmpi(CSVFile.Correctness,'Incorrect')) = {0};
  
    
    %% Convert the columns "Correctness" and "tRNS Mode" to vectors
    Data = cell2mat(CSVFile.Correctness);


    %% Change the different tRNS conditions to numbers 0 to 4
    CSVFile.tRNSMode(strcmpi(CSVFile.tRNSMode, '0% tRNS'))      = {0}; 
    CSVFile.tRNSMode(strcmpi(CSVFile.tRNSMode, '70% tRNS'))     = {1};
    CSVFile.tRNSMode(strcmpi(CSVFile.tRNSMode, '90% tRNS'))     = {2};
    CSVFile.tRNSMode(strcmpi(CSVFile.tRNSMode, '110% tRNS'))    = {3};
    CSVFile.tRNSMode(strcmpi(CSVFile.tRNSMode, '130% tRNS'))    = {4};

    Conditions = cell2mat(CSVFile.tRNSMode);

    
    %% Put the different conditions in a table. 0%tRNS, 70%tRNS, 110%tRNS and 130%tRNS
    tRNS0       = Data(Conditions == 0);
    tRNS70      = Data(Conditions == 1);
    tRNS90      = Data(Conditions == 2);
    tRNS110     = Data(Conditions == 3);
    tRNS130     = Data(Conditions == 4);

    CSVNew = [tRNS0, tRNS70, tRNS90, tRNS110, tRNS130];


    %% Write csv file with values
    table = array2table(CSVNew,'VariableNames',{'Control','70% tRNS','90% tRNS','110% tRNS','130% tRNS'});
    writetable(table, DataFileCSV');
    
end
