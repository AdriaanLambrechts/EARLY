function [E, wasEdited] = edit(E, kw, varargin);
% experiment/edit - edit experiment settings using a GUI
%   E = edit(E) launches a GUI filled with the settings of an
%   existing experiment E. The user is allowed to change the settings of
%   E except the names of the experiment and the experimenter. The
%   resulting, edited version of E is returned. This call has no effect on
%   the setting of the "current experiment".
%
%   A void experiment is returned if the user cancels the editing  by
%   hitting the Cancel button of the GUI.
%
%   Experiment/edit is also the callback function of the GUI.
%
%    See also Datadir, experiment/filename, experiment/save.

if nargin<2, kw='launch'; end % launch GUI


GUIname = 'experimentGUI';
switch lower(kw),
    case 'launch', % earcalibration launch DAchan
        figh = local_launch(E);
        local_GUImode(figh, 'Ready');
        GUIreaper(figh, 'wait'); % wait for a trigger to reap
        E = getGUIdata(figh, 'EditedExp', E); % return value save in GUI by local_OK (if any - use input E as default)
        wasEdited = getGUIdata(figh, 'wasEdited', false);
        GUIclose(figh); 
    case 'guimode', % edit(dum, 'guimode', Mode, gmess, gmessmode)
        [ok, figh]=existGUI(GUIname);
        if ~ok, error(['No ' mfilename ' GUI rendered']); end
        local_GUImode(figh, varargin{:});
    case 'keypress',
    case {'probenamebutton'}, % edit(dum, probenamebutton, LR, chan)
        LR = varargin{1};
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        local_PNbutton(gcbf, varargin{2});
    case {'ok'}, % edit(dum, 'OK', 'L')
        LR = varargin{1};
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        figh = gcbf;
        blank(getGUIdata(figh,'Messenger')); % empty messages
        if local_OK(figh), 
            setGUIdata(figh, 'wasEdited', true);
            GUIreaper(figh,'reap'); % trigger closing the figure
        end
    case {'cancel'}, % edit(dum, 'Cancel', 'L')
        LR = varargin{1};
        if ~isequal('Left', LR), return; end; % ignore right-clicks
        figh = gcbf;
        GUIreaper(figh,'reap'); % trigger closing the figure. No GUIdata ...
        % ... were set, so the launch call above knows that nothing was edited.
    case {'file'}, % edit(dum, 'file', 'save', Src)
        local_file(gcbf, varargin{:});
    case {'viewfile'}, % edit(dum, 'viewfile', ...)
        local_viewfile;
    case {'help'}, % edit(dum, 'Help', ...)
        local_help(varargin{:});
    case 'close',
        if nargin<3, figh=gcbf; else, figh=varargin{1}; end
        if ~GUIclosable(figh), return; end % ignore close request if not closable
        GUIreaper(figh, 'reap'); % triggers deletion @ hlated launch
    otherwise,
        error(['Unknown keyword ''' kw '''.']);
end


%=================================================================
%=================================================================
function figh=local_launch(E);
% launch GUI
GUIname = 'experimentEditGUI';
dum = experiment; % used for callbacks to Experiment/edit
CLR = 0.75*[1 1 1]+0.1*[0 1 0];
% for each field of E, call a local panel maker
P_ID = local_IDPanel(CLR,E); % name etc. Not editable.
P_Audio = local_AudioPanel(CLR,E); % Audio stim.
P_Elec = local_Electra(CLR); % electrical stim
P_Rec = local_Rec(CLR);
P_Act = local_actionPanel(CLR);
P_Pref = local_prefPanel(CLR);
% View = PulldownMenu('View', '&View');
% View = additem(View,'View Probe tube data from file', @(Src,Ev)edit(dum, 'viewfile'));
% Hlp = PulldownMenu('Help', '&Help');
% Hlp = additem(Hlp,'How to calibrate a probe tube', @(Src,Ev)edit(dum, 'help', 'HowTo'));
Pfile = local_FileMenu; % File pulldown menu
%======GUI itself===========
PT=GUIpiece(GUIname,[],[0 0],[10 4]);
PT = add(PT, Pfile);
PT = add(PT, P_ID);
PT = add(PT, P_Pref, nextto(P_ID), [50 0]);
PT = add(PT, P_Audio, below(P_ID),[0 10]);
PT = add(PT, P_Elec, below(P_Audio),[0 0]);
PT = add(PT, P_Rec, nextto(P_Audio),[10 0]);
PT = add(PT, P_Act, nextto(P_Elec),[10 5]);
PT = marginalize(PT,[20 20]);
% PT = add(PT, View);
% PT = add(PT, Hlp);
% open figure and draw GUI in it
figh = newGUI(GUIname, ['Editing ' name(E)], ...
    {fhandle(mfilename), 'launch', E}, 'color', CLR);
draw(figh, PT);
% empty all edit fields & message field
GUImessage(figh, ' ','neutral');
% closereq & keypress fun
set(figh,'keypressf',{@(Src,Ev)edit(dum, 'keypress')});
set(figh,'closereq',{@(Src,Ev)edit(dum, 'close')});
% store experiment 
setGUIdata(figh,'InitExp', E);
% restore most recent, approved GUI settings
GUIfill(figh,0);
if isvoid(E), 
    % newcomer: initialize
    IDstartedEdit = '-now-';
    IDcomputerEdit = CompuName;
    IDlocationEdit = Where;
    GUIfill(figh, CollectInStruct(GUIname, IDstartedEdit, IDcomputerEdit, IDlocationEdit));
else, % exp has been defined before; fill GUI edits with its current values
    local_exp2struct(figh, E);
    GUIfill(figh, local_exp2struct(figh, E));
end

%======
function Pfile = local_FileMenu;
% File pulldown menu
dum = experiment(); % dummy experiment for recursive edit calls
Pfile=pulldownmenu('File','&File');
Pfile=additem(Pfile,'&Save parameters', @(Src,Ev)edit(dum, 'File', 'Save', Src), 'accelerator', 'S');
Pfile=additem(Pfile,'&Open parameter file', @(Src,Ev)edit(dum, 'File', 'Open', Src), 'accelerator', 'O');
Pfile=additem(Pfile,'&Empty File List', @(Src,Ev)edit(dum, 'File', 'Emptylist',Src));
CL=cycleList('readagain', 10, @(Src, Event, L_Callback, L, Item)edit(dum,'File', 'Readagain',L_Callback, L, Item)); % clicking an item calls this fcn with 4 input args; see CycleList
Pfile=additem(Pfile,CL);

function S = local_IDPanel(CLR,E);
% panel for specifying stimulus params
if isvoid(E), AllErs = allexperimenters(experiment); else, AllErs = {experimenter(E)}; end
S = GUIpanel('ID', 'Experiment', 'backgroundcolor', CLR);
Name    = ParamQuery('IDName',  'Name:', 'RG10888  ', '', 'varname',  'Name of experiment, e.g., RG10888. Name must be valid Matlab identifier (see ISVARNAME).', 1e2);
Er      = ParamQuery('IDExperimenter',  'Experimenter:', '', 'Exp', 'varname',  'Experimenter. Introduce newcomers by creating subfolders of Parentfolder(Experiment()).', 1e2);
Type    = ParamQuery('IDType',  'Type:', 'ZWOAE/CM      ', '', 'string',  'Brief description of experiment type, e,g, ZWOAE/CM', 1e2);
Started = ParamQuery('IDstarted',  'Started', '17-Jan-2010 20:31:05 ', '', 'string',  '', 1e2);
Cmp     = ParamQuery('IDcomputer',  'Computer:', 'XXXXXXXX ', '', 'string',  '', 1e2);
Loc     = ParamQuery('IDlocation',  '@', 'Rotterdam   ', '', 'string',  '', 1e2);
S = add(S, Name);
S = add(S, Er, nextto(Name),[10 0]);
S = add(S, Type, nextto(Er),[10 0]);
S = add(S, Started, below(Name));
S = add(S, Cmp, nextto(Started));
S = add(S, Loc, nextto(Cmp));
S = marginalize(S,[3 5]);

function S = local_AudioPanel(CLR,E); % Audio properties.
% panel for specifying audio params
dum = experiment();
S = GUIpanel('Audio', 'Sound stimulation', 'backgroundcolor', CLR);
Device = ParamQuery('AudioDevice',  'Device:', '', {'RX6'}, 'string',  'Hardware device used for audio stimulation.  Unused value.', 1e2);
MaxAbsDA = ParamQuery('AudioMaxAbsDA',  'DA max:', '10 ', '', 'nonnegative/rreal',  'Maximum absolute value sent to D/A converter.', 1);
DAchan = ParamQuery('AudioDAchan',  'Chan:', '', {'Left' 'Right' 'Both'}, 'string',  'D/A channels used for sound stimulation.', 1e2);
DAbuf = ParamQuery('AudioBuffer',  'Buffer:', '', {'HB7' 'SA1' }, 'string',  'Headphone buffer or audio amplifier.  Unused value.', 1e2);
Spk = ParamQuery('AudioSpeakers',  'Speakers:', '', {'Supertweeter' 'ER-1' 'MF-1' 'Horntweeter' 'Shure' 'Visaton' 'CF1' 'ER-2' 'TDH39' 'HD520'},...
    'string',  'Loudspeakers or drivers.  Unused value.', 1e2);
Probe_1 = ParamQuery('AudioProbe_1',  'Probe 1:', 'XXXXXXXXXXXXXXXXXXXXXXXXX', '', 'string',  'Name of channel-1 probe or the SPL at 1 Volt RMS in case of the "Flat" calibration method.', 1e2, 'fontsize', 10);
ProbeButton_1 = ActionButton('AudioProbeButton_1',  'Browse...', 'xxxxxxxx', 'Click to browse for a probe tube file.', @(Src,Ev,LR)edit(dum, 'ProbeNameButton', LR, 1),'fontsize',8, 'backgroundcolor', CLR);
Probe_2 = ParamQuery('AudioProbe_2',  'Probe 2:', 'XXXXXXXXXXXXXXXXXXXXXXXXX', '', 'string',  'Name of channel-2 probe or the SPL at 1 Volt RMS in case of the "Flat" calibration method.', 1e2, 'fontsize', 10);
ProbeButton_2 = ActionButton('AudioProbeButton_2',  'Browse...', 'xxxxxxxx', 'Click to browse for a probe tube file.', @(Src,Ev,LR)edit(dum, 'ProbeNameButton', LR, 2),'fontsize',8, 'backgroundcolor', CLR);
Atten = ParamQuery('AudioAtten',  'Attenuators:', '', {'PA5' '-' }, 'string',  'Analog attenuators.  Unused value.', 1e2);
NumAtten = ParamQuery('AudioPrefNumAtten',  'Num. Atten:', '10  ', 'dB', 'nonnegative/rreal',  'Preferred minimum numerical attenuation (serves to limit D/A output Voltages.).', 1);
MinFsam = ParamQuery('AudioMinFsam',  'Min. Fsam:', '100X', 'kHz', 'nonnegative/rreal',  'Minimum sample rate for sound stimulation.', 1);
MinFstim = ParamQuery('AudioMinFstim',  'Low Freq:', '50 ', 'Hz', 'nonnegative/rreal',  'Lowest stimulus frequency allowed. Only used by SUP stimulus.', 1);
MaxFstim = ParamQuery('AudioMaxFstim',  'High Freq:', '45000 ', 'Hz', 'nonnegative/rreal',  'Highest stimulus frequency allowed. Only used by SUP stimulus.', 1);
CalibType = ParamQuery('AudioCalibType',  'Calib:', '', {'In situ' 'Probe' 'Flat'}, 'string',  'Calibration method. In situ=measure with probe in place. Probe=use probe -> cavity transfer. Flat=fixed SPL @ 1 V.', 1e2);
S = add(S, Device,'nextto',[0 0]); 
S = add(S, MaxAbsDA, nextto(Device), [5 0]);
S = add(S, DAchan, nextto(MaxAbsDA), [5 0]);
S = add(S, DAbuf, below(Device), [0 -5]);
S = add(S, Spk, nextto(DAbuf), [10 0]);
S = add(S, Probe_1, below(DAbuf),[0 -3]);
S = add(S, ProbeButton_1, nextto(Probe_1), [-9 4]);
S = add(S, Probe_2, below(Probe_1),[0 -5]);
S = add(S, ProbeButton_2, nextto(Probe_2), [-9 4]);
S = add(S, Atten, below(Probe_2), [0 -3]);
S = add(S, NumAtten, nextto(Atten),[15 0]);
S = add(S, MinFsam, below(Atten), [0 -5]);
S = add(S, CalibType, nextto(MinFsam), [15 0]);
S = add(S, MinFstim, below(MinFsam), [0 -5]);
S = add(S, MaxFstim, nextto(MinFstim), [10 0]);
S = marginalize(S,[3 5]);

function Act = local_Electra(CLR);
Act = GUIpanel('Elec', 'Electrical stimulation', 'backgroundcolor', CLR);
Device = ParamQuery('ElecDevice',  'Device:', '', {'RP2'}, 'string',  'Hardware device used for electrical stimulation. Unused value.', 1e2);
DA1 = ParamQuery('ElecDA_1',  'DA 1:', '', {'Axoclamp 1' '-'}, 'string',  'Target of electrical stimulation by D/A channel 1', 1e2);
DA2 = ParamQuery('ElecDA_2',  'DA 2:', '', {'Axoclamp 2' '-'}, 'string',  'Target of electrical stimulation by D/A channel 2', 1e2);
MaxAbsDA = ParamQuery('ElecMaxAbsDA',  'DA max:', '10 ', '', 'nonnegative/rreal',  'Maximum absolute value sent to D/A converter. Pairs mean [ch1 ch2]', 2);
MinFsam = ParamQuery('ElecMinFsam',  'Min. Fsam:', '100X', 'kHz', 'nonnegative/rreal',  'Minimum sample rate for electrical stimulation.', 1);
%==
Act = add(Act,Device);
Act = add(Act,DA1, below(Device), [0 -4]);
Act = add(Act,DA2, nextto(DA1), [20 0]);
Act = add(Act,MaxAbsDA, below(DA1), [0 -4]);
Act = add(Act,MinFsam,nextto(MaxAbsDA), [0 0]);
Act = marginalize(Act,[3 5]);

function Rec = local_Rec(CLR);
Rec = GUIpanel('Rec', 'Recording', 'backgroundcolor', CLR);
MinFsam = ParamQuery('RecMinFsam',  'Min. Fsam:', '100X', 'kHz', 'nonnegative/rreal',  'Minimum sample rate for analog recordings.', 1);
RecSide = ParamQuery('RecSide',  'Rec Side:', '', {'Left' 'Right'}, 'string',  'Recording side.', 1e2);
%=
Device  = ParamQuery('RecDevice',  'Device:', '', {'RX6'}, 'string',  'Hardware device used for recording.  Unused value.', 1e2);
%=
Chan = 'RX6_digital_1';
Ev      = ParamQuery(['Rec_' Chan '_DataType'],  'Events:', '', ['-' allKnownDataTypes(datagrabber, Chan)], 'string',  'Type of events to be time stamped by D0 ("A1") digital input of the RX6.', 1e2);
Dscr    = ParamQuery(['Rec_' Chan '_Discriminator'],  'Discriminator:', '', {'BAK' 'Peak Picker' '-'}, 'string',  'Device used for event detection. Unused', 1e2);
%=
allUnits = {'X' 'dB' 'V/Pa' 'V/nA' 'um/V' 'nm/V' 'mm/s/V'};
Chan = 'RX6_analog_1';
AD1     = ParamQuery(['Rec_' Chan '_DataType'],  'AD 1:', '', ['-' allKnownDataTypes(datagrabber, Chan)], 'string',  'Type of recording (what is connected to the analog IN-1 of the RX6)', 1e2);
Amp1    = ParamQuery(['Rec_' Chan '_Amp'],  'Amplifier:', '', {'-' 'Axoclamp 2B' 'Dagan BVC-700A' 'NPI ELC-03XS' 'Nexus ch1' 'Axoclamp-1' 'Parc' 'SRS'}, 'string',  'Conditioning amplifier.', 1e2);
Gain1   = ParamQuery(['Rec_' Chan '_Gain'],'Gain/Sens:', '10000  ', allUnits, 'nonnegative/rreal',  'Gain or sensitivity setting of amplifier.', 1e2);
LoFreq1 = ParamQuery(['Rec_' Chan '_LowFreq'],'Low cutoff:', '3333 ', 'Hz', 'nonnegative/rreal',  'Low filter cutoff of amplifier. Unused value.', 1e2);
HiFreq1 = ParamQuery(['Rec_' Chan '_HighFreq'],'High cutoff:', '333333 ', {'Hz' 'kHz'}, 'nonnegative/rreal',  'High filter cutoff of amplifier. Unused value.', 1e2);
%=
Chan = 'RX6_analog_2';
AD2     = ParamQuery(['Rec_' Chan '_DataType'],  'AD 2:', '', ['-' allKnownDataTypes(datagrabber, Chan)], 'string',  'Type of recording (what is connected to the analog IN-1 of the RX6)', 1e2);
Amp2    = ParamQuery(['Rec_' Chan '_Amp'],  'Amplifier:', '', {'-' 'Axoclamp 2B' 'Dagan BVC-700A' 'NPI ELC-03XS' 'Nexus ch1' 'Axoclamp-1' 'Parc' 'SRS'}, 'string',  'Conditioning amplifier.', 1e2);
Gain2   = ParamQuery(['Rec_' Chan '_Gain'],'Gain/Sens:', '10000  ', allUnits, 'rreal',  'Gain or sensitivity setting of amplifier.', 1e2);
LoFreq2 = ParamQuery(['Rec_' Chan '_LowFreq'],'Low cutoff:', '3333 ', 'Hz', 'nonnegative/rreal',  'Low filter cutoff of amplifier. Unused value.', 1e2);
HiFreq2 = ParamQuery(['Rec_' Chan '_HighFreq'],'High cutoff:', '333333 ', {'Hz' 'kHz'}, 'nonnegative/rreal',  'High filter cutoff of amplifier. Unused value.', 1e2);
%=
Chan = 'PC_COM1';
COM1 = ParamQuery(['Rec_' Chan '_DataType'],  'COM1:', '', ['-' allKnownDataTypes(datagrabber, Chan)], 'string',  'Type of recording (what is connect to the COM1 port.)', 1e2);
%==
Rec = add(Rec,Device);
Rec = add(Rec,MinFsam,nextto(Device), [10 0]);
Rec = add(Rec,RecSide, nextto(MinFsam), [10 0]);
Rec = add(Rec,Ev, below(Device), [0 -4]);
Rec = add(Rec,Dscr, nextto(Ev), [15 0]);
Rec = add(Rec,AD1, below(Ev), [0 5]);
Rec = add(Rec,Amp1, nextto(AD1), [5 0]);
Rec = add(Rec,Gain1, nextto(Amp1),[10 0]);
Rec = add(Rec,LoFreq1, below(AD1),[30 -6]);
Rec = add(Rec,HiFreq1, nextto(LoFreq1),[10 0]);
Rec = add(Rec,AD2, below(LoFreq1), [-30 5]);
Rec = add(Rec,Amp2, nextto(AD2), [5 0]);
Rec = add(Rec,Gain2, nextto(Amp2),[10 0]);
Rec = add(Rec,LoFreq2, below(AD2),[30 -6]);
Rec = add(Rec,HiFreq2, nextto(LoFreq2),[10 0]);
Rec = add(Rec,COM1, below(LoFreq2), [-30 -5]);
Rec = marginalize(Rec,[3 5]);

function Act = local_actionPanel(CLR);
dum = experiment(); % dummy experiment for recursive edit calls
Act = GUIpanel('Act', '', 'backgroundcolor', CLR);
MessBox = messenger('@MessBox', 'The problem is what you think it is or not ...',5, ... % the '@' in the name indicates that ...
    'fontsize', 12, 'fontweight', 'bold'); % MessBox will be the Main Messenger of he GUI
OK     = ActionButton('OK', 'OK',         'XXXXXXX', 'Save these settings and close GUI.', @(Src,Ev,LR)edit(dum, 'OK', LR, 1),'fontweight','bold');
Cancel = ActionButton('Cancel', 'CANCEL', 'XXXXXXX', 'Close GUI without saving the settings.', @(Src,Ev,LR)edit(dum, 'Cancel', LR, 1),'fontweight','bold');
Act = add(Act, MessBox);
Act = add(Act, OK, nextto(MessBox), [5 75]);
Act = add(Act, Cancel, nextto(OK), [20 0]);
Act = marginalize(Act,[3 5]);

function Prf = local_prefPanel(CLR)
Prf = GUIpanel('Pref', 'Preferences', 'backgroundcolor', CLR);
maxNcond = ParamQuery('PrefMaxNcond',  'max. # conditions:', 'XXXXXX', '', 'posint',  'Max number of conditions (reps not counted) in a single recording.', 1e2);
ITDc = ParamQuery('PrefITDconvention',  'ITD convention:', '', {'IpsiLeading' 'ContraLeading' 'LeftLeading' 'RightLeading'}, ...
    'string',  'Specify what it means for ITDs to be *positive*.', 1e2);
CW = ParamQuery('PrefCmplxWv',  'Store complex signals:', '', {'No' 'Yes'}, 'string',  'Optional internal storage of complex analytic stimulus waveforms.', 1e2);
checkID = ParamQuery('PrefCheckID',  'Prompt for dataset ID:', '', {'No' 'Yes'}, 'string',  'Optional confirmation of dataset ID before saving.', 1e2);
CheckAllDsInfo = ParamQuery('PrefCheckDsInfo',  'Prompt for full dataset Info:', '', {'No' 'Yes'}, 'string',  'Optional prompt for dataset settings(SeqID, Pen Depth, Electrode) before saving.', 1e2);
%==
Prf = add(Prf,maxNcond);
Prf = add(Prf,CW, 'below', [0 -7]);
Prf = add(Prf,ITDc, 'nextto PrefMaxNcond');
Prf = add(Prf,checkID, 'nextto PrefCmplxWv');
Prf = add(Prf,CheckAllDsInfo, below(CW));
Prf = marginalize(Prf,[3 5]);

function S = local_exp2struct(figh, E);
% convert E to struct that can be used to GUIfill the GUI
S.GUIname = getGUIdata(figh,'GUIname');
if isvoid(E), return; end;
% S.EnableStates_ = voidstruct( 'IDName', 'IDType', 'IDstarted', 'IDcomputer', 'IDlocation', ...
%     'AudioMaxAbsDA', 'AudioProbe_1', 'AudioProbe_2', 'AudioPrefMinAtten', 'AudioMinFsam', 'AudioMinFstim', 'AudioMaxFstim', ...
%     'ElecMaxAbsDA', 'ElecMinFsam', ...
%     'RecMinFsam', 'RecGain_1', 'RecLowFreq_1', 'RecHighFreq_1', 'RecGain_2', 'RecLowFreq_2', 'RecHighFreq_2');
%------ID-------
[S.IDNameEdit, S.IDExperimenterUnit, S.IDTypeEdit] = deal(name(E), experimenter(E), type(E));
[S.IDstartedEdit, S.IDcomputerEdit, S.IDlocationEdit] = deal(E.ID.Started, E.ID.Computer, E.ID.Location);
%------Audio----
if ~isempty(E.Audio.Device),
    Au = E.Audio;
    [S.AudioDeviceUnit, S.AudioMaxAbsDAEdit, S.AudioDAchanUnit] = deal(Au.Device, Au.MaxAbsDA, Au.DAchannelsUsed);
    [S.AudioBufferUnit, S.AudioSpeakersUnit] = deal(Au.HeadphoneBuffer, Au.Speakers);
    [S.AudioProbe_1Edit, S.AudioProbe_2Edit] = deal(Au.Probes{1}, Au.Probes{2});
    [S.AudioAttenUnit, S.AudioPrefNumAttenEdit] = deal(Au.Attenuators, Au.PreferredNumAtten);
    [S.AudioMinFsamEdit, S.AudioCalibTypeUnit] = deal(Au.MinFsam_kHz, Au.CalibrationType);
    [S.AudioMinFstimEdit, S.AudioMaxFstimEdit] = deal(Au.MinStimFreq, Au.MaxStimFreq);
end
%------Elec----
if ~isempty(E.Electra.Device),
    Ea = E.Electra;
    [S.ElecDeviceUnit, S.ElecDA_1Unit, S.ElecDA_2Unit] = deal(Ea.Device, Ea.DA1_target, Ea.DA2_target);
    [S.ElecMaxAbsDAEdit, S.ElecMinFsamEdit] = deal(Ea.MaxAbsDA, Ea.MinFsam_kHz);
end
%------Recording----
if ~isempty(E.Recording.Source),
    Rc = E.Recording.Source;
    CHN = fieldnames(Rc); % names of sAD channels
    for ii=1:numel(CHN),
        ch = CHN{ii};
        PNS = fieldnames(Rc.(ch)); % names of parameters of this channel
        for jj=1:numel(PNS),
            pn = PNS{jj}; % short param name
            fpn = ['Rec_' ch '_' pn]; % full param name
            S.(fpn) = Rc.(ch).(pn);
        end
    end
%     [S.RecDeviceUnit, S.RecMinFsamEdit, S.RecSideUnit] = deal(Rc.Device, Rc.minFsam, Rc.RecordingSide);
%     [S.RecEventTypeUnit, S.RecDiscriminatorUnit] = deal(Rc.EventType, Rc.Discriminator);
%     [S.RecAD_1Unit, S.RecAmp_1Unit, S.RecGain_1Edit, S.RecGain_1Unit] = deal(Rc.AD1_signal, Rc.AD1_Amplifier, Rc.AD1_Gain, Rc.AD1_GainUnit);
%     [S.RecLowFreq_1Edit, S.RecHighFreq_1Edit] = deal(Rc.AD1_lowCutoff, Rc.AD1_highCutoff);
%     [S.RecAD_2Unit, S.RecAmp_2Unit, S.RecGain_2Edit, S.RecGain_2Unit] = deal(Rc.AD2_signal, Rc.AD2_Amplifier, Rc.AD2_Gain, Rc.AD2_GainUnit);
%     [S.RecLowFreq_2Edit, S.RecHighFreq_2Edit] = deal(Rc.AD2_lowCutoff, Rc.AD2_highCutoff);
end
%------Prefs----
if ~isempty(E.Preferences.MaxNcond),
    Ep = E.Preferences;
    S.PrefMaxNcondEdit = Ep.MaxNcond;
    S.PrefITDconventionUnit = Ep.ITDconvention;
    S.PrefCmplxWvUnit = Ep.StoreComplexWaveforms;
    S.PrefCheckID = Ep.CheckID;
    if isfield(Ep,'CheckAllDsInfo');
        S.PrefFullDsInfo = Ep.CheckAllDsInfo;
    end
end

function E = local_struct2exp(E,S);
% convert GUIval struct S to Experiment object
% %------Audio----
[Au.Device, Au.MaxAbsDA, Au.DAchannelsUsed] = deal(S.AudioDevice, S.AudioMaxAbsDA, S.AudioDAchan);
[Au.HeadphoneBuffer, Au.Speakers] = deal(S.AudioBuffer, S.AudioSpeakers);
[Au.Probes{1}, Au.Probes{2}] = deal(S.AudioProbe_1, S.AudioProbe_2);
[Au.Attenuators, Au.PreferredNumAtten] = deal(S.AudioAtten, S.AudioPrefNumAtten);
[Au.MinFsam_kHz, Au.MinStimFreq, Au.MaxStimFreq] = deal(S.AudioMinFsam, S.AudioMinFstim, S.AudioMaxFstim);
Au.CalibrationType = S.AudioCalibType;
E.Audio = Au;
%------Elec----
[Ea.Device, Ea.DA1_target, Ea.DA2_target] = deal(S.ElecDevice, S.ElecDA_1, S.ElecDA_2);
[Ea.MaxAbsDA, Ea.MinFsam_kHz] = deal(S.ElecMaxAbsDA, S.ElecMinFsam);
E.Electra = Ea;
%------Recording----
E.Recording = local_parse_RecInfo(S);
%------Prefs----
Ep.MaxNcond = S.PrefMaxNcond;
Ep.ITDconvention = S.PrefITDconvention;
Ep.StoreComplexWaveforms = S.PrefCmplxWv;
Ep.CheckID = S.PrefCheckID;
Ep.CheckFullDsInfo = S.PrefCheckDsInfo;
E.Preferences = Ep;
%------Status----
if isempty(E.Status.Modified), % a new exp: 'modified' should equal 'started' 
    E.Status.Modified = E.ID.Started;
else, % the current editing is a modification. Note its time.
    E.Status.Modified = datestr(now);
end
% only provide default values for those State params that are empty; leave non-empty ones alone
if isempty(E.Status.StatusModified), E.Status.StatusModified = E.ID.Started; end
if isempty(E.Status.State), E.Status.State = 'Initialized'; end
if isempty(E.Status.Ndataset), E.Status.Ndataset = 0; end
if isempty(E.Status.iPen), E.Status.iPen = 0; end
if isempty(E.Status.PenDepth), E.Status.PenDepth = nan; end
if isempty(E.Status.iCell), E.Status.iCell = 0; end
if isempty(E.Status.iRecOfCell), E.Status.iRecOfCell = 0; end
if isempty(E.Status.AllSaved), 
    E.Status.AllSaved = emptystruct('iDataset', 'iCell', 'iRecOfCell', 'StimType'); 
end
if isempty(E.Status.iCalibMeasured), E.Status.iCalibMeasured = 0; end
checkfields(E); % test if E has up-to-date fields

function Rc = local_parse_RecInfo(S);
FNS = fieldnames(S);
imatch = strmatch('Rec', FNS);
S = structpart(S, FNS(imatch)); % restrict to RecXXX fieldnames
Rc.General = []; % first field to be filled below
% peel off the specifics from S, chan by chan
Chan = 'RX6_digital_1';
[S, Rc.Source.(Chan)] = local_Peel(S, ['Rec_' Chan '_']);
Chan = 'RX6_analog_1';
[S, Rc.Source.(Chan)] = local_Peel(S, ['Rec_' Chan '_']);
Chan = 'RX6_analog_2';
[S, Rc.Source.(Chan)] = local_Peel(S, ['Rec_' Chan '_']);
Chan = 'PC_COM1';
[S, Rc.Source.(Chan)] = local_Peel(S, ['Rec_' Chan '_']);
% remainder is generic Rec info, all starting with Rec
[S, Rc.General] = local_Peel(S, 'Rec');

function [S, Sp] = local_Peel(S, Prefix);
% select fields of S whose names start with Prefix; transfer put them from S to Sp 
FNS = fieldnames(S);
%S, Prefix
imatch = strmatch(Prefix, FNS);
for ii=imatch(:)',
    fnS = FNS{ii};
    fnSp = strrep(fnS, Prefix, ''); % fieldname in Sp drops the Prefix
    Sp.(fnSp) = S.(fnS);
end
S = rmfield(S, FNS(imatch)); 

function local_GUImode(figh, Mode, gmess, gmessmode);
% set enable status of uicontrols
if nargin<3, gmess = inf; end % indicates absence of message - '' would be bad choice.
if nargin<4, gmessmode = 'neutral'; end
[Mode, Mess] = keywordMatch(Mode,{'Busy' 'Ready'}, 'Mode argument');
error(Mess);
A = getGUIdata(figh, 'ActionButton', ActionButton);
Q = getGUIdata(figh, 'Query', ParamQuery);
iE = getGUIdata(figh, 'InitExp'); % initial value of experiment
readOnly = isequal('Finished', state(iE));
% D/A chan specific buttons & queries
switch Mode,
    case {'Busy'}, % disable all buttons & prevent closing the figure
        enable(A,0); enable(Q,0);
        GUIclosable(figh,0); % not okay to close GUI
    case 'Ready', % enable all buttons; okay to close GUI; 
        if readOnly, % disable everything
            enable(Q,0);
            enable(A,0);
            enable(A('Cancel'),1);
            GUImessage(figh, 'Experiment has been finished and may not be edited.', 'warn');
        else, % enable everything except some ID stuff
            enable(Q,1);
            enable(A,1);
            enable(Q('ID*'), 0); % disable all ID-related queries, but ...
            enable(Q('IDExperimenter'),0);
            if isvoid(iE), % ... make a few exceptions for newcomers
                enable(Q('IDName', 'IDType'),1);
            end
        end
        GUIclosable(figh,1); % okay to close GUI
end
% display GUI message, if any.
if ~isempty(gmess) && ~isequal(inf, gmess),
    GUImessage(figh,gmess,gmessmode);
end
figure(figh);
drawnow;

function okay = local_OK(figh);
okay = false;
% read parameters and check them
local_GUImode(figh, 'Busy', 'Checking parameters...');
S = GUIval(figh); % read parameters. [] is returned when something is wrong.
local_GUImode(figh, 'Ready');
if isempty(S), return; end % error is already reported by GUIval
% other checks
if isequal('Flat', S.AudioCalibType), % AudioProbe fields must contain a spec like '100 dB SPL'
    SPL1 = str2num(strtok(S.AudioProbe_1));
    SPL2 = str2num(strtok(S.AudioProbe_2));
    if ~isequal('Right', S.AudioDAchan) && ~issinglerealnumber(SPL1),
        GUImessage(figh, {'In case of Flat calibration, the', ...
            'Probe name field must contain', ....
            'a specification of the SPL', ...
            'at 1 Volt RMS, for instance:', ...
            '       104 dB SPL'}, 'error', {'AudioProbe_1' 'AudioDAchan'});
        return;
    elseif ~isequal('Left', S.AudioDAchan) && ~issinglerealnumber(SPL2),
        GUImessage(figh, {'In case of Flat calibration, the', ...
            'Probe name field must contain', ....
            'a specification of the SPL', ...
            'at 1 Volt RMS, for instance:', ...
            '       106 dB SPL'}, 'error', {'AudioProbe_2' 'AudioDAchan'});
        return;
    end
elseif isequal('In situ', S.AudioCalibType),
    % no input required
else,% AudioProbe fields must contain existing probes for the D/A channels used
    if ~isequal('Right', S.AudioDAchan) && ~exist(probetubecalib, S.AudioProbe_1),
        GUImessage(figh, 'Probe tube data for channel # 1 not found.', 'error', 'AudioProbe_1');
        return;
    elseif ~isequal('Left', S.AudioDAchan) && ~exist(probetubecalib, S.AudioProbe_2),
        GUImessage(figh, 'Probe tube data for channel # 2 not found.', 'error', 'AudioProbe_2');
        return;
    end
end
iE = getGUIdata(figh,'InitExp');
if isvoid(iE), % newly defined experiment. Valid newcomer?
    if exist(experiment(), S.IDName),
        GUImessage(figh, {['Experiment folder ''' S.IDName ''' already exists.'], 'Experiment names must be unique.'}, ...
            'error', 'IDName');
        return;
    end
    E = checkin(iE, S.IDName, S.IDExperimenter, S.IDType);
    E = local_struct2exp(E,S); % incorporate all new settings from S into E
    addtolog(E, compare(iE,E));
else, % redefining existing exp. Is that allowed?
    okay = false; % pessimistic default
    if isempty(locate(experiment, S.IDName, 1)),
        GUImessage(figh, {['Files for existing experiment ''' S.IDName ''' not found.']'}, ...
            'error', 'IDName');
    elseif ~iscurrent(find(experiment, S.IDName)),
        GUImessage(figh, {['Experiment ''' S.IDName ''' is not the current experiment.']}, ...
            'error', 'IDName');
    elseif ~isequal(CompuName, S.IDcomputer),
        Mess = {['Definition of Experiment ''' S.IDName '''' ], ...
            'cannot be changed because', ...
            'the experiment was initialized', ...
            'on a different computer.'};
        GUImessage(figh, Mess, 'error', 'IDcomputer');
    else,
        okay = true;
    end
    if ~okay, return; end
    E = defbackup(iE); % make a backup of the previous definitions
    E = local_struct2exp(E,S); % incorporate all new settings from S into E
    addtolog(E, strvcat(['o-o-o-o-o-o definition updated ' modified(E) ' o-o-o-o-o-o'], compare(iE,E)));
end
save(E);
GUIgrab(figh, '>');
setGUIdata(figh,'EditedExp', load(E)); % return of experiment/edit. Picked up by initial launch call after Reap
okay = true;


function local_viewfile;
% view probetubedata from file
[PTC, FFN] = load(probetubecalib());
[dum, Nam] = fileparts(FFN);
if ~isvoid(PTC),
    figure('numbertitle','off','integerhandle', 'off', 'name', [Nam ' (probe tube calibration).']);
    plot(PTC);
end

%======
function local_help(Topic);
switch lower(Topic),
    case 'howto',
        winopen(which('HowToCalibrateAProbeTube.pdf'));
    otherwise,
        error(['Unknown help topic ''' Topic '''.']);
end

%=========
function local_PNbutton(figh, ichan);
% browse for probe
chanstr = num2str(ichan);
[P, FFN] = load(probetubecalib(),'?',['Identify probe tube of D/A chan ' chanstr]);
if isvoid(P), return; end
% fill in name in corresponding edit field
Q = getGUIdata(figh, 'Query');
[dum, FN] = fileparts(FFN);
he = edithandle(Q(['AudioProbe_' chanstr]));
set(he, 'string', FN); drawnow;


%===================
function local_file(figh, kw, varargin);
%figh, kw, varargin{:};
switch lower(kw),
    case 'open',
        [Mess, Ignored, FN]=GUIfill(figh,'?',1); % 1: do display message
        [dum FN] = fileparts(FN);
    case 'save',
        S=GUIgrab(figh, '?',1);% 1: do display message
    case 'emptylist',
        warning(['fileemptylist NIY'])
    otherwise,
        error(['Invalid Filemenu keyword ''' kw '''.']);
end % switch/case
local_GUImode(figh,'Ready');




















