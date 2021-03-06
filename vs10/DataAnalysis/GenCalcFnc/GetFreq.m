function ArgOut = GetFreq(ds, FreqTypeStr)
%GETFREQ get frequency parameters for dataset
%   Freq = GETFREQ(ds, FreqType) returns the frequency of dataset ds given by 
%   FreqType. FreqType must be a character string with the following syntax: the
%   requested frequency, thus 'carrier'(abbreviated as 'fcar') or 'modulation'
%   (or 'fmod'), optionally followed by the side: 'left'(or master), 'right'(or
%   slave), 'both' or 'binbeat' (these last two suffixes for binaural datasets 
%   only). The requested frequency is always returned as a matrix with the number
%   of rows defined by the total number of subsequences in the datasets. The 
%   number of columns depends on the number of active channels for a given dataset
%   and on the requested side. For monaural datasets the frequency is given as a
%   columnvector. For binaural datasets this is only the case if an appropriate site
%   postfix is supplied. Otherwise the matrix has two columns, one for the left
%   channel and the other for the right channel. If requested frequency is not 
%   applicable for a subsequence, then NaN is returned.
%   
%   Freq = GETFREQ(ds) returns a structure with all the frequency parameters for
%   the given dataset. Each field of this structure is a numerical matrix with the
%   number of rows defined by the total number of subsequences and with the same 
%   number of columns as active channels used in the collection of data, except
%   for the beat frequencies which only have one column.

%B. Van de Sande 05-05-2004

if ~any(nargin == [1, 2])
    error('Wrong number of input arguments.');
end
if ~isa(ds, 'dataset')
    error('First argument should be dataset.');
end

if strcmp(ds.Stim.DAC,'Both')
    NChan = 2;
else
    NChan = 1;
end
if strcmp(ds.StimType,'THR')
    [NSub, NSubRec] = deal(length(ds.Stim.Presentation.X.PlotVal));
else
    NSub    = ds.Stim.Presentation.Ncond;
    NSubRec = ds.Stim.Presentation.Ncond;
end

% For SGSR-datasets: the CarFreq and ModFreq fields in the Special-structure of a
% dataset always have the same number of columns as the number of active channels
% used, except if there is no difference between both channels for a frequency.
% If one of the frequency parameters isn't varied then this parameters has
% only one row, otherwise the parameters has the same number of rows as there are
% subsequences in the dataset. If CarFreq or ModFreq isn't used then that parameter
% is set to 0 or [0 0] (depending on the number of active channels). For
% subsequences that weren't recorded the frequency values aren't set to NaN.
% The BeatFreq and BeatModFreq are calculated as the difference of the last column
% minus the first column. For monaural datasets the beatfrequencies are all zero.
%
% For EDF-datasets: the CarFreq and ModFreq fields in the Special-structure of a
% dataset always have the same number of columns as the number of active channels
% used. If one of the frequency parameters isn't varied the this parameters has
% only one row, otherwise the parameters has the same number of rows as there are
% subsequences in the dataset. If CarFreq or ModFreq isn't used then that parameter
% is set to NaN or [NaN, NaN] (depending on the number of active channels). For
% subsequences that weren't recorded the frequency values aren't set to NaN.
% The BeatFreq and BeatModFreq are calculated as the difference of the last column
% minus the first column. If the orginal frequency is NaN then the beatfrequency is
% also NaN. For monaural datasets the beatfrequencies are all zero or NaN.



if strcmpi(ds.StimType,'NRHO') 
  S.ModFreq     = NaN*ones(NSub, NChan);
  S.BeatFreq    = NaN*ones(NSub,NChan);
  S.BeatModFreq = NaN*ones(NSub,NChan);
  S.CarFreq = NaN*ones(NSub,NChan);
elseif isfield(ds.Stim, 'Fcar') && isfield(ds.Stim, 'Fmod')
S = getfields(ds.Stim, {'Fcar', 'Fmod'});
S.CarFreq     = ds.Stim.Fcar(1:NSub,1:NChan);
S.ModFreq     = ds.Stim.Fmod(1:NSub,1:NChan);
elseif isfield(ds.Stim, 'Fcar')
S.ModFreq     = NaN*ones(NSub, NChan);
S.BeatFreq    = NaN*ones(NSub,NChan);
S.BeatModFreq = NaN*ones(NSub,NChan);
S.CarFreq     = ds.Stim.Fcar(1:NSub,1:NChan);
elseif isfield(ds.Stim, 'ModFreq')
S.CarFreq     = NaN*ones(NSub,NChan);
S.ModFreq     = ds.Stim.Fmod(1:NSub,1:NChan);
elseif  isfield(ds.Stim, 'Fcar') && isfield(ds.Stim, 'Fmod')
    S.CarFreq     = ds.Stim.Fcar(1:NSub,1:NChan);
S.ModFreq     = ds.Stim.Fmod(1:NSub,1:NChan);
elseif isfield(ds.Stim, 'Fmod')
    S.CarFreq     = NaN*ones(NSub,NChan);
S.ModFreq     = ds.Stim.Fmod(1:NSub,1:NChan);
end 

if strcmp(ds.Stim.DAC,'Both')== 1 && (~strcmpi(ds.StimType,'NRHO'))
    S.BeatFreq    = abs(S.CarFreq(:,1)-S.CarFreq(:,2));
    S.BeatModFreq = abs(S.ModFreq(:,1)-S.ModFreq(:,2));
else
    S.BeatFreq    = NaN*ones(1,NSub);
    S.BeatModFreq = NaN*ones(1,NSub);
end
S.NChan       = NChan; 
if (nargin == 1)
    ArgOut = S; 
else 
    ArgOut = getFreqFromTypeStr(FreqTypeStr, S);
end
 
%% ParseFreqTypeStr
function Freq = getFreqFromTypeStr(FreqTypeStr, S)

NChan = S.NChan;

Tokens = Words2cell(FreqTypeStr);
NTokens = length(Tokens);

if NTokens == 1
    isexpr = ~ismember(Tokens{1}, {'carrier', 'fcar', 'modulation', 'fmod'});
elseif NTokens == 2
    isexpr = ~ismember(Tokens{1}, {'carrier', 'fcar', 'modulation', 'fmod'}) ...
        || ~ismember(Tokens{2}, {'binbeat', 'both', 'left', 'master', ...
        'right', 'slave'});
else
    isexpr = true;
end

if isexpr
    
    Freq = eval(regexprep(FreqTypeStr, ...
        {'fmod', 'modulation', 'fcar', 'carrier'}, ...
        [repmat({'S\.ModFreq'},1,2), repmat({'S\.CarFreq'},1,2)]));
    
    if (NChan == 2)
        ColNr = getColNr('both');
    else
        ColNr = getColNr('left');
    end
else
    
    if ~any(strcmpi(Tokens{1}, {'carrier', 'fcar', 'modulation', 'fmod'}))
        error('Invalid syntax in frequency expression.');
    end
    if (NTokens == 2) && ~any(strcmpi(Tokens{2}, {'binbeat', 'both', ...
            'left', 'master', 'right', 'slave'}))
        error('Invalid syntax in frequency expression.');
    end
    if (NTokens == 2) && (NChan == 1) && ...
            any(strcmpi(Tokens{2}, {'binbeat', 'both', 'right', 'slave'}))
        error('Requested frequency doesn''t exist for this dataset.');
    end
    
    %Default side indication depends on the number of channels in the dataset ...
    if (NTokens == 1)
        if (NChan == 2)
            Tokens{2} = 'both';
        else
            Tokens{2} = 'left';
        end
    end
    
    if any(strcmpi(Tokens{1}, {'carrier', 'fcar'})) %Carrier frequency ...
        if ~strcmpi(Tokens{2}, 'binbeat')
            FieldName = 'CarFreq';
        else
            FieldName = 'BeatFreq';
        end
    else %Modulation frequency ...
        if ~strcmpi(Tokens{2}, 'binbeat')
            FieldName = 'ModFreq';
        else
            FieldName = 'BeatModFreq';
        end
    end
    
    ColNr = getColNr(Tokens{2});
    Freq = S.(FieldName);
end

Freq = Freq(:, ColNr);

%% getColNr
function ColNr = getColNr(token)
if strcmpi(token, 'binbeat')
    ColNr = 1;
elseif strcmpi(token, 'both')
    ColNr = [1, 2];
elseif any(strcmpi(token, {'left', 'master'}))
    ColNr = 1;
else
    ColNr = 2;
end

%% TailorFreq
function TFreq = TailorFreq(Freq, NChan, NSubRec, NSub)

TFreq = repmat(NaN, NSub, NChan);

if all(Freq(:) == 0) || all(isnan(Freq(:)))
    return;
else
    if size(Freq, 1) > 1
        TFreq(1:NSubRec, 1) = Freq(1:NSubRec, 1);
        TFreq(1:NSubRec, NChan) = Freq(1:NSubRec, end);
    else
        TFreq(1:NSubRec, 1) = Freq(1); 
        TFreq(1:NSubRec, NChan) = Freq(end);
    end
end
