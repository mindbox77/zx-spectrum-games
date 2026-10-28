        org $8000

SCREEN  equ $4000
ATTRS   equ $5800
FONT    equ $3C00
FRAMES  equ $5C78

MSG_LEN equ 28
MSG_Y   equ 184
SM_Y    equ 168
SM_ROWS equ 24
SM_W    equ 3
SM_NFRAMES equ 12
SM_FRAME_SIZE equ SM_ROWS*SM_W
SM_SHIFTED_SIZE equ SM_ROWS*(SM_W+1)
WALK_SPEED  equ 256
ANIM_RATE   equ 3
ENTRY_DELAY equ 100
WINDUP_TIME equ 6
KICK_TIME   equ 6
END_PAUSE   equ 150
GRAVITY equ 26
BLITBUF_SIZE equ 32*5

P_STATE equ 0
P_CHAR  equ 1
P_X     equ 2
P_Y     equ 4
P_VX    equ 6
P_VY    equ 8
P_SC    equ 10
P_DS    equ 12
P_GRAV  equ 14
P_BUF   equ 16
P_SIZE  equ 32

SM_WAIT   equ 0
SM_WALK   equ 1
SM_WINDUP equ 2
SM_KICK   equ 3
SM_EXIT   equ 4
SM_OFFWAIT equ 5
SM_LEANIN  equ 6
SM_WAVE    equ 7
SM_LEANOUT equ 8
WAVE_TIME  equ 100
WAVE_SWAP  equ 8
LEAN_IN_X  equ $FC00
HIDDEN_X   equ $F400
SM_WATCH   equ 9
SM_SEQ     equ 10
VX0        equ -256
BOUNCE_VX  equ 54
VY0        equ -572
HEAD_X0    equ 10
HEAD_Y0    equ 168
HEAD_Y1    equ 173
WATCH_TIME equ 90

start:
        exx
        ld (basic_hl2),hl
        exx
        im 1
        ei
        ld a,(FRAMES)
        or 1
        ld (seed),a
        call init_shift_tables
        call setup_screen
        call init_particles
        call init_stickman_shifted
        jr first_run

restart:
        call setup_screen
        call init_particles
first_run:
        call init_stickman
        xor a
        ld (demo_done),a

main_loop:
        halt
        ld bc,$7FFE
        in a,(c)
        rra
        jr nc,exit
        call erase_all
        call update_particles
        call update_stickman
        call draw_all
        ld a,(demo_done)
        or a
        jr z,main_loop
        call any_flying
        jr nz,main_loop
        ld b,END_PAUSE
pause:  halt
        ld a,$7F
        in a,($FE)
        rra
        jr nc,exit
        xor a
        in a,($FE)
        cpl
        and $1F
        jr nz,restart
        djnz pause
        jr restart

exit:
        exx
        ld hl,(basic_hl2)
        exx
        ret

launch_bounce:
        ld (ix+P_STATE),3
        ld hl,VX0
        ld (ix+P_VX),l
        ld (ix+P_VX+1),h
        ld hl,VY0
        ld (ix+P_VY),l
        ld (ix+P_VY+1),h
        xor a
        ld (ix+P_DS),a
        ld (ix+P_DS+1),a
        ld (ix+P_GRAV),3
        ret

start_watch:
        ld a,WATCH_TIME
        ld (sm_timer),a
        ld a,SM_WATCH
        ld (sm_state),a
        ret

us_watch:
        ld hl,sm_timer
        dec (hl)
        jp z,us_go_exit
        xor a
        call particle_ptr
        ld a,(ix+P_STATE)
        cp 2
        jp c,us_go_exit
        ld l,(ix+P_X)
        ld h,(ix+P_X+1)
        call fix2int
        ld a,h
        or a
        ret nz
        ld c,l
        ld hl,(sm_x)
        call fix2int
        ld a,l
        add a,HEAD_X0
        ld b,a
        ld a,c
        add a,7
        cp b
        ret c
        ld a,b
        add a,7
        cp c
        ret c
        ld l,(ix+P_Y)
        ld h,(ix+P_Y+1)
        call fix2int
        ld a,h
        or a
        ret nz
        ld a,l
        add a,7
        cp HEAD_Y0
        ret c
        ld a,HEAD_Y1
        cp l
        ret c
        ld hl,-128
        ld (ix+P_VX),l
        ld (ix+P_VX+1),h
        ld hl,-512
        ld (ix+P_VY),l
        ld (ix+P_VY+1),h
        ld (ix+P_GRAV),1
        ld a,8
        ld (sm_frame),a
        ld a,(fall_seq+1)
        ld (sm_timer),a
        ld hl,fall_seq+2
        ld (sm_seqp),hl
        ld a,SM_SEQ
        ld (sm_state),a
        ret

us_seq:
        ld hl,sm_timer
        dec (hl)
        ret nz
        ld hl,(sm_seqp)
        ld a,(hl)
        cp $FF
        jp z,us_go_exit
        ld (sm_frame),a
        inc hl
        ld a,(hl)
        ld (sm_timer),a
        inc hl
        ld (sm_seqp),hl
        ret

us_go_exit:
        xor a
        ld (sm_frame),a
        ld (sm_anim),a
        ld a,SM_EXIT
        ld (sm_state),a
        ret

fall_seq:
        db 8,8, 9,6, 10,60, 11,18, 0,15, $FF

any_flying:
        ld ix,particles
        ld b,MSG_LEN
        ld de,P_SIZE
af_loop:
        ld a,(ix+P_STATE)
        cp 2
        jr nc,af_yes
        add ix,de
        djnz af_loop
        xor a
        ret
af_yes:
        or a
        ret

us_offwait:
        call any_flying
        ret nz
        ld hl,HIDDEN_X
        ld (sm_x),hl
        ld a,6
        ld (sm_frame),a
        ld a,SM_LEANIN
        ld (sm_state),a
        ret

us_leanin:
        ld hl,(sm_x)
        ld de,WALK_SPEED
        add hl,de
        ld (sm_x),hl
        ld de,LEAN_IN_X
        or a
        sbc hl,de
        ret c
        ld (sm_x),de
        xor a
        ld (sm_anim),a
        ld a,WAVE_TIME
        ld (sm_timer),a
        ld a,SM_WAVE
        ld (sm_state),a
        ret

us_wave:
        ld hl,sm_anim
        inc (hl)
        ld a,(hl)
        cp WAVE_SWAP
        jr c,uw_timer
        ld (hl),0
        ld a,(sm_frame)
        xor 1
        ld (sm_frame),a
uw_timer:
        ld hl,sm_timer
        dec (hl)
        ret nz
        ld a,6
        ld (sm_frame),a
        ld a,SM_LEANOUT
        ld (sm_state),a
        ret

us_leanout:
        ld hl,(sm_x)
        ld de,WALK_SPEED
        or a
        sbc hl,de
        ld (sm_x),hl
        ld de,HIDDEN_X
        or a
        sbc hl,de
        ret nc
        ld a,1
        ld (demo_done),a
        ret

setup_screen:
        ld a,7
        out ($FE),a
        ld hl,SCREEN
        ld de,SCREEN+1
        ld bc,6143
        ld (hl),0
        ldir
        ld hl,ATTRS
        ld de,ATTRS+1
        ld bc,767
        ld (hl),$38
        ldir
        ret

init_particles:
        ld ix,particles
        ld hl,blitbufs
        ld (ip_buf),hl
        ld hl,message
        ld b,MSG_LEN
        ld c,0
ip_loop:
        push bc
        push hl
        ld hl,(ip_buf)
        ld (ix+P_BUF),l
        ld (ix+P_BUF+1),h
        ld de,BLITBUF_SIZE
        add hl,de
        ld (ip_buf),hl
        pop hl
        ld a,(hl)
        inc hl
        ld (ix+P_CHAR),a
        ld (ix+P_STATE),1
        cp ' '
        jr nz,ip_notspace
        ld (ix+P_STATE),0
ip_notspace:
        ld a,c
        add a,a
        add a,a
        ld (ix+P_X+1),a
        ld (ix+P_X),0
        ld (ix+P_Y),0
        ld (ix+P_Y+1),MSG_Y/2
        ld (ix+P_VX),0
        ld (ix+P_VX+1),0
        ld (ix+P_VY),0
        ld (ix+P_VY+1),0
        ld (ix+P_SC),0
        ld (ix+P_SC+1),1
        ld (ix+P_DS),0
        ld (ix+P_DS+1),0
        ld (ix+P_GRAV),0
        ld a,(ix+P_STATE)
        or a
        jr z,ip_skipdraw
        push hl
        call draw_particle
        pop hl
ip_skipdraw:
        ld de,P_SIZE
        add ix,de
        pop bc
        inc c
        djnz ip_loop
        ret

init_stickman:
        ld hl,255*128
        ld (sm_x),hl
        xor a
        ld (sm_state),a
        ld (sm_frame),a
        ld (sm_anim),a
        ld (sm_drawn),a
        ld a,ENTRY_DELAY
        ld (sm_timer),a
        ld a,MSG_LEN-1
        ld (sm_target),a
        xor a
        ld (zoom_active),a
        ret

erase_all:
        ld a,(sm_drawn)
        or a
        call nz,draw_stickman
        ld ix,particles
        ld b,MSG_LEN
ea_loop:
        push bc
        ld a,(ix+P_STATE)
        cp 2
        call nc,redraw_particle
        ld de,P_SIZE
        add ix,de
        pop bc
        djnz ea_loop
        ret

draw_all:
        call draw_stickman
        ld a,1
        ld (sm_drawn),a
        ld ix,particles
        ld b,MSG_LEN
da_loop:
        push bc
        ld a,(ix+P_STATE)
        cp 2
        call z,draw_particle
        ld de,P_SIZE
        add ix,de
        pop bc
        djnz da_loop
        ret

update_particles:
        ld ix,particles
        ld b,MSG_LEN
up_loop:
        push bc
        ld a,(ix+P_STATE)
        cp 2
        jp c,up_next
        ld (ix+P_STATE),2

        ld l,(ix+P_X)
        ld h,(ix+P_X+1)
        ld e,(ix+P_VX)
        ld d,(ix+P_VX+1)
        add hl,de
        ld (ix+P_X),l
        ld (ix+P_X+1),h
        bit 1,(ix+P_GRAV)
        jr z,up_nobounce
        bit 7,(ix+P_X+1)
        jr z,up_nobounce
        xor a
        sub (ix+P_X)
        ld (ix+P_X),a
        ld a,0
        sbc a,(ix+P_X+1)
        ld (ix+P_X+1),a
        ld (ix+P_VX),BOUNCE_VX and $FF
        ld (ix+P_VX+1),BOUNCE_VX/256
        res 1,(ix+P_GRAV)
up_nobounce:

        ld l,(ix+P_Y)
        ld h,(ix+P_Y+1)
        ld e,(ix+P_VY)
        ld d,(ix+P_VY+1)
        add hl,de
        ld (ix+P_Y),l
        ld (ix+P_Y+1),h

        ld a,(ix+P_GRAV)
        or a
        jr z,up_nograv
        ld l,(ix+P_VY)
        ld h,(ix+P_VY+1)
        ld de,GRAVITY
        add hl,de
        ld (ix+P_VY),l
        ld (ix+P_VY+1),h
up_nograv:

        ld e,(ix+P_DS)
        ld d,(ix+P_DS+1)
        ld a,d
        or e
        jr z,up_nozoom
        ld l,(ix+P_SC)
        ld h,(ix+P_SC+1)
        add hl,de
        ld (ix+P_SC),l
        ld (ix+P_SC+1),h
        ex de,hl
        add hl,hl
        ex de,hl
        ld l,(ix+P_X)
        ld h,(ix+P_X+1)
        or a
        sbc hl,de
        ld (ix+P_X),l
        ld (ix+P_X+1),h
        ld l,(ix+P_Y)
        ld h,(ix+P_Y+1)
        or a
        sbc hl,de
        ld (ix+P_Y),l
        ld (ix+P_Y+1),h
up_nozoom:

        ld a,(ix+P_SC+1)
        cp 5
        jr nc,up_kill
        add a,a
        add a,a
        add a,a
        ld c,a

        ld l,(ix+P_X)
        ld h,(ix+P_X+1)
        call fix2int
        bit 7,h
        jr nz,up_xneg
        ld a,h
        or a
        jr nz,up_kill
        jr up_xok
up_xneg:
        ld e,c
        ld d,0
        add hl,de
        bit 7,h
        jr nz,up_kill
        ld a,h
        or l
        jr z,up_kill
up_xok:
        ld l,(ix+P_Y)
        ld h,(ix+P_Y+1)
        call fix2int
        bit 7,h
        jr nz,up_yneg
        ld a,h
        or a
        jr nz,up_kill
        ld a,l
        cp 192
        jr nc,up_kill
        jr up_next
up_yneg:
        ld e,c
        ld d,0
        add hl,de
        bit 7,h
        jr nz,up_kill
        ld a,h
        or l
        jr nz,up_next
up_kill:
        ld (ix+P_STATE),0
        ld a,(ix+P_DS)
        or (ix+P_DS+1)
        jr z,up_next
        xor a
        ld (zoom_active),a
up_next:
        ld de,P_SIZE
        add ix,de
        pop bc
        dec b
        jp nz,up_loop
        ret

update_stickman:
        ld a,(sm_state)
        cp SM_WAIT
        jp z,us_wait
        cp SM_WALK
        jp z,us_walk
        cp SM_WINDUP
        jp z,us_windup
        cp SM_KICK
        jp z,us_kick
        cp SM_OFFWAIT
        jp z,us_offwait
        cp SM_LEANIN
        jp z,us_leanin
        cp SM_WAVE
        jp z,us_wave
        cp SM_LEANOUT
        jp z,us_leanout
        cp SM_WATCH
        jp z,us_watch
        cp SM_SEQ
        jp z,us_seq
        ld hl,(sm_x)
        call fix2int
        ld a,h
        cp $FF
        jp nz,sm_step
        ld a,l
        cp -24
        jp nc,sm_step
        ld a,SM_OFFWAIT
        ld (sm_state),a
        ret

us_wait:
        ld hl,sm_timer
        dec (hl)
        ret nz
        ld a,SM_WALK
        ld (sm_state),a
        ret

us_walk:
        call sm_step
        ld a,(sm_target)
        call target_x
        ld hl,(sm_x)
        or a
        sbc hl,de
        ret nc
        ld (sm_x),de
        ld a,SM_WINDUP
        ld (sm_state),a
        ld a,4
        ld (sm_frame),a
        ld a,WINDUP_TIME
        ld (sm_timer),a
        ret

us_windup:
        ld hl,sm_timer
        dec (hl)
        ret nz
        ld a,SM_KICK
        ld (sm_state),a
        ld a,5
        ld (sm_frame),a
        ld a,KICK_TIME
        ld (sm_timer),a
        ld hl,(sm_x)
        ld de,8*128
        or a
        sbc hl,de
        ld (sm_x),hl
        ld a,(sm_target)
        call particle_ptr
        ld a,(sm_target)
        or a
        jp z,launch_bounce
        jp launch

us_kick:
        ld hl,sm_timer
        dec (hl)
        ret nz
        ld hl,(sm_x)
        ld de,8*128
        add hl,de
        ld (sm_x),hl
        xor a
        ld (sm_frame),a
        ld (sm_anim),a
        ld a,SM_WALK
        ld (sm_state),a
        ld a,(sm_target)
        or a
        jp z,start_watch
next_target:
        ld a,(sm_target)
        dec a
        ld (sm_target),a
        jp m,nt_exit
        call particle_ptr
        ld a,(ix+P_STATE)
        cp 1
        ret z
        jr next_target
nt_exit:
        ld a,SM_EXIT
        ld (sm_state),a
        ret

sm_step:
        ld hl,(sm_x)
        ld de,WALK_SPEED
        or a
        sbc hl,de
        ld (sm_x),hl
        ld hl,sm_anim
        inc (hl)
        ld a,(hl)
        cp ANIM_RATE
        ret c
        ld (hl),0
        ld a,(sm_frame)
        inc a
        and 3
        ld (sm_frame),a
        ret

target_x:
        add a,a
        add a,a
        add a,4
        ld d,a
        ld e,0
        ret

particle_ptr:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,particles
        add hl,de
        push hl
        pop ix
        ret

launch:
        ld (ix+P_STATE),3
        call rnd
        and 7
        cp 4
        jr c,la_preset
        cp 7
        jr z,la_preset
        ld c,a
        ld a,(zoom_active)
        or a
        ld a,c
        jr z,la_zoom
        and 3
        jr la_preset
la_zoom:
        ld a,1
        ld (zoom_active),a
        ld a,c
la_preset:
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,hl
        or a
        sbc hl,de
        ld de,presets
        add hl,de
        ld a,(hl)
        ld (ix+P_VX),a
        inc hl
        ld a,(hl)
        ld (ix+P_VX+1),a
        inc hl
        ld a,(hl)
        ld (ix+P_VY),a
        inc hl
        ld a,(hl)
        ld (ix+P_VY+1),a
        inc hl
        ld a,(hl)
        ld (ix+P_DS),a
        inc hl
        ld a,(hl)
        ld (ix+P_DS+1),a
        inc hl
        ld a,(hl)
        ld (ix+P_GRAV),a
        call rnd
        and $3F
        sub 32
        ld e,a
        rla
        sbc a,a
        ld d,a
        ld l,(ix+P_VX)
        ld h,(ix+P_VX+1)
        add hl,de
        ld (ix+P_VX),l
        ld (ix+P_VX+1),h
        call rnd
        and $3F
        sub 32
        ld e,a
        rla
        sbc a,a
        ld d,a
        ld l,(ix+P_VY)
        ld h,(ix+P_VY+1)
        add hl,de
        ld (ix+P_VY),l
        ld (ix+P_VY+1),h
        ret

rnd:
        ld a,(seed)
        add a,a
        jr nc,rnd_ok
        xor $1D
rnd_ok:
        ld (seed),a
        ret

fix2int:
        ld a,l
        rla
        ld a,h
        rla
        ld l,a
        sbc a,a
        ld h,a
        ret

draw_particle:
        call particle_setup
        ld a,(ix+P_CHAR)
        call expand_glyph
        ld hl,glyphbuf
        ld e,(ix+P_BUF)
        ld d,(ix+P_BUF+1)
        ld b,8
dp_row:
        push bc
        ld a,(cur_scale)
        ld b,a
        call shift_row
        ld a,(cur_scale)
        dec a
        jr z,dp_norep
        ld c,a
        ld a,(spr_w1)
        ld b,a
        xor a
dp_mul: add a,b
        dec c
        jr nz,dp_mul
        push hl
        ld c,b
        ld b,0
        ld h,d
        ld l,e
        or a
        sbc hl,bc
        ld c,a
        ldir
        pop hl
dp_norep:
        pop bc
        djnz dp_row
        jp draw_bitmap

redraw_particle:
        call particle_setup
        jp draw_bitmap

particle_setup:
        ld a,(ix+P_SC+1)
        ld (cur_scale),a
        inc a
        ld (spr_w1),a
        dec a
        add a,a
        add a,a
        add a,a
        ld (spr_lines),a
        ld l,(ix+P_X)
        ld h,(ix+P_X+1)
        call fix2int
        ld (spr_x),hl
        ld a,l
        and 7
        ld (spr_n),a
        ld l,(ix+P_Y)
        ld h,(ix+P_Y+1)
        call fix2int
        ld (spr_y),hl
        ld l,(ix+P_BUF)
        ld h,(ix+P_BUF+1)
        ld (spr_src),hl
        ret

draw_stickman:
        ld hl,(sm_x)
        call fix2int
        ld (spr_x),hl
        ld a,l
        and 7
        ld c,a
        ld a,(sm_frame)
        add a,a
        add a,a
        add a,a
        or c
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld d,h
        ld e,l
        add hl,hl
        add hl,de
        ld de,sm_shifted
        add hl,de
        ld (spr_src),hl
        ld hl,SM_Y
        ld (spr_y),hl
        ld a,SM_ROWS
        ld (spr_lines),a
        ld a,SM_W+1
        ld (spr_w1),a
        jp draw_bitmap

expand_glyph:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,FONT
        add hl,de
        ld de,glyphbuf
        ld a,(cur_scale)
        cp 2
        jr z,eg_2
        cp 3
        jr z,eg_3
        cp 4
        jr z,eg_4
        ld bc,8
        ldir
        ret

eg_2:   ld b,8
eg_2l:  ld a,(hl)
        inc hl
        push hl
        ld c,a
        rrca
        rrca
        rrca
        rrca
        and 15
        call dbl_lookup
        ld (de),a
        inc de
        ld a,c
        and 15
        call dbl_lookup
        ld (de),a
        inc de
        pop hl
        djnz eg_2l
        ret
dbl_lookup:
        ld hl,dbl_tab
        add a,l
        ld l,a
        ld a,(hl)
        ret

eg_3:   ld b,8
eg_3l:  ld a,(hl)
        inc hl
        push hl
        ld c,a
        rrca
        rrca
        rrca
        rrca
        rrca
        and 7
        ld hl,t3a_tab
        add a,l
        ld l,a
        ld a,(hl)
        ld (de),a
        inc de
        ld a,c
        rrca
        rrca
        and 15
        ld hl,t3b_tab
        add a,l
        ld l,a
        ld a,(hl)
        ld (de),a
        inc de
        ld a,c
        and 7
        ld hl,t3c_tab
        add a,l
        ld l,a
        ld a,(hl)
        ld (de),a
        inc de
        pop hl
        djnz eg_3l
        ret

eg_4:   ld b,8
eg_4l:  ld a,(hl)
        inc hl
        push hl
        ld c,a
        rlca
        rlca
        and 3
        call quad_lookup
        ld a,c
        rrca
        rrca
        rrca
        rrca
        and 3
        call quad_lookup
        ld a,c
        rrca
        rrca
        and 3
        call quad_lookup
        ld a,c
        and 3
        call quad_lookup
        pop hl
        djnz eg_4l
        ret
quad_lookup:
        ld hl,quad_tab
        add a,l
        ld l,a
        ld a,(hl)
        ld (de),a
        inc de
        ret

draw_bitmap:
        ld hl,(spr_x)
        sra h
        rr l
        sra h
        rr l
        sra h
        rr l
        ld (spr_col),hl
        ld a,(spr_w1)
        ld c,a
        xor a
        ld (spr_fast),a
        bit 7,h
        jr nz,db_vert
        ld a,h
        or a
        jr nz,db_vert
        ld a,l
        add a,c
        cp 33
        jr nc,db_vert
        ld a,1
        ld (spr_fast),a
db_vert:
        ld a,(spr_lines)
        ld c,a
        ld hl,(spr_y)
        ld a,h
        or a
        jr z,db_ypos
        ld a,l
        neg
        cp c
        ret nc
        ld b,a
        ld a,c
        sub b
        ld c,a
        ld a,(spr_w1)
        ld e,a
        ld d,0
        ld hl,(spr_src)
db_skip:
        add hl,de
        djnz db_skip
        ld (spr_src),hl
        ld l,0
        ld a,192
        jr db_vis
db_ypos:
        ld a,l
        cp 192
        ret nc
        ld a,192
        sub l
db_vis:
        cp c
        jr c,db_vis2
        ld a,c
db_vis2:
        or a
        ret z
        ld b,a
        ld a,l
        and $C0
        rrca
        rrca
        rrca
        ld h,a
        ld a,l
        and 7
        or h
        or $40
        ld h,a
        ld a,l
        and $38
        rlca
        rlca
        ld l,a
        ld de,(spr_src)
        ld a,(spr_fast)
        or a
        jr z,db_clipped
        ld a,(spr_col)
        or l
        ld l,a
        ld a,(spr_w1)
        add a,a
        push hl
        ld hl,blit_table-4
        add a,l
        ld l,a
        jr nc,db_bt
        inc h
db_bt:  ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ex (sp),hl
        ret

db_clipped:
        push hl
        push bc
        ld hl,(spr_col)
        ld a,(spr_w1)
        ld c,a
        bit 7,h
        jr z,db_cl_right
        ld a,l
        neg
        ld b,a
        ld a,c
        sub b
        jr c,db_cl_none
        jr z,db_cl_none
        ld c,a
        xor a
        ld (cl_col),a
        ld a,b
        ld (cl_lead),a
        jr db_cl_go
db_cl_right:
        ld a,h
        or a
        jr nz,db_cl_none
        ld a,l
        cp 32
        jr nc,db_cl_none
        ld (cl_col),a
        xor a
        ld (cl_lead),a
        ld a,32
        sub l
        cp c
        jr nc,db_cl_go
        ld c,a
db_cl_go:
        ld a,c
        ld (cl_vis),a
        ld a,(spr_w1)
        sub c
        ld (cl_skip),a
        pop bc
        pop hl
        ld a,(cl_col)
        or l
        ld l,a
        ld a,(cl_lead)
        add a,e
        ld e,a
        jr nc,db_cl_line
        inc d
db_cl_line:
        push bc
        push hl
        ld a,(cl_vis)
        ld b,a
db_cl_byte:
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        djnz db_cl_byte
        pop hl
        ld a,(cl_skip)
        add a,e
        ld e,a
        jr nc,db_cl_next
        inc d
db_cl_next:
        call next_line
        pop bc
        djnz db_cl_line
        ret
db_cl_none:
        pop bc
        pop hl
        ret

next_line:
        inc h
        ld a,h
        and 7
        ret nz
        ld a,l
        add a,32
        ld l,a
        ret c
        ld a,h
        sub 8
        ld h,a
        ret

blit_table:
        dw blit2, blit3, blit4, blit5

blit5:  ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        ld a,l
        sub 4
        ld l,a
        inc h
        ld a,h
        and 7
        jr nz,$+12
        ld a,l
        add a,32
        ld l,a
        jr c,$+6
        ld a,h
        sub 8
        ld h,a
        djnz blit5
        ret

blit4:  ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        ld a,l
        sub 3
        ld l,a
        inc h
        ld a,h
        and 7
        jr nz,$+12
        ld a,l
        add a,32
        ld l,a
        jr c,$+6
        ld a,h
        sub 8
        ld h,a
        djnz blit4
        ret

blit3:  ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        dec l
        dec l
        inc h
        ld a,h
        and 7
        jr nz,$+12
        ld a,l
        add a,32
        ld l,a
        jr c,$+6
        ld a,h
        sub 8
        ld h,a
        djnz blit3
        ret

blit2:  ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a
        inc de
        dec l
        inc h
        ld a,h
        and 7
        jr nz,$+12
        ld a,l
        add a,32
        ld l,a
        jr c,$+6
        ld a,h
        sub 8
        ld h,a
        djnz blit2
        ret

shift_row:
        ld a,(spr_n)
        add a,a
        add a,SHIFT_PAGE
        exx
        ld h,a
        inc a
        ld d,a
        ld c,0
        exx
sr_loop:
        ld a,(hl)
        inc hl
        exx
        ld l,a
        ld e,a
        ld a,(de)
        ld b,a
        ld a,(hl)
        or c
        ld c,b
        exx
        ld (de),a
        inc de
        djnz sr_loop
        exx
        ld a,c
        exx
        ld (de),a
        inc de
        ret

init_shift_tables:
        ld hl,shift_tables
        xor a
        ld (ist_n),a
ist_page:
        ld c,0
ist_val:
        ld d,c
        ld e,0
        ld a,(ist_n)
        or a
        jr z,ist_shifted
        ld b,a
ist_sh: srl d
        rr e
        djnz ist_sh
ist_shifted:
        ld (hl),d
        inc h
        ld (hl),e
        dec h
        inc l
        inc c
        jr nz,ist_val
        inc h
        inc h
        ld a,(ist_n)
        inc a
        ld (ist_n),a
        cp 8
        jr nz,ist_page
        ret

init_stickman_shifted:
        ld hl,stickman
        ld de,sm_shifted
        ld a,SM_NFRAMES
        ld (iss_frame),a
iss_frame_loop:
        xor a
        ld (spr_n),a
iss_shift_loop:
        push hl
        ld b,SM_ROWS
iss_row:
        push bc
        ld b,SM_W
        call shift_row
        pop bc
        djnz iss_row
        pop hl
        ld a,(spr_n)
        inc a
        ld (spr_n),a
        cp 8
        jr nz,iss_shift_loop
        ld bc,SM_FRAME_SIZE
        add hl,bc
        ld a,(iss_frame)
        dec a
        ld (iss_frame),a
        jr nz,iss_frame_loop
        ret

message:
        db 127," 1982 Sinclair Research Ltd"

presets:
        dw -320, -512, 0
        db 1
        dw  256, -576, 0
        db 1
        dw -512, -320, 0
        db 1
        dw -128, -640, 0
        db 1
        dw  -96, -192, 22
        db 0
        dw   64, -160, 24
        db 0
        dw -192, -128, 20
        db 0
        dw  448, -384, 0
        db 1

dbl_tab:  db $00, $03, $0C, $0F, $30, $33, $3C, $3F, $C0, $C3, $CC, $CF, $F0, $F3, $FC, $FF
quad_tab: db $00, $0F, $F0, $FF
t3a_tab:  db $00, $03, $1C, $1F, $E0, $E3, $FC, $FF
t3b_tab:  db $00, $01, $0E, $0F, $70, $71, $7E, $7F, $80, $81, $8E, $8F, $F0, $F1, $FE, $FF
t3c_tab:  db $00, $07, $38, $3F, $C0, $C7, $F8, $FF

stickman:
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00001111, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %01000110, %00100000
        db %00000000, %10000110, %00010000
        db %00000001, %00000110, %00001000
        db %00000001, %00000110, %00000100
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %01000000, %00100000
        db %00000000, %10000000, %00010000
        db %00000001, %00000000, %00001000
        db %00000010, %00000000, %00000100
        db %00000100, %00000000, %00000010
        db %00001110, %00000000, %00000111
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00001111, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010110, %10000000
        db %00000000, %00010110, %10000000
        db %00000000, %00010110, %10000000
        db %00000000, %00010110, %10000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001110, %00000000
        db %00000000, %00010110, %00000000
        db %00000000, %00100110, %00000000
        db %00000000, %00100110, %00000000
        db %00000000, %01000110, %00000000
        db %00000000, %01000110, %00000000
        db %00000000, %10000110, %00000000
        db %00000001, %11000111, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00001111, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000001, %00000110, %01000000
        db %00000000, %10000110, %00100000
        db %00000000, %01000110, %01000000
        db %00000000, %00100110, %10000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %01000000, %00100000
        db %00000000, %10000000, %01000000
        db %00000001, %00000000, %10000000
        db %00000010, %00000000, %10000000
        db %00000100, %00000000, %10000000
        db %00001110, %00000000, %11100000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00001111, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010110, %10000000
        db %00000000, %00010110, %10000000
        db %00000000, %00010110, %10000000
        db %00000000, %00010110, %10000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001110, %00000000
        db %00000000, %00010110, %00000000
        db %00000000, %00010110, %00000000
        db %00000000, %00100110, %00000000
        db %00000000, %00100110, %00000000
        db %00000000, %00100110, %00000000
        db %00000000, %01000110, %00000000
        db %00000000, %11100111, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00001111, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00100110, %01000000
        db %00000000, %01000110, %00100000
        db %00000000, %10000110, %00010000
        db %00000001, %00000110, %00001000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00010000, %01000000
        db %00000000, %00010000, %00100000
        db %00000000, %00010000, %00100000
        db %00000000, %00010000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00010001, %00000000
        db %00000000, %00111000, %00000000
        db %00000000, %00000011, %11000000
        db %00000000, %00000100, %00100000
        db %00000000, %00001000, %00010000
        db %00000000, %00001000, %00010000
        db %00000000, %00000100, %00100000
        db %00000000, %00000011, %11000000
        db %00000000, %00000001, %10000000
        db %00000000, %00000001, %10000000
        db %00000000, %10000001, %10000001
        db %00000000, %01000001, %10000010
        db %00000000, %00100001, %10000100
        db %00000000, %00010001, %10001000
        db %00000000, %00000001, %10000000
        db %00000000, %00000001, %10000000
        db %00000000, %00000001, %10000000
        db %00000000, %00000011, %11000000
        db %00000000, %00000100, %00100000
        db %00000000, %00001000, %00010000
        db %00000000, %00010000, %00010000
        db %00000000, %00100000, %00010000
        db %00000111, %11000000, %00010000
        db %11101000, %00000000, %00010000
        db %11110000, %00000000, %00010000
        db %11100000, %00000000, %00111000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00001111, %00001000
        db %00000000, %00010000, %10001000
        db %00000000, %00100000, %01010000
        db %00000000, %00100000, %01010000
        db %00000000, %00010000, %10010000
        db %00000000, %00001111, %00010000
        db %00000000, %00001100, %00100000
        db %00000000, %00011111, %11100000
        db %00000000, %00011000, %00000000
        db %00000000, %00110000, %00000000
        db %00000000, %00110000, %00000000
        db %00000000, %01100000, %00000000
        db %00000000, %11100000, %00000000
        db %00000000, %11000000, %00000000
        db %00000001, %11000000, %00000000
        db %00000001, %10000000, %00000000
        db %00000001, %10000000, %00000000
        db %00000011, %00000000, %00000000
        db %00000011, %00000000, %00000000
        db %00000110, %00000000, %00000000
        db %00000110, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000001
        db %00000000, %00010000, %10000010
        db %00000000, %00001111, %00001100
        db %00000000, %00001100, %00010000
        db %00000000, %00011111, %11100000
        db %00000000, %00011000, %00000000
        db %00000000, %00110000, %00000000
        db %00000000, %00110000, %00000000
        db %00000000, %01100000, %00000000
        db %00000000, %11100000, %00000000
        db %00000000, %11000000, %00000000
        db %00000001, %11000000, %00000000
        db %00000001, %10000000, %00000000
        db %00000001, %10000000, %00000000
        db %00000011, %00000000, %00000000
        db %00000011, %00000000, %00000000
        db %00000110, %00000000, %00000000
        db %00000110, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000001, %11100000
        db %00000000, %00000010, %00010000
        db %00000000, %00000100, %00001000
        db %00000000, %00000100, %00001000
        db %00000000, %00000010, %00010000
        db %00000000, %10000001, %11100000
        db %00000000, %01000000, %11000000
        db %00000000, %00110000, %11001100
        db %00000000, %00001001, %10110000
        db %00000000, %00000101, %11000000
        db %00000000, %00000011, %00000000
        db %00000000, %00000011, %00000000
        db %00000000, %00000011, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001001, %00000000
        db %00000000, %00001001, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %01000000, %00100000
        db %00000000, %01000000, %00100000
        db %00000000, %10000000, %00010000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %01111000
        db %00000000, %00000000, %10000100
        db %00000000, %00000001, %00000010
        db %00000000, %00100001, %00000010
        db %00000000, %00010000, %10000100
        db %00000000, %00001000, %01111000
        db %00000000, %00000100, %11000000
        db %00000000, %00000011, %10000000
        db %00000000, %00000011, %11000000
        db %00000000, %00001110, %00110000
        db %00000000, %00011000, %00001100
        db %00000000, %00110000, %00000000
        db %00000000, %01100000, %00000000
        db %00000000, %11000000, %00000000
        db %00000011, %10000000, %00000000
        db %00000100, %10000000, %00000000
        db %00001001, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00001000
        db %00000000, %00000000, %00011100
        db %00000000, %00000001, %00001000
        db %00000000, %00000011, %10000000
        db %00000000, %00000001, %00000010
        db %00000000, %00000000, %00000111
        db %00000000, %00000000, %00000010
        db %00000000, %00000010, %00000000
        db %00000000, %00000010, %01111000
        db %01100000, %00000100, %10000100
        db %00011000, %00000101, %00000010
        db %00000111, %11111111, %10000010
        db %00001111, %11111111, %10000100
        db %01110000, %00000000, %01111000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00000000, %00000000
        db %00000000, %00001111, %00000000
        db %00000000, %00010000, %10000000
        db %00000000, %00100000, %01000000
        db %00000000, %00100000, %01000000
        db %00000000, %00010000, %10000000
        db %00000000, %00001111, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00000110, %00000000
        db %00000000, %00001110, %00000000
        db %00000000, %00010110, %00000000
        db %00000000, %00101101, %00000000
        db %00000000, %01001100, %10000000
        db %00000000, %10001100, %01000000
        db %00000000, %00001110, %00000000
        db %00000000, %00010001, %11000000
        db %00000000, %01100000, %01000000
        db %00000001, %10000000, %00100000
        db %00000110, %00000000, %00100000

seed:      db 1
zoom_active: db 0
demo_done: db 0
sm_x:      dw 0
sm_state:  db 0
sm_frame:  db 0
sm_anim:   db 0
sm_timer:  db 0
sm_target: db 0
sm_drawn:  db 0
sm_seqp:   dw 0
basic_hl2: dw 0
cur_scale: db 1
spr_src:   dw 0
spr_lines: db 0
spr_w1:    db 0
spr_x:     dw 0
spr_y:     dw 0
spr_col:   dw 0
spr_n:     db 0
spr_fast:  db 0
cl_col:    db 0
cl_lead:   db 0
cl_vis:    db 0
cl_skip:   db 0
ist_n:     db 0
iss_frame: db 0
rowbuf:    ds 5
glyphbuf:  ds 32
ip_buf:    dw 0
blitbufs:  ds MSG_LEN*BLITBUF_SIZE
particles: ds MSG_LEN*P_SIZE
sm_shifted: ds SM_NFRAMES*8*SM_SHIFTED_SIZE

        ds ($100 - ($ and $FF)) and $FF
shift_tables:
SHIFT_PAGE equ shift_tables/256
        ds 4096
end_of_code:

        end start
