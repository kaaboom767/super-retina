% This script runs the second visual threshold part of the first pilot.
%% The usual necessities
if exist ('metaScript', 'var') == 0
    sca;
    close all;
    clear all;
    clearvars;
    metaScript = 0;
elseif metaScript == 1
    p.SessionNr = num2str(p.SessionNr);
end

clear CircleRect

%% --------------------Set up variables--------------------
%% Enter custom  parameters for the signal and number of trials
%Duration of the signal in seconds
duration = 5;
answersTrialArray = [];
intensityStart = 1;
valueArray = [];
% How many Trials to estimate Threshold?
numTrials = 80;
circleLocationArray = (1:1:numTrials);
trialArray = (1:1:numTrials);
contrastArray = [];
intervalArray = [];
answerArray = [];
keyAnswerArray = [];
questStaircaseArray = (1:1:numTrials);
questModeArray = [];
minBoundary = 0.001;
maxBoundary = 1;
           

%% prompt subject to enter parameter values for the following fields:
if metaScript == 0
    start_input = inputdlg({'Subject Number','Session Number','Age','Gender'},'Final Visual Threshold', [1 40]);
    p.SubjectsNumber = start_input(1,1);
    p.SessionNr = start_input(2,1); % Session number
    p.Age = start_input(3,1); % ppn age
    p.Gender = start_input(4,1);
end


%% Directory stuff for data storage
WorkingDir = ['C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Data\Pilot1\1.3-WP1-' p.SubjectsNumber '\Threshold_part']; %set directory for windows to save data
%WorkingDir = ['/home/kaaboom/Hyperion Cloud/ETH/Master Thesis/Data/Pilot1/Threshold_Part/']; %set directory for linux to save data
WorkingDir = [WorkingDir{:}];
WorkingDir = convertCharsToStrings(WorkingDir);

DataFile = [WorkingDir '\1.3-WP1-' p.SubjectsNumber '_Run_' p.SessionNr '_final_visual_threshold']; %set folders per subject

DataFileTXT = [DataFile, '.txt'];
DataFileTXT = [DataFileTXT{:}]; %some conversion magic going on in order to make it readable by fopen()
DataFileTXT = convertCharsToStrings(DataFileTXT); %dito

DataFileCSV = [DataFile '.csv'];
DataFileCSV = [DataFileCSV{:}];
DataFileCSV = convertCharsToStrings(DataFileCSV);

DataFileMAT = [DataFile '.mat'];
DataFileMAT = [DataFileMAT{:}];
DataFileMAT = convertCharsToStrings(DataFileMAT);

%mkdir (WorkingDir); %create the subject's folder


%% Open the previously generated threshold files and extract the threshold
WorkingDirThreshold = WorkingDir;

[DataFileThresholds, WorkingDirThreshold] = uigetfile('*.txt', 'Select the visual threshold file', WorkingDirThreshold);

visualThresholdFile = [WorkingDirThreshold DataFileThresholds];
%visualThresholdFile = [visualThresholdFile{:}];
visualThresholdFile = convertCharsToStrings(visualThresholdFile);

%Find and extract the threshold
visualThreshold = fileread(visualThresholdFile);
expr = '[^\n]*Estimated Threshold: [^\n]*';
visualThreshold = regexp(visualThreshold,expr,'match');
visualThreshold = convertCharsToStrings(visualThreshold);
visualThreshold = sscanf(visualThreshold, 'Estimated Threshold: %u%f');
p.VisualThreshold = visualThreshold(2,1);


%% Set-Up Starting Parameters for Quest         
% Provide prior knowledge about estimated Threshold
tGuess = p.VisualThreshold;
tGuess120 = 1.2*tGuess; % quest 120%
tGuess80 = 0.8*tGuess; % quest 80%

range120 = 0.5;
range80 = 0.5;

% range120 = (tGuess120*2);
% range80 = (tGuess80*2);

pThreshold = 0.6; % p-Value for 2afc Task: 0.82; p-Value for yes-no Task: 0.62
beta = 3; % typical value for visual tasks
delta = 0.01;
gamma = 0.5;
grain = 0.001; %step size of internal table
%range = 1; %centers it around tGuess and sets the maximum and minimum possible values, author recommends value of 5

tGuessSd = 0.5; % was 0.01

q120 = QuestCreate(tGuess120,tGuessSd,pThreshold,beta,delta,gamma,grain,range120);
q120.normalizePdf = 1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

q80 = QuestCreate(tGuess80,tGuessSd,pThreshold,beta,delta,gamma,grain,range80);
q80.normalizePdf = 1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.


%% linearise the screen contrast
load('C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Scripts\Alain\Beta folder\Calibration\normalGamma.mat');
load('C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Scripts\Alain\Beta folder\Calibration\gammaTableSonyCorrect.mat'); %%% Screen calibration
Screen('LoadNormalizedGammaTable', 0, gammaTable);


%% Write the collected information into a file in the subject's directory
FID = fopen(DataFileTXT, 'a');
%fprintf(FID, '\r\n\r\n\r\n');
fprintf(FID, 'This data file was created by the following script: %s.m',( mfilename));
%fprintf(FID, '\r\n');
fprintf(FID, ' at: %s', datestr(now));
%fprintf(FID, '\r\n');
fprintf(FID, ' for Pilot 1 ');
fprintf(FID, '\r\n\r\n');
fprintf(FID, 'Subject number: 1.3-WP1-%s',char(p.SubjectsNumber));
fprintf(FID, '\r\n');
fprintf(FID, 'Subjects age: %s',char(p.Age));
fprintf(FID, '\r\n');
fprintf(FID, 'Gender: %s' ,char(p.Gender));
fprintf(FID, '\r\n\r\n');
fprintf(FID, 'Session number: %s',char(p.SessionNr));
fprintf(FID, '\r\n');
fclose(FID);


%% define image properties
%Image
imLength = 108;
imWidth = 108;
%Circles
CircLength = 108;
CircWidth = 108;
nCircles = [1:1:8];

[ x, y ] = meshgrid( -imWidth/2+1:imWidth/2, -imLength/2+1:imLength/2);
nCosSteps = 25;%1/8*imSize;
gratingDiam = 108;
sigma = 20;
cosMask = makeRaisedCosineMask(imLength, imWidth,nCosSteps, gratingDiam );


%% --------------------Set up psychtoolbox--------------------
%% Keyboard information
% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
escapeKey = KbName('esc');
leftKey = KbName('left');
rightKey = KbName('right');


%% Skip sync tests
Screen('Preference', 'SkipSyncTests',0);


%% Set up screen and colors
%get number of screens
screens = Screen('Screens');

%choose which screen to use, if external screen available use it, as well
screenNumber = max(screens); %max -> external screen, min -> laptop screen

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);
scrCol = [ 120 120 120 ];

% Open an on screen window and color it grey. This function returns a number that identifies the window we have opened "window" and a vector" windowRect".
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 40);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% This function call will give use the same information as contained in "windowRect"
rect = Screen('Rect', window);

% Get the size of the on screen window in pixels, these are the last two numbers in "windowRect" and "rect"
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% We can also determine the refresh rate of our screen. The relationship between the two is: ifi = 1 / hertz
hertz = FrameRate(window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 40;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

% Hide mouse
HideCursor();


%% Timing information
% Presentation Time for the tRNS signal in seconds and frames
presTimeSecs = duration;
presTimeFrames = round(presTimeSecs / ifi);

% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;


%% More circle stuff
%Screen Set-Up and Display instructions
stimRectCircle = [ 0 0 CircLength CircWidth ] ;
MVrectCircle = CenterRect(stimRectCircle, rect);


%% Timing
gaborTime = 0.04;  % time in seconds for gabor presentation
gaborWind= round(hertz * gaborTime);
circleTime = 0.5 ; % time to present the circles, 2*500ms = 1s
circleWind = round(hertz * circleTime);
GratInterval = 1 ; % time in seconds of the interval between the two gratings
timeWait = length(circleTime) * 1/hertz;
 

%% Test for loc
rad = 262;  
degmat = [ 1/6*pi, 2/6*pi, 4/6*pi, 5/6*pi, 7/6*pi, 8/6*pi, 10/6*pi, 11/6*pi ];

for i = 1:length(degmat)
    
    loc(1,i) = 0+ rad* cos(degmat(:,i));
    loc(2,i) = 0+ rad* sin(degmat(:,i));
    
    CircleRect(i,:) = (abs(MVrectCircle));
    CircleRect(i,1) = (abs(MVrectCircle(:,1)) + loc(1,i));
    CircleRect(i,3) = (abs(MVrectCircle(:,3)) + loc(1,i));
    CircleRect(i,2) = (abs(MVrectCircle(:,2)) + loc(2,i));
    CircleRect(i,4) = (abs(MVrectCircle(:,4)) + loc(2,i));
end

CircleRect = CircleRect';


%% --------------------Gabor information--------------------
% Dimension of the region where will draw the Gabor in pixels
gaborDimPix = 300;

% Sigma of Gaussian
sigma = gaborDimPix / 7;

% Obvious Parameters
orientation = 90;
contrast = tGuess;
aspectRatio = 1.0;

% Spatial Frequency (Cycles Per Pixel)
% One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
numCycles = 8;
freq = numCycles / gaborDimPix;

% Build a procedural gabor texture
gaborOffsetValue = [0.5 0.5 0.5 1];
gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
gaborOffsetValue, 1, 1);

% Count how many Gabors there are
nGabors = 1;

% Randomise the phase of the Gabors and make a properties matrix.
phaseLine = rand(1, nGabors) .* 360;
propertiesMat = repmat([NaN, freq, sigma, contrast,...
aspectRatio, 0, 0, 0], nGabors, 1);
propertiesMat(:, 1) = phaseLine';

% Set the orientations for the methods of constant stimuli. We will center
% the range around zero (vertical) and give it a range of 1.8 degress, this
% will mean we test between -(1.8 / 2) and +(1.8 / 2). Finally we will test
% seven points linearly spaced between these extremes.
baseOrientation = 0;
orRange = 1.9;
numSteps = 8;
stimValues = linspace(-orRange / 2, orRange / 2, numSteps) + baseOrientation;

% Now we set the number of times we want to do each condition, then make a
% full condition vector and then shuffle it. This will randomly order the
% orientation we present our Gabor with on each trial.
numRepeats = 10;
condVector = Shuffle(repmat(stimValues, 1, numRepeats));

% Make a vector to record the response for each trial
respVector = zeros(1, numSteps);

% Make a vector to count how many times we present each stimulus. This is a
% good check to make sure we have done things right and helps us when we
% input the data to plot anf fit our psychometric function
countVector = zeros(1, numSteps);


%% --------------------Experimental loop--------------------
% Animation loop: we loop for the total number of trials
for trial = 1:numTrials

    
    %% First some variables
    randomCirclePick = randsample(circleLocationArray,1);

    if randomCirclePick (0<randomCirclePick) && (randomCirclePick<6)
        randomCircle = 1;
    elseif randomCirclePick (5<randomCirclePick) && (randomCirclePick<11)
        randomCircle = 2;
    elseif randomCirclePick (10<randomCirclePick) && (randomCirclePick<16)
        randomCircle = 3;
    elseif randomCirclePick (15<randomCirclePick) && (randomCirclePick<21)
        randomCircle = 4;
    elseif randomCirclePick (20<randomCirclePick) && (randomCirclePick<26)
        randomCircle = 5;
    elseif randomCirclePick (25<randomCirclePick) && (randomCirclePick<31)
        randomCircle = 6;
    elseif randomCirclePick (30<randomCirclePick) && (randomCirclePick<36)
        randomCircle = 7;
    elseif randomCirclePick (35<randomCirclePick) && (randomCirclePick<41)
        randomCircle = 8;
    elseif randomCirclePick (40<randomCirclePick) && (randomCirclePick<46)
        randomCircle = 1;
    elseif randomCirclePick (45<randomCirclePick) && (randomCirclePick<51)
        randomCircle = 2;
    elseif randomCirclePick (50<randomCirclePick) && (randomCirclePick<56)
        randomCircle = 3;
    elseif randomCirclePick (55<randomCirclePick) && (randomCirclePick<61)
        randomCircle = 4;
    elseif randomCirclePick (60<randomCirclePick) && (randomCirclePick<66)
        randomCircle = 5;
    elseif randomCirclePick (65<randomCirclePick) && (randomCirclePick<71)
        randomCircle = 6;
    elseif randomCirclePick (70<randomCirclePick) && (randomCirclePick<76)
        randomCircle = 7;
    elseif randomCirclePick (75<randomCirclePick) && (randomCirclePick<81)
        randomCircle = 8;
    end
    
    coin = round(rand);
%   coin = 0;


    %% Quest Stuff
    %pick one of the two quest staircases
    randomQuestPick = randsample(questStaircaseArray,1);
    
    if mod(randomQuestPick,2) == 1
       % Here we choose the algorithm for QUEST
            tTest = QuestMean(q120);      % Recommended by King-Smith et al. (1994)
            %tTest = QuestMode(q);		  % Recommended by Watson & Pelli (1983)
            %tTest = QuestQuantile(q);	  % Recommended by Pelli (1987)
                    
            % Limit the values for contrast
            tTest=min(max(tTest,minBoundary),maxBoundary);
            
            % Define Detection Signal with Current Intensity
            current_intensity = tTest;
            contrast = current_intensity;
            
            %set questMode
            questMode = "q120";
            
    elseif mod(randomQuestPick,2) == 0
        % Here we choose the algorithm for QUEST
            tTest = QuestMean(q80);       % Recommended by King-Smith et al. (1994)
            %tTest = QuestMode(q);		  % Recommended by Watson & Pelli (1983)
            %tTest = QuestQuantile(q);	  % Recommended by Pelli (1987)
                    
            % Limit the values for contrast
            tTest=min(max(tTest,minBoundary),maxBoundary);
            
            % Define Detection Signal with Current Intensity
            current_intensity = tTest;
            contrast = current_intensity;
            
            %set questMode
            questMode = "q80";
    end
    
    % Randomise the phase of the Gabors and make a properties matrix.
    phaseLine = rand(1, nGabors) .* 360;
    propertiesMat = repmat([NaN, freq, sigma, contrast,...
    aspectRatio, 0, 0, 0], nGabors, 1);
    propertiesMat(:, 1) = phaseLine';
             
    % Build a procedural gabor texture
    gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
    gaborOffsetValue, 1, 1);
    
    % Get the Gabor angle for this trial (negative values are to the right
    % and positive to the left)
    theAngle = condVector(trial);
    
    
    %% Start of the experiment
    % Change the blend function to draw an antialiased fixation cross
    % in the centre of the screen
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % If this is the first trial we present a start screen and wait for a key-press
    if trial == 1
        Screen('TextSize', window, 80);
        Screen('TextFont', window, 'Noto Font');
        DrawFormattedText(window, 'Press Any Key To Begin', 'center', 'center', white);
        Screen('Flip', window);
        KbStrokeWait;
    end
    
    % Flip again to sync us to the vertical retrace at the same time as
    % drawing our fixation cross
    Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window);
    
     % Now we present the isi interval with fixation cross minus one frame because we presented the fixation point once already when getting a time stamp
    for frame = 1:isiTimeFrames - 1
   
        % Draw the fixation cross
        Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);
        
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    
    %pause(1);
            
    
        %% Now we draw the eight circles and the gabor patch
            
        if coin  == 0
        % gabor in first interval
        correctkey = 37;   
        
            %first 1000ms
            for i = 1:(2*circleWind)
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %gabor presentation, 40ms
            for i = 1:gaborWind
                % Draw the Gabor
                Screen('DrawTextures', window, gabortex, [], CircleRect(:,randomCircle), theAngle, [], [], [], [],...
                kPsychDontDoRotation, propertiesMat');
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %second 1000ms
            for i = 1:(2*circleWind)
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
           
            % Flip to the screen
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        
            WaitSecs(GratInterval);
        
            %no gabor, 2000ms and add 40ms
            for i = 1:((4*circleWind)+round(hertz*0.04))
                Screen('FrameOval',window, black, CircleRect, 2);
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
        
            coinFlip = 1;
            
        elseif coin == 1
        % gabor in second interval
            correctkey = 39;
            
            %no gabor, 2000ms and add 40ms
            for i = 1:((4*circleWind)+round(hertz*0.04))
                Screen('FrameOval',window, black, CircleRect, 2);
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
        
            % Flip to the screen
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            
            WaitSecs(GratInterval);
            
            %first 1000ms
            for i = 1:(2*circleWind)
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %gabor presentation, 40ms
            for i = 1:gaborWind
                % Draw the Gabor
                Screen('DrawTextures', window, gabortex, [], CircleRect(:,randomCircle), theAngle, [], [], [], [],...
                kPsychDontDoRotation, propertiesMat');
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %second 1000ms
            for i = 1:(2*circleWind)
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            coinFlip = 2;
            
        end     
        
    % Draw the fixation cross
    Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);
    
    % Flip to the screen
    Screen('Flip', window);
       
    WaitSecs(GratInterval);
     
    
    %% Now we wait for a keyboard button signaling the observers response.
    % The left arrow key signals a "no strobe" response and the right arrow key
    % a "strobe" response. You can also press escape if you want to exit the
    % program
    respToBeMade = true;
    while respToBeMade == true
        
    %Very important to have something drawn withing the while loop,
    %otherwise a black screen occurs.
   
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Noto Font');
    DrawFormattedText(window, 'In which interval was the gabor patch? \n \n <-- 1st interval    |    2nd interval --> ', 'center', 'center', white);
    Screen('Flip', window);
        
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(escapeKey)
        ShowCursor;
        sca;
        Screen('CloseAll');
        return
    elseif keyCode(leftKey) %first interval
        keyAnswer = 1;
        if correctkey == 37
            response = 1;
            answer_name = "correct";
        else
            response = 0;
            answer_name = "incorrect";
        end
        respToBeMade = false;
    elseif keyCode(rightKey) %second interval
        keyAnswer = 2;
        if correctkey == 39
            response = 1;
            answer_name = "correct";
        else
            response = 0;
            answer_name = "incorrect";
        end
        respToBeMade = false;
    end
        
    end

    
  %% Update the pdf
  if mod(randomQuestPick,2) == 1
    q120 = QuestUpdate(q120,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
    %Record values
    values = QuestTrials(q120);
    valueArray = [valueArray, values];
    
  elseif mod(randomQuestPick,2) ==0
    q80 = QuestUpdate(q80,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
    %Record values
    values = QuestTrials(q80);
    valueArray = [valueArray, values];
  
  end
    
  
    %% Record the responses and other values in an arrays
    contrastArray = [contrastArray, contrast];
    keyAnswerArray = [keyAnswerArray, keyAnswer];
    answersTrialArray = [answersTrialArray, answer_name];
    intervalArray = [intervalArray, coinFlip];
    questModeArray = [questModeArray, questMode];
    
    
    %% Remove the quest and circle from their respective array
    circleLocationArray = circleLocationArray(circleLocationArray~=randomCirclePick);
    questStaircaseArray = questStaircaseArray(questStaircaseArray~=randomQuestPick);
    
end

%% --------------------Final stuff---------------------
%% Ask Quest for the final estimate of threshold.
t120 = QuestMean(q120);% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
sd120 = QuestSd(q120);

t80 = QuestMean(q80);
sd80 = QuestSd(q80);

%limit estimated thresholds
if t120 < minBoundary
   t120 = minBoundary;
end

if t80 < minBoundary
   t80 = minBoundary;
end

tMean = mean([t120, t80]);

nCorrect = nnz(strcmp(answersTrialArray,"correct"));
percentageCorrect = nCorrect/trial*100;


%% Combine all the important values into one array
A = [trialArray; contrastArray; keyAnswerArray; answersTrialArray; intervalArray; questModeArray];


%% Write text file with data   
FID = fopen(DataFileTXT, 'a');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, 'Estimated Threshold: %f',p.VisualThreshold);
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, 'Estimated Threshold from 120%%: %f',t120);
%fprintf(FID, ' mA');
fprintf(FID, '\r\n');
fprintf(FID, 'Estimated Threshold from 80%%: %f',t80);
fprintf(FID, '\r\n');
fprintf(FID, 'Final Mean Threshold: %f',tMean);
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, '%6s %8s %6s %11s %14s %10s \r\n','Trial','Contrast','Answer','Correctness','Gabor Interval', 'Quest Mode');
fprintf(FID, '%6.0f %8.5f %6s %11s %14.0f %10s \r\n',A);
%fprintf(FID, '%s \r\n',answersTrialArray{:});
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered: %f',percentageCorrect);
fprintf(FID, '%%');
fclose(FID);


%% Write csv file with values
B = transpose(A);
table = array2table(B,'VariableNames',{'Trial','Contrast','Answer','Correctness','Gabor Interval', 'Quest Mode'});
writetable(table, DataFileCSV');


%% Display End
Screen('TextSize', window, 80);
Screen('TextFont', window, 'Noto Font');
DrawFormattedText(window, 'End', 'center', 'center', white);
Screen('Flip', window);


%% Wait for a key press
KbStrokeWait;

Screen('LoadNormalizedGammaTable', 0, normalGamma);
sca;
Screen('CloseAll');


%% Save threshold and beta into respective q
q120.xThreshold = t120;
q120.beta = QuestBetaAnalysis(q120);

q80.xThreshold = t80;
q80.beta = QuestBetaAnalysis(q80);


%% Plot the psychometric function and save all variables
q120.p2 = q120.delta*q120.gamma+(1-q120.delta)*(1-(1-q120.gamma)*exp(-10.^(q120.beta*(q120.x2 + q120.xThreshold))));
figure()
plot(q120.x2, q120.p2, 'o', q120.x2, q120.p2, '-', 'LineWidth', 2);

q80.p2 = q80.delta*q80.gamma+(1-q80.delta)*(1-(1-q80.gamma)*exp(-10.^(q80.beta*(q80.x2 + q80.xThreshold))));
figure()
plot(q80.x2, q80.p2, 'o', q80.x2, q80.p2, '-', 'LineWidth', 2);

save(DataFileMAT);

winopen(DataFileTXT);
