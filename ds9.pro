pro ds9show, filename=filename, _extra=_extra
    ; for jupyter
    ; makes only shapshots

    on_error, 2
    compile_opt strictarr    ; https://stackoverflow.com/questions/64500086/idl-lambda-attempt-to-subscript-is-out-of-range/64500220#64500220; otherwise IDL_BASE64 is interpreted as variable
    addpath, '/opt/USW/harris/idl86/lib/'   ; idl_base64 needs idl7.1

    if not keyword_set(filename) then filename = "ids9tmp.png"
    ds9, tcl="exec import -window [winfo id .] "+filename, _extra=_extra
    ;print, file_test('ids9tmp.png'), file_test('ids9trmp.png', /ZERO_LENGTH)
    wait, 0.1
    print, "<html><img src='data:image/png;base64,"+IDL_BASE64(READ_BINARY(filename))+"'/></html>"
end



pro DS9, Data, Opt, PORT=port, FRAME=frame, LASTFRAME=lastframe, RESET=reset, OBJ=obj, MSK=msk, TMPFILE=tmpfile, CUBE=kwcube, MOSAIC=kwmosaic, CLEAR=clear, _extra=kwargs
;+
; NAME:
;       DS9
;
; VERSION:
;       v09 (2016-12-19)
;
; PURPOSE:
;       Display with ds9 an array or a fits file.
;
; AUTHOR:
;       M. Zechmeister
;
; CALLING SEQUENCE:
;       DS9, [Data] [, Opt]
;
; OPTIONAL INPUT KEYWORDS:
;       Data:   Array or fits file or empty string (access current frame)
;       Opt:    List of options piped to ds9
;       port:   A named port for an open pipe (address for xpa)
;       frame:  Writes to this frame number
;       lastframe:  Overwrites the last frame
;       obj:    Append an OBJECT keyword
;               (overcomes the shortcoming that ds9 does not use the
;               OBJECT keyword from primary HDU when displaying extension)
;       tmpfile:  Keyword for data transmission
;                 '-' (default and experimental) uses a pipe to transmit data instead of file
;       /TMPFILE:  tmpfile='tmp.fits'
;
; EXAMPLES:
;       IDL> ds9, dindgen(10,10), port='idl', obj='10x10'
;
;       Any keyword is transformed into a xpa argument
;
;       IDL> ds9, cmap='bb'
;       IDL> ds9, scale=['log', 'mode 90']
;       IDL> ds9, sin(dindgen(100,100)*0.005), zoom='to 4'
;       IDL> ds9, '../data_prod/harps_red/harps_red.flat.fits', ["cmap Heat", "cmap invert yes"], port="REDUCE"
;       IDL> ds9, '../data_prod/harps_red/harps_red.flat.fits', "cmap Heat -cmap invert yes"
;       IDL> ds9, '../data_prod/harps_red/harps_red.flat.fits ../data_prod/harps_red/harps_red.flat.fits -cmap Heat -cmap invert yes' ; only for the start
;
; SEE ALSO:
;      ods9
;
; NOTES:
;    any other keyword is transformed in
;    ds9.pro requires ds9 and xpa
;    define path to xpa
;    xpabin="/home/raid0/zechmeister/programs/fv5.3/xpabin/"
;    better: in ~/.bashrc
;    export PATH=$PATH:/home/raid0/zechmeister/programs/fv5.3/xpabin/
;
;    Using pipe for data transmission is now default, but might be instable.
;    pipe does not work in fl on startup
;-

   if keyword_set(msk) then begin
      msk2reg, msk, err=err
      if ~keyword_set(err) then begin
         optn = ['regions msk.reg']
         opt = ~n_elements(opt)? optn : [opt, optn]
      endif
   endif

   ds9 = getenv('newds9') + 'ds9'

   if ~keyword_set(data) then $
      tmpfile = '' $  ; no data
   else if size(data,/tn) eq 'STRING' then $
      tmpfile = data $ ; save the string
   else if keyword_set(tmpfile) && string(tmpfile) ne '-' then begin
      ; from data create a temporary fits file
      tmpfile = 'tmp.fits'
      writefits, tmpfile, data
   endif else begin
      tmpfile = '-'   ; pipe
      dim = 'dim='+strtrim(size(data,/dim),1)
      dim = strjoin(['x',',y',',z']+dim)
      dim += ",bitpix="+(['', '8', '16', '32', '-32', '-64', '', '', '', '', '', '', '-16', '32', '64', '64'])[size(data,/type)]
      ; -16 unsigned int; -32 float; -64 double;
   endelse

   if ~keyword_set(port) then port = 'idl'
   mode = ''
   if keyword_set(kwcube) then mode = 'mecube '
   if keyword_set(kwmosaic) then mode = 'mosaicimage '+(kwmosaic eq 1? 'iraf ': kwmosaic)

   ; prevend the message: ERROR: ld.so: object '/otherfs/USW/packages/idl/compat-lib/12.1/arch.x86_64/libX11.so.6' from LD_PRELOAD cannot be preloaded: ignored.
   ;if ~file_test(getenv('LD_PRELOAD')) then setenv, 'LD_PRELOAD='  ; better to idl
   setenv, 'LD_PRELOAD='  ; better to idl
   ; check if the port exists or create a new instance
   spawn, 'xpaget xpans | grep "DS9 '+port+' .* $USER"', result, err, EXIT_STATUS=xpamiss

   if xpamiss gt 0 then begin ;  switch to normal start and create a new port
      ds9opt = ~n_elements(opt)? '' : strjoin(' -'+opt)   ;  prepend the option sign
      for i=0,n_tags(kwargs)-1 do $   ; post executed
         ds9opt += strjoin(' -'+strlowcase((tag_names(kwargs))[i])+' '+kwargs.(i))

      if keyword_set(tmpfile) && tmpfile eq '-' then begin
         spawn, 'cat - | '+ds9+' -title '+port+" -tcl yes -port 0 -array -'["+dim+"]' " $
             +ds9opt+"  2> /dev/null", unit=unit
         ; tcl need for snapshots (jupyter)
         ; spawn, ds9+' -title '+port+" -port 0 -array -'["+dim+"]' " $
         ;         +ds9opt+"  2> /dev/null &", unit=unit
         writeu, unit, data
         wait, 0.01  ; somehow needed (for small arrays?, due to buffering?) e.g. ds9, dindgen(10,10), port='idl', obj='10x10'
         free_lun, unit
      endif else $
         spawn, ds9+' -title '+port+' -tcl yes -port 0 ' $
                  +(keyword_set(mode)? '-'+mode:'')+tmpfile+' '$
                  +ds9opt+" &"
   endif else begin  ; pipe to the named port
      ; Check pathes. ds9 might be started from another session and working directory.
      ; In those cases relative pathes for fits and regions files should also work.
      cd, current=idlpath
      spawn, 'xpaget '+port+' cd', ds9path
      ds9path = ds9path[[1]] ; make it scalar if multiple port exists
      pathswap = idlpath ne ds9path
      if pathswap then spawn, 'xpaset -p '+port+' cd '+idlpath

      if keyword_set(reset) then $
         spawn, 'xpaset -p '+port+' frame reset'
      if keyword_set(frame) then $
         spawn, 'xpaset -p '+port+' frame '+string(frame) $
      else if not keyword_set(lastframe) and tmpfile ne '' then $
         spawn, 'xpaset -p '+port+' frame new'
      if keyword_set(clear) then $
         spawn, 'xpaset -p '+port+' regions delete all'

      if tmpfile eq '-' then begin
         ; print, 'using pipe'
         spawn, "xpaset "+port+" array -'["+dim+"]' 2> /dev/null", unit=unit
         writeu, unit, data
         wait, 0.01  ; somehow needed, due to buffering? , e.g. ds9, dindgen(10,10)
         free_lun, unit
      endif else if keyword_set(tmpfile) then $
         spawn, 'xpaset -p '+port+' '+(keyword_set(mode)? mode:'file ')+tmpfile

      for i=0,n_elements(opt)-1 do $   ; post executed
         spawn, 'xpaset -p '+port+' '+opt[i]
      for i=0,n_tags(kwargs)-1 do $    ; post executed
         for j=0,n_elements(kwargs.(i))-1 do $
            spawn, 'xpaset -p '+port+' '+strlowcase((tag_names(kwargs))[i])+' '+(kwargs.(i))[j]

      if pathswap then spawn, 'xpaset -p '+port+' cd '+ds9path
   endelse
   ;for i in {1..64}; do s=`printf "%04x" $i`; echo ${s: -2}${s:0:-2}; done | xxd -r -ps |  $newds9/ds9 -array -[dim=8,bitpix=16]
   ;for i in {0..1024}; do  s=`printf "%08x" $i`; b=""; for e in {0..3}; do  b=${s:0:2}$b; s=${s:2}; done; echo $b; done | xxd -r -ps |  $newds9/ds9 -array -[dim=32,bitpix=32]

   ; works:
   ; spawn, "xpaset -p idl array 'filename[xdim=10,ydim=10,bitpix=-64]'"
   ; works:
   ; spawn, "cat filename | xpaset idl array -'[xdim=5,ydim=10,bitpix=-64]'"
   ; works only after many times on console?:
   ;   spawn, "xpaset -p idl frame new "
   ;   spawn, "xpaset idl array -'[xdim=10,ydim=10,bitpix=-64]' ", unit=unit
   ;    writeu, unit, dindgen(10,12)
   ;   close,unit
   ;   free_lun, unit

   ; pass an OBJECT name
   ; it can be appended to the wcs; send without the -p
   if keyword_set(obj) then spawn, 'xpaset '+port+' wcs append <<<"OBJECT = '''+STRMID(obj, 0, 63)+'''"';  strings longer than 63 will not be displayed
   ; or with tcl (but texts is resetted when entering image)
   ; spawn, 'xpaset -p idl tcl "{set infobox(object) aa}"
   ; ds9, tcl='"{set infobox(object) '+obj+'}"'
end

