pro ODS9, cx, cy, arg1, arg2, arg3, PORT=port, FRAME=frame, LASTFRAME=lastframe, RESET=reset, LABEL=label, TAG1=tag1, TAG2=tag2, REGFILE=regfile, COLOR=color, palette=palette, PT=pt, BOX=box, CIRCLE=circle, CURVE=CURVE, LINE=LINE, POINT=point, POLYGON=polygon, x=x, cross=cross, RED=red, BLUE=blue, GREEN=green, CLEAR=clear, header=header

;+
; NAME:
;       ODS9
;
; VERSION:
;       v01 (2016-06-30)
;
; PURPOSE:
;       Overplot data point in ds9 as a region file
;
; AUTHOR:
;       M. Zechmeister
;
; CALLING SEQUENCE:
;       DS9, X, Y
;
; INPUT:
;       Cx -   Data vector
;       Cy -   Data vector
;
; OPTIONAL INPUT KEYWORDS:
;       arg*   - The meaning depends on the selected style.
;       port   - A named port for an open pipe (address for xpa)
;       frame  -  Writes to this frame number
;       /lastframe - Overwrites the last frame
;       /clear - Deletes all regions
;       header - a header for the ds9 region file
;       regfile - Keyword for data transmission
;                0    direct (bi-directional) pipe (default, not working for some OS)
;                '-'  pipe via stdin (echo, not working for long input)
;                filename
;       ps     - point size (default: 2.5)
;       color  - color of the elements (vector possible).
;                A color name can be passed (i.e. string e.g. 'green' or '#AABBCC').
;                Otherwise the numerical value is translate via a color table (see palette)
;       palette - color table (0: grey, 1: blue-green-red)
;       pt     - point type (default: circle)
;                point x y # point=[circle|box|diamond|cross|x|arrow|boxcircle] [size]
;       curve  - connects points using lines (similar to polygon but not closed)
;       box    - x y width height angle (default: width=1, height=1)
;       circle - x y radius (default: radius=2.5)
;
;
; Ellipse
; Usage: ellipse x y radius radius angle
;
; Box
; Usage: box x y width height angle
;
; Polygon
; Usage: polygon x1 y1 x2 y2 x3 y3 ...
;
; Line
; Usage: line x1 y1 x2 y2 # line=[0|1] [0|1]
;
;
; EXAMPLES:
;       Display an array and overplot three points
;
;       IDL> ds9, dindgen(10,10)
;       IDL> ods9, [0,5,2], [0,5,4]
;
;       IDL> ods9, [0,5,2], [0,5,4], color=['red','blue', 'blue'], /clear
;       IDL> ods9, [0,5,2], [0,5,4], /blue, tag1=['','good','bad'] ,/clear
;       IDL> ods9, [0,5,2], [0,5,4], point='cross', color='yellow', /clear
;
;       Print the region file
;
;       IDL> ods9, [0,5,2], [0,5,4], color='yellow', point='cross', reg='-', $
;                 head=['# Region file format: DS9 version 4.0', $
;                       'global point=cross color=yellow font="helvetica 10 normal" select=1 highlite=1 edit=1 move=1 delete=1 include=1 fixed=0 source', 'image' ] ; (coordinate system)
;
; NOTES:
;    see ds9.pro for requirements (xpa)
;-

   on_error, 2

   if n_params() lt 2 then message, '% ods9: no data to display'

   args = strtrim(cx+1,2) + ', ' + strtrim(cy+1,2)
   opt = ''

   ; sarg1=0 means arg1 is of type size/width/length.
   ; sarg1=1 means arg1 is of type position and conversion from IDL-zeros to ds9-one based indexing is done
   sarg1 = 0
   sarg2 = 0
   sarg3 = 0

   if not keyword_set(port) then port = 'idl'

   if keyword_set(red) then color = 'red'
   if keyword_set(blue) then color = 'blue'
   if keyword_set(green) then color = 'green'

   if keyword_set(box) then begin
      pt = 'box'
      if ~n_elements(arg1) then arg1 = 1
      if ~n_elements(arg2) then arg2 = arg1
   endif
   if keyword_set(circle) then begin
      pt = 'circle'
      if ~n_elements(arg1) then arg1 = 2.5
   endif
   if keyword_set(curve) then begin
      pt = 'line'
      args = args[0:*] + ',' + args[1:*]
   endif
   if keyword_set(line) then begin
      if n_params() ne 4 then message, 'Option /LINE requires 4 arguments (x1,y1,x2,y2). Or maybe you want the option /CURVE (x,y) to connect points.'
      pt = ' line'
      sarg1 = 1
      sarg2 = 1
      if size(line,/tname) eq 'STRING' then opt += 'line='+line
   endif

   if keyword_set(cross) then point = 'cross'
   if keyword_set(x) then point = 'x'
   if keyword_set(point) then pt = point+' point'

   if keyword_set(polygon) then begin
      pt = 'polygon'
      args =  [strjoin(strtrim(cx+1,2 )+ ' ' + strtrim(cy+1,2),' ')]
   endif

   if n_elements(arg1) gt 0 then args += ', '+strtrim(arg1+sarg1,2)
   if n_elements(arg2) gt 0 then args += ', '+strtrim(arg2+sarg2,2)
   if n_elements(arg3) gt 0 then args += ', '+strtrim(arg3+sarg3,2)

   if keyword_set(label) then opt += ' text={'+label+'}'
   if keyword_set(tag1) then opt += ' tag={'+tag1+'}'
   if keyword_set(tag2) then opt += ' tag={'+tag2+'}'
   if keyword_set(color) then begin
      if size(color, /tname) eq 'STRING' then opt += ' color='+color $
      else begin
         z = (float(color)-min(color)) / (max(color)-min(color))
         ; http://www.tonton-pixel.com/blog/scripts/creative-scripts/create-color-ramp/examples-of-color-ramp-formulas/
         if not keyword_set(palette) then palette = 0
         case palette of
            ; blue-green-red
            1: z = {r:2*z-1, g:1-abs(2*z-1), b:1-2*z}
            ; Primary Colors (Darker) colorRampFormula
            2: z = {r:cos((z-1./6)*!pi), g:cos((z-3./6)*!pi), b:cos((z-5./6)*!pi)}
            ; Primary Colors (Lighter) colorRampFormula
            3: z = {r:cos((z-1./6)*!pi/1.5)^2, g:cos((z-3./6)*!pi/1.5)^2, b:cos((z-5./6)*!pi/1.5)^2}
            ; Primary Colors (Sunny) colorRampFormula
            4: z = {r:cos((z-1./6)*!pi/1.5), g:cos((z-3./6)*!pi/1.5), b:cos((z-5./6)*!pi/1.5)}
            ; grey:
            else: z = {r:z, g:z, b:z}
         endcase
         opt += ' color=#'+string(256L^2*long(255*z.r>0) + 256*long(255*z.g>0) + long(255*z.b>0), FORMAT='(Z06)')
      endelse
   endif
   ;tag2 = ~keyword_set(tag2)? '' : ' tag={'+tag2+'}'
   if ~keyword_set(pt) then pt = 'cross point'


   lines = pt+'('+args+') # '+opt
   if n_elements(lines) eq 1 then lines = [lines] ; ensure array

   if keyword_set(header) then begin
      lines = [header, lines]
   endif

   ; check if the port exists
   spawn, "xpaget xpans | grep 'DS9 "+port+"'", result, err, EXIT_STATUS=xpamiss

   if xpamiss gt 0 then begin
      message, string('xpa misses: ', port), /cont
      return
   endif

   if keyword_set(reset) then $
      spawn, 'xpaset -p '+port+' frame reset'
   if keyword_set(frame) then $
      spawn, 'xpaset -p '+port+' frame '+string(frame)
   if keyword_set(clear) then $
      spawn, 'xpaset -p '+port+' regions delete all'

   if ~keyword_set(regfile) then begin
      ; write data directly into bi-directional pipe (race between stdin and stdout)
      spawn, "xpaset "+port+" regions 2> /dev/null", unit=ounit ; '2> /dev/null' closes stdout?
      wait, 0.01  ; somehow needed, due to buffering?
      printf, ounit, transpose(lines)
      ; wait, 0.01  ; somehow needed, due to buffering?
      ; flush, ounit ; does this helps ?
      free_lun, ounit
   endif else if regfile eq '-' then $
      ; may result in % SPAWN: Error managing child process.
      ; Argument list too long
      ;spawn, 'echo -e "'+strjoin(lines,"\n")+'" | xpaset '+port+' regions' $
      print, transpose(lines) $
   else begin
      openw, ounit, regfile, /get_lun
      printf, ounit, transpose(lines)
      free_lun, ounit
   endelse

end
