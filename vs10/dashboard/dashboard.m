function Y=dashboard(kw, varargin);
% dashboard - experiment control panel
%   dashboard('launch') launches the Dasboard GUI for experiment control,
%   and returns a handle to the GUI. The can only be a single Dashboard
%   figure at a time. If a Dashboard GUI is already open, it receives
%   focus.
%
%   h=dashboard() returns a handle to the current dasboard GUI, or [] if
%   none is open.
%
%   The selection and arrangement of stimulus buttons appearing on the
%   Dashboard can be configired with the function StimButtonTiling.
%
%   See also Experiment, StimButtonTiling.

global datagraze
if isempty(datagraze)
    datagraze.active = 0;
    datagraze.disabled = 0;
end

if nargin<1, kw = 'launch'; end

switch lower(kw),
    case 'launch', % dashboard launch <1>
        try
            window_title = 'EARLY';
            jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
            jDesktop.getMainFrame.setTitle(window_title);
        end
        
        Exp = current(experiment);
        if(~isempty(Exp.name))
           start_datagraze(); 
        end
        
        Y = local_launch(Exp);
        local_GUImode(Y, 'Ready');
        if nargin>1, dashboard('launchstimmenu', 'Left', Y, varargin{1}); end
%         drawnow;
    case 'launchstimmenu', % dashboard 'launchstimmenu' Left/Right <StimType> <figh> (callback of a stimulus button)
        LR = varargin{1}; % left vs right click
        if nargin>2, StimType=varargin{2}; else, StimType=''; end
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        if nargin<4, figh = gcbf; % fig handle is either the callback figure, ...
        else, figh = varargin{3}; % ... or passed explicitly
        end
        try
            blank(getGUIdata(figh,'Messenger')); % empty messages
            stimh = local_stimmenu(figh, StimType);
            if strcmp(StimType,'THR')
               local_disable_play_buttons(figh); 
            else
                local_GUImode(figh, 'Ready');
            end
            %by abel: remove bug, crash when empty handle if user closes
            %dialog
            %<---
            if ishandle(stimh)
                figure(stimh);
            end
            %--->
            refresh(stimh);
        end;

    case 'guimode', % dashboard('guimode', Mode, gmess, gmessmode)
        [ok, figh]=existGUI('dashboard');
        if ~ok, error('No dashboard rendered'); end
        local_GUImode(figh, varargin{:});
    case 'keypress',
        local_keypress(gcbf, varargin{:});
    case {'play', 'playrecord', 'stop'}, % dashboard('Play', 'Left')
        LR = varargin{1};
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        blank(getGUIdata(gcbf,'Messenger')); % empty messages
        local_DA(gcbf, kw);
    case {'newunit', 'newelectrode' 'insertnote','addcomment','opendatabrowse'}, % dashboard('NewUnit', 'Left') etc
        figh = gcbf;
        GUImessage(figh, ' ');
        LR = varargin{1};
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        local_GUImode(figh, 'busy');
        [Mess, MessMode] = feval(['local_' kw], figh);
        if ~strcmp(kw,'opendatabrowse')
            local_GUImode(figh, 'ready', Mess, MessMode);
        end
    case {'newexp' 'finishexp' 'resumeexp' 'editexp'}, % dashboard('NewExp', 'Left') etc
        figh = gcbf;
        GUImessage(figh, ' ');
        LR = varargin{1};
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        local_GUImode(figh, 'busy');
        [Mess, MessMode, doRefresh] = feval(['local_' kw], figh);
        if doRefresh,
            hstim = getGUIdata(figh, 'StimGUIhandle', nan);
            IH = isSingleHandle(hstim);
            xx = {}; if IH, xx = {1}; end
            GUIclosable(figh,1); % overrule nonclosable state. Cannot use local_GUImode because exp is ill defined at this stage
            temp_dg = datagraze; % datagraze settings don't need to be changed by resuming an experiment
            dashboard('close', figh);
            datagraze = temp_dg;
            figh = dashboard('launch', xx{:});
            if datagraze.active == 1 && datagraze.disabled == 0 && (strcmpi(kw,'resumeexp') || strcmpi(kw,'newexp') || strcmpi(kw,'editexp'))
               datagraze.active = 0;
               start_datagraze(); 
            end
            GUImessage(figh, Mess, MessMode);
            refresh(figh);
        else,
            local_GUImode(figh, 'ready', Mess, MessMode);
        end
    case 'probetubecalib',
        figh = gcbf;
        GUImessage(figh, ' ');
        local_GUImode(figh, 'busy');
        hstim = getGUIdata(figh, 'StimGUIhandle', nan);
        if isSingleHandle(hstim), close(hstim); end
        hg = GUI(probetubecalib);
        waitfor(hg);
        local_GUImode(figh, 'ready');
    case 'earcalib',
        figh = gcbf;
        GUImessage(figh, ' ');
        local_GUImode(figh, 'busy');
        hstim = getGUIdata(figh, 'StimGUIhandle', nan);
        if isSingleHandle(hstim), close(hstim); end
        hg = GUI(earcalib);
        waitfor(hg);
        local_GUImode(figh, 'ready');
    case 'viewprobetubecalib'
        plot(load(probetubecalib));
    case 'viewearcalib'
        plot(load(earcalib,current(experiment),nan));
    case 'close',
        if nargin<2, figh=gcbf; else, figh=varargin{1}; end
        if ~GUIclosable(figh), return; end % ignore close request if not closable
        % close stimulus GUI, if any
        hstim = getGUIdata(figh,'StimGUIhandle');
        if isGUI(hstim), GUIclose(hstim); end;
        % save settings of recording panel
        Exp = current(experiment);
        recGUIpanel(Exp, 'savesettings', figh);
        % close
        GUIclose(figh);
        close_datagraze();
        datagraze.disabled = 0;
    case 'no_datagraze'
        % Trick in to thinking datagraze is active although its not
        datagraze.disabled=1;
        try
            window_title = 'EARLY';
            jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
            jDesktop.getMainFrame.setTitle(window_title);
        end
        
        Exp = current(experiment);
        if(~isempty(Exp.name))
           start_datagraze(); 
        end
        
        Y = local_launch(Exp);
        local_GUImode(Y, 'Ready');
        if nargin>1, dashboard('launchstimmenu', 'Left', Y, varargin{1}); end
    case 'backup'
        Exp = current(experiment);
        backup(Exp);
    otherwise,
        error(['Unknown keyword ''' kw '''.']);
end


%=================================================================
%=================================================================
function figh=local_launch(Exp, launchStim);
[EE, figh] = existGUI(mfilename);
if EE, 
    figure(figh); 
    return;
end
% launch dashboard GUI
CLR = 0.75*[1 1 1]+0.1*[0 0.3 0];
P_stim = local_stimPanel(CLR); % stimulus selection
P_rec = recGUIpanel(Exp,  'stimGUIpanel', 'backgroundcolor', CLR); % recording settings
P_ax = local_actionPanel(CLR,figh); % play/record/stop & messages
P_exp = local_Exp(CLR); % panel with experiment info
M_cal = local_Calib(); % calibration pulldown menu


%======GUI itself===========
% open figure and draw GUI in it
figh = newGUI(mfilename, 'Dashboard', {fhandle(mfilename), 'launch'}, 'color', CLR);
DB=GUIpiece('Dashboard',[],[0 0],[10 4]);
DB = add(DB,P_rec);
DB = add(DB,P_exp, nextto(P_rec), [20 3]);
DB = add(DB, P_stim, below(P_rec), [10 3]);
DB = add(DB, P_ax, below(P_stim), [30 0]);
DB = add(DB, M_cal); % calibration pulldown menu
% Temp Fix for GUI non-active until cause is found
P=pulldownmenu('Reset','&Reset');
P=additem(P,'&ResetEarly', @(Src,Ev)Reset_Early(Src,Ev,figh));
DB = add(DB,P);
DB=marginalize(DB,[40 20]);
draw(figh, DB); 
% Store references to the Panels in the UI UserData
Panels(1) = P_stim;
Panels(2) = P_rec;
Panels(3) = P_ax;
Panels(4) = P_exp;
setGUIdata(figh,'Panels',Panels);
% empty all edit fields & message field
GUImessage(figh, ' ','neutral');
% closereq & keypress fun
set(figh,'keypressf',{@(Src,Ev)dashboard('keypress')});
set(figh,'closereq',{@(Src,Ev)dashboard('close')});
% store StimGUI handle in GUIdata (yet empty)
setGUIdata(figh,'StimGUIhandle', []);
% restore previous settings
GUIfill(figh,0);
% set recording settings to previous values of this experiment, if any
recGUIpanel(Exp,'restoresettings', figh);

%======
function Exp = local_Exp(CLR);
% panel for experiment status, new cell announcement, etc.
[btcol] = [0.65 0.75 0.7];
Exp = GUIpanel('Exp', 'Experiment', 'backgroundcolor', CLR);
MessBox = messenger('ExpInfo', 'The problem is what you think it is  ?',5, ... % the '@' in the name indicates that ...
    'fontsize', 10, 'fontweight', 'normal'); % for displaying the experiment status %, 'backgroundcolor', [0 0 0]%
NewUnit = ActionButton('NewUnit', 'Unit!', 'New Unit', 'Click to increase cell count and note depth.', ...
    @(Src,Ev,LR)dashboard('NewUnit', LR), 'BackgroundColor', btcol([1 2 3]));
NewUnit = accelerator(NewUnit,'&Action', 'N');
NewElec = ActionButton('NewElectrode', 'Electrode', 'XXXXXXXX', 'Click after replacing the electrode to increase electrode count.', ...
    @(Src,Ev,LR)dashboard('NewElectrode', LR), 'BackgroundColor', btcol([1 3 2]));
Note = ActionButton('Note', 'Note', 'Note', 'Click to insert a note in the Experiment log file.', ...
    @(Src,Ev,LR)dashboard('InsertNote', LR), 'BackgroundColor', btcol([2 1 3]));
NewExp = ActionButton('NewExp', 'New Exp.', 'XXXXXXX', 'Click to define new experiment. Current experiment will be "closed".', ...
    @(Src,Ev,LR)dashboard('NewExp', LR), 'BackgroundColor', btcol([3 1 2]));
FinishExp = ActionButton('FinishExp', 'Finish Exp.', 'XXXXXXX', 'Click to define finish ("close") experiment.', ...
    @(Src,Ev,LR)dashboard('FinishExp', LR), 'BackgroundColor', btcol([2 3 1]));
ResumeExp = ActionButton('ResumeExp', 'Resume', 'XXXXXXX', 'Click to resume ongoing experiment.', ...
    @(Src,Ev,LR)dashboard('ResumeExp', LR), 'BackgroundColor', btcol([3 2 1]));
EditExp = ActionButton('EditExp', 'Edit', 'XXXXXXX', 'Click to change settings of current experiment.', ...
    @(Src,Ev,LR)dashboard('EditExp', LR), 'BackgroundColor', btcol([1 1 1]));
AddComment = ActionButton('AddComment', 'Comment', 'XXXXXXX', 'Click to add a comment or modify the current comment.', ...
    @(Src,Ev,LR)dashboard('addcomment', LR), 'BackgroundColor', btcol([1 1 1]));
OpenDatabrowse = ActionButton('OpenDatabrowse', 'Databrowse', 'XXXXXXX', 'Click to open databrowse.', ...
    @(Src,Ev,LR)dashboard('opendatabrowse', LR), 'BackgroundColor', btcol([1 1 1]));
Backup = ActionButton('Backup', 'Backup', 'XXXXXXX', 'Click to create a backup of this experiment on the server.', ...
    @(Src,Ev,LR)dashboard('backup', LR), 'BackgroundColor', btcol([1 1 1]));
Exp = add(Exp, MessBox);
Exp = add(Exp, NewUnit, below(MessBox), [0 16]);
Exp = add(Exp, NewElec, nextto(NewUnit), [9 0]);
Exp = add(Exp, Note, nextto(NewElec), [9 0]);
Exp = add(Exp, NewExp, nextto(MessBox), [2 -5]);
Exp = add(Exp, ResumeExp, 'below', [0 2]);
Exp = add(Exp, EditExp, 'below', [0 2]);
Exp = add(Exp, FinishExp, 'below', [0 2]);
Exp = add(Exp,AddComment,nextto(FinishExp), [2 0]);
Exp = add(Exp,OpenDatabrowse,nextto(EditExp), [2 0]);
Exp = add(Exp, Backup,nextto(ResumeExp), [2 0]);
Exp = marginalize(Exp,[3 5]);

%======
function Act = local_calibPanel(CLR);
% calib panel
Calib = GUIpanel('Calib', 'Calibration', 'backgroundcolor', CLR);
MessBox = messenger('CalibMessBox', 'measured RG10189_003.Earcalib   ',1, 'fontsize', 11, 'fontweight', 'normal'); 


%======
function Act = local_actionPanel(CLR,figh);
% Play/PlayRec/Stop panel
Act = GUIpanel('Act', 'action', 'backgroundcolor', CLR);
MessBox = messenger('@MessBox', 'The problem is what you think it is, don''t you? ',5, ... % the '@' in the name indicates that ...
    'fontsize', 12, 'fontweight', 'bold'); % MessBox will be the Main Messenger of he GUI
Play = ActionButton('Play', 'PLAY', 'XXXXXXXX', 'Play stimulus without recording. Endless loop; hit Stop to end.', @(Src,Ev,LR)dashboard('Play', LR));
PlayRec = ActionButton('PlayRec', 'PLAY/REC', 'XXXXXXXX', 'Play stimulus and record response(s).', @(Src,Ev,LR)dashboard('PlayRecord', LR));
Stop = ActionButton('Stop', 'STOP', 'XXXXXXXX', 'Immediately stop ongoing D/A & recording.', @(Src,Ev,LR)dashboard('Stop', LR), ...
    'enable', 'off', 'Interruptible', 'off');
Stutter = ParamQuery('Stutter',  'Stutter:', '', {'Off' 'On'}, 'string',  'Stutter: Repeat first condition twice.', 1e2);

Play = accelerator(Play,'&Action', 'P');
PlayRec = accelerator(PlayRec,'&Action', 'R');
Stop = accelerator(Stop,'&Action', 'W');
Act = add(Act,MessBox);
Act = add(Act,Play, 'below', [0 -3]);
Act = add(Act,PlayRec,'nextto', [10 0]);
Act = add(Act,Stop,'nextto', [10 0]);
Act = add(Act,Stutter,nextto(Stop), [10 0]);
Act = marginalize(Act,[3 5]);

function Reset_Early(Src,Evt,figh)
    local_GUImode(figh, 'All');

%======
function S = local_stimPanel(CLR); 
% panel for specifying stimulus & launching it
S = GUIpanel('Stim', 'stimuli', 'backgroundcolor', CLR);
% ===Stimulus buttons=====BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BP = stimButtonTiling; % not necessesarily the factory settings
LastLeftie = '';
Nrow = numel(BP);
for irow=1:Nrow,
    Row = Words2cell(BP{irow},'/');
    Nb = numel(Row);
    S = add(S,local_StimButton(Row{1}), ['below' LastLeftie],[0 3]);
    LastLeftie = [' ' Row{1}];
    for ii=2:Nb,
        xsep = 5 + 8*(mod(ii,3)==1);
        S = add(S,local_StimButton(Row{ii}), 'nextto',[xsep 0]);
    end
end
S = marginalize(S,[20 5]);

function B = local_StimButton(StimName);
% set the color of the Buttons 
stimNamesGreen = {'BBFC' 'BBFM' 'BBFB' 'ITD' 'ILD' 'MBL' 'NITD' 'NRHO' ...
    'MOVN' 'ARMIN' 'HP' 'NSAM' 'CAP'};
if isempty(find(ismember(stimNamesGreen, StimName)))
    rand('state', varname2int('FS'));
    CLR = rand(1,3); 
    SetRandState();
    % decide whether to use black or white letters
    LumWeight = [1 1 0.4]; % relative contributions of R,G,B to luminance
    Lum = sum(LumWeight.*CLR)/sum(LumWeight);
    Dark = (Lum<0.4);
    if Dark, FC = 'w'; else, FC = 'k'; end
    
else
    rand('state', varname2int('RCM'));
    CLR = rand(1,3); 
    SetRandState();
    % decide whether to use black or white letters
    LumWeight = [1 1 0.4]; % relative contributions of R,G,B to luminance
    Lum = sum(LumWeight.*CLR)/sum(LumWeight);
    Dark = (Lum<0.4);
    if Dark, FC = 'w'; else, FC = 'k'; end
end
B = ActionButton(StimName, StimName, 'XXXXXX', ['launch ' StimName ' stimulus menu.'], ...
    @(Src,Ev,LR)dashboard('launchstimmenu', LR, StimName), ...
    'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', CLR, 'ForegroundColor', FC);

%======
function stimh = local_stimmenu(figh, StimType);

global open_figures

% launch new stim menu
stimh = getGUIdata(figh,'StimGUIhandle');
hasExp = ~isvoid(current(experiment)); % true if experiment is going on
if isSingleHandle(stimh),
    GUIclose(stimh);
    % Close all figures opened by a stimuli (for example THR figure)
    if ~isempty(open_figures)
        for i=1:length(open_figures)
            if ishandle(open_figures(i))
                delete(open_figures(i));
            end
        end
    end
    GUImessage(figh,{'Existing stimulus menu', ...
        'must be closed before a new one',  'can be opened.'},'error');
    return;
end
% elseif ~hasExp,
if ~hasExp
    GUImessage(figh,{'Define or resume an experiment'...
        'before launching a stimulus menu.'},'error');
    return;
% elseif needsEarcalib(current(experiment)),
%     GUI(earcalib);
%     return;
else, % read stimname if not already specified and try to launch corresponding stim menu
    if isempty(StimType), 
        PP = GUIval(figh);
        if isempty(PP), return; end
        StimType = PP.StimName;
    end
    [stimh, Mess] = StimGUI(StimType,current(experiment),figh);
    if ~isempty(Mess), 
        GUImessage(figh, Mess, 'error', 'StimName');
    else, % all okay; store stimGUI handle
        setGUIdata(figh, 'StimGUIhandle', stimh);
        GUIgrab(figh,'>'); % store current settings
        figure(stimh); % window focus on stimulus menu

    end
end

function local_disable_play_buttons(figh)
A = getGUIdata(figh, 'ActionButton');
enable(A('Play'), 0);
enable(A('PlayRec'),0);
enable(A('Stop'), 0);


%======
function local_GUImode(figh, Mode, gmess, gmessmode);
% set enable status of dashboard uicontrols
if nargin<3, gmess = inf; end % indicates absence of message - '' would be bad choice.
if nargin<4, gmessmode = 'neutral'; end
[Mode, Mess] = keywordMatch(Mode,{'Busy' 'Ready' 'Play' 'PlayRecord' 'Replay' 'Stop' 'All'}, 'Mode argument');
error(Mess);
A = getGUIdata(figh, 'ActionButton');
A_ExpStat = A('NewUnit', 'NewElectrode', 'Note', 'FinishExp', 'EditExp'); % buttons changing  the Experiment status
Q = getGUIdata(figh, 'Query', ParamQuery()); if numel(Q) == 1 && isvoid(Q), Q = Q([]); end
Exp = current(experiment);
[dum RecSrc] = recordingsources(Exp);
Qmeasure = Q(RecSrc{:}); % queries having to do w recordings
hasExp = ~isvoid(Exp); % true if experiment is going on
if isvoid(Exp), ExpStr = ' (no experiment)'; else, ExpStr = [' -- Experiment ' name(Exp) ' by ' experimenter(Exp)]; end
set(figh, 'name', ['Dashboard' ExpStr]);

hasStim = isSingleHandle(getGUIdata(figh, 'StimGUIhandle'));
switch Mode,
    case {'Busy', 'Stop'}, % disable all buttons & prevent closing the figure
        enable(A,0); enable(Q,0);
        GUIclosable(figh,0); % not okay to close GUI
        % color Check or Stop buttons
        if isequal('Stop', Mode),
            highlight(A('Stop'),[0.5 0.15 0]);
        end
    case 'Ready', % enable all buttons except Stop; okay to close GUI; recording queries depend on experiment status
        enable(A,1);  enable(Q,1); enable(Qmeasure, hasExp);
        %enable(A('StimSpec'), hasExp);
        enable(A('Stop'),0);
        % only enable Play if D/A is possible; only enable PlayRec when an experiment is ongoing
        enable(A('Play'), CanPlayStim && hasStim);
        enable(A('PlayRec'), CanPlayStim && hasStim && canrecord(Exp));
        enable(A_ExpStat, hasExp); % Exp status may only be changed when an Exp has been defined
        enable(A('NewExp', 'ResumeExp'), ~hasExp);
        highlight(A,'default');
        GUIclosable(figh,1); % okay to close GUI
    case {'Play' 'PlayRecord' 'Replay'}, % disable all buttons except Stop
        enable(A,0); enable(Q,0);
        enable(A('Stop'),1);
        GUIclosable(figh,0); % not okay to close GUI
        % color Play or PlayRec buttons
        if isequal('Play', Mode) || isequal('Replay', Mode),
            highlight(A('Play'),[0 0.7 0]);
        elseif isequal('PlayRecord', Mode),
            highlight(A('PlayRec'),[0.85 0 0]);
        end
    case 'All'
        enable(A,1); enable(Q,1);
end
% display GUI message, if any.
if ~isempty(gmess) && ~isequal(inf, gmess),
    GUImessage(figh,gmess,gmessmode);
end
% update the Experiment status info
EM = GUImessenger(figh, 'ExpInfo');
EXP = current(experiment);
reportstatus(EXP, EM);
figure(figh);
% drawnow;

%======
function local_DA(figh, kw);
% D/A -related action: Play, PlayRecord or Stop.
% = check stimulus params
hstim = getGUIdata(figh, 'StimGUIhandle');
if ~isSingleHandle(hstim),
    GUImessage(figh, {'No stimulus specified.' 'Use StimSpec button to open stimulus GUI.'}, 'error');
    return;
end
switch kw,
    case {'Play' 'PlayRecord'}, % prepare D/A
        okay = StimCheck(hstim,figh,kw);
        if ~okay, figure(hstim); return; end
        local_GUImode(figh, 'Busy'); % will be changed to Play or Record inside PlayRecordStop call
        Exp = current(experiment);
        CheckFullDS = preferences(Exp);
        CheckFullDS = CheckFullDS.CheckFullDsInfo;
        if isequal(kw,'PlayRecord') && strcmpi(CheckFullDS,'no'), Exp = promptID(Exp, hstim); end;
        % Check if recording is cancelled
        if isempty(Exp)
            local_GUImode(figh, 'Ready');
           return; 
        end
        % = get recording settings from dashboard
        RecParam = GUIval(figh);
        StimParam = getGUIdata(hstim, 'StimParam');
        [RecordInstr, CircuitInstr] = recordingInstructions(Exp, StimParam, RecParam);
        if isempty(RecordInstr) && isequal('PlayRecord', kw),
            GUImessage(figh, {'No recording channels activated.' 'Cannot record nothing.'}, 'error');
            local_GUImode(figh, 'Ready'); 
            return;
        end
        LoadCircuits(CircuitInstr);
        GUImessage(figh, 'Preparing D/A');
        Rec = CollectInStruct(RecordInstr, '-', CircuitInstr, '-', RecParam); % all recording info available
        PlayRecordStop(kw, figh, hstim, Exp, Rec);
    case 'Stop',
        PlayRecordStop(kw, figh);
end % switch/case

%======
function [Mess, MessMode] = local_NewUnit(figh);
% increase cell count; prompt for pen depth
EXP = current(experiment);
St = status(EXP);
prompt={'Cell number:','Pen Depth (\mum):'};
name='Info on new unit';
numlines=1;
defaultanswer={num2str(St.iCell+1), num2str(St.PenDepth)};
Opt = struct('WindowStyle', 'modal', 'Interpreter', 'Tex');
answer=inputdlg(prompt,name,numlines,defaultanswer, Opt);
if isempty(answer)
    Mess='Unit Specification cancelled.';
    MessMode = 'error';
    return;
end % user cancelled
iCell = abs(round(str2num(answer{1}))); 
if ~issinglerealnumber(iCell,'posinteger'),
    Mess = 'Invalid cell number.'; 
    MessMode = 'error';
    return;
end
% the cell index may have been used before; find previous recordings from this cell
iprev = find([St.AllSaved.iCell]==iCell); % indices of prev rec
if isempty(iprev), iOfRecCell=0;
else, iOfRecCell = max(St.AllSaved(iprev).iRecOfCell);
end
PenDepth = str2num(answer{2});
if isempty(PenDepth) || numel(PenDepth)>1, 
    Mess = 'Invalid Pen. Depth.'; 
    MessMode = 'error';
    return;
end;
status(EXP, 'iCell', iCell, 'iRecOfCell', iOfRecCell, 'PenDepth', PenDepth);
LogStr = {['-----------Unit ' num2str(iCell) ' (' num2str(PenDepth) ' um)---------']};
addtolog(EXP, LogStr);
Mess = 'Unit & PenDepth updated.';
MessMode = 'neutral';

function [Mess, MessMode] = local_NewElectrode(figh);
% increase electrode count; reset pen depth
EXP = current(experiment);
St = status(EXP);
prompt={'electrode number:'};
name='Electrode count';
numlines=1;
defaultanswer={num2str(St.iPen+1)};
Opt = struct('WindowStyle', 'modal', 'Interpreter', 'Tex');
answer=inputdlg(prompt,name,numlines,defaultanswer, Opt);
Mess = {}; MessMode = 'neutral';
if isempty(answer), Mess=' '; return; end % user cancelled
iPen = abs(round(str2num(answer{1}))); 
if isempty(iPen) || isequal(0, iPen) || numel(iPen)>1, 
    Mess{end+1} = 'Invalid electrode number.'; 
else,
    status(EXP, 'iPen', iPen, 'PenDepth', nan);
    addtolog(EXP, ['==========Electrode # ' num2str(iPen) '==========']);
end
if isempty(Mess),
    Mess = 'Electrode count updated.'; 
    MessMode = 'neutral';
else,
    MessMode = 'error';
end

function [Mess, MessMode] = local_InsertNote(figh);
% insert a note in Exp log file
EXP = current(experiment);
okay = insertnote(EXP);
if okay, 
    [Mess, MessMode] = deal('Note inserted', 'neutral');
else,
    [Mess, MessMode] = deal(' ', 'neutral');
end

function [Mess, MessMode, doRefresh] = local_NewExp(figh);
% launch experiment GUI
[Mess, MessMode, doRefresh] = deal(' ', 'neutral', false);
[newEXP, wasEdited] = edit(experiment); % GUI for a new experiment
if ~wasEdited,
    Mess = 'Experiment definition cancelled.';
else,    
    Mess = ['New experiment defined: ''' name(newEXP) '''.'];
    doRefresh = true; % need to refresh dashboard GUI
    start_datagraze();
end

function [Mess, MessMode, doRefresh] = local_FinishExp(figh); 
% close exp 
doRefresh = false;
EXP = current(experiment);
if isvoid(EXP),
    Mess = 'Cannot finish non-existing experiment.';
    MessMode = 'warning';
else,
    finish(EXP);
    Mess = ['Finished experiment ''' name(EXP) '''.'];
    MessMode = 'neutral';
    close_datagraze();
end

function [Mess, MessMode, doRefresh] = local_ResumeExp(figh); 
% resume exp
doRefresh = false;
prompt = sprintf(['Enter the name of the Experiment you want to resume:\n' ...
    '(leave empty to resume lase experiment)']);

dlg_title = 'Resume Experiment';
num_lines = 1;
defaultans = {''};
exp_name = inputdlg(prompt,dlg_title,num_lines,defaultans);
exp_name = exp_name{1};
EXP = current(experiment);
if ~isvoid(EXP),
    Mess = [{'Resuming an experiment requires ' 'finishing the current one.'}];
    MessMode = 'warning';
    return;
end
EXP = experiment();
while (isvoid(EXP))
    if (strcmp(exp_name,''))
        EXP = current(experiment);
        if ~exist(experiment, lastcurrentname(experiment)),
            Mess = {'Nothing to resume.'};
            MessMode = 'warning';
            return;
        end
        EXP = find(experiment, lastcurrentname(experiment));
    else
        EXP = find(experiment(), exp_name);
        makecurrent(EXP);
    end
end    



resume(EXP);
Mess = ['Resumed experiment ''' name(EXP) '''.'];
MessMode = 'neutral';
doRefresh = true;
start_datagraze();

function [Mess, MessMode, doRefresh] = local_EditExp(figh);
% edit exp 
doRefresh = false;
EXP = current(experiment);
MessMode = 'neutral';
if isvoid(EXP),
    Mess = ['Cannot edit a non-existing experiment.'];
    MessMode = 'warning';
    return;
end
GUImessage(figh, 'editing experiment ...')
[EXP, wasEdited] = edit(EXP);
if ~wasEdited,
    Mess = 'Editing Experiment cancelled.';
    return;
end
Mess = ['Edited experiment ''' name(EXP) '''.'];
doRefresh = true;

function local_keypress(figh, varargin);
c = get(figh, 'CurrentCharacter');
switch c,
    case 'c',
        commandwindow;
end

function P = local_Calib();
P=pulldownmenu('Calib','&Calibration');
P=additem(P,'&Ear (in Situ)', @(Src,Ev)dashboard('earcalib'));
P=additem(P,'&Probe-Tube (system)', @(Src,Ev)dashboard('probetubecalib'));
P=additem(P,'View probe-tube calib', @(Src,Ev)dashboard('viewprobetubecalib'));
P=additem(P,'View previous ear calib', @(Src,Ev)dashboard('viewearcalib'));

function [Mess, MessMode] = local_opendatabrowse(figh)
curr_exp = current(experiment());
if isempty(curr_exp) || isvoid(curr_exp)
    Mess = 'No current expirement is currently opened in the dashboard';
    MessMode = 'error';
    local_GUImode(figh, 'ready', Mess, MessMode);
else
    local_GUImode(figh, 'Busy');
    databrowse(curr_exp,{@databrowse_close,figh,'Ready',[],[]});
    Mess = 'Daabrowse opened!';
    MessMode = 'neutral';
end

function [Mess, MessMode] = local_addcomment(figh)
Mess = 'Comment added!';
MessMode = 'neutral';
if isempty(figh)
   error('dashboard.m :: local_add_comment() :: input argument is empty'); 
end

ds = getGUIdata(figh,'dataset',[]);

if isempty(ds)
    Mess = 'There is no previous dataset recorder. No message can be added!';
    MessMord = 'error';
    return;
end

ds = download(ds);

if isfield(ds.ID,'comment')
    prev_comment = ds.ID.comment;
else
    prev_comment = '';
end
new_comment = inputdlg('Enter the comment:','Edit comment', 10, {prev_comment});

% The cancel button is pressed
if isempty(new_comment)
    Mess = 'No comment added!';
    MessMode = 'warning';
    setGUIdata(figh, 'dataset',ds);
else
    % save the new comment
    new_comment = new_comment{1};
    ds = add_comment(ds, new_comment);
    setGUIdata(figh,'dataset',ds);
    upload(ds);
    save(ds,'addcomment');
end


