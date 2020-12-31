pro ds9get, pos, debug=debug, port=port, msg=msg

; ds9, 'HARPS.2012-02-13T21:46:32.907.fits'
; xpaget ds9 crosshair physical
; xpaset -p ds9 regions group l1 update
; xpaget ds9 regions selected 

if ~keyword_set(port) then port = 'idl'
if ~arg_present(msg) then msg = 'mark/select all your lines and confirm or quit [C|q]'
if keyword_set(msg) then begin
   print, msg
   if get_kbrd(1) eq 'q' then return
endif

spawn, 'xpaget '+port+' regions selected', reg, err
; s=''
; a=''
; spawn, 'xpaget '+port+' regions selected', unit=unit
; ;spawn, 'xpaset '+port+' regions selected'
; while ~eof(unit) do begin & readf, unit,s & a= [a,s] & endwhile
; close, unit
; free_lun,unit

if keyword_set(debug) then print, reg ;transpose(a)
idx = where(strpos(reg,'circle') ge 0,nc)
idx = where(strpos(reg,'box') ge 0,nb)
pos = fltarr(2,nb+nc)

for i=0,nb+nc-1 do begin
   aa = strsplit(reg[idx[i]], '(,', /extr)
   pos[*,i] = float(aa[[1,2]])
endfor

end

; .r ds9get
; .r
; n = 4
; pos = dblarr(4,n)
; l = lonarr(n)
; for i=0,n-1 do begin
;    a = ['']
;    spawn, 'xpaset -p '+port+' regions select none', _, err
;    ds9get, a, msg=strtrim(i,2)+' Select two lines with Shift and confirm or quit [C|q]'
;    print, a
;    if a[0] ne '' then begin
;       pos[*,i] = a
;       l[i] = i
;       spawn, 'xpaset -p '+port+' regions group callines update', _, err
;       spawn, 'xpaset -p '+port+' regions group l'+strtrim(i,2)+' update', _, err
;       spawn, 'xpaget '+port+' regions selected' ;, _, err
;    endif
; endfor
; print, pos
; end

