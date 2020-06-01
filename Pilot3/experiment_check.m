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

Ohm = char(hex2dec('03A9'));

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

interventionControlArray = Shuffle([1:1:numTrials]); % set 40 trials, trial 1-20 are intervention trials, trial 21-40 are control trials
% Difference between the two being that tRNS is running during the
% presentation of the gabor patch in the intervention trials. During the
% control trial tRNS is running 250ms after gabor patch presentation.


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



p.VisualThreshold = input('Enter contrast value: ');


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
leftKey = KbName('left');
rightKey = KbName('right');

%% Set up screen and colors
%get number of screens
screens = Screen('Screens');

%choose which screen to use, if external screen available use it, as well
screenNumber = max(screens); %max -> external screen, min -> laptop screen

% Define colours
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);
green = [0, 255, 0];
red = [255, 0, 0];

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
%Control stimulation offset, 250ms
ctrlStimulationOffset = 0.25;
%tRNS signal duration
duration = 2*circleTime;

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
       
    coin = round(rand);
%      coin = 0;
    % Get the Gabor angle for this trial (negative values are to the right
    % and positive to the left)
    theAngle = 0;
    
    
    %% tRNS HF signal generation
        timeTRNS = duration + 1; %One second is added, because it will be cut due to filtering
        tRNSNoise = 1/4*1; %We divide by four to incorporate the std and the transferfunction of the stimulator (1V => 2mA)
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
    
    pause(3);
    
    %% pick one trial from the interventionControlArray
    sizeIntCtrlArray = numel(interventionControlArray);
    permutationIntCtrlArray = interventionControlArray(randperm(sizeIntCtrlArray));
    currentTrial = permutationIntCtrlArray(1);
%     currentTrial = 15;
    % if the current trial is between 1 and 20, then do an intervention
    % run, else do a control run
    
     %% Intervention trial 
    if (0<currentTrial) && (currentTrial<21)
        
        if coin  == 0
        % gabor in first interval
        correctkey = 37; 
                      
            %first 500ms
            for i = 1:circleWind
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %20ms offset
            for i = 1:(round(hertz*0.02))
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
        
            %second round, 480ms, due to the 20ms offset before
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
            
            %third 500ms
            for i = 1:circleWind
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %fourth 500ms
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
                                  
            %no gabor, 500ms + 20ms, play tRNS and then another 1520ms
            %first 500ms
            for i = 1:circleWind
                Screen('FrameOval',window, black, CircleRect, 2);
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %20ms offset
            for i = 1:(round(hertz*0.02))
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
                
            %second round, 1520, due to the 500ms and 20ms offset before = 2040ms
            for i = 1:(circleWind+round(hertz*1.02))
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
        
            coinFlip = 1;
            
        elseif coin == 1
        % gabor in second interval
            correctkey = 39;
            
           %no gabor, 500ms + 20ms, play tRNS and then another 1520ms
           %first 500ms
           for i = 1:circleWind
                Screen('FrameOval',window, black, CircleRect, 2);
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
           end
            
            %20ms offset
            for i = 1:(round(hertz*0.02))
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
                
            %second round, 1520, due to the 500ms and 20ms offset before = 2040ms
            for i = 1:(circleWind+round(hertz*1.02))
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
            
             %first 500ms
            for i = 1:circleWind
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %20ms offset
            for i = 1:(round(hertz*0.02))
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            
            %second round, 480ms, due to the 20ms offset before
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
            
            %third 500ms
            for i = 1:circleWind
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %fourth 500ms
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
    end

        %% Control trial
        
    if (20<currentTrial) && (currentTrial<41)
                    
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
        
            %wait 1ms, otherwise tRNS does not want to work
            pause(0.001);
                       
            pause(GratInterval);
        
            %no gabor, add 40ms
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
            
            %no gabor, add 40ms
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
            
            %wait 1ms, otherwise tRNS does not want to work
            pause(0.001);
                       
            pause(GratInterval);
            
            %first 1000ms
            for i = 1:(2*circleWind)
                %Draw circles
                Screen('FrameOval',window, black, CircleRect, 2);
                %Draw fixation cross
                Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
                Screen('Flip', window);
            end
            
            %gabor presentation
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
        
    end
      
    %% Additional stuff to ensure the tRNS offset of 250ms is applied correctly during the control trials
    
   if (0<currentTrial) && (currentTrial<21)
            % Draw the fixation cross
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
    
            % Flip to the screen
            Screen('Flip', window);
       
            pause(GratInterval);
            
   end
   
   if (20<currentTrial) && (currentTrial<41)
            % Draw the fixation cross
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
    
            % Flip to the screen
            Screen('Flip', window);
       
            pause(0.001); %needs to be in for some reason, otherwise the tRNS stimulation falls short
            
            
            
            pause(GratInterval);
        
    end
    
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
    DrawFormattedText(window, 'In which interval was the gabor patch? \n \n <-- 1st interval    |    2nd interval --> ', 'center', 'center', white);
    Screen('Flip', window);

    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(escapeKey)
        ShowCursor;
        sca;
        Screen('LoadNormalizedGammaTable', 0, normalGamma);
        Screen('CloseAll');
        return
    elseif keyCode(leftKey) %first interval
        keyAnswer = 1;
        if correctkey == 37
            response = 1;
            answer_name = "correct";
            Screen('TextSize', window, 50);
            Screen('TextFont', window, 'Noto Font');
            DrawFormattedText(window, ' correct ', 'center', 'center', green);
            Screen('Flip', window);
            pause(2);
        else
            response = 0;
            answer_name = "incorrect";
            Screen('TextSize', window, 50);
            Screen('TextFont', window, 'Noto Font');
            DrawFormattedText(window, ' incorrect ', 'center', 'center', red);
            Screen('Flip', window);
            pause(2);
        end
        respToBeMade = false;
    elseif keyCode(rightKey) %second interval
        keyAnswer = 2;
        if correctkey == 39;
            response = 1;
            answer_name = "correct";
            Screen('TextSize', window, 50);
            Screen('TextFont', window, 'Noto Font');
            DrawFormattedText(window, ' correct ', 'center', 'center', green);
            Screen('Flip', window);
            pause(2);
        else
            response = 0;
            answer_name = "incorrect";
            Screen('TextSize', window, 50);
            Screen('TextFont', window, 'Noto Font');
            DrawFormattedText(window, ' incorrect ', 'center', 'center', red);
            Screen('Flip', window);
            pause(2);
        end
        respToBeMade = false;
    end
        
    end
    
        %% Record the responses and other values in the corresponding arrays
        if (0<currentTrial) && (currentTrial<21)
            interventionAnswersArray = [interventionAnswersArray, answer_name];
            trialType = "intervention";
        elseif (20<currentTrial) && (currentTrial<41)
            ctrlAnswersArray = [ctrlAnswersArray, answer_name];
            trialType = "control";
        end
        
        keyAnswerArray = [keyAnswerArray, keyAnswer];
        answersTrialArray = [answersTrialArray, answer_name];
        intervalArray = [intervalArray, coinFlip];
        controlInterventionArray = [controlInterventionArray, trialType];
        

        
       %% Remove the current Trial and circle from their respective array
       interventionControlArray = interventionControlArray(interventionControlArray~=currentTrial);     
       circleLocationArray = circleLocationArray(circleLocationArray~=randomCirclePick);
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