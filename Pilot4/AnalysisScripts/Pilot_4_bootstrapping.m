%% Bootstrapping script for data of pilot 4

%% The usual necessities
sca;
close all;
clear;
clearvars;

nIterations = 10000;
rng('shuffle');

subjects = 19;

for a = 1:subjects

   %Create some arrays to store data in
    iterationArray = [];
    accuracyArray = [];
    optNLArray = []; 

    
    %% Directory stuff for data retrieval and saving
    p.SubjectsNumber = sprintf('%d', a); %use a instead of number for full group analysis

    WorkingDirData = ['D:\Hyperion Cloud\ETH\Master Thesis\Data\Pilot4\1.3-WP4-' p.SubjectsNumber '\']; %set directory for windows to save data
    WorkingDirData = convertCharsToStrings(WorkingDirData);

    WorkingDirAnalysis = ['D:\Hyperion Cloud\ETH\Master Thesis\Analysis\Pilot4\1.3-WP4-' p.SubjectsNumber '\']; %set directory for analysis
    WorkingDirAnalysis = convertCharsToStrings(WorkingDirAnalysis);
    mkdir(WorkingDirAnalysis);

    AnalysisData = [WorkingDirData '1.3-WP4-' p.SubjectsNumber '_bootstrapping_table.csv']; %set experimental file per subject
    AnalysisData = [AnalysisData{:}];
    AnalysisData = convertCharsToStrings(AnalysisData);

    DataFileCSV = [WorkingDirAnalysis '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis.csv']; %set folders per subject
    DataFileCSV = [DataFileCSV{:}];
    DataFileCSV = convertCharsToStrings(DataFileCSV);

    DataFileMat = [WorkingDirAnalysis '1.3-WP4-' p.SubjectsNumber '_bootstrapped_analysis.mat'];
    DataFileMat = [DataFileMat{:}];
    DataFileMat = convertCharsToStrings(DataFileMat);

    CSVFile = readtable(AnalysisData);

    Data = [CSVFile.Control, CSVFile.x70_TRNS, CSVFile.x90_TRNS, CSVFile.x110_TRNS, CSVFile.x130_TRNS];


    for i = 1:nIterations

        %% Data selection
        [~,r] = sort(rand(size(Data))); %calculate shuffle index
        [rr,rc] = size(r);
        shuffledInd=sub2ind(size(r), r, repmat(1:rc,rr,1));
        D_shuffled = Data(shuffledInd); %D_shuffled contains columnwise random permuations of the Data without replacement.       
        
        [nPoints, nCond] = size(D_shuffled);
        split = round(nPoints/2);
        D1 = D_shuffled(1:split,2:end); %We will determine optimal noise level based on D1, Note we only need the stimulation as we always compare to the complete baseline.
        D2 = D_shuffled(split+1:end,2:end); %And calculate effects based on D2

        %% Calculations
        %% Discovery Data

        %Find out which condition is the best one
        %Calculate the means of each condition
        meanD1_70   = mean(D1(:,1));
        meanD1_90   = mean(D1(:,2));
        meanD1_110  = mean(D1(:,3));
        meanD1_130  = mean(D1(:,4));

        %Put the values in an array
        meanD1 = [meanD1_70, meanD1_90, meanD1_110, meanD1_130];

        %Choose the best one
        [maxValueD1, bestCondD1] = max(meanD1);

        %% Calculation Data
        %save the iteration number
        iterationNr = i;

        %Calculate the mean of the best condition in the Calculation DataSet
        %from the information of the Discovery DataSet
        meanD2 = mean(D2(:,bestCondD1));

        %save the optimal noise level for this iteration
        if bestCondD1 == 1
            optNL = 70;

        elseif bestCondD1 == 2
            optNL = 90;

        elseif bestCondD1 == 3
            optNL = 110;

        elseif bestCondD1 == 4
            optNL = 130;

        end

        %% Data collection
        %Put everything in arrays which will be combined at the end
        iterationArray = [iterationArray, iterationNr]; %#ok<*AGROW>
        accuracyArray = [accuracyArray, meanD2];
        optNLArray = [optNLArray, optNL];
        
    end

    
    %% Combine all the important values into one array and then put them into a table
    bootstrapArray = [iterationArray; accuracyArray; optNLArray];

    bootstrapTable = array2table(transpose(bootstrapArray), 'VariableNames',{'Iteration','Accuracy','Optimal Noise Level %'});
    %Write the table to a file
    writetable(bootstrapTable, DataFileCSV);

    %% Final calculations
    % Calculate the mean and sd of all accuracies and the mode of the optimal
    % noise levels

    finalMean = mean(accuracyArray);
    finalStd = std(accuracyArray);
    finalMode = mode(optNLArray);
    finalControlMean = mean(Data(:,1));
    
    %save this data into a mat file
    save(DataFileMat, 'finalMean', 'finalStd', 'finalMode', 'finalControlMean');


    %% Plot the two histogramms
    % #Observations vs accuracy
%     figure()
%     histogram(accuracyArray);
% 
%     % #Observations vs optimal noise level
%     figure()
%     histogram(optNLArray);

end
