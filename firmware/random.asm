; 32-bit random generator (tested)
; The prime polynom is 0xA6A6A6A6
; By Mark Jeronimus of Digital Mosular
; modified for constant number of execution cycles

Random32:
    BCF     STATUS,C     ; 1       1
    RRCF    LFSRVALUEV,F ; 1       2
    RRCF    LFSRVALUEU,F ; 1       3
    RRCF    LFSRVALUEH,F ; 1       4
    RRCF    LFSRVALUEL,F ; 1       5
    BTFSS   STATUS,C     ; 1       6
    GOTO Rnd0            ; 1/2     7

    MOVLW   0xA6         ; 1       8
    XORWF   LFSRVALUEV   ; 1       9
    XORWF   LFSRVALUEU   ; 1      10
    XORWF   LFSRVALUEH   ; 1      11
    XORWF   LFSRVALUEL   ; 1      12
    RETURN               ; 2      14

Rnd0:                    ; 1       8
    nop                  ; 1       9
    nop                  ; 1      10
    nop                  ; 1      11
    nop                  ; 1      12
    RETURN               ; 2      14


