%% This script runs the experiment part of the first pilot.
%% The usual necessities
sca;
close all;
clear all;
clearvars;


%% --------------------Set up variables--------------------

%% Set parameters for the tRNS stimulation
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

interventionControlArray = Shuffle(1:1:numTrials); % set 40 trials, trial 1-20 are intervention trials, trial 21-40 are control trials
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
nCircles = (1:1:8);

[ x, y ] = meshgrid( -imWidth/2+1:imWidth/2, -imLength/2+1:imLength/2);
nCosSteps = 25;%1/8*imSize;
gratingDiam = 108;
%sigma = 20;
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
Quadrant1 = KbName('4');
Quadrant2 = KbName('5');
Quadrant3 = KbName('2');
Quadrant4 = KbName('1');

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
       
   %% Set the circle to its corresponding quadrant
    if randomCircle == 1 
            correctAnswer = 2;
        elseif randomCircle == 2
            correctAnswer = 2;
        elseif randomCircle == 3
            correctAnswer = 1;
        elseif randomCircle == 4
            correctAnswer = 1;
        elseif randomCircle == 5
            correctAnswer = 4;
        elseif randomCircle == 6
            correctAnswer = 4;
        elseif randomCircle == 7
            correctAnswer = 5;
        elseif randomCircle == 8
            correctAnswer = 8;
    end
    
    
    % Get the Gabor angle for this trial (negative values are to the right
    % and positive to the left)
    theAngle = 0;   
    
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
    
    %% pick one trial from the interventionControlArray
    sizeIntCtrlArray = numel(interventionControlArray);
    permutationIntCtrlArray = interventionControlArray(randperm(sizeIntCtrlArray));
    currentTrial = permutationIntCtrlArray(1);
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
    elseif keyCode(Quadrant2) %second quadrant
        keyAnswer = "Second";
        if correctAnswer == 5
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
    elseif keyCode(Quadrant3) %third quadrant
        keyAnswer = "Third";
        if correctAnswer == 2
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
    elseif keyCode(Quadrant4) %fourth quadrant
        keyAnswer = "Fourth";
        if correctAnswer == 1
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