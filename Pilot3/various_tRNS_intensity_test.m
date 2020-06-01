%% This script runs the experiment part of the first pilot.
%% The usual necessities
sca;
close all;
clear all;
clearvars;


%% --------------------Set up variables--------------------

%% Set parameters for the tRNS stimulation
%Sampling rate
S.Rate = 1280; %double of the max frequency of 640Hz
nyqF=S.Rate/2;
%Filters
filter_hf = fir1(150,100/(nyqF), 'high'); %highpass filter, 150th order, cutoff at 100Hz

% How many Trials to estimate Threshold?
numTrials = 40;
interventionAnswersArray = [];
ctrlAnswersArray = [];
valueArray = [];
circleLocationArray = (1:1:numTrials);
trialArray = (1:1:numTrials);
intervalArray = [];
answerArray = [];
keyAnswerArray = [];
controlInterventionArray = [];
answersTrialArray = [];
%tRNS starting intensity
 multiplier = 1;


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
% S.addAnalogInputChannel('Dev1', 'ai0', 'Voltage'); %Inputchannel if you want to monitor output
S.Rate = 1280; %Same as for tRNS in neuroconn device
% S.IsContinuous = true;

%% Ask whether manual or automated input for thresholds is desired
inputMethod = input('Would you like to manualy type in threshold values? [Y/n]: ','s');
if isempty(inputMethod)
    inputMethod = 'y';
end

if inputMethod == 'y'
    
    %% prompt subject to enter parameter values for the following fields:
    definput = {'',''};
    opts.Interpreter = 'tex';
    start_input = inputdlg({'tRNS Threshold Value','Contrast Threshold Value'}, 'Experiment', [1 40],definput,opts);
    p.tRNSThreshold = str2double(start_input(1,1));
    p.VisualThreshold = str2double(start_input(2,1)); % Session number

elseif inputMethod == 'n'
    %% Directory stuff for data storage
    WorkingDir = ['C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Data\Pilot2\']; %#ok<NBRAK> %set directory for windows to save data
%    WorkingDir = [WorkingDir{:}];
    WorkingDir = convertCharsToStrings(WorkingDir);

    %% Open the previously generated threshold files and extract the respective thresholds
    [DataFileThresholds, WorkingDir] = uigetfile('*.txt', 'Select the threshold files',WorkingDir, 'MultiSelect', 'on');

    tRNSThreshholdFile = [WorkingDir DataFileThresholds(1,(find(contains(DataFileThresholds,'tRNS'))))];
    tRNSThreshholdFile = [tRNSThreshholdFile{:}];
    tRNSThreshholdFile = convertCharsToStrings(tRNSThreshholdFile);

    visualThresholdFile = [WorkingDir DataFileThresholds(1, (find(contains(DataFileThresholds,'visual'))))];
    visualThresholdFile = [visualThresholdFile{:}];
    visualThresholdFile = convertCharsToStrings(visualThresholdFile);

    %Find and extract the thresholds
    tRNSThreshold = fileread(tRNSThreshholdFile);
    expr = '[^\n]*Estimated Threshold:[^\n]*';
    tRNSThreshold = regexp(tRNSThreshold,expr,'match');
    tRNSThreshold = convertCharsToStrings(tRNSThreshold);
    tRNSThreshold = sscanf(tRNSThreshold, 'Estimated Threshold: %u%f');
    p.tRNSThreshold = tRNSThreshold(2,1);

    %Calculate different percentages for tRNS intensity
    p.tRNS10 = 0.1 * p.tRNSThreshold;
    p.tRNS20 = 0.2 * p.tRNSThreshold;
    p.tRNS30 = 0.3 * p.tRNSThreshold;
    p.tRNS40 = 0.4 * p.tRNSThreshold;
    p.tRNS50 = 0.5 * p.tRNSThreshold;
    p.tRNS60 = 0.6 * p.tRNSThreshold;
    p.tRNS70 = 0.7 * p.tRNSThreshold;
    p.tRNS80 = 0.8 * p.tRNSThreshold;
    p.tRNS90 = 0.9 * p.tRNSThreshold;
    p.tRNSOff = 0;
      
    visualThreshold = fileread(visualThresholdFile);
    expr = '[^\n]*Final Mean Threshold: [^\n]*';
    visualThreshold = regexp(visualThreshold,expr,'match');
    visualThreshold = convertCharsToStrings(visualThreshold);
    visualThreshold = sscanf(visualThreshold, 'Final Mean Threshold: %u%f');
    p.VisualThreshold = visualThreshold(2,1);

    % p.VisualThreshold = 1;
end

%% linearise the screen contrast
load('C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Scripts\Alain\Beta folder\Calibration\normalGamma.mat');
load('C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Scripts\Alain\Beta folder\Calibration\gammaTableSonyCorrect.mat'); %%% Screen calibration
Screen('LoadNormalizedGammaTable', 0, gammaTable);


%% --------------------Set up psychtoolbox--------------------

%% Keyboard information
% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
escapeKey = KbName('esc');
spaceKey = KbName('space');
enterKey = KbName('return');


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

trial = 1;
%% --------------------Experimental loop--------------------
% Animation loop: we loop for the total number of trials
runTest = 1;
while runTest == 1

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
    end
       
%     coin = round(rand);
     coin = 0;
    % Get the Gabor angle for this trial (negative values are to the right
    % and positive to the left)
    theAngle = 0;
    
    
    %% tRNS HF signal generation
        timeTRNS = duration + 1; %One second is added, because it will be cut due to filtering
        tRNSNoise = 1/4*p.tRNSThreshold*multiplier; %We divide by four to incorporate the std and the transferfunction of the stimulator (1V => 2mA)
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
    
    pause(0.1);
    
    
     %% Intervention trial       
        if coin  == 0
        % gabor in first interval
        correctkey = 37; 
                      
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
            
            pause(GratInterval);
                                  
%             %no gabor, 20ms, play tRNS and then another 2020ms, for 2040ms
%             %in total
%             
%             %first 20ms
%             for i = 1:(round(hertz*0.02))
%                 Screen('FrameOval',window, black, CircleRect, 2);
%                 Screen('DrawLines', window, allCoords,...
%                 lineWidthPix, white, [xCenter yCenter], 2);
%                 Screen('Flip', window);
%             end
%                  
%             %Play the tRNS signal
%             S.queueOutputData(TRNS_Signal_hf);
%             S.startBackground();
%                 
%             %2020ms, due to the 20ms offset before = 2040ms
%             for i = 1:((2*circleWind)+round(hertz*0.02))
%                 %Draw circles
%                 Screen('FrameOval',window, black, CircleRect, 2);
%                 %Draw fixation cross
%                 Screen('DrawLines', window, allCoords,...
%                 lineWidthPix, white, [xCenter yCenter], 2);
%                 Screen('Flip', window);
%             end
%         
            coinFlip = 1;
            
        elseif coin == 1
        % gabor in second interval
        correctkey = 39;
            
           %no gabor, 20ms, play tRNS and then another 2020ms, for 2040ms
           %in total
            
            %first 20ms
            for i = 1:(round(hertz*0.02))
                Screen('FrameOval',window, black, CircleRect, 2);
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
                 
            %Play the tRNS signal
            S.queueOutputData(TRNS_Signal_hf);
            S.startBackground();
                
            %2020ms, due to the 20ms offset before = 2040ms
            for i = 1:(circleWind+round(hertz*2.02))
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
            
            pause(GratInterval);
            
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
            
            coinFlip = 2;
            
        end
        

      
    %% The end of all trials is always the same, hence this part is outside of the trial loop 
    % Draw the fixation cross
    Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);

    % Flip to the screen
    Screen('Flip', window);

    pause(0.1);
    
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

    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Noto Font');
    DrawFormattedText(window, 'Do you want to continue? (return yes, escape no)', 'center', 'center', white);
    Screen('Flip', window);

    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(escapeKey)
        Screen('LoadNormalizedGammaTable', 0, normalGamma);
        ShowCursor;
        sca;
        Screen('CloseAll');
        return
    
%     else %continue
%         Screen('TextSize', window, 50);
%         Screen('TextFont', window, 'Noto Font');
%         multiplier = Ask(window,sprintf('Enter a multiplier value for tRNS intensity. Old value %f4.2: ',multiplier), white, grey, 'GetChar',[],[]); % Accept keyboard input, echo it to screen
%         Screen('Flip', window);
%         multiplier = str2num(multiplier); %#ok<ST2NM>
%         respToBeMade = false;
    
   elseif keyCode(enterKey) %continue
        Screen('TextSize', window, 50);
        Screen('TextFont', window, 'Noto Font');
        multiplier = Ask(window,sprintf('Enter a multiplier value for tRNS intensity. Old value %4.2f: ',multiplier), white, grey, 'GetChar',[],[]); % Accept keyboard input, echo it to screen
        Screen('Flip', window);
        multiplier = str2num(multiplier); %#ok<ST2NM>
        respToBeMade = false;
    end
       
    end
        trial = trial + 1;
end

    
%% --------------------Final stuff---------------------
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


%% Save all variables
save(DataFileMAT);
