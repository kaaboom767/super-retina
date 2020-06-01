%% This script runs the experiment part of the fourth pilot.
%% Parameters are: 5 different conditions: 70%, 90%, 110%, 130% of tRNS threshold and no tRNS
%% The usual necessities
if exist ('metaScript', 'var') == 0
    sca;
    close all;
    clear;
    clearvars;
    metaScript = 0;
elseif metaScript == 1
    p.SessionNr = num2str(p.SessionNr);
end

clear CircleRect

%% --------------------Set up variables--------------------

%% Set parameters for the tRNS stimulation
%Sampling rate
S.Rate = 1280; %double of the max frequency of 640Hz
nyqF=S.Rate/2;
%Filters
filter_hf = fir1(150,100/(nyqF), 'high'); %highpass filter, 150th order, cutoff at 100Hz

Ohm = char(hex2dec('03A9'));

% How many Trials to estimate Threshold?
numTrials = 40;
tRNS70AnswersArray = [];
tRNS90AnswersArray = [];
tRNS110AnswersArray = [];
tRNS130AnswersArray = [];
tRNS0AnswersArray = [];
quadrantArray = [];
circleLocationArray = (1:1:numTrials);
circleTestArray = [];
trialArray = (1:1:numTrials);
answerArray = [];
keyAnswerArray = [];
controlInterventionArray = [];
answersTrialArray = [];


tRNSIntensityArray = (1:1:numTrials); % set 40 trials, trial 1-32 are intervention trials, trial 33-40 are control trials
% Difference between the two being that tRNS is running during the
% presentation of the gabor patch in the intervention trials. There is no
% tRNS stimulation during the control trials


%% define image properties
%Image
imLength = 108;
imWidth = 108;
%Circles
CircLength = 108;
CircWidth = 108;
nCircles = (1:1:8);

[ x, y ] = meshgrid( -imWidth/2+1:imWidth/2, -imLength/2+1:imLength/2);
nCosSteps = 25;%1/8*imSize;
gratingDiam = 108;
%sigma = 20;
cosMask = makeRaisedCosineMask(imLength, imWidth,nCosSteps, gratingDiam );


%% Set up communication with brain stimulator
%Setup Data Acquisition for tRNS
S = daq.createSession('ni'); % Create a data acquisition session for National Instruments
S.addAnalogOutputChannel('Dev1', 'ao0', 'Voltage'); %Outputchannel
%S.addAnalogInputChannel('Dev1', 'ai0', 'Voltage'); %Inputchannel if you want to monitor output
S.Rate = 1280; %Same as for tRNS in neuroconn device
%S.IsContinuous = true;


%% prompt subject to enter parameter values for the following fields:
if metaScript == 0
    definput = {'','','','',''};
    opts.Interpreter = 'tex';
    start_input = inputdlg({'Subject Number','Session Number','Age','Gender', 'Pre Impedance [k \Omega]'},'Experiment', [1 40],definput,opts);
    p.SubjectsNumber = start_input(1,1);
    p.SessionNr = start_input(2,1); % Session number
    p.Age = start_input(3,1); % ppn age
    p.Gender = start_input(4,1);
    p.PreImpedance = start_input(5,1);

else
    
    definput = {'','','','',''};
    opts.Interpreter = 'tex';
    start_input = inputdlg({'Pre Impedance [k \Omega]'},'Pre Impedance', [1 40],definput,opts);
    p.PreImpedance = start_input(1,1);
    
end


%% Directory stuff for data storage
WorkingDir = [p.SubjectsNumber '\']; %set directory for windows to save data
WorkingDir = [WorkingDir{:}];
WorkingDir = convertCharsToStrings(WorkingDir);

DataFile = [WorkingDir '1.3-WP4-' p.SubjectsNumber '_Run_' p.SessionNr '_experiment']; %set folders per subject
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


%% Open the previously generated threshold files and extract the respective thresholds
WorkingDirThreshold = [WorkingDir 'Threshold_part\'];
WorkingDirThreshold = [WorkingDirThreshold{:}];
WorkingDirThreshold = convertCharsToStrings(WorkingDirThreshold);

[DataFileThresholds, WorkingDirThreshold] = uigetfile('*.txt', 'Select the threshold files',WorkingDirThreshold, 'MultiSelect', 'on');

tRNSThreshholdFile = [WorkingDirThreshold DataFileThresholds(1,(find(contains(DataFileThresholds,'tRNS'))))];
tRNSThreshholdFile = [tRNSThreshholdFile{:}];
tRNSThreshholdFile = convertCharsToStrings(tRNSThreshholdFile);

visualThresholdFile = [WorkingDirThreshold DataFileThresholds(1, (find(contains(DataFileThresholds,'visual'))))];
visualThresholdFile = [visualThresholdFile{:}];
visualThresholdFile = convertCharsToStrings(visualThresholdFile);

%Find and extract the thresholds
tRNSThreshold = fileread(tRNSThreshholdFile);
expr = '[^\n]*Estimated Threshold:[^\n]*';
tRNSThreshold = regexp(tRNSThreshold,expr,'match');
tRNSThreshold = convertCharsToStrings(tRNSThreshold);
tRNSThreshold = sscanf(tRNSThreshold, 'Estimated Threshold: %u%f');
p.tRNSThreshold = tRNSThreshold(2,1);

%Calculate the different tRNS intensities

p.tRNS70 = 0.7 * p.tRNSThreshold;
p.tRNS90 = 0.9 * p.tRNSThreshold;
p.tRNS110 = 1.1 * p.tRNSThreshold;
p.tRNS130 = 1.3 * p.tRNSThreshold;
p.tRNS0 = 0;

visualThreshold = fileread(visualThresholdFile);
expr = '[^\n]*Final Mean Threshold: [^\n]*';
visualThreshold = regexp(visualThreshold,expr,'match');
visualThreshold = convertCharsToStrings(visualThreshold);
visualThreshold = sscanf(visualThreshold, 'Final Mean Threshold: %u%f');
p.VisualThreshold = visualThreshold(2,1);

% p.VisualThreshold = 1;


%% linearise the screen contrast
load('normalGamma.mat');
load('gammaTableSonyCorrect.mat'); %%% Screen calibration
Screen('LoadNormalizedGammaTable', 0, gammaTable);


%% Write the collected information into a file in the subject's directory
FID = fopen(DataFileTXT, 'a');
%fprintf(FID, '\r\n\r\n\r\n');
fprintf(FID, 'This data file was created by the following script: %s.m',( mfilename));
%fprintf(FID, '\r\n');
fprintf(FID, ' at: %s', datestr(now));
%fprintf(FID, '\r\n');
fprintf(FID, ' for Pilot 4');
fprintf(FID, '\r\n\r\n');
fprintf(FID, 'Subject number: 1.3-WP4-%s',char(p.SubjectsNumber));
fprintf(FID, '\r\n');
fprintf(FID, 'Subjects age: %s',char(p.Age));
fprintf(FID, '\r\n');
fprintf(FID, 'Gender: %s' ,char(p.Gender));
fprintf(FID, '\r\n\r\n');
fprintf(FID, 'Session number: %s',char(p.SessionNr));
fprintf(FID, '\r\n');
fprintf(FID, 'tRNS Threshold: ');
fprintf(FID, '%f', p.tRNSThreshold);
fprintf(FID, ' mA');
fprintf(FID, '\r\n');
fprintf(FID, 'Visual Threshold: ');
fprintf(FID, '%f', p.VisualThreshold);
fclose(FID);


%% --------------------Set up psychtoolbox--------------------

%% Keyboard information
% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
escapeKey = KbName('esc');
Quadrant1 = KbName('4');
Quadrant2 = KbName('5');
Quadrant3 = KbName('2');
Quadrant4 = KbName('1');


%% Set up screen and colors
%get number of screens
screens = Screen('Screens');

%choose which screen to use, if external screen available use it, as well
screenNumber = max(screens); %max -> external screen, min -> laptop screen

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

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

% Here we set the size of the arms of our quadrant cross
fixCrossDimPix = 400;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoordsQuadrant = [xCoords; yCoords];

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
circleTime = 1 ; % time to present the circles, 1000ms = 1s
circleWind = round(hertz * circleTime);
GratInterval = 1 ; % time in seconds of the interval between the two gratings
timeWait = length(circleTime) * 1/hertz;
%tRNS signal duration
duration = 2*circleTime; %2s tRNS


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
contrast = p.VisualThreshold;
%contrast = 0.5;
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
numRepeats = 5;
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
    %% Choose the circle 
    randomCirclePick = circleLocationArray(randsample(length(circleLocationArray),1));

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
    elseif randomCirclePick (35<randomCirclePick) && (randomCirclePick<41) % trial 41 to 50 are control and thus empty, anyway
        randomCircle = 8;
    end
    
    
    %% Set the circle to its corresponding quadrant
    if randomCircle == 1 
            correctAnswer = 2;
            quadrantUsed = "Third";
        elseif randomCircle == 2
            correctAnswer = 2;
            quadrantUsed = "Third";
        elseif randomCircle == 3
            correctAnswer = 1;
            quadrantUsed = "Fourth";
        elseif randomCircle == 4
            correctAnswer = 1;
            quadrantUsed = "Fourth";
        elseif randomCircle == 5
            correctAnswer = 4;
            quadrantUsed = "First";
        elseif randomCircle == 6
            correctAnswer = 4;
            quadrantUsed = "First";
        elseif randomCircle == 7
            correctAnswer = 5;
            quadrantUsed = "Second";
        elseif randomCircle == 8
            quadrantUsed = "Second";
            correctAnswer = 5;
    end
    
    
    %% Choose the tRNS intensitiy
    randomtRNSPick = tRNSIntensityArray(randsample(length(tRNSIntensityArray),1));
    
    if randomtRNSPick (0<randomtRNSPick) && (randomtRNSPick<9)
        tRNSIntensity = p.tRNS70;
        tRNSMode = "70% tRNS";
    elseif randomtRNSPick (8<randomtRNSPick) && (randomtRNSPick<17)
        tRNSIntensity = p.tRNS90;
        tRNSMode = "90% tRNS";
    elseif randomtRNSPick (16<randomtRNSPick) && (randomtRNSPick<25)
        tRNSIntensity = p.tRNS110;
        tRNSMode = "110% tRNS";
    elseif randomtRNSPick (24<randomtRNSPick) && (randomtRNSPick<33)
        tRNSIntensity = p.tRNS130;
        tRNSMode = "130% tRNS";
    elseif randomtRNSPick (32<randomtRNSPick) && (randomtRNSPick<41)
        tRNSIntensity = p.tRNS0;
        tRNSMode = "0% tRNS";
    end
    
    % Get the Gabor angle for this trial (negative values are to the right
    % and positive to the left)
    theAngle = 0;
    
    
    %% tRNS HF signal generation
        timeTRNS = duration + 1; %One second is added, because it will be cut due to filtering
        tRNSNoise = 1/4*tRNSIntensity; %We divide by four to incorporate the std and the transferfunction of the stimulator (1V => 2mA)
        TRNS_Signal = tRNSNoise*randn((S.Rate*timeTRNS),1); % Create an array with dimensions of (sample rate x time) by 1.

        TRNS_Signal(TRNS_Signal > 2*tRNSNoise) = 2*tRNSNoise;
        TRNS_Signal(TRNS_Signal < -2*tRNSNoise) = -2*tRNSNoise;
        TRNS_Signal(end) = 0;

        TRNS_Signal_hf = filter(filter_hf,1,TRNS_Signal);
        TRNS_Signal_hf = TRNS_Signal_hf(S.Rate+1:end);
    
    
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
    
    pause(1);
    
    %% Presentation with tRNS                             
            %first 20ms
            for i = 1:(round(hertz*0.02))
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %Play the tRNS signal
            S.queueOutputData(TRNS_Signal_hf);
            S.startBackground();          
                        
            %980ms, due to the 20ms offset before. We are now at 1000ms
            for i = 1:(circleWind-round(hertz*0.02))
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
            
            %last 1000ms
            for i = 1:circleWind
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
            
 
            %% The end of gabor presentation 
            % Draw the fixation cross
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);

            % Flip to the screen
            Screen('Flip', window);

            pause(GratInterval);
               

    
    %% Now we wait for a keyboard button signaling the observers response.
    % The left arrow key signals a "first interval" response and the right arrow key
    % a "second interval" response. You can also press escape if you want to exit the
    % program
    respToBeMade = true;
    while respToBeMade == true
        
    %Very important to have something drawn withing the while loop,
    %otherwise a black screen occurs.
       
    % Change the blend function to draw an antialiased fixation point
%    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    Screen('TextSize', window, 40);
    Screen('TextFont', window, 'Noto Font');
    DrawFormattedText(window, 'In which quadrant was the gabor patch?', 'center', 100, white);
    Screen('TextSize', window, 80);
    DrawFormattedText(window, '4',xCenter-150 ,yCenter-100, white);
    DrawFormattedText(window, '5',xCenter+100 ,yCenter-100, white);
    DrawFormattedText(window, '1',xCenter-150 ,yCenter+150, white);
    DrawFormattedText(window, '2',xCenter+100 ,yCenter+150, white);
    %Draw circles
    Screen('FrameOval',window, black, CircleRect, 2);
    %Draw separation cross
    Screen('DrawLines', window, allCoordsQuadrant,...
    lineWidthPix, white, [xCenter yCenter], 2);
    Screen('Flip', window);  
    
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(escapeKey)
        Screen('LoadNormalizedGammaTable', 0, normalGamma);
        ShowCursor;
        sca;
        Screen('CloseAll');
        return
    elseif keyCode(Quadrant1) %first quadrant
        keyAnswer = "First";
        if correctAnswer == 4
            response = 1;
            answer_name = "correct";
        else
            response = 0;
            answer_name = "incorrect";
        end
        respToBeMade = false;
    elseif keyCode(Quadrant2) %second quadrant
        keyAnswer = "Second";
        if correctAnswer == 5
            response = 1;
            answer_name = "correct";
        else
            response = 0;
            answer_name = "incorrect";
        end
        respToBeMade = false;
    elseif keyCode(Quadrant3) %third quadrant
        keyAnswer = "Third";
        if correctAnswer == 2
            response = 1;
            answer_name = "correct";
        else
            response = 0;
            answer_name = "incorrect";
        end
        respToBeMade = false;
    elseif keyCode(Quadrant4) %fourth quadrant
        keyAnswer = "Fourth";
        if correctAnswer == 1
            response = 1;
            answer_name = "correct";
        else
            response = 0;
            answer_name = "incorrect";
        end
        respToBeMade = false;
    end
        
    end
    
        %% Record the responses and other values in the corresponding arrays       
        keyAnswerArray = [keyAnswerArray, keyAnswer];
        answersTrialArray = [answersTrialArray, answer_name];
        controlInterventionArray = [controlInterventionArray, tRNSMode];
        circleTestArray = [circleTestArray, randomCircle];
        quadrantArray = [quadrantArray, quadrantUsed];
        
        if tRNSMode == "70% tRNS"
            tRNS70AnswersArray = [tRNS70AnswersArray, answer_name];
        elseif tRNSMode == "90% tRNS"
            tRNS90AnswersArray = [tRNS90AnswersArray, answer_name];
        elseif tRNSMode == "110% tRNS"
            tRNS110AnswersArray = [tRNS110AnswersArray, answer_name];
        elseif tRNSMode == "130% tRNS"
            tRNS130AnswersArray = [tRNS130AnswersArray, answer_name];
        elseif tRNSMode == "0% tRNS"
            tRNS0AnswersArray = [tRNS0AnswersArray, answer_name];
        end
        
        
       %% Remove the current Trial and circle from their respective array
       tRNSIntensityArray = tRNSIntensityArray(tRNSIntensityArray~=randomtRNSPick);     
       circleLocationArray = circleLocationArray(circleLocationArray~=randomCirclePick);
end
  

%% --------------------Final stuff---------------------
% Check for correct answers
nCorrect70 = nnz(strcmp(tRNS70AnswersArray,"correct"));
percentageCorrect70 = nCorrect70/(trial/5)*100;

nCorrect90 = nnz(strcmp(tRNS90AnswersArray,"correct"));
percentageCorrect90 = nCorrect90/(trial/5)*100;

nCorrect110 = nnz(strcmp(tRNS110AnswersArray,"correct"));
percentageCorrect110 = nCorrect110/(trial/5)*100;

nCorrect130 = nnz(strcmp(tRNS130AnswersArray,"correct"));
percentageCorrect130 = nCorrect130/(trial/5)*100;

nCorrect0 = nnz(strcmp(tRNS0AnswersArray,"correct"));
percentageCorrect0 = nCorrect0/(trial/5)*100;


%% Combine all the important values into one array
A = [trialArray; keyAnswerArray; answersTrialArray; quadrantArray; controlInterventionArray; circleTestArray];


%% Write text file with data   
FID = fopen(DataFileTXT, 'a');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
%fprintf(FID, 'Estimated visual threshold: %f',p.VisualThreshold);
%fprintf(FID, ' mA');
fprintf(FID, '\r\n');
%fprintf(FID, 'Estimated tRNS Threshold: %f',p.tRNSThreshold);
fprintf(FID, '\r\n');
fprintf(FID, '%6s %7s %11s %8s %10s %15s \r\n','Trial','Answer','Correctness','Quadrant','tRNS Mode','Circle Location');
fprintf(FID, '%6.0f %7s %11s %8s %10s %15s \r\n',A);
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered in 70%% tRNS trials:    %4.2f',percentageCorrect70);
fprintf(FID, '%%');
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered in 90%% tRNS trials:    %4.2f',percentageCorrect90);
fprintf(FID, '%%');
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered in 110%% tRNS trials:   %4.2f',percentageCorrect110);
fprintf(FID, '%%');
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered in 130%% tRNS trials:   %4.2f',percentageCorrect130);
fprintf(FID, '%%');
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered in 0%% tRNS trials:     %4.2f',percentageCorrect0);
fprintf(FID, '%%');
fprintf(FID, '\r\n');
fclose(FID);


%% Write csv file with values
B = transpose(A);
table = array2table(B,'VariableNames',{'Trial','Answer','Correctness','Quadrant','tRNS Mode','Circle Location'});
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


%% Ask for post Impedance information
start_input = inputdlg({'Post Impedance'},'Post Impedance',[1 40]);
p.PostImpedance = start_input(1,1);


%% Write pre and post impedance information in the data file
FID = fopen(DataFileTXT, 'a');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, 'Pre impedance: %s', char(p.PreImpedance));
fprintf(FID, ' kOhm');
fprintf(FID, '\r\n');
fprintf(FID, 'Post impedance: %s', char(p.PostImpedance));
fprintf(FID, ' kOhm');
fclose(FID);


%% Save all variables
save(DataFileMAT);

winopen(DataFileTXT);
