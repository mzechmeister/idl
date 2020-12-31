; I wanted to have pause with the same name for function and routine.
; The same name can indeed exists at the same time.
; But when automatic compiling it stops after finding the first.
;
; But it works with sav file!
; Save it with:
; idl -IDL_STARTUP ""
; .r pausep
; save, /routine, file='pause.sav', /verb
;
; Now calling a function or a routine pause will automatically
; load both from the sav file.

pro pause, text, key=key, level=level
;+
; NAME:
;       PAUSE
;
; VERSION:
;       v00 (2015-10-30)
;
; PURPOSE:
;       Set a pause to wait for user keypress
;
; AUTHOR:
;       M. Zechmeister
;
; CALLING SEQUENCE:
;       PAUSE, [Text]
;
; OPTIONAL INPUT KEYWORDS:
;       Text:  A message (default:  'press any key to continue or q to stop')
;       Key:   The key pressed by user.
;
;-

   on_error, 2
   if not keyword_set(level) then level = 2
   if n_elements(text) eq 0 then text = 'press any key to continue or q to stop'

   scope = (scope_traceback(/str))[scope_level()-level]

   ;print, '% Pause at: '+string(scope.routine, scope.line,' ', scope.filename)+' '
   ;if keyword_set(text) then print, '% Pause: ', text
   print, f='("% Pause at: ",A,I," ",A,$)', scope.routine, scope.line, scope.filename
   if keyword_set(text) then print, f='(A,"% Pause: ", A,$) ',string(10b), text

   ; READ, dummy, PROMPT='Press q to quit or Enter ' ; Read input from the terminal.
   key = get_kbrd()
   print
   if key eq 'q' or key eq 'd' then message, '', /noprint; /informational;level=-1
   ; if( get_kbrd(/esc) eq "q") then stop
end

function pause, text, fold_case=fold_case
;+
; NAME:
;       PAUSE
;
; VERSION:
;       v00 (2015-10-30)
;
; PURPOSE:
;       Set a pause to wait for user keypress
;
; AUTHOR:
;       M. Zechmeister
;
; CALLING SEQUENCE:
;       b = PAUSE(Text)
;
; OPTIONAL INPUT KEYWORDS:
;       Text:  A message (default:  'press any key to continue or q to stop')
;       VAL:   A char to be tested
;-

   on_error, 2
   pause, text, key=key, level=3

   return, key
END
