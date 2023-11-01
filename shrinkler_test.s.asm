LOAD_ADDR = $5800

unshrinkler_FAST    = TRUE
unshrinkler_PARITY  = FALSE
unshrinkler_data    = $2c00

\ Allocate vars in ZP
ORG &80
GUARD &9F
.zp_start
    INCLUDE ".\lib\shrinkler.h.asm"
.zp_end

\ Main
CLEAR 0, unshrinkler_data
GUARD unshrinkler_data
ORG &1100
.start
    INCLUDE ".\lib\shrinkler.s.asm"

.entry_point

    \\ Turn off cursor by directly poking crtc
    lda #&0b
    sta &fe00
    lda #&20
    sta &fe01

    lda #LO(comp_data)
    sta src+0
    lda #HI(comp_data)
    sta src+1
    lda #LO(LOAD_ADDR)
    sta dst+0
    lda #HI(LOAD_ADDR)
    sta dst+1

    jsr unshrinkler
    jmp *
    
.comp_data
    INCBIN ".\tests\test_0.bin.shr"

.end

SAVE "SHRNKLR", start, end, entry_point

\ ******************************************************************
\ *	Memory Info
\ ******************************************************************

PRINT "------------------------"
PRINT " Shrinkler Decompressor "
PRINT "------------------------"
PRINT "CODE SIZE         = ", ~end-start
PRINT "DECOMPRESSOR SIZE = ", entry_point-start, "bytes"
PRINT "ZERO PAGE SIZE    = ", zp_end-zp_start, "bytes"
PRINT "------------------------"
PRINT "LOAD ADDR         = ", ~start
PRINT "HIGH WATERMARK    = ", ~P%
PRINT "RAM BYTES FREE    = ", ~LOAD_ADDR-P%
PRINT "------------------------"

PUTBASIC "loader.bas","LOADER"
PUTFILE  "BOOT","!BOOT", &FFFF  