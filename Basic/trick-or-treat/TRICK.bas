30 BORDER 0: PAPER 0: INK 7: BRIGHT 1: CLS
40 GO SUB 9000
50 LET hi=0
60 GO SUB 8000
100 LET t=0: LET bg=0: LET bk=0
120 DIM o(8): DIM v(8): DIM l(8): DIM p(8): DIM k(8): DIM s(8)
130 GO SUB 3000
140 GO SUB 2000
200 GO SUB 2500: IF t>=360 THEN GO TO 5000
205 LET z=0: FOR y=1 TO 8: LET z=z+v(y): NEXT y
206 IF z=8 THEN GO SUB 2600: LET m$="Every door on this street done.": GO SUB 2700: PAUSE 75: GO TO 1800
220 PRINT AT 21,0; FLASH 1;"Which door?"; FLASH 0;"                   "
230 GO SUB 2800
240 IF a$="h" OR a$="H" THEN GO TO 1700
250 IF a$="n" OR a$="N" THEN GO TO 1800
260 IF a$<"1" OR a$>"8" THEN GO TO 230
270 LET d=VAL a$: IF v(d) THEN GO SUB 2600: LET m$="You've already been to number "+STR$ d+".": GO SUB 2700: GO TO 230
1000 LET v(d)=1: LET t=t+8+INT (RND*8)
1020 GO SUB 2600: PRINT AT 21,0;"                               ": LET m$="You knock at number "+STR$ d+"...": GO SUB 2700
1030 BEEP .05,-20: PAUSE 6: BEEP .05,-20: PAUSE 40
1040 GO SUB 2500
1050 GO TO 1000+100*o(d)
1100 LET n=s(d): LET r=INT (RND*4)
1115 IF n>=6 THEN LET m$="Full size chocolate bars!": GO SUB 2700: LET m$="JACKPOT!": GO TO 1150
1120 IF r=0 THEN LET m$="A handful of toffees."
1125 IF r=1 THEN LET m$="A little old lady with a bowl."
1130 IF r=2 THEN LET m$="Two kids in bin bags. They share."
1135 IF r=3 THEN LET m$="A tired dad. Quality Street."
1150 GO SUB 2700: LET m$="You get "+STR$ n+" sweets.": GO SUB 2700
1160 LET bg=bg+n: FOR j=1 TO n: BEEP .04,10+j*2: NEXT j
1170 GO TO 1900
1200 LET r=INT (RND*2)
1220 IF NOT l(d) THEN LET m$="The lights are off. No answer.": GO TO 1240
1225 IF r=0 THEN LET m$="A curtain twitches. Nothing."
1230 IF r=1 THEN LET m$="The door opens... and slams."
1240 GO SUB 2700: BEEP .3,-20
1250 GO TO 1900
1300 LET m$="A huge dog bursts out barking!": GO SUB 2700
1320 LET n=INT (RND*3)+1: IF n>bg THEN LET n=bg
1330 LET m$="You run. You drop "+STR$ n+" sweets.": IF n=0 THEN LET m$="You run. Bag was empty anyway."
1340 GO SUB 2700: LET bg=bg-n: LET t=t+10
1350 FOR j=1 TO 8: BEEP .03,-30+RND*6: NEXT j
1360 GO TO 1900
1400 LET m$="The door creaks open...": GO SUB 2700: PAUSE 50
1420 LET m$="A WITCH! She snatches your bag": GO SUB 2700: LET m$="and chases you all the way home!": GO SUB 2700
1430 LET bg=0: LET t=t+20
1440 FOR j=1 TO 4: BEEP .06,24: BEEP .06,19: BEEP .06,15: NEXT j: FOR j=12 TO -12 STEP -3: BEEP .04,j: NEXT j
1450 GO TO 1900
1500 LET m$="'Trick or treat? TRICK! Go on.'": GO SUB 2700
1520 LET m$="Type the magic word before the": GO SUB 2700: LET m$="door shuts!": GO SUB 2700
1530 LET w$=q$(INT (RND*8)+1)
1540 PRINT AT 13,11; INK 6; FLASH 1;"  ";w$;"  "; FLASH 0
1550 LET lim=180-15*h: LET f0=PEEK 23672+256*PEEK 23673: LET j=1
1560 LET f=PEEK 23672+256*PEEK 23673-f0: IF f<0 THEN LET f=f+65536
1565 LET n=INT ((lim-f)/lim*20): IF n<0 THEN LET n=0
1570 PRINT AT 14,6; INK 2;b$( TO n);"                    "( TO 20-n)
1575 IF f>=lim THEN GO TO 1620
1580 LET a$=INKEY$: IF a$="" THEN GO TO 1560
1585 IF a$<>w$(j) AND a$<>CHR$ (CODE w$(j)+32) THEN GO TO 1560
1590 BEEP .03,20+j*5: PRINT AT 15,12+j; INK 4;w$(j)
1595 IF INKEY$<>"" THEN GO TO 1595
1600 LET j=j+1: IF j<=3 THEN GO TO 1560
1605 GO SUB 2600: LET m$="'Ha! Not bad, kid. Here.'": GO SUB 2700
1610 LET n=5+INT (RND*4): LET m$="You get "+STR$ n+" sweets!": GO SUB 2700: LET bg=bg+n
1615 FOR j=1 TO 6: BEEP .05,j*3: NEXT j: GO TO 1900
1620 GO SUB 2600: LET m$="Too slow! The door slams shut.": GO SUB 2700: BEEP .3,-25: LET t=t+5
1630 GO TO 1900
1700 IF bg=0 THEN GO SUB 2600: LET m$="Your bag is empty. No point yet!": GO SUB 2700: GO TO 230
1720 GO SUB 2600: LET t=t+30
1730 LET m$="You run home and tip "+STR$ bg+" sweets": GO SUB 2700: LET m$="into the big bowl. Safe!": GO SUB 2700
1740 LET bk=bk+bg: LET bg=0
1750 BEEP .1,0: BEEP .1,4: BEEP .1,7: BEEP .2,12
1760 LET m$="Then you head back out...": GO SUB 2700
1770 GO TO 1910
1800 LET t=t+15: GO SUB 3000: GO SUB 2000: GO SUB 2600
1820 LET m$="You wander over to "+s$: GO SUB 2700
1830 GO TO 1910
1900 GO SUB 2200
1910 GO SUB 2500
1920 PRINT AT 21,0;"Press any key                  "
1930 GO SUB 2800
1940 GO TO 200
2000 CLS : PRINT AT 0,0; INK 6;"TRICK OR TREAT"
2020 PRINT AT 2,9; INK 5;s$
2030 FOR i=1 TO 8: LET c=(i-1)*4
2040 PRINT AT 3,c; INK 2;" ";CHR$ 144;CHR$ 145;" "
2050 PRINT AT 4,c; INK 7;CHR$ 146; INK 1+5*l(i);CHR$ 147;CHR$ 147; INK 7;CHR$ 146
2060 PRINT AT 5,c; INK 7;CHR$ 146; INK 3;CHR$ 148; INK 7;STR$ i;CHR$ 146
2070 PRINT AT 6,c;" "; INK 6;(CHR$ 149 AND p(i))+(" " AND NOT p(i)); INK 4;(CHR$ 150 AND k(i))+(" " AND NOT k(i));" "
2080 NEXT i
2090 PRINT AT 7,0; INK 1;g$
2100 PRINT AT 17,0; INK 5;"1-8"; INK 7;" Knock on a door"
2110 PRINT AT 18,0; INK 5;"H"; INK 7;"   Run home and empty bag (30m)"
2120 PRINT AT 19,0; INK 5;"N"; INK 7;"   Try the next street (15m)"
2130 RETURN
2200 LET c=(d-1)*4+2
2220 IF o(d)=1 THEN PRINT AT 5,c; INK 6;CHR$ 151
2230 IF o(d)=2 THEN PRINT AT 5,c; INK 1;"X"
2240 IF o(d)=3 THEN PRINT AT 5,c; INK 4;CHR$ 152
2250 IF o(d)=4 THEN PRINT AT 5,c; INK 3;CHR$ 153
2260 IF o(d)=5 THEN PRINT AT 5,c; INK 5;"!"
2270 RETURN
2500 LET hh=18+INT (t/60): LET mm=t-60*INT (t/60)
2520 LET c$=STR$ hh+":"+("0" AND mm<10)+STR$ mm: IF t>=360 THEN LET c$="00:00"
2530 PRINT AT 0,21; INK 7;"Time "; INK 6;c$;"  "
2540 PRINT AT 1,0; INK 7;"Bag "; INK 6;bg; INK 7;"  Home "; INK 6;bk; INK 7;"  Best "; INK 6;hi;"    "
2550 RETURN
2600 FOR y=9 TO 15: PRINT AT y,0;"                                ": NEXT y
2620 LET mr=9: RETURN
2700 PRINT AT mr,0;m$: LET mr=mr+1: RETURN
2800 IF INKEY$<>"" THEN GO TO 2800
2810 LET a$=INKEY$: IF a$="" THEN GO TO 2810
2820 RETURN
3000 LET h=INT (t/60): IF h>5 THEN LET h=5
3020 LET s$=n$(INT (RND*8)+1)
3030 FOR i=1 TO 8
3040 LET r=RND*100: LET v(i)=0
3050 LET o(i)=1: IF r>=55-5*h THEN LET o(i)=2
3060 IF r>=70-6*h THEN LET o(i)=3
3070 IF r>=80-4*h THEN LET o(i)=4
3080 IF r>=85 THEN LET o(i)=5
3090 LET s(i)=1+INT (RND*4): IF RND<.1 THEN LET s(i)=s(i)+5
3100 LET l(i)=(RND<.8): LET p(i)=(RND<.7): LET k(i)=(RND<.15)
3110 IF o(i)=2 THEN LET l(i)=(RND<.15): LET p(i)=(RND<.3)
3120 IF o(i)=3 THEN LET k(i)=(RND<.7)
3130 IF o(i)=4 THEN LET l(i)=(RND<.35): LET p(i)=(RND<.5)
3140 IF o(i)=5 THEN LET l(i)=(RND<.9): LET p(i)=(RND<.8)
3150 NEXT i
3160 RETURN
5000 GO SUB 2600
5020 LET m$="MIDNIGHT! Mum's on the doorstep.": GO SUB 2700
5030 LET n=INT (bg/2)
5040 IF bg>0 THEN LET m$="'You're late! Half that bag is": GO SUB 2700: LET m$="going in the cupboard.'": GO SUB 2700: LET m$="You keep "+STR$ n+" of "+STR$ bg+".": GO SUB 2700
5050 LET bk=bk+n: LET bg=0
5060 LET m$="Total haul: "+STR$ bk+" sweets.": GO SUB 2700
5070 LET m$="Rubbish. Straight to bed.": IF bk>=20 THEN LET m$="Not bad for a first go."
5080 IF bk>=40 THEN LET m$="Sugar rush incoming!"
5090 IF bk>=60 THEN LET m$="Legendary haul. Dentist's dream."
5100 GO SUB 2700
5110 IF bk>hi THEN LET hi=bk: PRINT AT mr,0; INK 6; FLASH 1;"        NEW BEST HAUL!          "
5120 GO SUB 2500
5130 FOR j=1 TO 12: BEEP .12,-5: PAUSE 8: NEXT j
5140 PRINT AT 21,0;"Play again? (Y/N)              "
5150 GO SUB 2800: IF a$="y" OR a$="Y" THEN GO TO 100
5160 IF a$="n" OR a$="N" THEN GO TO 60
5170 GO TO 5150
8000 CLS
8020 FOR i=0 TO 7: PRINT AT 2,2+i*4; INK 6;CHR$ 149: NEXT i
8030 PRINT AT 4,9; INK 2; FLASH 1;"TRICK OR TREAT"
8040 PRINT AT 6,3; INK 7;"A Halloween game of nerve"
8050 PRINT AT 8,0; INK 5;"Knock on doors until midnight."
8060 PRINT AT 9,0; INK 5;"Sweets in your bag are at risk:"
8070 PRINT AT 10,0; INK 5;"dogs make you drop them and the"
8080 PRINT AT 11,0; INK 5;"witch takes the lot. Run home to"
8090 PRINT AT 12,0; INK 5;"bank them, but it costs time."
8100 PRINT AT 14,0; INK 7;"Read the street. "; INK 6;CHR$ 147; INK 7;" lit windows"
8110 PRINT AT 15,0; INK 7;"and "; INK 6;CHR$ 149; INK 7;" pumpkins are good signs."
8120 PRINT AT 16,0; INK 4;CHR$ 150; INK 7;" is a kennel. Mind the dog."
8130 PRINT AT 18,0; INK 6;"Trick houses want a magic word."
8140 PRINT AT 20,5; INK 7; FLASH 1;"Press any key to start"
8150 PRINT AT 21,7; INK 1;"Damian Cooper 2026"
8160 BEEP .2,0: BEEP .2,3: BEEP .2,7: BEEP .4,12: BEEP .2,7: BEEP .2,3: BEEP .5,0
8170 GO SUB 2800: RANDOMIZE : RETURN
9000 LET u=USR "a"
9020 FOR i=0 TO 87: READ b: POKE u+i,b: NEXT i
9030 DATA 1,3,7,15,31,63,127,255
9040 DATA 128,192,224,240,248,252,254,255
9050 DATA 255,136,136,136,255,34,34,34
9060 DATA 255,145,145,145,255,145,145,255
9070 DATA 255,129,189,189,185,189,129,255
9080 DATA 16,56,126,219,255,189,66,60
9090 DATA 24,60,126,255,231,195,195,255
9100 DATA 0,189,126,255,255,126,189,0
9110 DATA 0,12,15,126,252,124,68,68
9120 DATA 24,24,60,126,255,60,60,126
9130 DATA 60,126,219,255,255,255,255,165
9140 DIM n$(8,13): FOR i=1 TO 8: READ n$(i): NEXT i
9150 DATA "Pumpkin Lane","Gallows Row","Bone Alley","Cobweb Close","Raven Street","Marrow Drive","Coffin Court","Bat Crescent"
9160 DIM q$(8,3): FOR i=1 TO 8: READ q$(i): NEXT i
9170 DATA "BOO","BAT","HEX","OWL","WEB","RIP","FOG","EEK"
9180 LET g$="": LET b$="": FOR i=1 TO 32: LET g$=g$+CHR$ 140: NEXT i
9190 FOR i=1 TO 20: LET b$=b$+CHR$ 143: NEXT i
9200 RETURN
