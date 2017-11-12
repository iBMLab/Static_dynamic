% dynamic expression
% only one eye is tracked
% screen = 39 cm width, screen resolution 1920*1080, 120 Hz
% video size: 576*760, 30fp
% Clear Matlab/Octave window:


Screen('Preference', 'SkipSyncTests', 1)

ScreenX=34;
ScreenY=28;
PixelX=1080;
PixelY=900;
% setting the size of the stimuli at a distance of 60cm
% scale=3;
% pixel --> aller regarder la r?solution de l'?cran ex: 1400 x900
% sur le Mac Book Air Screen X= 28.8; Screen Y= 18
% scale= (3*18/28)*(1400/900);
scale=(3*ScreenY/ScreenX)*(PixelX/PixelY);


clear all;
clc;

Screen('Preference', 'SkipSyncTests', 1);
% setup experiment
exptype = str2double(input('experiment type (1 - dynamic 2 - dynmaic shuffle 3 - static): ','s'));
practicerun = str2double(input('is it a practise run (1) or a real experiment (2)?: ','s'));
if practicerun==2
    subInitials = input('participant''s name: ','s');
    subage = input('participant''s age: ','s');
    subgender = input('participant''s gender: (1 Female 2 Male) ','s');
    newexp = str2double(input('is it a new participant (1) or a continue participant (2)?: ','s'));
    % eyetracking = str2double(input('enter 1 to use eyetracker: ','s'));
    eyetracking = 0;
    
    filename = sprintf('%s',subInitials);
    % create text file for data and parameters recording
    datatxt=[filename '_g' subgender '_a' subage '_DyExp_beh.txt'];
else
    % eyetracking = str2double(input('enter 1 to use eyetracker: ','s'));
    eyetracking = 0;
    newexp=1;
    filename='pracseq';
    datatxt=[filename '_DyExp_beh.txt'];
end

Nblock=2;
Ntrial=48;% 6*8 item in total
Nexpall=Nblock*Ntrial;
if newexp==1
    randseq=randperm(Nexpall);
    ii2=0;
    save([filename,num2str(exptype),'.mat'],'ii2','randseq')
else
    try
        load([filename,num2str(exptype),'.mat']);
    catch
        randseq=randperm(Nexpall);
        ii2=0;
        save([filename,num2str(exptype),'.mat'],'ii2','randseq')
    end
end

distdrift=50000;
seuildrift=75;
drifthres=200;
% video scale
fps1=30; % refresh rate for the movie

% load videos
folder=cd;
% VideoMat=load('JOV2013ExpressionStimuli-3.mat');
% VideoMat=rmfield(VideoMat,'randomsequences');
if exptype==1
    load('VideoMatnd.mat')
    VideoMat=VideoMatnd;
    clear VideoMatnd;
elseif exptype==2
    load('VideoMatnd.mat')
    VideoMat=VideoMatnd;
    clear VideoMatnd;
elseif exptype==3
    load('VideoMatns.mat')
    VideoMat=VideoMatns;
    clear VideoMatns;
end
expressions=fieldnames(VideoMat);
itemall=fieldnames(VideoMat.Anger);
Nrep=Nexpall/(size(expressions,1)*size(itemall,1));
ii=0;
clear exptable;
for irep=1:Nrep
    for iexp=1:size(expressions,1)
        for iitem=1:size(itemall,1)
            ii=ii+1;
            exptable(ii,1)=expressions(iexp);
            exptable(ii,2)=itemall(iitem);
        end
    end
end
load Mask.mat
% check for Opengl compatibility, abort otherwise:
AssertOpenGL;

% Reseed the random-number generator for each expt.
rand('state',sum(100*clock));
%% EyeLink Stuff
if eyetracking==1
    eyedatatxt=[filename '_DyExp_eye.txt'];
    dummymode=0;
    % Initialization of the connection with the Eyelink Gazetracker. exit program if this fails.
    if ~EyelinkInit(dummymode, 1)
        fprintf('ahhhhhh.\n');
        cleanup;  % cleanup function
        return;
    end
    
    % STEP 1
    % Open a graphics window on the main screen using the PsychToolbox's Screen function.
    % weyelink is the screen used for the Eyelink functions calibration, drift correction,...
    screenNumber=max(Screen('Screens'));
    [mainw, wRect]=Screen('OpenWindow', screenNumber, 0,[],32,2);
    Screen(mainw,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % STEP 2
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    el=EyelinkInitDefaults(mainw);
    % Disable key output to Matlab window:
    % ListenChar(2);
    
    [v vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    
    % make sure that we get event data from the Eyelink
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    Eyelink('command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY');
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,BLINK,SACCADE,BUTTON');
    
    % hide mouse cursor
    HideCursor;
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    % do a final check of calibration using driftcorrection
    success=EyelinkDoDriftCorrection(el);
    if success~=1
        cleanup;
        return;
    end
    
    % start recording eye position
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);
    % mark zero-plot time in data file
    Eyelink('Message', 'SYNCTIME');
    
    % get eye that's tracked
    evt = Eyelink( 'NewestFloatSample');
    eye_used = Eyelink('EyeAvailable');
    eye_used=eye_used+1;
else
    screenNumber=max(Screen('Screens'));
    [mainw, wRect]=Screen('OpenWindow', screenNumber, 0,[],32,2);
    ifi=Screen('GetFlipInterval', mainw);
    waitframe=round(1/fps1/ifi);% at refresh rate 60HZ
    % hide mouse cursor
    HideCursor;
end
%%
% set screen
Screen('FillRect', mainw, [255/2 255/2 255/2 0]);% black screen
Screen('Flip', mainw);
% % second screen for optimal synchronization purpose.
% white=WhiteIndex(1);
% [w2, wRect2]=Screen('OpenWindow',1, white);%%% ,[0 0 800 600]

%% reaction key
% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');

recal=KbName('p');
afk=KbName('p');% Fear
ank=KbName('c');% Anger
dik=KbName('d');% Disgust
hak=KbName('j');% Happy
sak=KbName('t');% Sadness
suk=KbName('s');% Surprise
skipk=KbName('l');% Skip
breakcode=KbName('q');% breakkey

% screen size
screenx=0.5*wRect(3);
screeny=0.5*wRect(4);

%% introduction
instru_v = ['The experiment is about to start...'];
% Write instruction message for subject, nicely centered in the
% middle of the display, in white color. As usual, the special
% character '\n' introduces a line-break:
Screen('TextSize', mainw, 50);
DrawFormattedText(mainw, instru_v, 'center', 'center', WhiteIndex(mainw));
Screen('Flip', mainw);

% Wait for mouse click:
GetClicks(mainw);

% Clear screen to background color (our 'white' as set at the
% beginning):
Screen('Flip', mainw);

% Wait a second before starting trial
WaitSecs(1.000);

%% main experiment
while ii2<Nexpall
    ii2=ii2+1;
    %         DrawFormattedText(w2, num2str(itrial), 'center', 'center', BlackIndex(w2));
    %         Screen('Flip', w2);
    
    [KeyIsDown, vert, KeyCode]=KbCheck;
    Screen('TextSize', mainw, 50);
    DrawFormattedText(mainw, '+', 'center', 'center', WhiteIndex(mainw)); % fixation
    [VBLTimestamp startrt2] = Screen('Flip', mainw);
    
    if eyetracking==1
        % Start recording with Eyelink
        % get eye that's tracked
        eye_used = Eyelink('EyeAvailable');
        eye_used = 1;
        
        % start recording eye position
        Eyelink('StartRecording');
        % record a few samples before we actually start displaying
        WaitSecs(0.1);
        % mark zero-plot time in data file
        Eyelink('Message', 'SYNCTIME');
        
        [mx, my, buttons]=GetMouse(mainw);
        
        while (~any(buttons) || distdrift>seuildrift)
            % Get mouse position
            [mx, my, buttons]=GetMouse(mainw);
            % Get eye position
            evt = Eyelink( 'newestfloatsample');
            % get current gaze position from sample
            eyex = evt.gx(eye_used); % OK for left eye, right eye??? +1 as we're accessing MATLAB array for right eye on EyeLink2
            eyey = evt.gy(eye_used);
            %draw a circle on the screen at current gaze position
            gazeRect=[eyex-3 eyey-3 eyex+3 eyey+3];
            Screen('TextSize', mainw, 50);
            DrawFormattedText(mainw, '+', 'center', 'center', WhiteIndex(mainw)); % fixation
            Screen('FrameOval', mainw, [255 255 255], gazeRect,5,5);
            Screen('Flip',mainw);
            clear keyCode
            [keyIsDown, secs, keyCode]=KbCheck;
            
            %% new calibration if necessary
            
            if keyCode(recal)==1
                % Close eyelink stuff
                Eyelink('Stoprecording');
                Eyelink('closefile');
                Eyelink('Shutdown');
                % Close all screens but textures also so will have to calculate
                % anew the textures
                Screen('CloseAll');
                clear screen;
                
                % Initialization of the connection with the Eyelink Gazetracker. exit program if this fails.
                if ~EyelinkInit(dummymode, 1)
                    fprintf('ahhhhhh.\n');
                    cleanup;  % cleanup function
                    return;
                end
                
                % STEP 1
                % Open a graphics window on the main screen using the PsychToolbox's Screen function.
                % mainw is the screen used for the Eyelink functions calibration, drift correction,...
                screenNumber=max(Screen('Screens'));
                [mainw, wRect]=Screen('OpenWindow', screenNumber, 0,[],32,2);
                Screen(mainw,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                % STEP 2
                % Provide Eyelink with details about the graphics environment
                % and perform some initializations. The information is returned
                % in a structure that also contains useful defaults
                % and control codes (e.g. tracker state bit and Eyelink key values).
                el=EyelinkInitDefaults(mainw);
                % Disable key output to Matlab window:
                % ListenChar(2);
                
                [v vs]=Eyelink('GetTrackerVersion');
                fprintf('Running experiment on a ''%s'' tracker.\n', vs );
                
                % make sure that we get event data from the Eyelink
                Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
                Eyelink('command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY');
                Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,BLINK,SACCADE,BUTTON');
                
                % hide mouse cursor
                HideCursor;
                
                % Calibrate the eye tracker
                EyelinkDoTrackerSetup(el);
                
                % do a final check of calibration using driftcorrection
                success=EyelinkDoDriftCorrection(el);
                if success~=1
                    cleanup;
                    return;
                end
                
                % start recording eye position
                Eyelink('StartRecording');
                % record a few samples before we actually start displaying
                WaitSecs(0.1);
                % mark zero-plot time in data file
                Eyelink('Message', 'SYNCTIME');
                
                % get eye that's tracked
                evt = Eyelink( 'NewestFloatSample');
                eye_used = Eyelink('EyeAvailable');
                eye_used=eye_used+1;
                
                buttons=0;
                WaitSecs(0.5);
                
                % set screen
                Screen('FillRect', mainw, [0 0 0 0]);% black screen
                Screen('Flip', mainw);
                %                     % second screen for optimal synchronization purpose.
                %                     white=WhiteIndex(screenNumber);
                %                     [w2, wRect2]=Screen('OpenWindow',1, white);%%% ,[0 0 800 600]
                
                while ~any(buttons)
                    % Get mouse position
                    [mx, my, buttons]=GetMouse(mainw);
                    % Get eye position
                    evt = Eyelink( 'newestfloatsample');
                    % get current gaze position from sample
                    eyex = evt.gx(eye_used); % OK for left eye, right eye??? +1 as we're accessing MATLAB array for right eye on EyeLink2
                    eyey = evt.gy(eye_used);
                    %draw a circle on the screen at current gaze position
                    gazeRect=[eyex-3 eyey-3 eyex+3 eyey+3];
                    Screen('TextSize', mainw, 50);
                    DrawFormattedText(mainw, '+', 'center', 'center', WhiteIndex(mainw)); % fixation
                    Screen('FrameOval', mainw, [255 255 255], gazeRect,5,5);
                    Screen('Flip',mainw);
                    [keyIsDown, secs, keyCode]=KbCheck;
                end
            end
            %% end new calibration
            % homemade drift correction :/
            diffx=eyex-screenx;
            diffy=eyey-screeny;
            distdrift=sqrt(diffx*diffx+diffy*diffy);
            
        end % end calibration checking
    else
        while (GetSecs - startrt2)<.5 %presentation until respond
            [KeyIsDown, endrt2, KeyCode]=KbCheck;
        end
    end
    if KeyCode(breakcode)==1
        break
    end
    eval(['videotmp=VideoMat.' exptable{randseq(ii2),1} '.' exptable{(ii2),2} ';'])
    if exptype==2
        videotmp=videotmp(:,:,randperm(30));
    end
    videotmp(mask==0)=255/2;
    
    % load first frame
ScreenX=34;
ScreenY=28;
PixelX=1080;
PixelY=900;
% setting the size of the stimuli at a distance of 60cm
% scale=3;
% pixel --> aller regarder la r?solution de l'?cran ex: 1400 x900
% sur le Mac Book Air Screen X= 28.8; Screen Y= 18
% scale= (3*18/28)*(1400/900);
scale=(3*ScreenY/ScreenX)*(PixelX/PixelY);
[height1,width1,counts]=size(videotmp);
width2=width1*scale;
height2=height1*scale;
    
    if eyetracking==1
        imdata1=squeeze(videotmp(:,:,iframe));
        tex1=Screen('MakeTexture', mainw, imdata1);
        r1 = [unifrnd(width2*.6, wRect(3)-width2*.6),unifrnd(height2*.6, wRect(4)-height2*.6)];
        while r1(1)>(wRect(3)/2-width2/2)&&r1(1)<(wRect(3)/2+width2/2)&&r1(2)>(wRect(4)/2-height2/2)&&r1(2)<(wRect(4)/2+height2/2)
            r1 = [unifrnd(width2*.6, wRect(3)-width2*.6),unifrnd(height2*.6, wRect(4)-height2*.6)];
        end
        cRect1=SetRect(r1(1)-width1/2, r1(2)-height1/2, r1(1)+width1/2, r1(2)+height1/2);
        
        % Draw the new texture immediately to screen:
        Screen('DrawTexture', mainw, tex1, [], cRect1);
        %         % Draw border
        %         Screen('FrameRect', mainw, [255 255 255],cRect1, 5);
        % Update display:
        Screen('Flip', mainw);
        distdrift2=1000;
        % Playback loop1: continue when subject's gaze is close to the video
        while  distdrift2>drifthres % currenttime-debtrial
            % Get eye position
            evt = EyeLink( 'newestfloatsample');
            % get current gaze position from sample
            eyex = evt.gx(eye_used); % OK for left eye, right eye??? +1 as we're accessing MATLAB array for right eye on EyeLink2
            eyey = evt.gy(eye_used);
            diffx=eyex-r1(1);
            diffy=eyey-r1(2);
            distdrift2=sqrt(diffx*diffx+diffy*diffy);
        end
        % Release texture:
        Screen('Close', tex1);
    else
        r1=[screenx,screeny];
        cRect1=SetRect(r1(1)-width2/2, r1(2)-height2/2, r1(1)+width2/2, r1(2)+height2/2);
    end
    
    debtrial=GetSecs;
    currenttime=debtrial;
    oldtime=debtrial;
    echantillon=0;
    tvbl = Screen('Flip', mainw);
    % Playback loop: Runs until end of movie
    for iframe=1:counts
        imdata1=squeeze(videotmp(:,:,iframe));
        tex1=Screen('MakeTexture', mainw, imdata1);
        % Draw the new texture immediately to screen:
        Screen('DrawTexture', mainw, tex1, [], cRect1);
        %             % Draw border
        %             Screen('FrameRect', mainw, [255 255 255],cRect1, 5);
        % Update display:
        if eyetracking==1
            [VBLTimestamp currenttime] = Screen('Flip', mainw);
            while GetSecs-VBLTimestamp<(1/fps1)
                % Get eye position
                evt = EyeLink( 'newestfloatsample');
                % get current gaze position from sample
                eyex = evt.gx(eye_used); % OK for left eye, right eye??? +1 as we're accessing MATLAB array for right eye on EyeLink2
                eyey = evt.gy(eye_used);
                
                timeloop=GetSecs-oldtime;
                echantillon=echantillon+1;
                % save subject respond
                eyedatatowrite=[ii2 echantillon eyex eyey timeloop debtrial currenttime exptype];
                dlmwrite(eyedatatxt, eyedatatowrite, '-append','delimiter', '\t', 'precision', 7);
            end
        else
            tvbl = Screen('Flip', mainw, tvbl + ifi*(waitframe-0.5));
        end
        % Release texture:
        Screen('Close', tex1);
    end
    
    DrawFormattedText(mainw, 'Respond?', 'center', 'center', WhiteIndex(mainw)); % fixation
    [VBLTimestamp startrt2] = Screen('Flip', mainw);
    ACC=0;
    while (GetSecs - startrt2) %presentation until respond
        [KeyIsDown, endrt2, KeyCode]=KbCheck;
        if KeyCode(afk)==1
            resp=1;
            ACC=strcmp(exptable{randseq(ii2),1},'Fear');
            break
        elseif KeyCode(ank)==1
            resp=2;
            ACC=strcmp(exptable{randseq(ii2),1},'Anger');
            break
        elseif KeyCode(dik)==1
            resp=3;
            ACC=strcmp(exptable{randseq(ii2),1},'Disgust');
            break
        elseif KeyCode(hak)==1
            resp=4;
            ACC=strcmp(exptable{randseq(ii2),1},'Happiness');
            break
        elseif KeyCode(sak)==1
            resp=5;
            ACC=strcmp(exptable{randseq(ii2),1},'Sadness');
            break
        elseif KeyCode(suk)==1
            resp=6;
            ACC=strcmp(exptable{randseq(ii2),1},'Surprise');
            break
        elseif KeyCode(skipk)==1
            resp=NaN;
            ACC=NaN;
            break
        end
    end
    rt=endrt2-startrt2;
    % save subject respond
    datatowrite=[ii2 resp ACC rt cRect1(1) cRect1(2) cRect1(3) cRect1(4) randseq(ii2) exptype];
    dlmwrite(datatxt, datatowrite, '-append','delimiter', '\t', 'precision', 7);
    save([filename,num2str(exptype),'.mat'],'ii2','randseq');
    
    if practicerun==1 && ii2>15
        break
    end
    if ii2==Nexpall/2
        instru_v = ['The next block will start soon...'];
        % Write instruction message for subject, nicely centered in the
        % middle of the display, in white color. As usual, the special
        % character '\n' introduces a line-break:
        Screen('TextSize', mainw, 50);
        DrawFormattedText(mainw, instru_v, 'center', 'center', WhiteIndex(mainw));
        Screen('Flip', mainw);
        
        % Wait for mouse click:
        GetClicks(mainw);
        
        % Clear screen to background color (our 'white' as set at the
        % beginning):
        Screen('Flip', mainw);
        
        % Wait a second before starting trial
        WaitSecs(1.000);
    end
end

Screen('TextSize', mainw, 50);
KbCheck;
WaitSecs(0.1);
endword = ['Please wait...'];
% Write instruction message for subject, nicely centered in the
% middle of the display, in black color. As usual, the special
% character '\n' introduces a line-break:
DrawFormattedText(mainw, endword, 'center', 'center', WhiteIndex(mainw));

% Update the display to show the instruction text:
Screen('Flip', mainw);

% Wait 1 sec
WaitSecs(1);

%%close window
if eyetracking==1
    EyeLink('Stoprecording');
    EyeLink('closefile');
    EyeLink('Shutdown');
end
fclose('all');
Screen('Closeall');
ShowCursor;