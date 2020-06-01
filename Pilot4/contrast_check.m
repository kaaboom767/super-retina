%% This script runs the visual threshold part of the first pilot.
%% The usual necessities
sca;
close all;
clear all;
clearvars;


%% linearise the screen contrast
load('C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Scripts\Alain\Beta folder\Calibration\normalGamma.mat');
load('C:\Users\kaaboom\Hyperion Cloud\ETH\Master Thesis\Scripts\Alain\Beta folder\Calibration\gammaTableSonyCorrect.mat'); %%% Screen calibration
Screen('LoadNormalizedGammaTable', 0, gammaTable);


%% Enter custom  parameters for the signal and number of trials
intensityStart = 1;
contrastArray = [];
intervalArray = [];
answerArray = [];
keyAnswerArray = [];
screenShotNr = 1;

%% define image properties
%Image
imLength = 108;
imWidth = 108;
%Circles
CircLength = 108;
CircWidth = 108;
nCircles = 1:1:8;

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
insertKey = KbName('insert');
screenShotKey = KbName('s');


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


%% More circle stuff
%Screen Set-Up and Display instructions
stimRectCircle = [ 0 0 CircLength CircWidth ] ;
MVrectCircle = CenterRect(stimRectCircle, rect);


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
contrast = 0.5;
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



respToBeMade = true;
while respToBeMade == true
    
Screen('TextSize', window, 50);

%Draw contrast value
Screen('DrawText', window, num2str(contrast), 100, 100, white);

% Build a procedural gabor texture
    gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
    gaborOffsetValue, 1, 1);

% Get the Gabor angle for this trial (negative values are to the right
% and positive to the left)
theAngle = 0;

% Draw the Gabor
Screen('DrawTextures', window, gabortex, [], CircleRect(), theAngle, [], [], [], [],...
kPsychDontDoRotation, propertiesMat');
%Draw circles
Screen('FrameOval',window, black, CircleRect, 2);
%Draw fixation cross
Screen('DrawLines', window, allCoords,...
lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window);

[keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(escapeKey)
        ShowCursor;
        sca;
        Screen('LoadNormalizedGammaTable', 0, normalGamma);
        Screen('CloseAll');
        return
    elseif keyCode(leftKey) %increase contrast
            contrast = contrast + 0.001;
            answer_name = "increase";
            %make a properties matrix
            propertiesMat = repmat([NaN, freq, sigma, contrast,...
            aspectRatio, 0, 0, 0], nGabors, 1);
            propertiesMat(:, 1) = phaseLine';
            % Draw the Gabor
            Screen('DrawTextures', window, gabortex, [], CircleRect(), theAngle, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');
            %Draw circles
            Screen('FrameOval',window, black, CircleRect, 2);
            %Draw fixation cross
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
            Screen('Flip', window);
    elseif keyCode(rightKey) %decrease contrast
            contrast = contrast - 0.001;
            answer_name = "decrease";
            %make a properties matrix.
            propertiesMat = repmat([NaN, freq, sigma, contrast,...
            aspectRatio, 0, 0, 0], nGabors, 1);
            propertiesMat(:, 1) = phaseLine';
            % Draw the Gabor
            Screen('DrawTextures', window, gabortex, [], CircleRect(), theAngle, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');
            %Draw circles
            Screen('FrameOval',window, black, CircleRect, 2);
            %Draw fixation cross
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
            Screen('Flip', window);
    elseif keyCode(insertKey) % enter value
            contrast = Ask(window,'Enter a contrast value: ',[],[grey],'GetChar',RectLeft,RectTop); % Accept keyboard input, echo it to screen
            contrast = str2num(contrast);
            %make a properties matrix.
            propertiesMat = repmat([NaN, freq, sigma, contrast,...
            aspectRatio, 0, 0, 0], nGabors, 1);
            propertiesMat(:, 1) = phaseLine';
            % Draw the Gabor
            Screen('DrawTextures', window, gabortex, [], CircleRect(), theAngle, [], [], [], [],...
            kPsychDontDoRotation, propertiesMat');
            %Draw circles
            Screen('FrameOval',window, black, CircleRect, 2);
            %Draw fixation cross
            Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
    elseif keyCode(screenShotKey) % take a screenshot
            filename = ['test_' num2str(contrast) '_.jpg'];
            %filename = [filename{:}];
            filename = convertCharsToStrings(filename);
            
            % GetImage call.
            imageArray = Screen('GetImage', window, rect);
            imwrite(imageArray, filename)    

    end
            
end
sca;
Screen('LoadNormalizedGammaTable', 0, normalGamma);
Screen('CloseAll');