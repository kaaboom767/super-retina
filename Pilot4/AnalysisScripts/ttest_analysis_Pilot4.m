%% T-Test script for data of pilot 4

%% The usual necessities
sca;
close all;
clear;
clearvars;

subjects = 19;

%% Create the arrays that are needed so save the control and maximum improvement values
controlArray = [];
accuracyArray = [];
modeArray = [];

%% Set the file location for the final analysis files
tTestFileMat    = 'D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\paired_ttest_Pilot4.mat';
tTestFileTxt    = 'D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\paired_ttest_Pilot4.txt';
tTestFileCSV    = 'D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\group_control_intervention_Pilot4.csv';
tTestFileCSV2   = 'D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\BootstrappedData_Pilot4.csv';
%     DataFileMat = [DataFileMat{:}];
%     DataFileMat = convertCharsToStrings(DataFileMat);

for a = 1:subjects
    
    
    %% Directory stuff for data retrieval and saving
    p.SubjectsNumber = sprintf('%d', a); %use a instead of number for full group analysis

    WorkingDirData = ['D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\1.3-WP4-' p.SubjectsNumber '\']; %set directory for windows to save data
    WorkingDirData = convertCharsToStrings(WorkingDirData);

%     AnalysisData = [WorkingDirData '1.3-WP4-' p.SubjectsNumber '_bootstrapping_table.csv']; %set experimental file per subject
%     AnalysisData = [AnalysisData{:}];
%     AnalysisData = convertCharsToStrings(AnalysisData);


    %% Get the current participant's mat file
    matDataDir = [WorkingDirData '*_bootstrapped_analysis.mat'];
    matDataDir = convertCharsToStrings([matDataDir{:}]);
    matDataDir = dir(matDataDir);   
    matData = load([matDataDir.folder '\' matDataDir.name]);
    
    
    %% Add the values to the array
    controlArray    = [controlArray, matData.finalControlMean]; %#ok<*AGROW>
    accuracyArray   = [accuracyArray, matData.finalMean];
    modeArray       = [modeArray, matData.finalMode];
   
end

%% Conduct a paired t-test between control and max improvement arrays
[h,p,ci,stats] = ttest(controlArray, accuracyArray);


%% Save the test values into a .mat file and a .txt file and two .csv files
save(tTestFileMat,'h','p','ci','stats')

FID = fopen(tTestFileTxt, 'a');
fprintf(FID, 'This is the result file from the paired T-Test of the data from Pilot');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, 'p-value:                  %f',p);
fprintf(FID, '\r\n');
fprintf(FID, 'Confidence interval:      %f', ci(1));
fprintf(FID, ' - %f', ci(2));
fprintf(FID, '\r\n');
fprintf(FID, 'Standard deviation:       %f', stats.sd);
fclose(FID);

B = [controlArray; accuracyArray];
table = array2table(transpose(B),'VariableNames',{'Control','Intervention'});
writetable(table, tTestFileCSV);

subjectArray = [];
for i = 1:subjects
    %currentSubject = sprintf('Subject %d',i);
    currentSubjectNr = sprintf('%d', i);
    currentSubject = ['Subject ' currentSubjectNr];
    
    subjectArray = [subjectArray, cellstr(currentSubject)];
end


C = [subjectArray;num2cell(controlArray); num2cell(accuracyArray); num2cell(modeArray)];
table2 = array2table(transpose(C),'VariableNames',{'Subject','Control','Intervention','Condition'});
writetable(table2, tTestFileCSV2);
