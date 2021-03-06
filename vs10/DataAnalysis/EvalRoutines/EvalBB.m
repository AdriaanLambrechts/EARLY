function ArgOut = EvalBB(varargin)
%EVALBB  evaluate binaural beat (BB) datasets
%   EVALBB(ds) evaluates the binaural beat responses in dataset ds.
%   D = EVALBB(ds) returns the results in structure D.
%
%   Optional properties and their values can be given as a comma-separated list. To view list
%   of all possible properties and their default value, use 'list' as only property.

%B. Van de Sande 13-09-2004

%% ---------------- CHANGELOG -----------------------
%  Wed Apr 13 2011  Abel   
%   - added support for new getThr4Cell() function
%	- code syntax cleanup/update
%  Thu Apr 21 2011  Abel   
%   - no reason why ds2 is in the output,... removing 
%  Fri Apr 22 2011  Abel   
%   - added vector.beat
%  Tue May 31 2011  Abel   
%   - reorganise output struct
%  Mon Apr 2 2012  Abel   
%   - added bin centers and firering rate at bin center in output (=
%   unprocessed output from cyclehist())


%% ---------------- TODO ----------------------------
% 

%% ---------------- Default parameters ---------------
%Template for scatterplots ... 
% - Dataset parameters
Template.ds.filename   = '';  
Template.ds.sys        = '';		%system EDF/SGSR etc,...
Template.ds.icell      = NaN;
Template.ds.iseq       = NaN;  
Template.ds.seqid      = '';
Template.ds.recside    = '';        %Recording site (userdata)

% - Stimulus parameters
% stim.step, stim.repdur, stim.nrep, stim.spl, stim.inc, stim.freqcon,
% stim.freqips, stim.freqbeat, stim.type (ADD: SRPP, BCS, ..., as in header
% of RAP)
Template.stim.chanl      = NaN;			%Left chanel (userdata)
Template.stim.chanr      = NaN;			%Right chanel (userdata)
Template.stim.mdss       = NaN;			%Master chanel (EDF datasets, from userdata)
Template.stim.repdur     = NaN;			%Repetition duration in ms ...
Template.stim.burstdur   = [NaN NaN];	%Stimulus duration in ms ...
Template.stim.nrep       = NaN;			%Repetition number ...
Template.stim.spl        = [NaN NaN];	%Sound pressure level in dB ...
Template.stim.inc        = '';			%Linear or logaritmic independent value incrementation ...
Template.stim.step       = NaN;			%Size of independent value incrementation ...
Template.stim.freqcon    = nan;			%Freq at contra side 
Template.stim.freqips    = nan;			%Freq at ipsi side 
Template.stim.freqbeat   = nan;			%Beat frequency
Template.stim.type       = '';			%Stimulus type

% - Analysis parameters
% Template.param.repdur   = NaN;       %Repetition duration in ms ...
% Template.param.burstdur = [NaN NaN];       %Stimulus duration in ms ...
% Template.param.nrep     = NaN;       %Repetition number ...
% Template.param.spl      = [NaN NaN];       %Sound pressure level in dB ...
% Template.param.inc      = '';        %Linear or logaritmic independent value incrementation ...
% Template.param.step     = NaN;       %Size of independent value incrementation ...

% param.eval (ipv created by), param.tag, param.aw, param.binf
Template.param.eval		= mfilename; %Name of MATLAB function that generated the data
Template.param.anwin	= [];        %Analysis window
Template.param.binf		= [];        %Binning frequency

%Response (RATE)
% resp.ratemax, resp.ratebf, resp.rmax, resp.rbf, resp.rbeat
% Template.resp.ratemax = nan; %Maximum firing rate (spk/sec)
% Template.resp.ratebf = nan;  %Frequency at maximum rate (Hz)
Template.resp.rmax      = nan;		%Maximum firing rate (spk/sec)
Template.resp.rbf       = nan;		%Frequency at maximum rate (Hz)
Template.resp.rbeat     = nan;		%?
% Template.rate.max       = NaN;       %Maximum firing rate (spk/sec)
% Template.rate.bf        = NaN;       %Frequency at maximum rate (Hz)

%Vector Strenght
Template.vs.maxr        = NaN;       %Maximum synchronicity
Template.vs.bf          = NaN;       %Frequency at maximum synchronicity (Hz)
Template.vs.cd          = NaN;       %Characteristic delay (ms)
Template.vs.cp          = NaN;       %Characteristic phase (cycles)
Template.vs.cpmod       = NaN;       %Characteristic phase restricted to interval [0, +1[(cycles)
Template.vs.plinreg     = NaN;       %Probability of linear regression

%ITD / DIFF / FTT ? 
Template.itd.max        = NaN;       %Maximum 'interaural' firing rate (spk/sec)
Template.itd.bestitd    = NaN;       %Delay at this maximum rate (ms)
Template.itd.ratio      = NaN;       %Ratio of secundary versus primary peak in interaural delay curve
Template.diff.max       = NaN;       %Maximum 'interaural' firing rate (spk/sec)
Template.diff.bestitd   = NaN;       %Delay at this maximum rate (ms)
Template.diff.ratio     = NaN;       %Ratio of secundary versus primary peak in interaural delay curve
Template.diff.hhw       = NaN;       %Half height width (ms) ...
Template.fft.df         = NaN;       %Dominant frequency in interaural delay curve (Hz)
Template.fft.bw         = NaN;       %Bandwidth of interaural delay curve (Hz)

%VECTOR ? (Is this needed since its added lateron in ArgOut,..) 
Template.vector.freq1   = NaN;       %
Template.vector.freq2   = NaN;       %
Template.vector.rate    = NaN;       %
Template.vector.vs		= NaN;       %
Template.vector.phase   = NaN;       %
Template.vector.z       = NaN;       %
Template.vector.bins    = NaN;       %Bin centers ->  cyclehist()
Template.vector.binrate = NaN;		 %firering rate a bin center ->  cyclehist()

%THR Info
Template.thr.cf         = NaN;       %Characteristic frequency retrieved from threshold curve
Template.thr.sr         = NaN;       %Spontaneous rate retrieved from threshold curve
Template.thr.thr        = NaN;       %Threshold at characteristic frequency
Template.thr.q10        = NaN;       %Q10 retrieved from threshold curve (CF/BW)
Template.thr.bw         = NaN;       %Bandwidth 10dB above CF

%General Output 
Template.tag            = 0;         %General purpose tag field

%for temp function
% Template.vector.delay = NaN;
Template.vector.time = NaN;

%Output for debugging
% Template.vector.freq1Minfreq2   = NaN;       %Beat freqency = freq1 - freq2 
% Template.vector.beatInEvalBB	= NaN;
% Template.vector.beatContMinIpsi = NaN;


%---------------------------------------------------------------------------------------------
%List of default parameters ...
%Calculation parameters ...
DefParam.indep2val     = 'max';       %Value for second independent var in 
                                      %case of EDF (Madison) datasets: 
									  %'min', 'max' or specific value ...

DefParam.anwin         = [0 -1];      %in ms ... (-1 designates stimulus duration)
DefParam.histnbin      = 64;
DefParam.vsraysig      = 0.001;   
DefParam.calcdf        = NaN;           %in Hz, NaN (automatic), 'cf' or 'df' ...
DefParam.itdconfreq    = 'mean';      %'mean' or 'master' ... The constant 
                                      %frequency can be taken as the frequency of 
									  %the DSS/channel (i.e. master) that was varied or 
									  %it can be taken as the mean of the 
									  %frequencies administered at both ears ...
DefParam.itdbinwidth   = 0.05;        %in ms ...
DefParam.itdmaxlagunit = '#';         %'#' or 'ms' ...
DefParam.itdmaxlag     = 0.5; 
DefParam.itdrunavunit  = 'ms';        %'ms' or '#' ...   
DefParam.itdrunav      = 0.20;
DefParam.envrunavunit  = '#';         %'ms' or '#' ...   
DefParam.envrunav      = 1;    
%Plot parameters ...
DefParam.plot         = 'yes';       %'yes' or 'no' ...
DefParam.plottype     = 'all';       %'all', 'cc' or 'vs' ... 
DefParam.freqxrange   = [-Inf +Inf]; %in Hz ...
DefParam.rasmaxytick  = 12;          
DefParam.itdxrange    = [-5 +5];     %in ms ...
DefParam.itdxstep     = 1;           %in ms ...
DefParam.fftxrange    = [0 2500];    %in Hz ...
DefParam.fftxstep     = 250;         %in Hz ...
DefParam.fftyunit     = 'dB';        %'dB' or 'P' ...
DefParam.fftyrange    = [-20 0]; 
DefParam.sort         = 'yes';      % See CalcRATE()
DefParam.sync         = 'auto';      %'auto' or 'man' connect to userdata (See RAP help)

%For temp polar plot
DefParam.polarrunav         = 0;      %
DefParam.gridmax = 2500;
DefParam.gridmin = 100;
DefParam.logscale = false;


%% ---------------- Main function --------------------

%Evaluate input parameters ...
[dsBB, CellInfo, Param] = EvalParam(DefParam, varargin);

%Retrieving data from SGSR server ...
[ Thr, dsThr ] = getThr4Cell(dsBB.ID.Experiment, dsBB.ID.iCell);
if ~iscell(Thr.str) && isnan(Thr.str)
	CellInfo.thrstr = Thr.str;
else
	CellInfo.thrstr = [ ...
		sprintf('Threshold curve:%s <%s>\n', dsBB.ID.Experiment.ID.Name, num2str(Thr.seqnr)) ...
		sprintf('CF: %s @ %s\n', Param2Str(Thr.cf, dsThr.Stim.StartFreqUnit, 0), Param2Str(Thr.thr, 'dB', 0)) ...
		sprintf('SR: %s / ', Param2Str(Thr.sr, 'spk/sec', 1)) ...
		sprintf('BW: %s / ', Param2Str(Thr.bw, dsThr.Stim.StartFreqUnit, 1)) ...
		sprintf('Q10: %s', Param2Str(Thr.q10, '', 1)) ...
		];
end

%Calculate data ...
[CalcData, CellInfo] = CalcCurve(dsBB, CellInfo, Thr, Param);

%Display data ...
if strcmpi(Param.plot, 'yes'),
	if strcmpi(Param.plottype, 'all')
		PlotCurve('cc', CalcData, CellInfo, Param);
		%by abel: Added dsBB for TEMP PLOT
		Param = PlotCurve('vs', CalcData, CellInfo, Param, dsBB);
	elseif strcmpi(Param.plottype, 'cc')
		PlotCurve('cc', CalcData, CellInfo, Param);
	else
		Param = PlotCurve('vs', CalcData, CellInfo, Param, dsBB);
	end
end

%TEMP PLOT
	Param = tempPlotFunction_(dsBB, CalcData, Param);

%Return output parameters ...
if nargout > 0, 
	%THR info
    CalcData.thr = Thr;
	
    ArgOut = structtemplate(CalcData, Template); 
    ArgOut.vector.freq1   = Param.carfreq(:,1)';       
    ArgOut.vector.freq2   = Param.carfreq(:,2)';
    ArgOut.vector.rate    = CalcData.rate.rate;       
    ArgOut.vector.vs      = CalcData.vs.r;       
    ArgOut.vector.phase   = CalcData.vs.ph;       
    ArgOut.vector.z       = CalcData.vs.raysig;
	ArgOut.vector.bins    = CalcData.vs.bins;

	
	%Extra dataset info
	ArgOut.ds = updatestruct(Template.ds, CellInfo, 'skipnontemplate', true);
% 	ArgOut.ds.sys = CellInfo.sys;
% 	ArgOut.ds.recside = CellInfo.recside;
% 	ArgOut.ds.filename = CellInfo.filename;
% 	ArgOut.ds.seqid = CellInfo.dsid;
	
	
	%Extra stim info
	stimStruct = Template.stim;
 	stimStruct = updatestruct(stimStruct, CalcData.stim, 'skipnontemplate', true);
	stimStruct = updatestruct(stimStruct, Param, 'skipnontemplate', true);
	ArgOut.stim = stimStruct;
	contColNr = CalcData.param.contraColumnNrInCarFreq;
	ipsiColNr = CalcData.param.ipsiColumnNrInCarFreq;
	try
		ArgOut.stim.freqcon = Param.carfreq(:,contColNr);
		ArgOut.stim.freqips = Param.carfreq(:,ipsiColNr);
	catch
		warning('EARLY:Critical', ...
		'freqcon/freqips can not be determined since the contra and ipsi colunm number is unknown (?no userdata?)');
	end
% 	ArgOut.stim.freqbeat = unique(dsBB.fcar(:,contColNr)-dsBB.fcar(:,ipsiColNr));
% 	ArgOut.stim.chanL = CellInfo.chanL;
% 	ArgOut.stim.chanR = CellInfo.chanR;
% 	ArgOut.stim.MDSS = CellInfo.MDSS;
% 	if strcmpi(dsBB.FileFormat, 'EDF')
% 		ArgOut.param.masterDSS      = dsBB.mdssnr;
% 	else
% 		%keep #elements equal for structview()
% 		ArgOut.param.masterDSS      = NaN;
% 	end

	%Analysis param
	ArgOut.param = updatestruct(Template.param, Param, 'skipnontemplate', true);
	ArgOut.param.binf = Param.beat;
	
	%Response param (rate)
	ArgOut.resp = updatestruct(Template.resp, CalcData.rate, 'skipnontemplate', true);
	
	%for temp funct
% 	ArgOut.vector.delay = Param.vector.delay;
	ArgOut.vector.time = Param.vector.time;
	
	
	%output for debugging
% 	ArgOut.vector.freq1Minfreq2 = unique(ArgOut.vector.freq1 - ArgOut.vector.freq2); %beat freq = diff in
% 	ArgOut.vector.beatInEvalBB = unique(CalcData.param.beat); %should be 1 value, adding unique() test for now                                                                           %should be 1 value, adding unique() test for now
% 	ArgOut.vector.beatContMinIpsi = unique(dsBB.fcar(:,CalcData.param.contraColumnNrInCarFreq)-dsBB.fcar(:,CalcData.param.ipsiColumnNrInCarFreq));
	%ArgOut.vector.ContraFreq = dsBB.fcar(:,CalcData.param.contraColumnNrInCarFreq);
	%ArgOut.vector.IpsiFreq = dsBB.fcar(:,CalcData.param.ipsiColumnNrInCarFreq);
% 	ArgOut.vector.ContraFreq = Param.carfreq(:,CalcData.param.contraColumnNrInCarFreq);
% 	ArgOut.vector.IpsiFreq = Param.carfreq(:,CalcData.param.ipsiColumnNrInCarFreq);
	
	
	%cleanup output (all in rows)
	ArgOut = torow(ArgOut);
	
	%needs to remain a matrix
	ArgOut.vector.binrate = CalcData.vs.binrate;
	
end    



%% ---------------- Local functions ------------------
function [dsBB, CellInfo, Param] = EvalParam(DefParam, ParamList)

%Checking input parameters ...
if (length(ParamList) < 1)
	error('Wrong number of input parameters.'); 
end
if ~isa(ParamList{1}, 'dataset') || ~strcmp(ParamList{1}.Stim.DAC, 'Both')
	error('First argument should be binaural dataset.'); 
end
dsBB = ParamList{1};

%Checking dataset ...
FileFormat = 'EarlyDS'; 
SeqID = [num2str(dsBB.ID.iCell) '-' num2str(dsBB.ID.iRecOfCell) '-' dsBB.StimType];
[CellNr, TestNr, StimType] = UnRavelID(SeqID);
if ~any(strcmpi(StimType, {'BBFC', 'FS'}))
	warning(sprintf('Unknown dataset type: ''%s''.', upper(StimType)));
end
if strcmpi(FileFormat, 'EDF') && (dsBB.indepnr > 1)
	warning('Multiple independent variables, using one-dimensional restriction.'); 
end

%Evaluate optional list of property/values ...
ParamList(1) = [];
Param = checkproplist(DefParam, ParamList{:});
CheckParam(Param);

%Assembling stimulus parameters ...
StimParam = GetStimParam(dsBB, Param);

%StimType
StimParam.type = StimType;

%Setting shortcuts in calculation parameters ...
if Param.anwin(2) == -1, Param.anwin(2) = max(StimParam.burstdur); end %Taking maximum burst duration as default offset for analysis window ...
if strcmpi(Param.itdrunavunit, 'ms'), 
    RunAvTsup = Param.itdrunav;
    RunAvNsup = round(Param.itdrunav/Param.itdbinwidth);
    RunAvNeff = 2*round(RunAvNsup/2)+1; %Effective number of points overwhich RUNAV.M averages (always odd) ...
    RunAvTeff = RunAvNeff*Param.itdbinwidth;
    Param.itdrunav = RunAvNsup;
    RunAvItdStr = sprintf('%.2fms (%.0f#, %.2fms)', RunAvTsup, RunAvNeff, RunAvTeff);
else,
    RunAvNsup = Param.itdrunav;
    RunAvNeff = 2*round(RunAvNsup/2)+1; %Effective number of points overwhich RUNAV.M averages (always odd) ...
    RunAvTeff = RunAvNeff*Param.itdbinwidth;
    Param.itdrunav = RunAvNsup;
    RunAvItdStr = sprintf('%.0f# (%.0f#, %.2fms)', RunAvNsup, RunAvNeff, RunAvTeff);
end 
if strcmpi(Param.itdmaxlagunit, '#')
    if strcmpi(StimParam.inc, 'lin')
        StepPer = 1000/abs(StimParam.step);
    else
        StepPer = 1000/((StimParam.indepval(1)*2^StimParam.step)-StimParam.indepval(1)); 
    end %Smallest StepSize used ...
    MaxLagN = Param.itdmaxlag;
    MaxLagT = MaxLagN*StepPer;
    Param.itdmaxlag = MaxLagT;
    MaxLagStr = sprintf('%.1f# (%.0fms)', MaxLagN, MaxLagT);
else
    MaxLagStr = Param2Str(Param.itdmaxlag, 'ms', 0); 
end
%Running average parameters on enveloppe cannot be unified yet, dominant frequency necessary ...

%Assembling cell information ....
FileName = dsBB.ID.Experiment.ID.Name;
CellInfo.filename = FileName;
CellInfo.iseq    = dsBB.ID.iDataset;
CellInfo.seqid     = SeqID;
CellInfo.cellstr  = sprintf('%s <%s> (#%d)', CellInfo.filename, CellInfo.seqid, CellInfo.iseq);
CellInfo.sys      = FileFormat;
CellInfo.icell = CellNr;

%Constructing information string on parameters ...
if isnan(Param.calcdf)
	CalcDFStr = 'auto';
elseif ischar(Param.calcdf)
	CalcDFStr = lower(Param.calcdf);
else
	CalcDFStr = Param2Str(Param.calcdf, 'Hz', 0);
end
s = sprintf('AnWin = %s', Param2Str(Param.anwin, 'ms', 0));
s = strvcat(s, sprintf('NBin(CH) = %s', Param2Str(Param.histnbin, '#', 0)));
s = strvcat(s, sprintf('Calc. DF = %s', CalcDFStr));
s = strvcat(s, sprintf('BinWidth(ITD) = %s', Param2Str(Param.itdbinwidth, 'ms', 2)));
s = strvcat(s, sprintf('MaxLag(ITD) = %s', MaxLagStr));
s = strvcat(s, sprintf('RunAv(ITD) = %s', RunAvItdStr));
CellInfo.ccparamstr = s;
s = sprintf('AnWin = %s', Param2Str(Param.anwin, 'ms', 0));
s = strvcat(s, sprintf('NBin(CH) = %s', Param2Str(Param.histnbin, '#', 0)));
s = strvcat(s, sprintf('RaySig(CH) = %s', Param2Str(Param.vsraysig, '', 3)));
CellInfo.vsparamstr = s;

%Constructing information string on stimulus parameters ...
s = sprintf('BurstDur/IntDur/#Reps = %s/%s x %s', Param2Str(StimParam.burstdur, '', 0), ...
    Param2Str(StimParam.repdur, 'ms', 0), Param2Str(StimParam.nrep, '', 0));
s = strvcat(s, sprintf('SPL = %s', Param2Str(StimParam.spl, 'dB', 0)));
if strcmpi(StimParam.inc, 'lin')
	s = strvcat(s, sprintf('StepFreq = %s', Param2Str(StimParam.step, 'Hz', 0)));
else
	s = strvcat(s, sprintf('StepFreq = %s', Param2Str(StimParam.step, 'Oct', 2))); 
end
if ~isnan(StimParam.beatcarfreq)
    s = strvcat(s, sprintf('CarFreq = %s (%s)', Param2Str(StimParam.carfreq, 'Hz', 0), upper(StimParam.inc)));
    s = strvcat(s, sprintf('CarBeat = %s', Param2Str(StimParam.beatcarfreq, 'Hz', 0)));
else
    s = strvcat(s, sprintf('CarFreq = %s', Param2Str(StimParam.carfreq, 'Hz', 0)));
    s = strvcat(s, sprintf('ModFreq = %s (%s)', Param2Str(StimParam.modfreq, 'Hz', 0), upper(StimParam.inc)));
    s = strvcat(s, sprintf('ModBeat = %s', Param2Str(StimParam.beatmodfreq, 'Hz', 0)));
end
CellInfo.stimstr = s;

%Reorganize parameters ...
Param = structcat(StimParam, Param);

%---------------------------------------------------------------------------------------------
function CheckParam(Param)

if ~(isnumeric(Param.indep2val) && (length(Param.indep2val) == 1)) & ~(any(strcmpi(Param.indep2val, {'min', 'max'}))), error('Invalid value for property indep2val.'); end
if ~isnumeric(Param.anwin) | (size(Param.anwin) ~= [1,2]), error('Invalid value for property anwin.'); end
if ~isnumeric(Param.vsraysig) | (length(Param.vsraysig) ~= 1) | (Param.vsraysig <= 0), error('Invalid value for property vsraysig.'); end
if ~isnumeric(Param.histnbin) | (length(Param.histnbin) ~= 1) | (Param.histnbin <= 0) | (mod(Param.histnbin, 1) ~= 0), error('Invalid value for property histnbin.'); end
if (mod(Param.histnbin, 2) ~= 0), error('Property histnbin must be assigned an even number.'); end
if ~(isnumeric(Param.calcdf) && ((Param.calcdf > 0) || isnan(Param.calcdf))) & ...
        ~(ischar(Param.calcdf) & any(strcmpi(Param.calcdf, {'cf', 'df'}))), 
    error('Property calcdf must be positive integer, NaN, ''cf'' or ''df''.'); 
end
if ~any(strcmpi(Param.itdconfreq, {'mean', 'master'})), error('Property itdconfreq should be ''mean'' or ''master''.'); end
if ~isnumeric(Param.itdbinwidth) | (length(Param.itdbinwidth) ~= 1) | (Param.itdbinwidth <= 0), error('Invalid value for property itdbinwidth.'); end
if ~any(strcmpi(Param.itdmaxlagunit, {'ms', '#'})), error('Property itdmaxlagunit should be ''ms'' or ''#''.'); end
if ~isnumeric(Param.itdmaxlag) || (length(Param.itdmaxlag) ~= 1) || (Param.itdmaxlag <= 0), error('Invalid value for property itdmaxlag.'); end
if ~isnumeric(Param.itdrunav) || (length(Param.itdrunav) ~= 1) | (Param.itdrunav < 0), error('Invalid value for property itdrunav.'); end
if ~any(strcmpi(Param.itdrunavunit, {'ms', '#'})), error('Property itdrunavunit should be ''ms'' or ''#''.'); end
if ~isnumeric(Param.envrunav) || (length(Param.envrunav) ~= 1) | (Param.envrunav < 0), error('Invalid value for property envrunav.'); end
if ~any(strcmpi(Param.envrunavunit, {'ms', '#'})), error('Property envrunavunit should be ''ms'' or ''#''.'); end

if ~any(strcmpi(Param.plot, {'yes', 'no'})), error('Property plot must be ''yes'' or ''no''.'); end
if ~any(strcmpi(Param.plottype, {'all', 'cc', 'vs'})), error('Property plottype should be ''all'', ''cc'' or ''vs''.'); end
if ~isinrange(Param.freqxrange, [-Inf +Inf]), error('Invalid value for property freqxrange.'); end
if ~isnumeric(Param.rasmaxytick) || (length(Param.rasmaxytick) ~= 1) || (Param.rasmaxytick <= 0), error('Invalid value for property rasmaxytick.'); end
if ~isinrange(Param.itdxrange, [-Inf +Inf]), error('Invalid value for property itdxrange.'); end
if ~isnumeric(Param.itdxstep) | (length(Param.itdxstep) ~= 1) | (Param.itdxstep <= 0), error('Invalid value for property itdxstep.'); end
if ~isinrange(Param.fftxrange, [0 +Inf]), error('Invalid value for property fftxrange.'); end
if ~isnumeric(Param.fftxstep) || (length(Param.fftxstep) ~= 1) | (Param.fftxstep <= 0), error('Invalid value for property fftxstep.'); end
if ~any(strcmpi(Param.fftyunit, {'dB', 'P'})), error('Property fftyunit must be ''dB'' or ''P''.'); end
if ~isinrange(Param.fftyrange, [-Inf +Inf]), error('Invalid value for property fftyrange.'); end

%---------------------------------------------------------------------------------------------
function StimParam = GetStimParam(dsBB, Param)

StimParam = struct('repdur', [], 'burstdur', [], 'risedur', [], 'falldur', [], 'spl', [], 'carfreq', [], 'modfreq', [], ...
    'beatcarfreq', [], 'beatmodfreq', [], 'freq', [], 'beat', [], 'inc', [], 'step', [], 'indepval', [], 'isubseqs', []);
Nrec = dsBB.Stim.Presentation.Ncond; 

%Nr of indep vars can be more than one 
if isempty(dsBB.Stim.Presentation.Y), 
	Nindep = 1; 
else
	Nindep = 2; 
end

%if more than one indepvar determine the indepvar containing 'frequency' in
%its name (first indepvar) and select iSubSeqs based the max, min or
%specific value of the second indepvar
if (Nindep > 1)
    FreqIndepNr = isempty(strfind(dsBB.EDFIndepVar(1).ShortName, 'frequency')) + 1; %2 if ShorName contains frequency, else 1
    SecIndepNr  = mod(FreqIndepNr, 2) + 1; %1 if ShorName contains frequency, else 2
	
	%Param.indep2val is min() or max() specific number
	if isnumeric(Param.indep2val)
		SecVal = Param.indep2val;
	else
		SecVal = feval(Param.indep2val, dsBB.EDFIndepVar(SecIndepNr).Values); 
	end
	iSubSeqs = find(dsBB.EDFIndepVar(SecIndepNr).Values == SecVal);
else 
	iSubSeqs = 1:Nrec; 
end

%Stimulus duration, burst duration, nr of repetitions, rise and fall duration 
StimParam.repdur   = dsBB.Stim.ISI(1); %Repetition duration is always equal for both channels ...
StimParam.burstdur = dsBB.Stim.BurstDur([1, min(2, end)]); %Always two-element columnvector ...
StimParam.nrep     = dsBB.Stim.Presentation.Nrep; %Number of repetition is always equal for both channels ...
StimParam.risedur = [dsBB.Stim.RiseDur, dsBB.Stim.RiseDur]; %Always two-element columnvector ...
StimParam.falldur = [dsBB.Stim.FallDur, dsBB.Stim.FallDur]; %Always two-element columnvector ...


%Combine SPL left and right (= two-element column vector)
SPL = GetSPL(dsBB); 
LeSPL = unique(SPL(iSubSeqs, 1)); 
ReSPL = unique(SPL(iSubSeqs, 2));
if (length(LeSPL) == 1) && (length(ReSPL) == 1)
	StimParam.spl = [LeSPL, ReSPL];
else
	StimParam.spl = SPL(iSubSeqs, :); 
end


S = GetFreq(dsBB);
LeCarFreq = unique(S.CarFreq(iSubSeqs, 1));
ReCarFreq = unique(S.CarFreq(iSubSeqs, 2));
if (length(LeCarFreq) == 1) && (length(ReCarFreq) == 1)
    StimParam.carfreq = [LeCarFreq, ReCarFreq];
else
    StimParam.carfreq = S.CarFreq(iSubSeqs, :);
end

ModFreq = S.ModFreq(iSubSeqs, :);
if all(isnan(ModFreq(:)))
    StimParam.modfreq = NaN;
else
    StimParam.modfreq = ModFreq;
end

if all(isnan(S.BeatFreq(iSubSeqs)))
    StimParam.beatcarfreq = NaN;
else
    StimParam.beatcarfreq = round(abs(S.BeatFreq(iSubSeqs)));
end

if all(isnan(S.BeatModFreq(iSubSeqs)))
    StimParam.beatmodfreq = NaN;
else
    StimParam.beatmodfreq = abs(S.BeatModFreq(iSubSeqs));
end

if isnan(StimParam.beatcarfreq) & isnan(StimParam.beatmodfreq)
    error('Wrong stimulus in dataset: beatcarfreq and beatmodfreq are NaN.');
end


%The constant frequency can be taken as the frequency of the DSS/channel that was varied or 
%it can be taken as the mean of the frequencies administered at both ears ...
if ~all(isnan(StimParam.beatcarfreq))
	if strcmpi(Param.itdconfreq, 'mean')
		StimParam.freq = mean(StimParam.carfreq, 2)';
	else
		StimParam.freq = StimParam.carfreq(:, 1)';
	end
	StimParam.beat     = StimParam.beatcarfreq';
    if StimParam.carfreq(1,1)<StimParam.carfreq(1,2)
        StimParam.indepval = StimParam.carfreq(:, 1)';
    else
        StimParam.indepval = StimParam.carfreq(:, 2)';
    end
elseif ~all(isnan(StimParam.beatmodfreq))
	if strcmpi(Param.itdconfreq, 'mean')
		StimParam.freq = mean(StimParam.modfreq, 2)';
	else
		StimParam.freq = StimParam.modfreq(:, 1)';
	end
	StimParam.beat     = StimParam.beatmodfreq';
	StimParam.indepval = StimParam.modfreq(:, 1)';
end
[StimParam.inc, StimParam.step] = GetIndepScale(StimParam.indepval); %Logaritmic or linear scale ...
StimParam.isubseqs = iSubSeqs;

%---------------------------------------------------------------------------------------------
function [CellNr, TestNr, StimType] = UnRavelID(dsID)

CellNr = elem(strsplit(dsID,'-'),1);
TestNr = elem(strsplit(dsID,'-'),2);
StimType = elem(strsplit(dsID,'-'),3);

%---------------------------------------------------------------------------------------------
function [Inc, Step] = GetIndepScale(Val, Tol)

if (nargin == 2), Val = round(Val/Tol)*Tol; end
DVal = unique(diff(Val));
if (length(Val) == 1),
    Inc = 'lin';
    Step = Val;
elseif (length(DVal) == 1),  %Linear ...
    Inc  = 'lin';
    Step = DVal;
else, %Logaritmic ...
    Inc  = 'log'; 
    Step = log2(Val(2)/Val(1));
end

%---------------------------------------------------------------------------------------------
function Str = Param2Str(V, Unit, Prec)

C = num2cell(V);
Sz = size(V);
N  = prod(Sz);

if (N == 1) | all(isequal(C{:})), Str = sprintf(['%.'  int2str(Prec) 'f%s'], V(1), Unit);
elseif (N == 2), Str = sprintf(['%.' int2str(Prec) 'f%s/%.' int2str(Prec) 'f%s'], V(1), Unit, V(2), Unit);
elseif any(Sz == 1), 
    Str = sprintf(['%.' int2str(Prec) 'f%s..%.' int2str(Prec) 'f%s'], min(V(:)), Unit, max(V(:)), Unit); 
else, 
    Str = sprintf(['%.' int2str(Prec) 'f%s/%.' int2str(Prec) 'f%s..%.' int2str(Prec) 'f%s/%.' int2str(Prec) 'f%s'], ...
        min(V(:, 1)), Unit, min(V(:, 2)), Unit, max(V(:, 1)), Unit, max(V(:, 2)), Unit); 
end

%---------------------------------------------------------------------------------------------
function [CalcData, CellInfo] = CalcCurve(dsBB, CellInfo, Thr, Param)

%WHAT IS DIFF between Freq and IndepVal ? 

Freq   = Param.freq; %Freq from StimParam
Beat   = round(Param.beat); %beat from StimParam
NFreq  = length(Freq);
Period = 1000./Freq;  %Periods in [ms] 

IndepVal = round(Param.indepval); %indepval from StimParam
iSubSeqs = Param.isubseqs;

%Calculating rate curve. (Save in RATE)
% by Abel: getrate() is obsolete and should be replaced by CalcRATE()
%Rate = getrate(dsBB, iSubSeqs, Param.anwin(1), Param.anwin(2));
calcRate = CalcRATE(dsBB, 'anwin', Param.anwin, 'sort', Param.sort, 'isubseqs', Param.isubseqs, 'IndepVal', IndepVal);
Rate = calcRate.curve.rate;
[Max, idx] = max(Rate); 
BestFreq = IndepVal(idx);
%
RATE.Freq = IndepVal;
RATE.Rate = Rate;
RATE.RMax = Max;
RATE.RBF  = BestFreq;
RATE = lowerFields(RATE);

%Calculating histograms on beatfrequencies. (Save in STIM)
try
	%If the sign of the binaural parameter is stored according standard
	%conventions true is returned, otherwise false is given back.
	[defaultConvention, binParam] = CheckBinParam(dsBB, 'bb', 'sync', Param.sync);	
	FlipSign = ~defaultConvention			                    

	CellInfo.recside    = upper(binParam.RecSide);         %Recording site (userdata), Part of DS info (CellInfo)
	
	%Save in STIM 
	STIM.freqbeat = binParam.beatFreq;
	if strcmpi(binParam.Chan1atEar, 'l')		
		STIM.chanL      = 1;         %Left chanel (userdata)
		STIM.chanR      = 2;         %Right chanel (userdata)
	else
		STIM.chanL      = 2;
		STIM.chanR      = 1;
	end
	
	if isfield(binParam, 'MasteratChanNr')
		STIM.MDSS = binParam.MasteratChanNr;
	else
		STIM.MDSS = nan;
	end
	
		
% 	%for debug
 	Param.ipsiColumnNrInCarFreq = binParam.ipsiColumnNrInCarFreq;
 	Param.contraColumnNrInCarFreq = binParam.contraColumnNrInCarFreq;
	
catch
	warning(lasterr);
	FlipSign = false;
	STIM.chanL = nan;
	STIM.chanR = nan;
	STIM.MDSS = nan;
	Param.ipsiColumnNrInCarFreq = nan;
	Param.contraColumnNrInCarFreq = nan;
end
for n = 1:NFreq, 
    HIST(n) = SGSR_cyclehist(dsBB, iSubSeqs(n), Beat(n), Param.histnbin, Param.anwin(1), Param.anwin(2));
    if FlipSign,
% 		testNoFlip(n) = HIST(n).Ph;
        HIST(n).Ph = 1 - HIST(n).Ph;
        HIST(n).Y  = fliplr(HIST(n).Y);
    end
end

%temporary plot
% if strcmpi(Param.plot, 'yes')
% % 	%flip HIST to have the circles from high to low indepval freq.
% % 	Delay = (-Param.itdmaxlag):Param.itdbinwidth:(+Param.itdmaxlag);
% %  	polarPhColor(fliplr(HIST), 'indepval', fliplr(IndepVal), 'periods', fliplr(Period), 'delay', Delay);
% 	polarPhColor(fliplr(HIST), 'indepval', fliplr(IndepVal));
% end


%Calculating vector strength magnitude and phase curves ...
%Output cyclehist(): HIST.R  -> vector strength magnitude
%                    HIST.Ph -> vector strength phase 
R       = cat(2, HIST.R);
% ??? -> is not completely equal to output of calcVSPHCurve() ?
% !!! Compare to testNoFlip since a flip was not included in calcVSPHCurve
% yet

%WHY *2pi and /2pi? -> was also in old calcVSPH() ? 
% -> same effect as: Ph = Ph + (2*pi);Ph = mod(Ph, (2*pi));
%    ?? In all cases ?? 
Ph      = unwrap(cat(2, HIST.Ph)*(2*pi))/2/pi; %Unwrapping ...
RaySig  = cat(2, HIST.pRaySig);
idxSign = find(RaySig <= Param.vsraysig);
%Ph not in cycles yet? 
% -> divide by stim period (2*pi) to transfer to cycles 


if ~isempty(idxSign) && (length(idxSign) > 1)
    SIndepVal = IndepVal(idxSign);
    MaxR = max(R(idxSign)); 
	BestFreq = min(SIndepVal(find(R(idxSign) == MaxR)));
    
    Wg = R(idxSign).*RATE.rate(idxSign); %Synchronicity Rate is weight-factor ...
    P = linregfit(IndepVal(idxSign), Ph(idxSign), Wg);
    [pLinReg, MSerr, DF] = signlinreg(P, IndepVal(idxSign), Ph(idxSign), Wg);
    
    CD = P(1)*1000; CP = P(2); %Characteristic delay in ms, phase in cycles ...
    CPMod = mod(CP, 1);        %Restrict phase to interval [0,+1[ ...
else
	[MaxR, BestFreq, CD, CP, CPMod, pLinReg, MSerr, DF] = deal(NaN); 
end
VS.Freq    = IndepVal;
VS.R       = R;
VS.Ph      = Ph;
VS.RaySig  = RaySig;
VS.MaxR    = MaxR;
VS.BF      = BestFreq;
VS.CD      = CD;
VS.CP      = CP;
VS.CPMod   = CPMod;
VS.pLinReg = pLinReg;
VS.MSerr   = MSerr;
VS.DF      = DF;
%by Abel: save bincenters and firering rate 
VS.BINS = HIST(1).X;
for n = 1:NFreq, 
	VS.BINRATE(n,:) = HIST(n).Y;
end

VS = lowerFields(VS);

% %by Abel:
% %introduce calcVSPH to calculate vector strength
% %as test we re-calculate here and compare it to the existing method 
% vsNewParam = calcVSPH();
% vsNewParam = updatestruct(vsNewParam, Param, 'skipnontemplate', true);
% vsNewParam.isubseqs = iSubSeqs;
% vsNewParam.phaselinreg = 'weighted';
% vsNewParam.ireps = ExpandiReps(dsBB, iSubSeqs, 'all');
% vsNewParam.binfreq = Beat;
% % vsNewParam.binfreq = ExpandBinFreq(dsBB, 'auto', iSubSeqs)
% vsNew = calcVSPHCurve(dsBB.spt, IndepVal, vsNewParam);

%Calculating ITD curves and composite curve ...
BinCenters     = HIST(1).X;
Delay          = (-Param.itdmaxlag):Param.itdbinwidth:(+Param.itdmaxlag);
[RateP, RateN] = deal(zeros(NFreq, length(Delay)));

%HIST(:).X = bin centers of cyclo histogram (phase in cycles 0-1)
%HIST(n).Y = firering rate at X 

if elem(size(BinCenters),1) ~=1
    BinCenters = BinCenters';
end
for n = 1:NFreq,
    NPeriods = 2*ceil(Param.itdmaxlag/Period(n));
    X = Period(n) * (repmat(BinCenters, 1, (NPeriods/2)) + mmrepeat(0:((NPeriods/2)-1), Param.histnbin));
    X = [-fliplr(X), X];
    if elem(size(HIST(n).Y),1) ~= 1
        HIST(n).Y = HIST(n).Y';
    end
    if elem(size(HIST(n).X),1) ~= 1
        HIST(n).X = HIST(n).X';
    end
    Y = repmat(HIST(n).Y, 1, NPeriods);
    RateP(n, :) = interp1(X, Y, Delay, 'cubic');
    HalfNBin = Param.histnbin/2; %Property histnbin is always assigned an even number ...
    Y = [Y(HalfNBin+1:end), Y(1:HalfNBin)];
    RateN(n, :) = interp1(X, Y, Delay, 'cubic');
end
%If logaritmic scale is used for constant frequencies, then weigthed arithmetic average is used
%to assemble the composite curve ... The frequencies itself are used as weight-factor ...
if strcmpi(Param.inc, 'log')
    SumFreq = sum(Freq);
    CumRate(1, :) = sum(RateP.*repmat(Freq', 1, length(Delay)), 1)/SumFreq;
    CumRate(2, :) = sum(RateN.*repmat(Freq', 1, length(Delay)), 1)/SumFreq;
else
	CumRate = [sum(RateP, 1); sum(RateN, 1)]/NFreq; 
end
DiffRate = -diff(CumRate, 1, 1);

%Taking running average ...
CumRateAv(1, :) = runav(CumRate(1, :), Param.itdrunav);
CumRateAv(2, :) = runav(CumRate(2, :), Param.itdrunav);
DiffRateAv = -diff(CumRateAv, 1, 1);

ITD.Delay    = Delay;
ITD.SupRatep = RateP;
ITD.SupRaten = RateN;
ITD.CumRate  = [CumRate; CumRateAv];
DIFF.Delay   = Delay;
DIFF.Rate    = [DiffRate; DiffRateAv];

%Fast fourier transform on difference composite curve ...
FFT = spectana(Delay, DiffRate, 'runavunit', '#', 'runavrange', 0);

%Determine which dominant frequency to be used in the calculation ...
if ~isempty(Thr)
	DomFreq = DetermineCalcDF(Param.calcdf, Thr.cf, FFT.DF, NaN);
else
	DomFreq = DetermineCalcDF(Param.calcdf, NaN, FFT.DF, NaN); 
end
if (DomFreq ~= 0)
	DomPer = 1000/DomFreq; 
else DomPer = NaN; 
end %Dominant period in ms ...

%Peak ratio on composite curve ...
[ITD.BestItd, ITD.Max] = getmaxloc(Delay, CumRateAv(1, :));
[ITD.Ratio, ITD.Xpeaks, ITD.Ypeaks] = getpeakratio(Delay, CumRateAv(1, :), DomFreq);

%Evaluate running average parameters on enveloppe ...
if strcmpi(Param.envrunavunit, 'ms')
    RunAvTsup = Param.envrunav;
    RunAvNsup = round(Param.envrunav/Param.itdbinwidth);
    RunAvNeff = 2*round(RunAvNsup/2)+1; %Effective number of points overwhich RUNAV.M averages (always odd) ...
    RunAvTeff = RunAvNeff*Param.itdbinwidth;
    Param.envrunav = RunAvNsup;
    RunAvEnvStr = sprintf('%.2fms (%.0f#, %.2fms)', RunAvTsup, RunAvNeff, RunAvTeff);
else
    FracPer    = Param.envrunav;
    if (FFT.DF ~= 0), RunAvTsup = FracPer*DomPer; else, RunAvTsup = NaN; end
    RunAvNsup  = round(RunAvTsup/Param.itdbinwidth);
    RunAvNeff  = 2*round(RunAvNsup/2)+1; %Effective number of points overwhich RUNAV.M averages (always odd) ...
    RunAvTeff  = RunAvNeff*Param.itdbinwidth;
    Param.envrunav = RunAvNsup;
    RunAvEnvStr = sprintf('%.1f#Per (%.0f#, %.2fms)', FracPer, RunAvNeff, RunAvTeff);
end
CellInfo.ccparamstr = strvcat(CellInfo.ccparamstr, sprintf('RunAv(ENV) = %s', RunAvEnvStr));

%Peak ratio and halfheight width on difference curve ...
YDiffEnv = abs(hilbert(DiffRateAv));
if ~isnan(Param.envrunav)
	YDiffEnv = runav(YDiffEnv, Param.envrunav); 
end

DIFF.Env = [YDiffEnv; -YDiffEnv];
DIFF.HH = max(YDiffEnv)/2;
DIFF.HHx = cintersect(Delay, YDiffEnv, DIFF.HH); 
DIFF.HHW = diff(DIFF.HHx);
[DIFF.BestItd, DIFF.Max] = getmaxloc(Delay, DiffRateAv);
[DIFF.Ratio, DIFF.Xpeaks, DIFF.Ypeaks] = getpeakratio(Delay, DiffRateAv, DomFreq);

%Save in structs
FFT.Magn = lowerFields(FFT.Magn); 
FFT = lowerFields(FFT);
ITD = lowerFields(ITD); 
DIFF = lowerFields(DIFF);
STIM = lowerFields(STIM);
%Reorganizing data ...
CalcData = lowerFields(CollectInStruct(RATE, VS, ITD, DIFF, FFT, STIM));
% CalcData.ds = dsBB;
CalcData.param = Param;


% Temp polar plot
% Find delay within one period (after resample)
if strcmpi(Param.plot, 'yes')
% 	PP = [];
% 	for n=1:NFreq
% 		idx = find(Delay >= 0 & Delay <= Period(n)); %range of resampled delay within one period
% 		PP(n).X = Delay(idx)/Period(n); % put back in cycles 
% 		
% 		Y = RateP(n,:);
% 		PP(n).Y = Y(idx);
% 	end
% 	%
% 	% 	%flip HIST to have the circles from high to low indepval freq.
% 	% 	Delay = (-Param.itdmaxlag):Param.itdbinwidth:(+Param.itdmaxlag);
% 	polarPhColor(fliplr(PP), 'indepval', fliplr(IndepVal));
% 	
	polarPhColor(fliplr(HIST), 'freqs', fliplr(Freq), 'runav', Param.polarrunav, 'periods', fliplr(Period), 'gridmax', Param.gridmax, 'gridmin', Param.gridmin, 'logscale', true);
end


%---------------------------------------------------------------------------------------------
function DF = DetermineCalcDF(ParamCalcDF, ThrCF, DifDF, SacDF)

if isnumeric(ParamCalcDF), 
    if ~isnan(ParamCalcDF), DF = ParamCalcDF;
    elseif ~isnan(ThrCF), DF = ThrCF;
    elseif ~isnan(DifDF), DF = DifDF;
    else, DF = SacDF; end
elseif strcmpi(ParamCalcDF, 'cf'), DF = ThrCF;
elseif strcmpi(ParamCalcDF, 'df'), 
    if ~isnan(DifDF), DF = DifDF;
    else, DF = SacDF; end    
else, DF = NaN; end                

%---------------------------------------------------------------------------------------------
function Param = PlotCurve(Type, CalcData, CellInfo, Param, dsBB)
%Start Page
FigHdl = defaultPage(mfilename);

if strcmpi(Type, 'cc') %Superimpose, composite curve and spectrum ...
    %Axis parameters for Delay Curves ...
    [XRange, XStep] = InterpretParam('itdx', Param, CalcData.itd.delay(:));
    
    %Superimpose Curves ...
    AxSIP = axes('Position', [0.10, 0.72, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'XTick', XRange(1):XStep:XRange(2));
    Hdl = line(CalcData.itd.delay, CalcData.itd.supratep, 'LineStyle', '-', 'Marker', 'none', 'LineWidth', 1); 
    title('SuperImpose Curve (+)', 'fontsize', 12);
    xlabel('Delay (ms)'); ylabel('Rate (spk/sec)');
    AxSIN = axes('Position', [0.10, 0.385, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'XTick', XRange(1):XStep:XRange(2));
    Hdl = line(CalcData.itd.delay, CalcData.itd.supraten, 'LineStyle', '-', 'Marker', 'none', 'LineWidth', 1); 
    title('SuperImpose Curve (-)', 'fontsize', 12);
    xlabel('Delay (ms)'); ylabel('Rate (spk/sec)');
    
    %Composite Curve ...
    AxCC = axes('Position', [0.575, 0.72, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'XTick', XRange(1):XStep:XRange(2));
    LnHdl(1) = line(CalcData.itd.delay, CalcData.itd.cumrate(1, :), 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'LineWidth', 1, 'tag', 'ccposorig'); 
    LnHdl(2) = line(CalcData.itd.delay, CalcData.itd.cumrate(3, :), 'LineStyle', '-', 'Color', 'b', 'Marker', 'none', 'LineWidth', 2, 'tag', 'ccposrunav'); 
    LnHdl(3) = line(CalcData.itd.delay, CalcData.itd.cumrate(2, :), 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'LineWidth', 1, 'tag', 'ccnegorig'); 
    LnHdl(4) = line(CalcData.itd.delay, CalcData.itd.cumrate(4, :), 'LineStyle', '-', 'Color', 'g', 'Marker', 'none', 'LineWidth', 1.5, 'tag', 'ccnegrunav'); 
    LnHdl(5) = line(CalcData.itd.xpeaks, CalcData.itd.ypeaks, 'LineStyle', '-', 'Color', 'r', 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 7, 'tag', 'peakratioline');
    LnHdl(6) = line([0 0], ylim, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'verzeroline');
    LnHdl(7) = line(CalcData.itd.bestitd([1 1]), ylim, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'bestitdverline');
    title('Composite Curve', 'fontsize', 12);
    xlabel('Delay (ms)'); ylabel('Rate (spk/sec)');
    text(0, 1, {sprintf('Max = %.0fspk/sec @ %.2fms', CalcData.itd.max, CalcData.itd.bestitd); ...
            sprintf('PeakRatio = %.2f', CalcData.itd.ratio)}, ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
    legend(LnHdl([2, 4, 1]), {'Pos', 'Neg', 'Orig'}, 1);
    
    %DiffCorrelation Curve ...
    AxDIFF = axes('Position', [0.575, 0.385, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'XTick', XRange(1):XStep:XRange(2));
    LnHdl(1) = line(CalcData.diff.delay, CalcData.diff.rate(1, :), 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'LineWidth', 1, 'tag', 'difforig'); 
    LnHdl(2) = line(CalcData.diff.delay, CalcData.diff.rate(2, :), 'LineStyle', '-', 'Color', 'b', 'Marker', 'none', 'LineWidth', 2, 'tag', 'diffrunav'); 
    LnHdl([3 4]) = line(CalcData.diff.delay, CalcData.diff.env, 'LineStyle', '-', 'Color', 'k', 'Marker', 'none', 'LineWidth', 1, 'tag', 'diffenv'); 
    LnHdl(5) = line(CalcData.diff.xpeaks, CalcData.diff.ypeaks, 'LineStyle', '-', 'Color', 'r', 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 7, 'tag', 'peakratioline');
    LnHdl(6) = line([0 0], ylim, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'verzeroline');
    LnHdl(7) = line(CalcData.diff.bestitd([1 1]), ylim, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'betsitdverline');
    LnHdl([8:10]) = plotcintersect(CalcData.diff.hhx, CalcData.diff.hh([1 1]), min(ylim));
    set(LnHdl(8), 'LineStyle', '-', 'Color', 'k', 'Marker', 'none');
    title('Diffcor Curve', 'fontsize', 12);
    xlabel('Delay (ms)'); ylabel('DiffRate (spk/sec)');
    text(0, 1, {sprintf('Max = %.0fspk/sec @ %.2fms', CalcData.diff.max, CalcData.diff.bestitd); ...
            sprintf('PeakRatio = %.2f', CalcData.diff.ratio); ...
            sprintf('HHW = %.2f', CalcData.diff.hhw)}, ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
    legend(LnHdl([2 1]), {'RunAv', 'Original'}, 1);
    
    %Axis parameters for FFT Curve ...
    if strcmpi(Param.fftyunit, 'p')
        YVal = CalcData.fft.magn.p;
        YLbl = 'Power';
	else
        YVal = CalcData.fft.magn.db;
        YLbl = 'Amplitude (dB)';
    end    
    [XRange, XStep] = InterpretParam('fftx', Param, CalcData.fft.freq(:));
    YRange = InterpretParam('ffty', Param, YVal(:));
    
    %FFT on Composite Curve ...
    AxFFT = axes('Position', [0.10, 0.05, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'XTick', XRange(1):XStep:XRange(2), 'YLim', YRange);
    line(CalcData.fft.freq, YVal, 'LineStyle', '-', 'Color', 'b', 'Marker', 'none', 'LineWidth', 1, 'tag', 'curve'); 
    line(CalcData.fft.df([1 1]), ylim, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'verlinedomfreq');
    title('FFT on DifCor', 'fontsize', 12);
    xlabel('Frequency (Hz)'); ylabel(YLbl);
    text(0, 1, {sprintf('DomFreq = %.0fHz', CalcData.fft.df); ...
            sprintf('BandWidth = %.0fHz', CalcData.fft.bw)}, ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
    
    %Additional Information
    AxINFO = axes('Position', [0.575 0.05 0.375 0.235], 'Visible', 'off', 'Box', 'on', 'Color', [0.7 0.7 0.7], ...
        'Units', 'normalized', 'YTick', [], 'YTickLabel', [], 'XTick', [], 'XTickLabel', []);
    TxtHdl = text(0.10, 0.5, char(CellInfo.cellstr, '', CellInfo.ccparamstr, '', CellInfo.stimstr, '', CellInfo.thrstr), ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', ...
        'FontSize', 8, 'FontWeight', 'normal');
else %Rate, raster and vector strength curves ...
    %Axis parameters for Frequency curves ...
    XRange = InterpretParam('freqx', Param, Param.indepval);
    
    %Raster plot ...
    AxRAS = axes('Position', [0.10, 0.72, 0.85, 0.235],  'TickDir', 'out', 'Box', 'off');
    RasHdl = rasplot(dsBB, 'isubseqs', Param.isubseqs, 'axhdl', AxRAS, 'colors', {'k'});
%     set(RasHdl, 'Color', 'k');
    %Restricting maximum number of ticks on Y axis ...
    YTick = get(AxRAS, 'YTick'); NYTicks = length(YTick); YLbls = get(AxRAS, 'YTickLabel');
    if (NYTicks > Param.rasmaxytick),
        Step = diff(YTick([1, 2])); ReqStep = diff(YTick([1, end]))/Param.rasmaxytick;
        N = ceil(ReqStep/Step); NewStep = Step*N;
        NewYTick = YTick(1) + NewStep*(0:Param.rasmaxytick-1);
        NewYTick = NewYTick(find(NewYTick <= YTick(end)));
        NewYLbls = YLbls(find(ismember(YTick, NewYTick)));
        set(AxRAS, 'YTick', NewYTick, 'YTickLabel', NewYLbls);
    end
    
    %Rate Curve ...
    AxRATE = axes('Position', [0.575, 0.385, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange);
    Hdl(1) = line(CalcData.rate.freq, CalcData.rate.rate, 'Color', 'b', 'LineStyle', '-', 'Marker', '.', 'LineWidth', 1, 'tag', 'curve'); 
    Hdl(2) = line(CalcData.rate.rbf([1 1]), ylim, 'Color', 'k', 'LineStyle', ':', 'Marker', 'none', 'LineWidth', 1, 'tag', 'verlinebestfreq'); 
    Hdl(3) = line(CalcData.rate.rbf, CalcData.rate.rmax, 'Color', 'r', 'LineStyle', 'none', 'Marker', '.', 'LineWidth', 7, 'tag', 'markerbestfreq'); 
    title('Rate Curve', 'fontsize', 12);
    xlabel('Freq (Hz)'); ylabel('Rate (spk/sec)');
    text(0, 1, sprintf('Max = %.0fspk/sec @ %.0fHz', CalcData.rate.rmax, CalcData.rate.rbf), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
    
    %Vector strength magnitude plot ...
    AxVSM = axes('Position', [0.10, 0.385, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'YLim', [0 1]);
    Hdl = PlotSign(CalcData.vs.freq, CalcData.vs.r, CalcData.vs.raysig, Param.vsraysig);
    Hdl(2) = line(CalcData.vs.bf([1 1]), ylim, 'Color', 'k', 'LineStyle', ':', 'Marker', 'none', 'LineWidth', 1, 'tag', 'verlinebestfreq'); 
    Hdl(3) = line(CalcData.vs.bf, CalcData.vs.maxr, 'Color', 'r', 'LineStyle', 'none', 'Marker', 'o', 'tag', 'markerbestfreq'); 
    title('Vector Strength Magnitude', 'fontsize', 12);
    xlabel('Freq (Hz)'); ylabel('R');
    text(0, 1, {sprintf('Max = %.2f @ %.0fHz', CalcData.vs.maxr, CalcData.vs.bf), ...
            sprintf('BinFreq = %s (Beat)', Param2Str(Param.beat, 'Hz', 0))}, ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

    %Vector strength phase plot ...
    AxVSP = axes('Position', [0.10, 0.05, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
        'XLim', XRange, 'YLim', [floor(min(CalcData.vs.ph)), ceil(max(CalcData.vs.ph))]);
    Hdl(1) = PlotSign(CalcData.vs.freq, CalcData.vs.ph, CalcData.vs.raysig, Param.vsraysig);
    Hdl(2) = line(xlim, xlim*CalcData.vs.cd/1000+CalcData.vs.cp, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'linelinreg');
    title('Vector Strength Phase', 'fontsize', 12);
    xlabel('Freq (Hz)'); ylabel('Phase (cyc)');
    text(0, 1, {sprintf('CD = %.2fms', CalcData.vs.cd),...
            sprintf('CP = %.2fcyc', CalcData.vs.cp),...
            sprintf('pLinReg = %.3f', CalcData.vs.plinreg),...
            sprintf('MSerr = %.3f', CalcData.vs.mserr),...
            sprintf('BinFreq = %s (Beat)', Param2Str(Param.beat, 'Hz', 0))}, ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

    %Additional Information
    AxINFO = axes('Position', [0.575 0.05 0.375 0.235], 'Visible', 'off', 'Box', 'on', 'Color', [0.7 0.7 0.7], ...
        'Units', 'normalized', 'YTick', [], 'YTickLabel', [], 'XTick', [], 'XTickLabel', []);
    TxtHdl = text(0.10, 0.5, char(CellInfo.cellstr, '', CellInfo.vsparamstr, '', CellInfo.stimstr, '', CellInfo.thrstr), ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', ...
        'FontSize', 8, 'FontWeight', 'normal');
	
end

%---------------------------------------------------------------------------------------------
function [Range, Step] = InterpretParam(Type, Param, Data)

XMargin = 0.0;
YMargin = 0.5;

switch Type,
case 'freqx',
    Margin = XMargin;
    Range = Param.freqxrange;
    Step  = [];
case 'itdx',
    Margin = XMargin;
    Range = Param.itdxrange;
    Step  = Param.itdxstep;
case 'fftx',
    Margin = XMargin;
    Range = Param.fftxrange;
    Step  = Param.fftxstep;
case 'ffty',
    Margin = YMargin;
    Range = Param.fftyrange;
    Step  = [];
end

if isinf(Range(1)), Range(1) = min(Data)*(1-Margin); end
if isinf(Range(2)), Range(2) = max(Data)*(1+Margin); end

if isequal(Range(1), Range(2)), Range = [Range(1)-0.5, Range(1)+0.5]; end
%---------------------------------------------------------------------------------------------
function LnHdl = PlotSign(X, Y, Sign, Thr)

idxNS = find(Sign <= Thr);
% markerFaceColor = repmat({'b'}, 1, length(X));
% markerFaceColor{idxNS} = 'none';
LnHdl = line(X, Y, 'LineStyle', '-', 'Color', 'b', 'Marker', 'o', 'tag', 'curve', 'markerFaceColor', 'none');
%  MrkSize = get(LnHdl, 'MarkerSize') * 3.5;
%  DotHdl = line(X(idxNS), Y(idxNS), 'LineStyle', 'none', 'Color', 'b', 'Marker', '.', 'MarkerSize', MrkSize, 'tag', 'insigndots');
DotHdl = line(X(idxNS), Y(idxNS), 'LineStyle', 'none', 'Color', 'b', 'Marker', 'o', 'tag', 'insigndots', 'markerFaceColor', 'b');

%%TEMP function for additional plot (will be removed when EvalBB is updated
%%to use KPlot)
function Param = tempPlotFunction_(dsBB, CalcData, Param)
%     AxVSP = axes('Position', [0.10, 0.05, 0.375, 0.235],  'TickDir', 'out', 'Box', 'off', ...
%         'XLim', XRange, 'YLim', [floor(min(CalcData.vs.ph)), ceil(max(CalcData.vs.ph))]);
%     Hdl(1) = PlotSign(CalcData.vs.freq, CalcData.vs.ph, CalcData.vs.raysig, Param.vsraysig);
%     Hdl(2) = line(xlim, xlim*CalcData.vs.cd/1000+CalcData.vs.cp, 'LineStyle', ':', 'Color', 'k', 'Marker', 'none', 'tag', 'linelinreg');
%     title('Vector Strength Phase', 'fontsize', 12);
%     xlabel('Freq (Hz)'); ylabel('Phase (cyc)');
%     text(0, 1, {sprintf('CD = %.2fms', CalcData.vs.cd),...
%             sprintf('CP = %.2fcyc', CalcData.vs.cp),...
%             sprintf('pLinReg = %.3f', CalcData.vs.plinreg),...
%             sprintf('MSerr = %.3f', CalcData.vs.mserr),...
%             sprintf('BinFreq = %s (Beat)', Param2Str(Param.beat, 'Hz', 0))}, ...
%         'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

% subplot(2,1,1);
X = CalcData.vs.freq;
Y = [];
for n=1:length(CalcData.vs.ph)
	Y(n) = (CalcData.vs.ph(n)/CalcData.vs.freq(n)) * 1000;	
end

if strcmpi('yes', Param.plot)
	defaultPage(mfilename);
	AxVSP(1) = axes('Position', [0.1, 0.58, 0.8, 0.4], 'TickDir', 'out', 'Box', 'off');
	PlotSign(X, Y, CalcData.vs.raysig, Param.vsraysig);
	xlabel('Freq (Hz)');
	ylabel('Delay (ms)');
    title('Vector Strngth Phase vs Frequency');
end
% Param.vector.delay = Y;

%periode aftrekken
% subplot(2,1,2);
Y = [];
doMin = CalcData.vs.cp >= 0.5;
if doMin
	for n=1:length(CalcData.vs.ph);
		Y(n) = CalcData.vs.ph(n) - 1;
		Y(n) = (Y(n)/CalcData.vs.freq(n)) * 1000;	
	end
else
	for n=1:length(CalcData.vs.ph)
		Y(n) = (CalcData.vs.ph(n)/CalcData.vs.freq(n)) * 1000;
	end
end
Param.vector.time = Y;


if strcmpi('yes', Param.plot)
	AxVSP(2) = axes('Position', [0.1, 0.08, 0.8, 0.4],'TickDir', 'out', 'Box', 'off');
	PlotSign(X, Y, CalcData.vs.raysig, Param.vsraysig);
	ylabel('Delay (ms)');
	xlabel('Freq (Hz)');
end


		




%---------------------------------------------------------------------------------------------