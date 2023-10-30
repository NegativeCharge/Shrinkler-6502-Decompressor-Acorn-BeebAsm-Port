.unshrinkler
probs		=	unshrinkler_data

IF unshrinkler_PARITY
probsRef	=	unshrinkler_data+$200+$200
ELSE
probsRef	=	unshrinkler_data+$200
ENDIF

probsLength	=	probsRef
probsOffset	=	probsRef+$200
	
IF unshrinkler_FAST
	IF 0 <> LO(unshrinkler_data)
		ERROR "Data must be page aligned"
	ENDIF
	sqrZeroLo	=	probsOffset+$300
	sqrZeroHi	=	probsOffset+$600
ENDIF

	ldx #>(probsOffset+$100)
	ldy #1
	sty d3+0
	dey
	sty d3+1

	IF LO(unshrinkler_data) = 0
		sty	tabs
	ELSE
		lda	#<unshrinkler_data
		sta tabs
	ENDIF

	tya
.initPage
	stx	tabs+1
.initByte
	sta	(tabs),y
	iny
	bne	initByte
	sta	srcBits	; eventually $80
	eor	#$80
	dex
	cpx	#>unshrinkler_data
	bcs	initPage
	tax	; #0

IF unshrinkler_FAST
	lda #>sqrZeroLo
	sta mal+1
	lda #>sqrZeroHi
	sta mah+1
	stx	sqrZeroLo
	stx	sqrZeroHi
	ldy	#$ff
.initSqr1
	txa
	lsr	a
	adc	sqrZeroLo,x
	sta	sqrZeroLo+1,x
	sta	sqrZeroLo-$100,y
	lda	#0
	adc	sqrZeroHi,x
	sta	sqrZeroHi+1,x
	sta	sqrZeroHi-$100,y
	inx
	dey
	bne	initSqr1
.initSqr2
	tya
	sbc	#0	; C=0
	ror	a
	adc	sqrZeroLo+$ff,y
	sta	sqrZeroLo+$100,y
	lda	#0
	adc	sqrZeroHi+$ff,y
	sta	sqrZeroHi+$100,y
	iny
	bne	initSqr2
ENDIF

.literal
IF unshrinkler_FAST
	lda #1
	sta tabs
.literalBit
	jsr	getBit
	rol	tabs
	bcc	literalBit
	lda tabs
	sta (dst),y
ELSE
	ldy	#1
.literalBit
	jsr	getBit
	tya
	rol	a
	tay
	bcc	literalBit
	sta	(dst,x)	; X=0
ENDIF

	inc dst+0
	bne storeSamePage
	inc dst+1
.storeSamePage
	jsr	getKind
	bcc	literal

	lda	#>probsRef
	jsr	getBitFrom
	bcc	readOffset

.readLength
	lda	#>probsLength
	jsr	getNumber
	lda	#$ff
offsetL=*-1
	adc	dst	; C=0
	sta	copy
	lda	#$ff
offsetH=*-1
	adc	dst+1
	sta	copy+1

	ldx	number+1
	beq	copyRemainder
.copyPage
    lda (copy),y
    sta (dst),y
    iny
    bne copyPage

	inc	copy+1
	inc	dst+1
	dex
	bne	copyPage

.copyRemainder
	ldx	number
	beq	copyDone
.copyByte
    lda (copy),y
    sta (dst),y
    iny
	dex
	bne	copyByte
	tya
	clc
	adc dst
	sta	dst
	bcc copyDone
	inc dst+1

.copyDone
	jsr	getKind
	bcc	literal

.readOffset
	lda	#>probsOffset
	jsr	getNumber
	lda	#3
	sbc	number	; C=0
	sta	offsetL
	tya	; #0
	sbc	number+1
	sta	offsetH
	bcc	readLength
	rts	; finish

.getNumber
	sta	tabs+1
	lda #1
	sta number
	sty	number+1	; #0

IF unshrinkler_FAST
	sty	tabs
ENDIF

.getNumberCount
IF unshrinkler_FAST
	inc tabs
	inc tabs
ELSE
	iny
	iny
ENDIF

	jsr	getBit
	bcs	getNumberCount

.getNumberBit
IF unshrinkler_FAST	
	dec	tabs
ELSE
    dey
ENDIF

	jsr	getBit
	rol	number
	rol	number+1

IF unshrinkler_FAST	
	dec	tabs
ELSE
	dey
ENDIF

	bne	getNumberBit
	rts

.getKind
	ldy	#0

IF unshrinkler_FAST
	sty	tabs
ENDIF

IF unshrinkler_PARITY
	lda	dst
	and	#1
	asl	a
	adc	#>probs
ELSE
	lda	#>probs
ENDIF

.getBitFrom
	sta	tabs+1
	bne	getBit	; always

.readBit
	asl	d3+0
	rol	d3+1
	asl	srcBits
	bne	gotBit

IF unshrinkler_FAST	
	lda	(src),y	; Y=0
ELSE
	lda	(src,x)	; X=0
ENDIF

	inc src+0
	bne readSamePage
	inc src+1
.readSamePage
	rol	a	; C=1
	sta	srcBits
.gotBit
	rol	d2+0
	rol	d2+1

.getBit
	lda	d3+1
	bpl	readBit
	lda (tabs),y
	sta factor+1

IF unshrinkler_FAST	
	lsr	a
ENDIF

	sta	frac+1
	inc	tabs+1
	lda	(tabs),y

IF unshrinkler_FAST
; fast multiplication
	ror	a
	lsr	frac+1
	ror	a
	lsr	frac+1
	ror	a
	lsr	frac+1
	ror	a
	sta	frac+0

	lda	(tabs),y
	jsr	setupMul
; result byte 0
	ldy	d3+0
	lda	(mal),y
	cmp	(msl),y
; result byte 1
	lda	(mah),y
	sbc	(msh),y
	ldy	d3+1
	adc	(mal),y	; C=1
	php
	clc
	sbc	(msl),y
	sta	cp+1
; result byte 2
	lda	#0
	adc	(mah),y
	plp
	sbc	(msh),y
	tax
; result byte 1
	lda	factor+1
	jsr	setupMul
	ldy	d3
	lda	cp+1
	clc
	adc (mal),y
	php
	cmp	(msl),y
; result byte 2
	txa
	ldx	#0
	adc	(mah),y
	bcc skip_over4
	inx
.skip_over4
	plp
	sbc	(msh),y
	bcs skip_over5
	dex
.skip_over5
	ldy	d3+1
	clc
	adc (mal),y
	bcc skip_over6
	inx
.skip_over6
	sec
	sbc (msl),y
	sta	cp
; result byte 3
	txa
	adc	(mah),y
	clc
	sbc	(msh),y
	sta	cp+1
	ldy	#0
	lda	d2
	sbc	cp	; C=1
ELSE
; slow multiplication
	sta	factor
	ldx	#4
.computeFrac
	lsr	frac+1
	ror	a
	dex
	bne	computeFrac
	sta	frac
	txa	; #0
	sta	cp+1
	ldx	#16
.mulLoop
	lsr	factor+1
	ror	factor
	bcc	mulNext
	clc
	adc d3
	pha
	lda	cp+1
	adc	d3+1
	sta	cp+1
	pla
.mulNext
	ror	cp+1
	ror	a
	dex
	bne	mulLoop
	sta	cp
	eor	#$ff
	sec
	adc	d2
ENDIF

	tax
	lda	d2+1
	sbc	cp+1
	bcs	zero
	ldx	cp
	lda	cp+1
	bcc	setD3	; always
.zero
	stx	d2
	sta	d2+1
	lda	d3
	sbc	cp	; C=1
	tax
	lda	d3+1
	sbc	cp+1
.setD3
	stx	d3
	sta	d3+1
	php
	lda	(tabs),y
	sbc	frac
	sta	(tabs),y
	dec	tabs+1
	lda	(tabs),y
	sbc	frac+1
	plp
	bcs	retZero
	sbc	#$ef	; C=0
	sec
	EQUB &a2	; dta	{ldx #}
.retZero
	clc
	sta	(tabs),y

IF unshrinkler_FAST = FALSE
	ldx	#0
ENDIF

	rts

IF unshrinkler_FAST
.setupMul
	sta	mal
	sta	mah
	eor	#$ff
	clc
	adc #1
	sta	msl
	sta	msh
	lda	#0
	adc	#>(sqrZeroLo-$100)
	sta	msl+1
	adc	#>(sqrZeroHi-sqrZeroLo)
	sta	msh+1
	rts
ENDIF