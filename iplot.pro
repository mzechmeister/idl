pro iplot, Arg1,Arg2,Arg3,Arg4,Arg5,Arg6,Arg7,Arg8,Arg9,Arg10,Arg11,Arg12, wait=time, _extra=_extra
;+
; NAME:
;       IPLOT
;
; VERSION:
;       v01 (2020-12-31)
;
; AUTHOR:
;       M. Zechmeister (IAG)
;
; PURPOSE:
;       A gnuplot wrapper for Jupyter (via gplot.pro)
;
;-
    on_error, 2
    compile_opt strictarr   ; https://stackoverflow.com/questions/64500086/idl-lambda-attempt-to-subscript-is-out-of-range/64500220#64500220; otherwise IDL_BASE64 is interpreted as variable
    addpath, '/opt/USW/harris/idl86/lib/'   ; idl_base64 needs IDL 7.1

    file_delete, 'gptmp.png', /allow_nonexistent   ; to prevent reading previous image
    gplot, term='pngcairo enh', out='"gptmp.png"'
    gplot, Arg1,Arg2,Arg3,Arg4,Arg5,Arg6,Arg7,Arg8,Arg9,Arg10,Arg11,Arg12, _extra=_extra
    gplot, set='out'
    if n_elements(arg1) gt 0 then begin
        if not n_elements(time) then time = 0.1
        k = 5
        ; wait until file exists and is written
        while((~file_test("gptmp.png") || file_test("gptmp.png", /zero)) && k--) do wait, time
        print, "<html><img src='data:image/png;base64,"+IDL_BASE64(READ_BINARY("gptmp.png"))+"'/></html>"
    endif
end

