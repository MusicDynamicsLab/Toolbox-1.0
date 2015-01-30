%% stimulusMake
%  STIMULUSMAKE
%  Make a stimulus structure, which will include a time vector,
%  signal vector, and other values for NLTFT toolbox use.
%
%  s = stimulusMake(type, varargin)
%  type      = 'fcn', 'wav', 'mid'
%  Required varargins for type 'fcn':
%  ts        = time-span [starttime, stoptime]
%  fs        = sampling rate
%  carrier   = {'cos'}, {'sin'}, {'exp'}, {'saw'}, {'squ'}, {'noi'}
%  fc        = frequency of the carrier
%  ac        = amplitude of the carrier
%  s = stimulusMake('fcn', ts, fs, carrier, fc, ac)
%
%   Examples:
%   s = stimulusMake('fcn', ts, fs, carrier, fc, ac)
%   s = stimulusMake('wav', filename, ts {optional}, fs {optional})
%   s = stimulusMake('mid', filename, ts {optional}, fs {optional})
%   s = stimulusMake('mid', nmat, ts{optional}, fs {optional}) %where 'nmat'is a valid Midi Toolbox-style midi matrix.
%   s = stimulusMake('rfcn', ts {optional}, fs {optional}, numer, denom, mType, mCode, 'tempo_mod' {optional}, {optional canonMake params})
%   %see help for canonMake for a description of numer, denom, mType, and mCode as well as optional params.
%
%
%  12/13/11 KDL
%  Added serveral options to type 'fcn' for waveforms, modulators, and input syntax.
%  Syntax: First five inputs are same as always (after 'fcn' of course):
%  Timespans matrix, samp freq, waveforms, freqs, amps.
%
%  'noi' is also an option now for carrier waveform, for white noise.
%  Freqs still need to be entered but it doesn't matter what they are.
%
%  Optional is now also a starting phase vector or matrix as a sixth varargin,
%  same format as other varargins, 1st dim is timespans, 2nd is components of
%  each of those ts's. Also there are many other optional varargins now, all
%  discussed below. They can come in any order after either amps or starting
%  phases varargin. There is also a lot of error catching now to let user know
%  what was incorrectly passed. There is also a lot of generalization now with
%  repmat, etc., so that only one waveform, one freq, etc., need to be entered
%  if they should be repeated. So if there are mult time courses spec'd but
%  only one freq time course spec'd (maybe with mult components), this complex
%  is copied for all spec'd time courses, and this freq matrix is now the
%  master matrix that all others will refer to for repmat'ing. So if for amps,
%  waveforms, etc., or any other params for other varargins, there is only a
%  single value passed, it is copied for all components and all time courses.
%  If a vector is passed but freqs is a matrix, it is repmat'ed, and a warning
%  is given. If any lengths passed ~=1 and ~=those of freqs, appropriate
%  errors are given.
%
%  White noise is also now an option for waveform of carrier: 'noi'
%  This can be filtered as described below.
%
%  fm: Pass 'fm' and next THREE varargs are waveform(s), freq(s) and amp(s) of
%  modulator. All are required, but same repmat stuff applies as above. This
%  ode was already in stimulusMake and stimulusFcn, so nothing changed except
%  how it's entered in stimulusMake, i.e., anywhere after first five varargs,
%  and with tag 'fm'. Waveforms can be 'cos' 'saw' or 'squ'
%
%  am: Pass 'am' and next FOUR varargs are waveform(s), freq(s), amp(s) and amp(s) of
%  carrier. Amp corresponds to "depth" of modulation, and the fourth vararg
%  corresponds to A in (A + cos(wm*t))*sin(wc*t). This should usually be one
%  if carrier component is desired. If only sidebands are desired, this should
%  be zero. Waveforms can be 'cos' 'sin' 'saw' or 'squ'
%
%  ramp: Pass 'ramp'and next TWO varargs are same as the ramp as described above: length
%  of ramp, up and down, in ms, and power law number. This second vararg should
%  be one for linear ramp, two for quadratic, .5 for sqrt function, etc. As
%  before, defaults are 100 and 1 if nothing is spec'd.
%
%  mask: Pass 'mask' and next ONE varag is a scalar, vector or matrix (with repmat'ing
%  same as above) of SNR's, in dB, of white mask noise over stimulus time
%  courses. This can be filtered as described below. So, e.g.,
%  ...'mask',[0 ; 100],...will compare your two stim time courses so that
%  the first is masked one to one with noise, and the second is effectively not
%  masked, since 100 dB of signal over noise is not much. Negative numbers of
%  course give more noise than signal.
%
%  iter: Pass 'iter' and next TWO varargs are length in ms of delay, and number of
%  iterations of the delay-and-add process. This is mostly for noise, but should
%  work for other functions. This can currently only do what Yost et al. (1996)
%  call "IRNS", "add-same", which adds sequentially, as opposed to "IRNO",
%  "add-original", which adds the original waveform to the subsequent ones every
%  time. There is not a huge difference between these.
%
%  filtstim: Pass 'filtstim' and next ONE vararg is an m-by-2 array where m is number of
%  time courses in stim. Each 2-element row in the array are filter coefficient
%  vectors b and a, respectively, which will go to MATLAB's filter(). Repmat'ing
%  applies if there is more than one time course but only one filter is specified.
%  Use ...;[] [];... to not filter a time course.
%
%  filtmask: Same exact situation as filtstim except we filter the mask noise here instead
%  of the stim.
%
%  Note: if including time span and sample rates, they must always be 1st and 2nd args
%  respectively, sample rate cannot be the first argument
%

%%
function s = stimulusMake(type, varargin)


%% Call relevant 'make' function

switch type
    case 'fcn'
        s = makeFcnInput(varargin{:});
    case 'wav'
        s = makeWaveInput(varargin{:});
    case 'mid'
        s = makeMidiInput(varargin{:});
    case 'rfcn'
        s = makeRfcnInput(varargin{:});
    otherwise
        error('unknown stimulus type');
end

%Fields for all types
%MS1 - added 12/19/08
s.useDirectIndex = 0; %used in stimulusRun
s.lenx = length(s.x);
s.inputType = '1freq';
s.dStep = 0;
s.dispChan = 1;

for i = 1:length(varargin)
    if strcmpi(varargin{i},'inputType') %&& length(varargin) > i && ischar(varargin{i+1})
        s.inputType = varargin{i+1};
    end
    if strcmpi(varargin{i},'display') %&& length(varargin) > i && ischar(varargin{i+1})
        s.dStep = varargin{i+1};
    end
    if strcmpi(varargin{i},'displayChannel') %&& length(varargin) > i && ischar(varargin{i+1})
        if ismember(varargin{i+1}, 1:size(s.x,1))
            s.dispChan = varargin{i+1};
        else
            error('not available stimulus channel')
        end
    end
end

s.x = castCS(s.x);

%% Make type 'function'
function s = makeFcnInput(varargin)

s.type = 'fcn';

if length(varargin) < 5
    error('Need at least 5 inputs for fcns: time spans, sampling freq, carrier waveforms, carrier freqs, and carrier amplitudes')
end

s.analytic = 1;
s.ts = varargin{1};         % time spans
s.fs = varargin{2};         % sampling frequency
s.dt = 1/s.fs;
s.carrier = varargin{3};    % carrier waveforms
s.fc = varargin{4};         % carrier frequencies
s.ac = varargin{5};         % carrier amplitudes
s.sc = .02;                 % ramp time in sec of beginning and end of stim timecourses
s.sp = 1;                   % ramp strength exponent, ie, larger than 1, sudden onset, smaller than one, gradual

s = stimulusParser(s, varargin{:});

s.N  = 1;
s.t  = min(min(s.ts)):s.dt:max(max(s.ts));
s.x  = zeros(size(s.t));

for a = 1:size(s.ts,1)                % For each section of the signal
    t0n = find(s.t <= s.ts(a,1), 1, 'last' );
    tfn = find(s.t <= s.ts(a,2), 1, 'last' );
    %     t  = s.t(t0n:tfn);
    t  = s.t(1:tfn-t0n+1);
    
    temp = stimulusFcn(t, s, a);  %quicker to write temp vector than keep indexing into s.x
    
    if any(s.sc) && ~strcmp(s.carrier{1}, 'pls') %kludgy but works for now
        temp = stimulusRamp(temp, s.sc(a), s.sp(a), s.fs);
    end
    
    if isfield(s, 'filtstim') && ~isempty(s.filtstim{a,1}) && ~isempty(s.filtstim{a,2})
        temp = filter(s.filtstim{a,1},s.filtstim{a,2},temp);
    end
    
    if isfield(s, 'mask')
        noise = zeros(size(temp));
        for i = 1:length(temp)
            noise(i) = rand*2 - 1;
        end
        if isfield(s, 'filtmask') && ~isempty(s.filtmask{a,1}) && ~isempty(s.filtmask{a,2})
            noise = filter(s.filtmask{a,1},s.filtmask{a,2},noise);
        end
        noise = noise * (1/rms(noise)) * 10^(-s.mask(a)/20) * rms(temp);    %interpret noise input as SNR in dB with reference to stim

        noise = stimulusRamp(noise, s.sc(a), s.sp(a), s.fs);
        temp = temp + noise;
    end
    
    s.x(t0n:tfn) = temp;            %write temp vector to approp. part of s.x
    
end

if isfield(s, 'maskall')
    noise = zeros(size(s.x));
    for i = 1:length(s.x)
        noise(i) = rand*2 - 1;
    end
    if isfield(s, 'filtmaskall') && ~isempty(s.filtmaskall{1}) && ~isempty(s.filtmaskall{2})
        noise = filter(s.filtmaskall{1},s.filtmaskall{2},noise);
    end
    noise = noise * (1/rms(noise)) * 10^(-s.maskall/20) * rms(s.x);
    
    noise = stimulusRamp(noise, s.sc(1), s.sp(1), s.fs);
    s.x = s.x + noise;
end

%% Make type 'wave'

function s = makeWaveInput(varargin)

s.type = 'wav';

s.analytic = 0;

if iscell(varargin{1})           % If multiple wavreads
    
    for numRead = 1:length(varargin{1})
        
        s.fn{numRead} = varargin{1}{numRead};
        
        [temp s.fs] = wavread(s.fn{numRead});
        
        temp = sum(temp,2) / size(temp,2);
        
        s.x(:,numRead) = temp;
        
    end
    
else                             % else one wavread
    
    s.fn = varargin{1};
    
    [s.x s.fs] = wavread(s.fn);
    
end

s = stimulusParser(s, varargin{:});      % Parse attributes and values

s.dt = 1/s.fs;
s.t  = linspace(s.ts(1),s.ts(2),size(s.x,1));

s.x  = s.x';                     % Transpose because toolbox expects row vector(s)


%% Make type 'midi'

function s = makeMidiInput(varargin)

s.type = 'mid';

s.analytic = 0;
s.fn   = varargin{1};

%Parse data input type. Filename or nmat matrix
if ischar(s.fn)
    N = mdlreadmidi(s.fn);
else
    %user passed in a nmat matrix directly
    N = s.fn;
end

% Set default values for optional arguments
N_orig = N; %for storing the original unaltered matrix
N = N(N(:,4)>0, :); %Likely uncecessary, but in previous version -DH

s.ts = [];
s.fs = 160; %Default presumes rhythm file
num_stim_chans = 1;
stim_chan_map = [];
melody = 0;
out_type = {'pls'};

% Parse arguments
for i=2:nargin
    if ischar(varargin{i}) 
        switch varargin{i}
            case 'tempo_mod'
                if (i+1)<=length(varargin) && iscell(varargin{i+1})
                    mmr_vararg = varargin{i+1};
                    [N, ~, ~, ~] = moduRhythm(N, mmr_vararg{:});
                else
                    [N, ~, ~, ~] = moduRhythm(N);
                end
            case 'chan_per_note' % can only do one type, if both first will be overwritten
                if (i+1)<=length(varargin) && isnumeric(varargin{i+1})%upper and lower bounds - midi notes
                    num_stim_chans = varargin{i+1}(2) - varargin{i+1}(1) + 1;
                    midi_notes = (varargin{i+1}(1):varargin{i+1}(2));
                else
                    unique_notes = unique(N(:,4));
                    hi_note = max(unique_notes);
                    lo_note = min(unique_notes);
                    num_stim_chans = hi_note - lo_note + 1;
                    midi_notes = (lo_note:hi_note);
                end

                stim_chan_map = containers.Map(midi_notes, (1:num_stim_chans));
                %stim_chan_map_keys = midi_notes;
                col_ind = 4;
            case 'chan_per_chan'% can only do one type, if both first will be overwritten
                unique_midi_chans = unique(N(:, 3));
                num_stim_chans = length(unique_midi_chans);
                stim_chan_map = containers.Map(unique_midi_chans, (1:num_stim_chans));
                col_ind = 3;
                midi_notes = [];
            case 'melody'
                melody = 1;
                out_type = {'sin'};
                midi_note2freq_map = 440*pow2((-68:59)*1/12);
%             otherwise
%                 s.x=0;
%                 error('Unknown argument')
        end
    elseif i == 2 %error check that not text (&& ~ischar())
        s.ts   = varargin{2};
    elseif i == 3 && isnumeric(varargin{2}) %can't update i within loop
        s.fs   = varargin{3};
    end
end

s.dt = 1/s.fs;

s.N  = 1; %?

%  Melodic or Pulse stimulus set time parameters
%  If pulse stim, set all note durations to equal value.  If melodic stim,
%  set the sample rate to 10 times the highest frequency in the stim.
if melody == 0
    %pulse duration
    N(:, 7) = .12*ones(1, length(N(:, 7)));
elseif ~isempty(stim_chan_map) && ~isempty(midi_notes)%Need to be this high if highest frequency is empty? Only do by truly highest?
    %10 * Nyquist
    s.fs = 10*2*midi_note2freq_map(midi_notes(end));
else
    unique_notes = unique(N(:,4));
    hi_note = max(unique_notes);
    %10 * Nyquist
    s.fs = 10*2*midi_note2freq_map(hi_note);
end

%  Set time limits and create time (per sample) array
%  If time limits are set, sort the nmat matrix in order of note onset time
%  and remove or truncate all notes the are on past the off time.
if ~isempty(s.ts)
    s0 = floor(s.ts(  1)*s.fs);
    sf = floor(s.ts(end)*s.fs);
    n  = s0:1:sf;
    s.t = n/s.fs;
    Ntmp = sortrows(N, 6);
    Ntmp = Ntmp(Ntmp(:,6)<s.ts(end), :);
    N = Ntmp(Ntmp(:,6)>s.ts(1), :);
    too_long_note_rows = find((N(:,6)+N(:,7))>s.ts(end));

    for i=1:length(too_long_note_rows)
        N(too_long_note_rows(i),7) = s.ts(end) - N(too_long_note_rows(i),6);
    end
else
    s0 = 0;
    sf = floor( max(N(:,6)+N(:,7))*s.fs );
    s.ts = [s0 sf]/s.fs;
    n  = s0:sf;
    s.t = n/s.fs;
end

% Eliminate notes under 50ms to get rid of ramp time error and warnings
% especially for notes near the end of the time span likely to be truncated
N = N(N(:,7) >= 0.05, :);
final_note_ind = size(N,1);

if isempty(stim_chan_map) %ignore midi channels
    N(:, 3) = ones(1, length(N(:, 3)));
else
    %replace midi channel with stimulus channel
    for j = 1:length(N(:, 3))
        tmp = values(stim_chan_map, num2cell(N(j,col_ind)));
        N(j,3) = tmp{1}; %not vectorized because mapped output is a cell
    end
end

% If creating a melodic stimulus get frequencies for tone synthesis
if melody ~= 0 
    freq = midi_note2freq_map(N(:,4)+1);
else
    freq = 1./N(:,7);
end

% Allocate output array and synthesize each pulse or tone (loop)
O  = zeros(num_stim_chans, length(s.t));

for n = 1:final_note_ind

    stim_chan = N(n, 3);
    note_on = round(N(n,6)*s.fs) - s0;
    
    note = makeFcnInput([0 (N(n,7)-s.dt)], s.fs, out_type, freq(n), N(n,5)/127/4); %max velocity is 127, 1/4 is legacy -DH
    xb = note.x;
    %required because makeFcnInput sometimes returns .x one sample short
    note_off = note_on+length(xb);

    O(stim_chan, (note_on:note_off-1)+1) = O(stim_chan, (note_on:note_off-1)+1) + xb;
end


s.Notes = N_orig;

a = max(1,abs(hilbert(O)));
s.x = O./a;




%% Make Rhythm Function
%  Calls canonMake and creates a time series stimulus from the matrix.
%  For now, cannot enter a sample rate without time span.
function s = makeRfcnInput(varargin)
    
    s.type = 'rfcn';
    s.analytic = 0;
    
    s.ts = [];
    s.fs = 100;
    
    if numel(varargin{1}) == 2 %it's a time span
        s.ts = varargin{1};
        varargin(1) = [];
        if varargin{1} >= 50 %presume sample rate and not time sign numerator, can likely be higher ask Ed lowest used for rhythms
            s.fs = varargin{1};
            varargin(1) = []; 
        end
    end
    
    s.dt = 1/s.fs;
    s.N  = 1;
    
    temp_mod = 0;
    for i=5:length(varargin)
        if strcmp(varargin{i}, 'tempo_mod') %note its value needs to be cell array of....
            temp_mod = 1;
            varargin(i) = [];
            %to not have any values need to check if next value is numeric
            if i<=length(varargin) && iscell(varargin{i})
                mod_args = varargin{i};
                varargin(i) = [];
            else
                mod_args = [];
            end
            break
        end
    end
    
    if length(varargin) > 4
        N = canonMake(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5:end});
    else
        N = canonMake(varargin{1}, varargin{2}, varargin{3}, varargin{4});
    end
    
    if temp_mod
        if isempty(mod_args)
            [N, ~, ~, ~] = moduRhythm(N);
        else
            [N, ~, ~, ~] = moduRhythm(N, mod_args{:});
        end
    end
    
    N(:, 7) = .12*ones(1, length(N(:, 7)));
    freq = 1./N(1,7);
    
    if ~isempty(s.ts)
        s0 = floor(s.ts(  1)*s.fs); 
        sf = floor(s.ts(end)*s.fs);
        n  = s0:1:sf;
        s.t = n/s.fs;
        Ntmp = sortrows(N, 6);
        Ntmp = Ntmp(Ntmp(:,6)<s.ts(end), :);
        N = Ntmp(Ntmp(:,6)>s.ts(1), :);
        too_long_note_rows = find((N(:,6)+N(:,7))>s.ts(end));

        for i=1:length(too_long_note_rows)
            N(too_long_note_rows(i),7) = s.ts(end) - N(too_long_note_rows(i),6);
        end
    else
        s0 = 0;
        sf = floor( max(N(:,6)+N(:,7))*s.fs );
        s.ts = [s0 sf]/s.fs;
        n  = s0:sf;
        s.t = n/s.fs;
    end
    
    N = N(N(:,7) >= 0.05, :);
    final_note_ind = size(N,1);
    NMAT = N;
    
    O  = zeros( 1, length(s.t));

    for n = 1:final_note_ind
        note_on = round(N(n,6)*s.fs) - s0;

        note = makeFcnInput([0 (N(n,7)-s.dt)], s.fs, {'pls'}, freq, N(n,5)/127/4); %max velocity is 127, 1/4 is legacy -DH
        xb = note.x;
        %required because makeFcnInput sometimes returns .x one sample short
        note_off = note_on+length(xb);
        %this summation for overlapping notes necessary for canonMake
        %output?
        O((note_on:note_off-1)+1) = O((note_on:note_off-1)+1) + xb;
    end
%time span initial beat mihgt be cut off

    s.Notes = N;
    a = max(1,abs(hilbert(O)));
    s.x = O./a;   


%% Revision history
%
%  09/26/11 KDL Wrote stimulusRamp.m function, added functionality in here, for fcn's.
%              Default values are 100 milliseconds for each ramp, linear. These can be
%              specified: Pass length in ms of ramps and exponent of strength as two
%              variables AFTER all the carrier stuff OR at the end of the modulator
%              stuff if using that. Affective for each individual timecourse. Must pass
%              both values or neither. So pass 0, 0 to NOT use this.
%  09/26/11 KDL Also added functionality for stimulusRamp for type 'wav'. Default values 
%              are 50 ms and linear, but have not incorporated varargin's yet.
%
%  04/04/12 KDL Offloaded all error checking, repmat'ing, etc. to a new function,
%               stimulusFcnParser. Now code is MUCH cleaner in here.
%
%  06/25/14 DH  added rfunc and tempo modulation to midi
