; -----------------
; Subroutine for managing golf-input state.
; Here's how I think this is gonna work:
; 1. Check sonic status stuff for something that we won't use in golf hack, like spindash status, to determine whether or not we're in pre-golf-strike mode.
; 2. Use sub-state to track how far through a golf swing we are, to figure out what we're displaying and what swing strength variable we need to save into 
; 3. At final state, swing that golf club and send the hedgehog hurtling through the air. 
;
; Basic logic of golf: 
; 1. At rest, pressing a controller button will move into strike mode. 
; 2. X-axis meter display, and will move a marker left and right, pressing again will freeze it there.
; 3. Once X-axis set, Y-axis appears (where bottom of the axis is 0-angle, and top is 90 degrees), does the same thing.
; 4. Once X and Y axis are set, play a thwack sound, and launch our spherical friend into the air according to the X and Y forces picked.
; 
;
;	Status Flags for Checking:
;	Sonic status, bit 5: pushing is now strikemode or not
;
;
; -----------------

; --- SNOLF BOUNCING SUBROUTINE
Golf_Bouncer:
	neg.w	obVelX(a0); GOLF! negate it
	asr.w	#1,obVelX(a0); and half it
GolfBouncerEnd:
    rts

Golf_ResetBall:
	move.w	(Golf_bar_posx).w,obX(a0)
	move.w	(Golf_bar_posy).w,obY(a0)

	move.w	#0,obVelX(a0)
	move.w	#0,obVelY(a0)
	move.w	#0,obInertia(a0)

	; tele vfx & sfx
	;move.b	#$40,(Teleport_active_timer).w
	;move.b	#1,(Teleport_active_flag).w
	move.w	#sfx_Teleport,d0 ; play teleport sound
	jsr	(PlaySound_Special).l
	
	rts

Sonic_GolfMeter:
	tst.b (f_lockctrl).w ;test controls not locked
	bne.w	SkipGolf ; if golfmode overridden, skip this func

	move.w 	#0,(Golf_did_just_swing).w ; reset just-hit flag
	addi.w, #1,(Golf_accumulator).w ;; increment golf accumulator. do we need to worry about overflow?
	cmpi.w, #512,(Golf_accumulator).w ; reset after it hits 512 anyways (should be enough for a full sinewave?)
	blo.s +
	move.w, #0,(Golf_accumulator).w
+
	; CHECK FOR RESET HELD
	btst #bitA,(v_jpadhold1).w ; is A button held?
	beq.s GolfResetRelease ; if not held, reset timer and move on
	; else tick down 
	subi.w, #1,(Golf_reset_timer).w
	; check above one
	cmpi.w, #1,(Golf_reset_timer).w
	bhi.s +
	; if below one, we reset the ball
	jsr	Golf_ResetBall
	
	jmp GolfResetRelease
+
	jmp GolfMeterMainCheck



GolfResetRelease:
	move.w	#90,(Golf_reset_timer).w
	jmp GolfMeterMainCheck

GolfMeterMainCheck:
	move.b 	(v_jpadpress1).w,d0 
	andi.b	#btnB|btnA|btnC,d0 ; look for button press
	bne.w	GolfButtonPressed ; have we pushed a button? if not, just do what we normally do.
GolfButtonNotPressed:
	btst	#0,(Golf_mode_status).w ;don't increment meter x or y if not in strikemode
	beq.w	SkipGolf
	move.w	obX(a0),(Golf_bar_posx).w ; store meter pos each frame in strikemode.
	move.w	obY(a0),(Golf_bar_posy).w
	move.w	(Golf_accumulator).w,d0 ;precalc sine on accumulator val
	jsr		(CalcSine).l
	btst	#1,(Golf_mode_status).w ; are we in x or y strike mode
	bne.s	golfymode ; branch if we are in Y mode
;----------------------------------------------------
	;xmode
	;put sin of acc in d0
	asl.w  	#4,d0
	move.w	d0,(Golf_meter_x).w
	jmp 	SkipGolf	
;---------------------------------------
golfymode:
	;ymode
	addi.w	#255,d1
	asl.w	#3,d1
	neg.w	d1
	move.w	d1,(Golf_meter_y).w
	jmp		SkipGolf

GolfButtonPressed:
	move.w	obInertia(a0),d0; cannot enter golf mode while still moving, unless override set
	cmpi.w  #1,(Golf_force_allow).w
	beq.s +
	cmpi.w  #1,(Golf_force_temp).w
	beq.s +
	cmpi.w  #$0040,d0
	bhi.s	GolfButtonNotPressed
+
	btst	#0,(Golf_mode_status).w ;are we in strike mode?
	bne.w	+
	bclr	#1,(Golf_mode_status).w ; reset X/Y of strike mode
	move.w  #0,(Golf_meter_x).w;
	move.w  #0,(Golf_meter_y).w;
	
	bset	#0,(Golf_mode_status).w ;in strike mode now

	; ENTERING STRIKE MODE - RESET GOLF ACCUMULATOR.
	; if facing left, reset to half-way?
	move.w	#0,(Golf_accumulator).w
	btst	#0,obStatus(a0)
	beq.w	GolfSkipAccumLeft
	move.w	#127,(Golf_accumulator).w
GolfSkipAccumLeft:

	; ENTERING STRIKE MODE = ADD PIP
    bsr.w	FindFreeObj
	_move.b	#id_GolfMeterPip,(a1) ; load objDD via GolfMeterH.


	; ENTERING STRIKE MODE = ADD H-BAR
    bsr.w	FindFreeObj
	_move.b	#id_GolfMeterH,(a1) ; load objDD via GolfMeterH.

	move.w	#sfx_Bumper,d0 ; play sound
	jsr	(PlaySound_Special).l
	jmp 	GolfButtonNotPressed
+
	;in strike status already, check if it's in X or Y mode, and advance to next step if so
	btst	#1,(Golf_mode_status).w
	bne.s	GolfSwing

	move.w	#sfx_Bumper,d0 ;play sound
	jsr	(PlaySound_Special).l
	; ENTERING Y MODE - RESET ACCUM
	move.w	#127,(Golf_accumulator).w ;127 for cosine is at bottom.

	; ENTERING Y MODE = ADD V-BAR
	bset	#1,(Golf_mode_status).w
	jmp 	GolfButtonNotPressed

SkipGolf:
	rts

GolfSwing:
	bclr	#0,(Golf_mode_status).w ; strike mode cleared! 
	move.w  #0,(Golf_force_temp).w; clear temp force flag

	; set x veloc, set y veloc, set rolling/jumping
	move.w	(Golf_meter_y).w,obVelY(a0)
	move.w	(Golf_meter_x).w,obVelX(a0)
	move.w	#$400,obInertia(a0)
	bset	#1,obStatus(a0)
	bclr	#1,(Golf_mode_status).w ; reset X/Y of strike mode
	; increment the number of swings taken on this act
	addi.w	#1,(Golf_swings_taken).w;
	move.w 	#1,(Golf_did_just_swing).w ; set just-hit flag

	; play sound
    move.w	#sfx_Basaran,d0 ;play sound
	jsr	(PlaySound_Special).l
	ori.b 	#1,(f_ringcount).w ; tell hud to update
	

	jmp		GolfButtonNotPressed

