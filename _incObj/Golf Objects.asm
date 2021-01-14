

;;;;;;; GOLF OBJECTS!
Obj_GolfMeterH:
	moveq	#0,d0
	move.b	obRoutine(a0),d0
	move.w	Obj_GolfMeterH_Index(pc, d0.w),d1
	jmp		Obj_GolfMeterH_Index(pc,d1.w)

Obj_GolfMeterH_Index: dc.w Obj_GolfMeterH_Init-Obj_GolfMeterH_Index; 0
	dc.w Obj_GolfMeterH_Main-Obj_GolfMeterH_Index; 2

Obj_GolfMeterH_Init:
	addq.b	#2,obRoutine(a0)
	move.l	#Map_ShotMeter,obMap(a0)
	move.w	#$27AF,obGfx(a0)
	move.b	#4,obRender(a0)
	move.w	#$80,obPriority(a0)
	move.b	#8,obWidth(a0)
	

Obj_GolfMeterH_Main:
	;; H-BAR; test if not in strike or in y-mode & delete self if so.

	; set pos to orig spawn pos + hbar offset? hbar should probably only display...
	btst	#0,(Golf_mode_status).w ; test on/off strike mode
	beq.w	DeleteObject		; if it's not in strke mode, delete self
	btst 	#1,(Golf_mode_status).w ; test X/Y status.
	bne.w	GolfMeterYMode		; if it's in Y mode

	;; display Horizontal
	move.w	(Golf_bar_posx).w,obX(a0)
	move.w	(Golf_bar_posy).w,obY(a0)
	subi.w	#32,obY(a0) ; move above sonic a little
	bra.w	DisplaySprite
GolfMeterYMode:
	;; display Vertical
	move.w	(Golf_bar_posx).w,obX(a0)
	move.w	(Golf_bar_posy).w,obY(a0)
	subi.w	#16,obY(a0) ; move above sonic a little
	bra.w	DisplaySprite
;	rts
	

;---------------------------------------------

Obj_GolfMeterPip:
	moveq	#0,d0
	move.b	obRoutine(a0),d0
	move.w	Obj_GolfMeterPip_Index(pc, d0.w),d1
	jmp		Obj_GolfMeterPip_Index(pc,d1.w)

Obj_GolfMeterPip_Index: dc.w Obj_GolfMeterPip_Init-Obj_GolfMeterPip_Index; 0
	dc.w Obj_GolfMeterPip_Main-Obj_GolfMeterPip_Index; 2

Obj_GolfMeterPip_Init:
	addq.b	#2,obRoutine(a0)
	move.l	#Map_Ring,obMap(a0)
	move.w	#$27B2,obGfx(a0)
	move.b	#4,obRender(a0)
	move.w	#$80,obPriority(a0)
	move.b	#8,obWidth(a0)

Obj_GolfMeterPip_Main:
	; set pos to hbar spawn pos + hbar offset
	; logic would involve storing initial pos somewhere in init func probly.
	; likely only need to store one axis, since the spawning of the object takes care of the other.

	btst	#0,(Golf_mode_status).w ; test on/off strike mode
	beq.w	DeleteObject		; if it's not in strke mode, delete self
	btst 	#1,(Golf_mode_status).w ; test X/Y status.
	bne.s	Obj_GolfMeterPip_MoveYMode ; if in Y mode, skip to y mode logic
; else just do x mode logic
	move.w	(Golf_bar_posy).w,obY(a0);  move self to hbar y pos
	move.w	(Golf_bar_posx).w,obX(a0);  move self to hbar x pos, then add stuff
	subi.w	#32,obY(a0) ; move above sonic a little
	move.w	(Golf_meter_x).w,d3 ; capture x str
	asr.w	#6, d3; range is about +- 2k, so shift right by 6 bits gets in the +- 32 range..?
	add.w	d3,obX(a0) ; apply to xpos
	jmp Obj_GolfMeterPip_MainMode

Obj_GolfMeterPip_MoveYMode:
	move.w	(Golf_bar_posx).w,obX(a0);  move self to ybar x pos
	move.w	(Golf_bar_posy).w,obY(a0);  move self to ybar y pos, then add stuff
	subi.w	#16,obY(a0) ; move above sonic a little
	move.w	(Golf_meter_y).w,d3 ; capture y str
	asr.w	#6, d3; range is about 4k, so shift right by 6 bits gets in the 0-64 range..?
	add.w	d3,obY(a0) ; apply to ypos

Obj_GolfMeterPip_MainMode:
	bra.w	DisplaySprite
	rts