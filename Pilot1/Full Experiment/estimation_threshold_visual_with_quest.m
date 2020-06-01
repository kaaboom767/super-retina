%% This script runs the visual threshold part of the first pilot.
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
numTrials = 40;
circleLocationArray = (1:1:numTrials);
trialArray = (1:1:numTrials);
contrastArray = [];
intervalArray = [];
answerArray = [];
keyAnswerArray = [];
minBoundary = 0.001;
maxBoundary = 1;


%% Set-Up Starting Parameters for Quest         
% Provide prior knowledge about estimated Threshold

tGuess = 0.3; % quest 1
minThreshold = minBoundary; % set the minimum possible threshold
range = (tGuess*2) - (minThreshold);

pThreshold = 0.75; % p-Value for 2afc Task: 0.82; p-Value for yes-no Task: 0.62
beta = 3; % typical value for visual tasks
delta = 0.01;
gamma = 0.5;
grain = 0.01; %step size of internal table
%range = 0.6; %centers it around tGuess and sets the maximum and minimum possible values, author recommends value of 5

tGuessSd = 3; % was 0.01, the documentation says to be generous, i.e. 3, so let's try that

q = QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range);
q.normalizePdf = 1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.            


%% prompt subject to enter parameter values for the following fields:
if metaScript == 0
    start_input = inputdlg({'Subject Number','Session Number','Age','Gender'},'Estimation Visual Threshold', [1 40]);
    p.SubjectsNumber = start_input(1,1);
    p.SessionNr = start_input(2,1); % Session number
    p.Age = start_input(3,1); % ppn age
    p.Gender = start_input(4,1);     
end


%% Directory stuff for data storage
WorkingDir = [[p.SubjectsNumber '\']; %set directory for windows to save data
WorkingDir = [WorkingDir{:}];
WorkingDir = convertCharsToStrings(WorkingDir);

DataFile = [WorkingDir '\1.3-WP1-' p.SubjectsNumber '_Run_' p.SessionNr '_estimated_visual_threshold']; %set folders per subject

DataFileTXT = [DataFile, '.txt'];
DataFileTXT = [DataFileTXT{:}]; %some conversion magic going on in order to make it readable by fopen()
DataFileTXT = convertCharsToStrings(DataFileTXT); %dito

DataFileCSV = [DataFile '.csv'];
DataFileCSV = [DataFileCSV{:}];
DataFileCSV = convertCharsToStrings(DataFileCSV);

DataFileMAT = [DataFile '.mat'];
DataFileMAT = [DataFileMAT{:}];
DataFileMAT = convertCharsToStrings(DataFileMAT);

mkdir (WorkingDir); %create the subject's folder


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
%     coin = 0;

    
    %% Quest Stuff
     % Here we choose the algorithm for QUEST
            tTest = QuestMean(q);         % Recommended by King-Smith et al. (1994)
            %tTest = QuestMode(q);		  % Recommended by Watson & Pelli (1983)
            %tTest = QuestQuantile(q);	  % Recommended by Pelli (1987)
                    
            % Limit the values for contrast
            tTest=min(max(tTest,minBoundary),maxBoundary);
            
            % Define Detection Signal with Current Intensity
            current_intensity = tTest;
            contrast = current_intensity;         
            
%             if contrast < 0
%                 contrast = 0.001;
%             elseif contrast > 1
%                 contrast = 1;
%             end
%             % Randomise the phase of the Gabors and make a properties matrix.
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
    q = QuestUpdate(q,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
    %Record values
    values = QuestTrials(q);
    valueArray = [valueArray, values];


    %% Record the responses and other values in an arrays
    contrastArray = [contrastArray, contrast];
    keyAnswerArray = [keyAnswerArray, keyAnswer];
    answersTrialArray = [answersTrialArray, answer_name];
    intervalArray = [intervalArray, coinFlip];


    %% Remove the current and circle from their respective array
    circleLocationArray = circleLocationArray(circleLocationArray~=randomCirclePick);
    
end


%% --------------------Final stuff---------------------
%% Ask Quest for the final estimate of threshold.
t = QuestMean(q);% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
sd = QuestSd(q);

if t < minBoundary
   t = minBoundary;
end

nCorrect = nnz(strcmp(answersTrialArray,"correct"));
percentageCorrect = nCorrect/trial*100;


%% Combine all the important values into one array
A = [trialArray; contrastArray; keyAnswerArray; answersTrialArray; intervalArray];


%% Write text file with data   
FID = fopen(DataFileTXT, 'a');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, 'Estimated Threshold: %f',t);
%fprintf(FID, ' mA');
fprintf(FID, '\r\n');
%fprintf(FID, 'Estimated SubThreshold: %f',tSub);
%fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, '%6s %8s %6s %11s %14s \r\n','Trial','Contrast','Answer','Correctness','Gabor Interval');
fprintf(FID, '%6.0f %8.5f %6s %11s %14.0f \r\n',A);
%fprintf(FID, '%s \r\n',answersTrialArray{:});
fprintf(FID, '\r\n');
fprintf(FID, 'Percentage correctly answered: %f',percentageCorrect);
fprintf(FID, '%%');
fclose(FID);


%% Write csv file with values
B = transpose(A);
table = array2table(B,'VariableNames',{'Trial','Contrast','Answer','Correctness','Gabor Interval'});
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


%% Save threshold and beta into q
q.xThreshold = t;
q.beta = QuestBetaAnalysis(q);


%% Plot the psychometric function and save all variables
q.p2 = q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*(q.x2 + q.xThreshold))));
plot(q.x2, q.p2, 'o', q.x2, q.p2, '-', 'LineWidth', 2);

save(DataFileMAT);

winopen(DataFileTXT);
