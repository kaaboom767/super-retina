%% Analysis script for data of pilot 4

%% The usual necessities
sca;
close all;
clear;
clearvars;

parentAccuracy = [];
parentLevel = [];

subjects = 19;

for a = 1:subjects

      
    %% Directory stuff for data retrieval and saving
    p.SubjectsNumber = sprintf('%d', a); %use a instead of number for full group analysis

    WorkingDirData = ['D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\1.3-WP4-' p.SubjectsNumber '\']; %set directory for windows to save data
    WorkingDirData = convertCharsToStrings(WorkingDirData);

    WorkingDirAnalysis = WorkingDirData;

    AnalysisData = [WorkingDirData '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis.csv']; %set experimental file per subject
    AnalysisData = [AnalysisData{:}];
    AnalysisData = convertCharsToStrings(AnalysisData);

    DataFileCSVAccuracy = [WorkingDirAnalysis '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis_accuracy.csv']; %set folders per subject
    DataFileCSVAccuracy = [DataFileCSVAccuracy{:}];
    DataFileCSVAccuracy = convertCharsToStrings(DataFileCSVAccuracy);

    DataFileCSVLevel = [WorkingDirAnalysis '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis_level.csv']; %set folders per subject
    DataFileCSVLevel = [DataFileCSVLevel{:}];
    DataFileCSVLevel = convertCharsToStrings(DataFileCSVLevel);
    
    WorkingDirParent = 'D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\'; %set directory for windows to save data
    WorkingDirParent = convertCharsToStrings(WorkingDirParent);
    
    DataFileCSVAccuracySummary = [WorkingDirAnalysis '_bootstrapped_analysis_accuracy.csv']; %set folders per subject
    DataFileCSVAccuracySummary = [DataFileCSVAccuracySummary{:}];
    DataFileCSVAccuracySummary = convertCharsToStrings(DataFileCSVAccuracySummary);
    
    DataFileCSVLevelSummary = [WorkingDirAnalysis '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis_level.csv']; %set folders per subject
    DataFileCSVLevelSummary = [DataFileCSVLevelSummary{:}];
    DataFileCSVLevelSummary = convertCharsToStrings(DataFileCSVLevelSummary);
    
    CSVFile = readtable(AnalysisData);
    
    %Count the number of accuracy occurences
    [GCA, GRA] = groupcounts(CSVFile.Accuracy);
    %Combine the two arrays
    accuracyArray = [GRA, GCA];
    
    %Count the number of optimal noise occurences
    [GCO, GRO] = groupcounts(CSVFile.OptimalNoiseLevel_);
    %Combine the two arrays
    optimalNLArray = [GRO, GCO];
    
    accuracytable = array2table((accuracyArray), 'VariableNames',{'Accuracy','Amount'});
    %Write the table to a file
    writetable(accuracytable, DataFileCSVAccuracy);
    
    optimalNoiseTable = array2table((optimalNLArray), 'VariableNames',{'Level','Amount'});
    %Write the table to a file
    writetable(optimalNoiseTable, DataFileCSVLevel);

%     %% Concatenate the date for each subject into a bigger matrix
%     parentAccuracy  = [parentAccuracy; a; accuracyArray];
%     parentLevel     = [parentLevel; a; optimalNLArray];
%     
%     %% add to the Parent file
    
end




    
