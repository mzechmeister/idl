PRO ds9msk, msk, bx=bx, by=by, color=color, limit=limit, err=err, _extra=_extra
; NAME:
;       DS9MSK
;
; VERSION:
;       v01 (2020-12-29)
;
; PURPOSE:
;       Create a ds9 region from a map and mark bad pixels with boxes.
;
; AUTHOR:
;       M. Zechmeister
;
; INPUT:
;       msk -  array, nonzero values are marked with boxes
;
; OPTIONAL INPUT KEYWORDS:
;       bx - box size in x
;       by - box size in y
;
; EXAMPLES:
;       IDL> z = dindgen(10,10)
;       IDL> ds9, z
;       IDL> ds9msk, ~(z mod 7), /clear
;
; NOTES:
;       created from msk2reg.pro

   on_error, 2

   if not keyword_set(msk) then $
      message, '% ds9msk: no mask to display'

   if ~keyword_set(limit) then limit = 25000
   err = 0
   idx = where(msk, n)

   if n gt limit then begin
      err = 'ds9msk WARNING: more then '+strtrim(limit)+' pixels ('+strtrim(n,2)+') to mask.'
      print, err + ' Continue masking [Y/n]? ', FORMAT='(A,$)'
      s = get_kbrd(1)
      print, s
      if strlowcase(s) eq 'n' then return $
      else err = 0
   endif

   if n gt 0 then begin
      if n_elements(color) eq 1 then ci = color
      if n_elements(color) gt 1 then ci = color[idx]
         
      idx = ARRAY_INDICES(msk, idx)
      ods9, reform(idx[0,*]), reform(idx[1,*]), bx, by, /box, color=ci, _extra=_extra
   endif

END
