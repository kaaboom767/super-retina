%% This script runs the tRNS threshold part of the first pilot.
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


%% --------------------Set up variables--------------------

%% Set parameters for the tRNS stimulation
%Sampling rate
S.Rate = 1280; %double of the max frequency of 640Hz
nyqF=S.Rate/2;
%Filters
filter_hf = fir1(150,100/(nyqF), 'high'); %highpass filter, 150th order, cutoff at 100Hz
filter_lf = fir1(150,100/(nyqF), 'low'); %lowpass filter, 150th order, cutoff at 100Hz
%InitializePsychSound %initializse sound output


%% Enter custom parameters for the signal and number of trials
%Duration of the signal in seconds
duration = 5;
%Intensity in mA, 100microA seem reasonable as a starting point
intensityStart = 1; % value for the quest
tRNSNoiseInt_lf = 0.1;
tRNSNoiseInt_hf = tRNSNoiseInt_lf;
tRNSTrialArray = [];
tRNS_hf_Array = [];
answersTrialArray = [];
% How many Trials to estimate Threshold?
numTrials = 40;
trialArray = (1:1:numTrials);
intensityArray = [];

%% Set-Up Starting Parameters for Quest         
% Provide prior knowledge about estimated Threshold

tGuess = 0.2; % guess where the threshold may be, usually around 0.2mA

tGuessSd = 3; % was 0.01, the documentation says to be generous, i.e. 3, so let's try that

pThreshold = 0.5; % p-Value for 2afc Task: 0.82; p-Value for yes-no Task: 0.62
beta = 3;
delta = 0.01;
gamma = 0;
grain = 0.01; %step size of internal table
range = 0.6; %centers it around tGuess and sets the maximum and minimum possible values
q = QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range);
q.normalizePdf = 1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.

% Responses
stimulationPerception={'NO','YES'};
            
        
%% Set up communication with brain stimulator
%Setup Data Acquisition for tRNS
S = daq.createSession('ni'); % Create a data acquisition session for National Instruments
S.addAnalogOutputChannel('Dev1', 'ao0', 'Voltage'); %Outputchannel
% %S.addAnalogInputChannel('Dev1', 'ai0', 'Voltage'); %Inputchannel if you want to monitor output
S.Rate = 1280; %Same as for tRNS in neuroconn device


%% prompt subject to enter parameter values for the following fields:
if metaScript == 0
    start_input = inputdlg({'Subject Number','Session Number','Age','Gender'},'tRNS Threshold',[1 40]);
    p.SubjectsNumber = start_input(1,1);
    p.SessionNr = start_input(2,1); % Session number
    p.Age = start_input(3,1); % ppn age
    p.Gender = start_input(4,1);
end


%% Directory stuff for data storage
WorkingDir = [p.SubjectsNumber '\Threshold_part']; %set directory for windows to save data
WorkingDir = [WorkingDir{:}];
WorkingDir = convertCharsToStrings(WorkingDir);

DataFile = [WorkingDir '\1.3-WP2-' p.SubjectsNumber '_Run_' p.SessionNr '_tRNS_threshold']; %set folders per subject

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


%% Write the collected information into a file in the subject's directory
FID = fopen(DataFileTXT, 'a');
%fprintf(FID, '\r\n\r\n\r\n');
fprintf(FID, 'This data file was created by the following script: %s.m',( mfilename));
%fprintf(FID, '\r\n');
fprintf(FID, ' at: %s', datestr(now));
%fprintf(FID, '\r\n');
fprintf(FID, ' for Pilot 1');
fprintf(FID, '\r\n\r\n');
fprintf(FID, 'Subject number: 1.3-WP2-%s',char(p.SubjectsNumber));
fprintf(FID, '\r\n');
fprintf(FID, 'Subjects age: %s',char(p.Age));
fprintf(FID, '\r\n');
fprintf(FID, 'Gender: %s' ,char(p.Gender));
fprintf(FID, '\r\n\r\n');
fprintf(FID, 'Session number: %s',char(p.SessionNr));
fprintf(FID, '\r\n');
fclose(FID);


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


%% --------------------Experimental loop--------------------
% Animation loop: we loop for the total number of trials
for trial = 1:numTrials

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
    
    
    %% Quest Stuff
     % Here we choose the algorithm for QUEST
            tTest = QuestMean(q);         % Recommended by King-Smith et al. (1994)
            %tTest = QuestMode(q);		  % Recommended by Watson & Pelli (1983)
            %tTest = QuestQuantile(q);	  % Recommended by Pelli (1987)
                    
            % Define Detection Signal with Current Intensity
            % Should only change within low frequency trials
            if mod(trial,2) == 1
                current_intensity = tTest;
                tRNSNoiseInt_lf = intensityStart * current_intensity;
            end
            
    
        %% tRNS HF signal generation
        time = duration + 1; %One second is added, because it will be cut due to filtering
        tRNSNoise = 1/4*tRNSNoiseInt_hf; %We divide by four to incorporate the std and the transferfunction of the stimulator (1V => 2mA)
        TRNS_Signal = tRNSNoise*randn((S.Rate*time),1); % Create an array with dimensions of (sample rate x time) by 1.

        TRNS_Signal(TRNS_Signal > 2*tRNSNoise) = 2*tRNSNoise;
        TRNS_Signal(TRNS_Signal < -2*tRNSNoise) = -2*tRNSNoise;
        TRNS_Signal(end) = 0;

        TRNS_Signal_hf = filter(filter_hf,1,TRNS_Signal);
        TRNS_Signal_hf = TRNS_Signal_hf(S.Rate+1:end);


        %% tRNS LF Signal generation
        time = duration + 1; %One second is added, because it will be cut due to filtering
        tRNSNoise = 1/4*2.4*tRNSNoiseInt_lf; %We divide by four to incorporate the std and the transferfunction of the stimulator (1V => 2mA) and double the intensity for low frequency tRNS.
        TRNS_Signal = tRNSNoise*randn((S.Rate*time),1); % Create an array with dimensions of (sample rate x time) by 1.

        TRNS_Signal(TRNS_Signal > 2*tRNSNoise) = 2*tRNSNoise;
        TRNS_Signal(TRNS_Signal < -2*tRNSNoise) = -2*tRNSNoise;
        TRNS_Signal(end) = 0;

        TRNS_Signal_lf = filter(filter_lf,1,TRNS_Signal);
        TRNS_Signal_lf = TRNS_Signal_lf(S.Rate+1:end);
        
        S.IsContinuous = true;
    
        
        %% Now we draw the fixation cross and stimulate with tRNS  
          
        %Play tRNS noise, change low and high frequency every round but
        %within use the same instensity between the two
        if mod(trial,2) == 1
                S.queueOutputData(TRNS_Signal_lf);
                S.startBackground();       
%                 tRNSNoiseInt_hf = tRNSNoiseInt_lf;
        elseif mod(trial,2) == 0
                S.queueOutputData(TRNS_Signal_hf);
                S.startBackground();
        end
        
        % Change the blend function to draw an antialiased fixation point
        % in the centre of the array
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

        % Draw the fixation cross
         Screen('DrawLines', window, allCoords,...
         lineWidthPix, black, [xCenter yCenter], 2);

        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        
        pause(duration+1);
   
        %Sound cue to answer
        %Beeper('medium',1,0.5);

    %% Now we wait for a keyboard button signaling the observers response.
    % The left arrow key signals a "no strobe" response and the right arrow key
    % a "strobe" response. You can also press escape if you want to exit the
    % program
    respToBeMade = true;
    while respToBeMade == true
        
        %text to ask if participant saw strobe effect
%         Screen('TextSize', window, 80);
%         Screen('TextFont', window, 'Noto Font');
%         DrawFormattedText(window, 'Did you see a strobe effect?', 'center', 'center', white);
%         Screen('Flip', window);
        
    %Very important to have something drawn withing the while loop,
    %otherwise a black screen occurs.
       
    %Text to display
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Noto Font');
    DrawFormattedText(window, 'Did you perceive visual flickering? \n \n <-- No    |    Yes --> ', 'center', 'center', white);
    Screen('Flip', window);

        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            return
        elseif keyCode(leftKey) % no flickering perceived
            response = 0;
            answer_name = "NO";
            respToBeMade = false;
        elseif keyCode(rightKey) % flickering perceived
            response = 1;
            answer_name = "YES";
            respToBeMade = false;
        end
    end

    
    %% Update the pdf, only the odd trials
    if mod(trial,2) == 1
        q=QuestUpdate(q,tTest,response); % Add the new datum (actual test intensity and observer response) to the database.
    end
    
        
    %% Check answers in high frequency trials
    %In high frequency trials, participants should not see any flickering
    if mod(trial,2) == 0
        if response == 0
            tRNS_hf_Array = [tRNS_hf_Array, "no flickering"]; %#ok<*AGROW>
        elseif response == 1
            tRNS_hf_Array = [tRNS_hf_Array, "flickering perceived"];
        end
    end
    
    % Record the responses and other values in an array
   
    answersTrialArray = [answersTrialArray, answer_name];
    tRNSTrialArray = [tRNSTrialArray, tRNSNoiseInt_lf];
    
    
end

%% --------------------Final stuff---------------------

%% Ask Quest for the final estimate of threshold.
t = QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
sd = QuestSd(q);


%% Check if flickering during high frequency stimulation was perceived
if any(strcmp(tRNS_hf_Array,'flickering perceived'))
    HF_Index = find(contains(tRNS_hf_Array,'flickering perceived'));
    HF_Flickering = ['High frequency flickering in Blocks ' mat2str(HF_Index) ' perceived!'];
else
    HF_Flickering = ('No high frequency flickering perceived!');
end


%% Combine all the important values into one array
A = [trialArray; tRNSTrialArray; answersTrialArray];
     

%% Write text file with data   
FID = fopen(DataFileTXT, 'a');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, 'Estimated Threshold: %f',t);
fprintf(FID, ' mA');
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, '%s',HF_Flickering);
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fprintf(FID, '%6s %14s %6s \r\n','Trial','Intensity [mA]','Answer');
fprintf(FID, '%6.0f %14.6f %6s \r\n',A);
fprintf(FID, '\r\n');
fprintf(FID, '\r\n');
fclose(FID);


%% Write csv file with values
B = transpose(A);
table = array2table(B,'VariableNames',{'Trial','Intensity [mA]','Answer'});
writetable(table, DataFileCSV');
    
%% Display End
Screen('TextSize', window, 80);
Screen('TextFont', window, 'Noto Font');
DrawFormattedText(window, 'End', 'center', 'center', white);
Screen('Flip', window);


%% Wait for a key press
KbStrokeWait;
sca;


%% Save threshold and beta into q
q.xThreshold = t;
q.beta = QuestBetaAnalysis(q);


%% Plot the psychometric function and save all variables
%x = linspace(min(q.intensity(1:40)), max(q.intensity(1:40)), 101);
q.p2 = q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*(q.x2 + q.xThreshold))));
plot(q.x2, q.p2, '-', 'LineWidth', 2);
%ylim([0,1])

save(DataFileMAT);

winopen(DataFileTXT);
