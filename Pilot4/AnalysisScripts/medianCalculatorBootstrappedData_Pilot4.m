%% Script for calculating the mean of bootstrapping data of pilot 4

%% The usual necessities
sca;
close all;
clear;
clearvars;


subjects = 19;

for a = 1:subjects

      
    %% Directory stuff for data retrieval and saving
    p.SubjectsNumber = sprintf('%d', a); %use a instead of number for full group analysis

    WorkingDirData = ['D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\1.3-WP4-' p.SubjectsNumber '\']; %set directory for analysis
    WorkingDirData = convertCharsToStrings(WorkingDirData);
    mkdir(WorkingDirData);

    AnalysisData = [WorkingDirData '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis.csv']; %set experimental file per subject
    AnalysisData = [AnalysisData{:}];
    AnalysisData = convertCharsToStrings(AnalysisData);

    DataFileCSV = [WorkingDirData '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis_median.csv']; %set folders per subject
    DataFileCSV = [DataFileCSV{:}];
    DataFileCSV = convertCharsToStrings(DataFileCSV);

    DataFileMat = [WorkingDirData '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis_median.mat'];
    DataFileMat = [DataFileMat{:}];
    DataFileMat = convertCharsToStrings(DataFileMat);

    CSVFile = readtable(AnalysisData);

    ControlDataDir  = ['D:\Hyperion Cloud\ETH\Master Thesis\Data\Pilot4\1.3-WP4-' p.SubjectsNumber '\'];
    ControlDataDir  = convertCharsToStrings(ControlDataDir);
    
    ControlDataCSV  = [ControlDataDir '1.3-WP4-' p.SubjectsNumber '_bootstrapping_table.csv'];
    ControlDataCSV  = [ControlDataCSV{:}];
    ControlData     = readtable(ControlDataCSV);
    ControlData     = table2array(ControlData(:,1));
    
    %% Final calculations
    % Calculate the mean and sd of all accuracies and the mode of the optimal
    % noise levels
    
    finalMedian = median(CSVFile.Accuracy);
    finalStd = std(CSVFile.Accuracy);
    finalMode = mode(CSVFile.OptimalNoiseLevel_);
    finalControlMean = mean(ControlData);
    
    %save this data into a mat file
    save(DataFileMat, 'finalMedian', 'finalStd', 'finalMode', 'finalControlMean');


    %% Plot the two histogramms
    % #Observations vs accuracy
%     figure()
%     histogram(accuracyArray);
% 
%     % #Observations vs optimal noise level
%     figure()
%     histogram(optNLArray);

end
