;+
; NAME:
;       GPLOT
;
; VERSION:
;       v07 (2020-10-02)
;
; AUTHOR:
;       M. Zechmeister (IAG)
;
; CALLING SEQUENCE:
;       GPLOT, Arg1, Arg2, Arg3, Arg4, ..., Arg12
;
; PURPOSE:
;       Pipes the input to gnuplot.
;
; INPUTS:
;       Arg1:   Data or plot command string
;
; KEYWORD PARAMETERS:
;       K:      Port unit number
;               k = -1  prints to stdout instead to pipe
;       TMP:    Temporary file (default 'gptmp')
;       SPF:    Special filename (equivalent to tmp='-')
;               pipes data without temporary file
;               zoom only partly supported
;       PL:     Prepended string (default: 'pl ')
;       BIN:    output files as binary files instead of ascii
;               (advantage binary:
;                 smaller file sizes
;                 speed improvement, but only ~20% for large files
;                 NANs handled similar as in IDL plot)
;
; EXAMPLES:
;       gplot, pl='set xlabel "Time"'
;       gplot, findgen(45), cos(findgen(45)/10), " t''", /spf
;       gplot, '"~/programs/GLS/GJ1046.dat" w e', n=1
;       x = findgen(45) & gplot, x, cos(x/10), 0.2*sin(x/10), " w e t''"
;
; ISSUES:
;       problem with mouse focus
;       solution see: http://objectmix.com/graphics/139281-control-gnuplot-via-popen-how-get-focus-back-caller-2.html
;       http://comments.gmane.org/gmane.comp.graphics.gnuplot.devel/5282
;
;       special filename reads from stdin and will not work with replot in ogplot
;-

function GPINIT, N, INFO=info, VERSION=version
common gplotc, gpunit, gpversion
; initialise the pipe
if keyword_set(info) then return, gpunit
if n_elements(gpunit) EQ 0 then gpunit = [{n:-1, unit:-1L}]   ; init with STDOUT (should be always open)
if not keyword_set(n) then n = 0          ; default window 0

num = where(n EQ gpunit.n, compl=other)   ; check if window exists

if num LT 0 OR ~(FSTAT(gpunit[num>0].unit)).OPEN then begin   ; check if pipe is still open and hopefully still the same; remove from list
   ; GETENV('LD_PRELOAD')
   spawn, 'gnuplot --version', version
   gpversion = float((strsplit(version,/extr))[1])
   setenv, 'LD_PRELOAD='                        ; prevents xli1o error
   spawn, 'gnuplot', UNIT=UNIT, /noshell        ; create plot window
   gpunit = [gpunit[other], {n:n, unit:unit}]   ; add to known list, delete if not open
   num = where(n EQ gpunit.n)
   if file_test('~/zoom.gnu') then printf, unit, 'load "~/zoom.gnu"'
   defsysv, '!noflush', 0
   defsysv, '!og', -1
endif
version = gpversion
return, gpunit[num].unit
end


pro OGPLOT, Arg1,Arg2,Arg3,Arg4,Arg5,Arg6,Arg7,Arg8,Arg9,Arg10,Arg11,Arg12, _EXTRA=_extra, PL=pl
   GPLOT, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12, _extra=_extra, pl="repl "
end

pro GSPLOT, Arg1,Arg2,Arg3,Arg4,Arg5,Arg6,Arg7,Arg8,Arg9,Arg10,Arg11,Arg12, _EXTRA=_extra, PL=pl
   GPLOT, arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12, _extra=_extra, pl="spl "
end


pro GPLOT, Arg1,Arg2,Arg3,Arg4,Arg5,Arg6,Arg7,Arg8,Arg9,Arg10,Arg11,Arg12, K=k, TMP=tmp, SPF=spf, SPLOT=spl, PLOT=pl, NOFLUSH=noflush, SET=set, RESET=reset, UNSET=unset, PRINT=print, BIN=bin, _extra=_extra

on_error, 2

if ~n_params() && ~n_elements(pl) && ~n_elements(set) && ~n_elements(print) && ~n_elements(reset) && ~n_elements(unset) && ~n_elements(_extra) then begin   ; output gplot.pro documentation
   DOC_LIBRARY, 'gplot'
   return
endif

unit = GPINIT(k, version=version)   ; initialise
buf = ''
if not keyword_set(tmp) then tmp = 'gptmp'
if keyword_set(spf) then tmp = '-'
if keyword_set(spl) then pl = 'spl ' + (spl eq '1'? '' : spl)
if not keyword_set(pl) then pl = ~n_params()? '' : 'pl '
if keyword_set(print) then pl = string('print ', print)
if keyword_set(set) then pl = 'set ' + set
if keyword_set(unset) then pl = 'unset ' + unset
if keyword_set(reset) then printf, unit, 'reset'   ; reset immediately, other arguments can be processed
if pl ne 'repl ' then !og = -1
if pl eq 'repl ' and !noflush then pl = ','   ; used by OGPLOT
_flush = keyword_set(noflush)? '\' : ''
defsysv, '!noflush', keyword_set(noflush)

for i=0,n_tags(_extra)-1 do $
    gplot, set=strlowcase((tag_names(_extra))[i]), ' ', _extra.(i)

for i=1,n_params()+1 do begin
   ; arg = i le n_params()? SCOPE_VARFETCH('arg'+strtrim(i,2)) : _flush
   arg = i le n_params()? (n_elements(SCOPE_VARFETCH('arg'+strtrim(i,2))) gt 0? SCOPE_VARFETCH('arg'+strtrim(i,2)) : '') : _flush ; check if arg really exists and fetch it
   if size(arg,/tn) EQ 'STRING' and n_elements(arg) eq 1 then begin   ; pipe an expression
      if n_elements(data) gt 0 then begin
         tmpname = tmp
         opt = ''
         if tmp eq '-' then begin
            buf = transpose(string(buf,transpose(data),'e'))
         endif else begin
            tmpname += strtrim(++!og,2)
            openw,  ounit, tmpname, /get_lun, WIDTH=~keyword_set(bin)?100000:0
            if ~keyword_set(bin) then $
               printf, ounit, transpose(data) $ ;, FORM='(2F20.8)'
            else begin
               opt = " binary format='%"
               writeu, ounit, transpose(data)
               type = size(data, /type)
               sz = size(data, /dim)
               nn = size(data, /n_dim)
               type=(['UNDEFINED','BYTE','int16','int32','float32','float64','COMPLEX','STRING','STRUCT','DCOMPLEX','POINTER','OBJREF','uint16','ULONG','LONG64','ULONG64'])[type]
; Type Code Type Name Data Type
; 0 UNDEFINED Undefined
; 1 BYTE Byte
; 2 INT Integer
; 3 LONG Longword integer
; 4 FLOAT Floating point
; 5 DOUBLE Double-precision floating
; 6 COMPLEX Complex floating
; 7 STRING String
; 8 STRUCT Structure
; 9 DCOMPLEX Double-precision complex
; 10 POINTER Pointer
; 11 OBJREF Object reference
; 12 UINT Unsigned Integer
; 13 ULONG Unsigned Longword Integer
; 14 LONG64 64-bit Integer
; 15 ULONG64 Unsigned 64-bit Integer
               ;sz = ' array=('+strjoin(sz,",")+')'
               opt += (nn gt 1? strtrim(sz[1],2):"") +type+"'"        ; prepend number of columns
               if nn eq 1 then  opt += ' array=('+strtrim(sz[0],2)+')'  ; workaround for vectors (otherwise %float is handled as %float%float and 1:2)

            endelse
            free_lun, ounit   ; closes also tmpname
         endelse
         pl += "'"+tmpname+"'" + opt
         del = size(temporary(data))   ; delete data
      endif
      pl += arg
   endif else if n_elements(arg) gt 0 then $
      data = n_elements(data) eq 0? arg : [[data],[arg]]
endfor

printf, unit, pl

if tmp eq '-' then printf, unit, buf
; error: gplt_x11.c: buffer overflow in read_input!
; occurs when function title gets to long (esp. when autoti)
if version eq 4.6 and ~!noflush then printf, unit, ''   ; append a newline to workaround a gnuplot pipe bug
; with mouse zooming (see http://sourceforge.net/p/gnuplot/bugs/1203/)
end

