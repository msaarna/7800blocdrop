
; Disassembly of blocdrop78.bin, by Mike Saarna
; In honored memory of Ken Siders. (1968-2017) You are missed.

 processor        6502

INPTCTRL   =        $01
INPT4      =        $0C
INPT5      =        $0D
AUDC0      =        $15
AUDC1      =        $16
AUDF0      =        $17
AUDF1      =        $18
AUDV0      =        $19
AUDV1      =        $1A
BACKGRND   =        $20
P0C1       =        $21
P0C2       =        $22
P0C3       =        $23
P1C1       =        $25
P1C2       =        $26
P1C3       =        $27
MSTAT      =        $28
P2C1       =        $29
P2C2       =        $2A
P2C3       =        $2B
DPPH       =        $2C
P3C1       =        $2D
P3C2       =        $2E
P3C3       =        $2F
DPPL       =        $30
P4C1       =        $31
P4C2       =        $32
P4C3       =        $33
CHBASE     =        $34
P5C1       =        $35
P5C2       =        $36
P5C3       =        $37
OFFSET     =        $38
P6C1       =        $39
P6C2       =        $3A
P6C3       =        $3B
CTRL       =        $3C
P7C1       =        $3D
P7C2       =        $3E
P7C3       =        $3F
SWCHA      =        $0280
SWACNT     =        $0281
SWBCNT     =        $0283

PAUDCTL    =        $4008

; ******************* ZP Memory Allocations...

TEMP1      =        $90
TEMP2      =        $91

PieceShapePointer = $92     ; + $93

PieceX     =        $9D
PieceY     =        $9E

PieceTypeIndex =    $A0
PieceRotation =     $A1

NMIPointer =        $B0     ; + $B1

SFX0EnabledFlag =   $B7
SFX1EnabledFlag =   $B8
SFX0Pointer =       $B9     ; + $BA
SFX1Pointer =       $BB     ; + $BC
SFX0SampleDuration =        $BD
SFX1SampleDuration =        $BE

P0PieceType =       $BF
P1PieceType =       $C0

P0PieceRotation =   $C3
P1PieceRotation =   $C4
P0PieceX   =        $C5
P1PieceX   =        $C6
P0PieceY   =        $C7
P1PieceY   =        $C8

P0DownwardTicks =   $D5
P1DownwardTicks =   $D6

P0DownwardSpeed =   $D7
P1DownwardSpeed =   $D8

P0ClearRowState =   $DB
P1ClearRowState =   $DC

P0LinesLeftInLevel =        $E1
P1LinesLeftInLevel =        $E2

P0GameStateFlag =   $E3
P1GameStateFlag =   $E4

P0PointsScoredDelay =       $E5
P1PointsScoredDelay =       $E6
PlayerIndex =       $E7

FrameCounter =      $E8     ; + $E9

P0TotalLinesClearedBCD =    $EA     ; + $EB
P1TotalLinesClearedBCD =    $EC     ; + $ED
P0TotalLinesCleared =       $EE     ; + $EF
P1TotalLinesCleared =       $F0     ; + $F1


; ******************* Upper Memory Allocations...

DUMMYDL    =        $2300   ; - $2301: a 2 byte DL terminator, used for blank DLs.

; When you clear lines, the amount to be added to your score is temporarily displayed.
; These are the display memory locations used for that...
P0ScoreAdditionDisplay =    $2416   ; to 2418
P1ScoreAdditionDisplay =    $241D   ; to 241F

; 4 bytes of score for player 0...
ScoreP0    =        $253D   ; to $2540

; 4 bytes of score for player 1...
ScoreP1    =        $2541   ; to $2544

; 4 bytes for the high score...
HiScore    =        $2545   ; to $2548

; 3 bytes of lines cleared for player 0...
LinesClearedP0 =    $24ED   ; to $24EF

; 3 bytes of lines cleared for player 1...
LinesClearedP1 =    $250E   ; to $2410

; ********************* Constants...

GameStateGAMEOVER = $FF
GameStateINITIALIZING =     $FE
GameStatePLAYING =  $00


           ORG       $4000
           .byte   $00     ; ** I guess this was Ken's way of reserving this ROM?

                     ; ** TODO: reverse the graphics to sprite sheets. The game appears to use 320C. (exclusively?)

                     ; ** 8000-87FF Sprite GFX, 8-lines tall
                     ; ** 9000-97FF Sprite GFX, 8-lines tall
                     ; ** A000-A7FF Sprite GFX, 8-lines tall


           ORG       $8000
           incbin    ImageData8000.bin

           ORG       $9000
                     ; the character set graphics for the game...
           incbin    ImageData9000.bin

           ORG       $A000
           incbin    ImageDataA000.bin

           ORG       $B000


; *** a fairly standard 7800 console init...
ConsoleInit
           SEI
           CLD
           LDA       #%00000111      ; disable TIA video and bios, enable Maria
           STA       INPTCTRL
                     ;         CDDWBKRR   C=ColorKill, D=DMA, W=double-wide chars, K=kangaroo, R=read-mode
                     ;         ||||||||
           LDA       #%01111111      ; Color on, DMA off, double-wide chars, kangaro on, 320A/320C mode
           STA       CTRL

           LDA       #$00
           STA       PAUDCTL
           STA       OFFSET
           STA       INPTCTRL        ; INPTCTRL is locked

                     ; *** clear out lower memory, etc...
GameInit

           LDX       #$FF    ; set us up the stack...
           TXS
           LDX       #$40    ; clear-out zero page and stack...
           LDA       #$00
ClearMemLoop
           STA       $00,X
           STA       $0100,X
           INX
           BNE       ClearMemLoop

                     ; *** set all palette colors to black...
           LDA       #$00
           LDX       #$1B
ClearPaletteLoop
           STA       P0C1,X
           STA       P0C2,X
           STA       P0C3,X
           DEX
           DEX
           DEX
           DEX
           BPL       ClearPaletteLoop

                     ; *** clear out the upper memory locations...
           LDA       #$00
           STA       TEMP1
           LDA       #$18
           STA       TEMP2   ; (TEMP1) = $1800
           LDA       #$40    ; #_of_bytes to clear
           LDX       #$08    ; #_of_pages to clear
           JSR       ClearMemory     ; clear $1800-203F
           LDA       #$00
           STA       TEMP1
           LDA       #$22
           STA       TEMP2   ; (TEMP1) = $2200
           LDA       #$00    ; #_of_bytes to clear
           LDX       #$06    ; #_of_pages to clear
           JSR       ClearMemory     ; clear $2200-$27FF


                     ; *** clear riot and the last bit of upper memory...
           LDA       #$00
           LDY       #$7F
ClearMiscRamLoop
           STA       $480,Y  ; RIOT RAM
           STA       $2100,Y
           DEY
           BPL       ClearMiscRamLoop


                     ; *** set RIOT ports to input...
           LDA       #$00
           STA       SWACNT  ; joystick pins
           STA       SWBCNT  ; console switches

                     ; *** ???
           LDA       #$07    ; B065 A9 07
           LDX       #$15    ; B067 A2 15
           JSR       LC0EC   ; ... ($B2) = $1507, ($B4) = 0000

                     ; *** point NMI to our IRQ handler, which just does an "RTI"...
           LDA       #<IRQ
           STA       NMIPointer
           LDA       #>IRQ
           STA       NMIPointer+1

                     ; ** setup color palettes...
           LDA       #$00    ; Black
           STA       BACKGRND
           LDA       #$44    ; Drk.Red
           STA       P0C1
           LDA       #$48    ; Med.Red
           STA       P0C2
           LDA       #$4B    ; Lgt.Red
           STA       P0C3
           LDA       #$34    ; Drk.Salmon
           STA       P1C1
           LDA       #$38    ; Med.Salmon
           STA       P1C2
           LDA       #$3B    ; Lgt.Salmon
           STA       P1C3
           LDA       #$94    ; Drk.Blue
           STA       P2C1
           LDA       #$98    ; Med.Blue
           STA       P2C2
           LDA       #$9B    ; Lgt.Blue
           STA       P2C3
           LDA       #$06    ; Drk.Grey
           STA       P3C1
           LDA       #$08    ; Med.Grey
           STA       P3C2
           LDA       #$0D    ; Lgt.Grey
           STA       P3C3
           LDA       #$C4    ; Drk.Green
           STA       P4C1
           LDA       #$C8    ; Med.Green
           STA       P4C2
           LDA       #$CB    ; Lgt.Green
           STA       P4C3
           LDA       #$16    ; Drk.Yellow
           STA       P5C1
           LDA       #$1A    ; Med.Yellow
           STA       P5C2
           LDA       #$1D    ; Lgt.Yellow
           STA       P5C3
           LDA       #$64    ; Drk.Purple
           STA       P6C1
           LDA       #$68    ; Med.Purple
           STA       P6C2
           LDA       #$6B    ; Lgt.Purple
           STA       P6C3
           LDA       #$A6    ; Drk.Turquoise
           STA       P7C1
           LDA       #$AA    ; Med.Turquoise
           STA       P7C2
           LDA       #$AD    ; Drk.Turquoise
           STA       P7C3

           JSR       ScreenInit      ; Setup DLL, DLs, and init char buffer contents.

           LDA       #$00
           STA       DPPL
           LDA       #$22
           STA       DPPH    ; DLL is at $2200

                     ; *** set the NMI pointer to the main game NMI routine...
           LDA       #<NMIMainGame
           STA       NMIPointer
           LDA       #>NMIMainGame
           STA       NMIPointer+1

           JSR       WaitForVblankStart

;                      CDDWBKRR   C=ColorKill, D=DMA, W=double-wide chars, K=kangaroo, R=read-mode
;                      ||||||||
           LDA       #%01010000
           STA       CTRL    ; Color on, DMA on, double-wide chars, kangaro off, 160A/160B mode

           LDA       #$00
           STA       PlayerIndex

; We use the piece render routine to draw the "BLOC DROP" logo...

           LDA       #$1C    ; "B"
           LDX       #$00    ; Y=X Coordinate
           LDY       #$04    ; Y=Y Coordinate
           JSR       RenderPiece

           LDA       #$1D    ; "L"
           LDX       #$03
           LDY       #$04
           JSR       RenderPiece

           LDA       #$1E    ; "O"
           LDX       #$04
           LDY       #$04
           JSR       RenderPiece

           LDA       #$1F    ; "C"
           LDX       #$07
           LDY       #$04
           JSR       RenderPiece

           LDA       #$20    ; "D"
           LDX       #$00
           LDY       #$09
           JSR       RenderPiece

           LDA       #$21    ; "R"
           LDX       #$03
           LDY       #$09
           JSR       RenderPiece

           LDA       #$22    ; "O"
           LDX       #$04
           LDY       #$09
           JSR       RenderPiece

           LDA       #$23    ; "P"
           LDX       #$07
           LDY       #$09
           JSR       RenderPiece


                     ; copy "(c) 2013" string into the left play-area...
           LDA       #<string_copyright_2013
           STA       PieceShapePointer
           LDA       #>string_copyright_2013
           STA       PieceShapePointer+1
           LDX       #$00
           LDY       #$0F
           LDA       #$40
           JSR       CopyStringToBuf


                     ; copy "KEN" string into the left play-area...
           LDA       #<string_KEN
           STA       PieceShapePointer
           LDA       #>string_KEN
           STA       PieceShapePointer+1
           LDX       #$02
           LDY       #$11
           LDA       #$00
           JSR       CopyStringToBuf


                     ; copy "SIDERS" string into the left play-area...
           LDA       #<string_SIDERS
           STA       PieceShapePointer
           LDA       #>string_SIDERS
           STA       PieceShapePointer+1
           LDX       #$02
           LDY       #$12
           LDA       #$00
           JSR       CopyStringToBuf


                     ; copy "NOT 4 SALE" string into the left play-area...
           LDA       #<string_NOT_4_SALE
           STA       PieceShapePointer
           LDA       #>string_NOT_4_SALE
           STA       PieceShapePointer+1
           LDX       #$00
           LDY       #$14
           LDA       #$80
           JSR       CopyStringToBuf


                     ; copy "Demo Mar10" string into the left play-area...
           LDA       #<string_demo_mar10
           STA       PieceShapePointer
           LDA       #>string_demo_mar10
           STA       PieceShapePointer+1
           LDX       #$00
           LDY       #$16
           LDA       #$C0
           JSR       CopyStringToBuf


           LDA       #GameStateGAMEOVER
           STA       P0GameStateFlag
           STA       P1GameStateFlag

           LDA       #$01
           STA       PlayerIndex

           LDA       #$42
           STA       P0LinesLeftInLevel
           STA       P1LinesLeftInLevel

MainLoop
           LDA       PlayerIndex
           EOR       #$01
           STA       PlayerIndex     ; flip back and forth between players, for each loop iteration.
           LDX       PlayerIndex
           TAX
           LDA       P0PointsScoredDelay,X
           BNE       SkipClearPointsScored
           LDY       #$02
           LDA       PlayerIndex
           BEQ       ClearPointsScored
           LDY       #$07    ; if this is P1, adjust the offset so we change the P1 characters instead
ClearPointsScored
           LDA       #$0A    ; the space character
           STA       P0ScoreAdditionDisplay,Y
           STA       P0ScoreAdditionDisplay+1,Y
           STA       P0ScoreAdditionDisplay+2,Y
SkipClearPointsScored
           JSR       LC0BF
           LDX       PlayerIndex
           LDA       P0GameStateFlag,X
           BPL       LB1F2
           LDA       INPT4,X ; Check if the joystick button is pressed...
           AND       #$80
           BEQ       PlayerStartedGame
           LDA       P0GameStateFlag,X
           CMP       #GameStateINITIALIZING
           BEQ       GamePlayingRoutines
           JMP       MainLoop
PlayerStartedGame
           LDA       P0GameStateFlag,X
           CMP       #GameStateINITIALIZING
           BEQ       MainLoop
           LDA       #GameStateINITIALIZING
           STA       P0GameStateFlag,X
           JMP       MainLoop
GamePlayingRoutines
           LDA       #GameStatePLAYING
           STA       P0GameStateFlag,X
           JSR       InitPlayerGameVars
           JSR       LB95B
LB1F2      LDX       PlayerIndex
           LDA       P0ClearRowState,X
           BNE       LB1FB   ; branch if we're in the middle of a row clearing
           JMP       LB287   ; otherwise ?
LB1FB      BPL       LB229
           LDX       PlayerIndex
           LDA       $DD,X   ; B1FF B5 DD
           STA       $A4     ; B201 85 A4
           LDA       #$00    ; B203 A9 00
           STA       $A3     ; B205 85 A3
LB207      ASL       $A4     ; B207 06 A4
           BCC       LB218   ; B209 90 0D
           LDX       PlayerIndex
           CLC               ; B20D 18
           LDA       $A3     ; B20E A5 A3
           ADC       P0PieceY,X
           TAY               ; B212 A8
           LDA       #$61    ; B213 A9 61
           JSR       LC1FE   ; B215 20 FE C1
LB218      INC       $A3     ; B218 E6 A3
           LDA       $A3     ; B21A A5 A3
           CMP       #$04    ; B21C C9 04
           BNE       LB207   ; B21E D0 E7
           LDA       #$08    ; B220 A9 08
           LDX       PlayerIndex
           STA       P0ClearRowState,X
           JMP       MainLoop        ; B226 4C A3 B1
LB229      LDA       P0ClearRowState,X
           CMP       #$01    ; B22B C9 01
           BEQ       LB232   ; B22D F0 03
           JMP       MainLoop        ; B22F 4C A3 B1
LB232      LDX       PlayerIndex
           LDA       $DD,X   ; B234 B5 DD
           STA       $A4     ; B236 85 A4
           JSR       LB50C   ; B238 20 0C B5
           LDA       #$00    ; B23B A9 00
           STA       $A3     ; B23D 85 A3
LB23F      ASL       $A4     ; B23F 06 A4
           BCC       LB263   ; B241 90 20
           CLC               ; B243 18
           LDA       $A3     ; B244 A5 A3
           LDX       PlayerIndex
           ADC       P0PieceY,X      ; B248 75 C7
           TAY               ; B24A A8
           JSR       LC21F   ; B24B 20 1F C2
           LDA       #$01    ; B24E A9 01
           JSR       LC6EF   ; B250 20 EF C6
           LDX       PlayerIndex
           LDA       P0LinesLeftInLevel,X
           SEC               ; B257 38
           SBC       #$01    ; B258 E9 01
           BPL       LB25E   ; B25A 10 02
           LDA       #$00    ; B25C A9 00
LB25E      STA       P0LinesLeftInLevel,X
           JSR       LC08B   ; B260 20 8B C0
LB263      INC       $A3     ; B263 E6 A3
           LDA       $A3     ; B265 A5 A3
           CMP       #$04    ; B267 C9 04
           BNE       LB23F   ; B269 D0 D4
           LDA       #$00    ; B26B A9 00
           LDX       PlayerIndex
           STA       P0ClearRowState,X
           JSR       LB95B   ; B271 20 5B B9
           BCS       LB279   ; B274 B0 03
           JMP       MainLoop        ; B276 4C A3 B1
LB279      PLA               ; B279 68
           PLA               ; B27A 68
           LDX       PlayerIndex
           LDA       #GameStateGAMEOVER
           STA       P0GameStateFlag,X
           JSR       LC6A0   ; B281 20 A0 C6
           JMP       MainLoop        ; B284 4C A3 B1
LB287      LDX       PlayerIndex
           LDA       P0DownwardTicks,X
           BEQ       LB290   ; B28B F0 03
           JMP       LB347   ; B28D 4C 47 B3
LB290      LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA               ; B296 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX
           PLA
           JSR       LC187
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA
           LDY       P0PieceY,X
           INY
           LDA       P0PieceX,X
           TAX               ; B2AC AA
           PLA               ; B2AD 68
           JSR       LC249   ; B2AE 20 49 C2
           BCS       LB2CF   ; B2B1 B0 1C
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA               ; B2B9 48
           LDY       P0PieceY,X
           INY               ; B2BC C8
           STY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B2C1 AA
           PLA               ; B2C2 68
           JSR       RenderPiece     ; B2C3 20 21 C1
           LDA       #$14    ; B2C6 A9 14
           LDX       PlayerIndex
           STA       P0DownwardTicks,X
           JMP       MainLoop        ; B2CC 4C A3 B1
LB2CF      LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B2DA AA
           PLA               ; B2DB 68
           JSR       RenderPiece
           LDX       PlayerIndex
           LDA       #$00    ; B2E1 A9 00
           STA       $CB,X   ; B2E3 95 CB
           LDA       #$01    ; B2E5 A9 01
           STA       $C9,X   ; B2E7 95 C9
           LDA       P0PieceY,X
           CMP       #$03    ; B2EB C9 03
           BCS       LB308   ; B2ED B0 19
           LDA       #GameStateGAMEOVER
           STA       P0GameStateFlag,X
           JSR       LC6A0   ; B2F3 20 A0 C6
           JMP       MainLoop        ; B2F6 4C A3 B1
           LDA       P0GameStateFlag
           CMP       #GameStateGAMEOVER
           BNE       LB308   ; B2FD D0 09
           LDA       P1GameStateFlag
           CMP       #GameStateGAMEOVER
           BNE       LB308   ; B303 D0 03
           JMP       MainLoop        ; B305 4C A3 B1
LB308      LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           TAY
           LDA       P0PieceY,X
           JSR       LB4C3
           LDA       #$00
           LDX       PlayerIndex
           STA       $DD,X
           LDA       #$03
           STA       PieceRotation
LB31C      CLC
           LDA       P0PieceY,X
           ADC       PieceRotation
           TAY
           JSR       LC1D8
           LDX       PlayerIndex
           ROR       $DD,X
           DEC       PieceRotation
           BPL       LB31C
           LDA       $DD,X
           BEQ       SetupDropPieceSFX
           LDA       #$80
           STA       P0ClearRowState,X
           JMP       MainLoop
SetupDropPieceSFX
           LDA       #<SFXDropData
           LDY       #>SFXDropData
           LDX       PlayerIndex
           JSR       SetupSFX
           JSR       LB95B   ; B341 20 5B B9
           JMP       MainLoop        ; B344 4C A3 B1
LB347      LDX       PlayerIndex
           LDA       INPT4,X ; Check if single-button fire is pressed...
           AND       #$80
           BPL       LB359   ; ...if so, skip
           LDA       #$01
           STA       $CD,X
           LDA       #$00
           STA       $CF,X
           BEQ       HandleJoystick
LB359
           LDA       $CD,X
           BNE       HandleJoystick
           LDA       $CF,X
           BNE       HandleJoystick
           LDA       #$14
           STA       $CF,X
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B36E AA
           PLA               ; B36F 68
           JSR       LC187   ; B370 20 87 C1
           LDY       PlayerIndex
           LDX       P0PieceRotation,Y
           STX       PieceRotation
           DEX               ; B379 CA
           TXA               ; B37A 8A
           AND       #$03    ; B37B 29 03
           STA       $00C3,Y ; B37D 99 C3 00
           LDA       $00C5,Y ; B380 B9 C5 00
           STA       $A2     ; B383 85 A2
           JSR       LB9B9   ; B385 20 B9 B9
           LDX       PlayerIndex
           LDA       P0PieceType,X   ; B38A B5 BF
           ORA       P0PieceRotation,X
           PHA               ; B38E 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B393 AA
           PLA               ; B394 68
           JSR       LC249   ; B395 20 49 C2
           LDX       PlayerIndex
           BCC       LB3A4   ; B39A 90 08
           LDA       $A2     ; B39C A5 A2
           STA       P0PieceX,X
           LDA       PieceRotation
           STA       P0PieceRotation,X
LB3A4      LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA               ; B3A8 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B3AD AA
           PLA               ; B3AE 68
           JSR       RenderPiece
           LDX       PlayerIndex
           LDA       #$14    ; B3B4 A9 14
           STA       $CF,X   ; B3B6 95 CF
           LDA       #$01    ; B3B8 A9 01
           STA       $CD,X   ; B3BA 95 CD

HandleJoystick
           LDA       SWCHA
           LDX       PlayerIndex
           BNE       SkipDownshiftP0Bits
           LSR
           LSR
           LSR
           LSR
SkipDownshiftP0Bits
           AND       #$0F
           TAX
           LDA       JoystickDecodeTable,X   ;A=%0000RLDU, where 0=on and 1=off
           PHA
           LDX       PlayerIndex
           AND       #$02
           BEQ       HandleJoyDown
           LDA       P0DownwardSpeed,X
           CMP       #$17
           BCS       SkipGravityPull
           LDA       #$01
           STA       P0DownwardSpeed,X
SkipGravityPull
           LDA       #$00
           STA       $DF,X
           JMP       LB3FB
HandleJoyDown
           LDA       $DF,X   ; B3E5 B5 DF
           BNE       LB3FB   ; B3E7 D0 12
           LDA       $D9,X   ; B3E9 B5 D9
           BNE       LB3FB   ; B3EB D0 0E
           LDY       P0DownwardSpeed,X
           INY
           INY
           CPY       #$18    ; B3F1 C0 18
           BCS       SkipP0DownwardIncrease
           STY       P0DownwardSpeed,X
SkipP0DownwardIncrease
           LDA       #$02
           STA       $D9,X
LB3FB
           PLA
           LDY       PlayerIndex
           STA       $00D1,Y
           LSR
           LSR
           LSR
           BCC       HandleJoyLeft
           LSR
           BCC       HandleJoyRight
           LDA       #$01
           STA       $00C9,Y
           LDA       #$00
           STA       $00CB,Y
LB413
           JMP       HandleJoystickEnd       ; B413 4C AB B4

HandleJoyLeft
           LDA       $00C9,Y
           BNE       LB413
           LDA       $00CB,Y
           BNE       LB413
           LDA       #$0A    ; B420 A9 0A
           STA       $00CB,Y ; B422 99 CB 00
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA               ; B42B 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B430 AA
           PLA               ; B431 68
           JSR       LC187   ; B432 20 87 C1
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B440 AA
           DEX               ; B441 CA
           PLA               ; B442 68
           JSR       LC249   ; B443 20 49 C2
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA               ; B44C 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B451 AA
           BCS       LB455   ; B452 B0 01
           DEX               ; B454 CA
LB455      TXA               ; B455 8A
           LDX       PlayerIndex
           STA       P0PieceX,X
           TAX               ; B45A AA
           PLA               ; B45B 68
           JSR       RenderPiece
           JMP       MainLoop        ; B45F 4C A3 B1
HandleJoyRight
           LDA       $00C9,Y
           BNE       HandleJoystickEnd
           LDA       $00CB,Y
           BNE       HandleJoystickEnd
           LDA       #$0A
           STA       $00CB,Y
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX
           PLA
           JSR       LC187
           LDX       PlayerIndex
           LDA       P0PieceType,X
           ORA       P0PieceRotation,X
           PHA
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B48C AA
           INX               ; B48D E8
           PLA               ; B48E 68
           JSR       LC249   ; B48F 20 49 C2
           LDX       PlayerIndex
           LDA       P0PieceType,X   ; B494 B5 BF
           ORA       P0PieceRotation,X
           PHA               ; B498 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B49D AA
           BCS       LB4A1   ; B49E B0 01
           INX               ; B4A0 E8
LB4A1
           TXA               ; B4A1 8A
           LDX       PlayerIndex
           STA       P0PieceX,X
           TAX               ; B4A6 AA
           PLA               ; B4A7 68
           JSR       RenderPiece
HandleJoystickEnd
           JMP       MainLoop

; *** this code block doesn't seem active - the game doesn't reach here during a normal run.
           LDA       #$40    ; B4AE
           STA       BACKGRND        ; Darkest Red
LB4B2
           LDA       INPT4   ; check player 0 fire button
           BPL       LB4C0   ;    and branch if it is
           LDA       INPT5   ; check player 1 fire button
           BPL       LB4C0   ;    and branch if it is.
           JSR       LC0BF
           JMP       LB4B2   ; B4BD 4C B2 B4

LB4C0
           JMP       GameInit
LB4C3
           CLC
           ADC       PieceHeights,Y
           EOR       #$FF
           CLC
           ADC       #23
           STA       $9C
           LDY       #$09
           LDX       PlayerIndex
           LDA       P0TotalLinesCleared+1,X
           BNE       LB4E1
           LDA       P0TotalLinesCleared,X
           LSR
           LSR
           TAY
           CPY       #$09
           BCC       LB4E1
           LDY       #$09
LB4E1
           INY
           STY       PieceX
           TYA
           CLC
           ADC       $9C
           JSR       LB58F
           LDX       PlayerIndex
           LDA       P0DownwardSpeed,X
           CMP       #$17
           BCC       LB4F7
           ASL       $F4
           ROL       $F5
LB4F7
           LDA       $F4
           LDX       $F5
           JSR       LB549
           JSR       LC71A
           LDA       #$0A
           LDX       PlayerIndex
           LDY       P0PointsScoredDelay,X
           BNE       SkipClearPointsScored2
           STA       P0PointsScoredDelay,X
SkipClearPointsScored2
           RTS

LB50C
           LSR
           LSR
           LSR
           LSR
           PHA
           JSR       SetupClearRowsSFX
           PLA
           TAY
           LDA       LB529,Y
           PHA
           LDA       LB539,Y
           TAX
           PLA
           JSR       LC71A
           LDA       #$5A    ; we use a longer points-scored delay when rows are cleared
           LDX       PlayerIndex
           STA       P0PointsScoredDelay,X
           RTS

LB529
           .byte   $00     ; |         | $B529
           .byte   $50     ; | X X    | $B52A
           .byte   $50     ; | X X    | $B52B
           .byte   $50     ; | X X    | $B52C
           .byte   $50     ; | X X    | $B52D
           .byte   $50     ; | X X    | $B52E
           .byte   $50     ; | X X    | $B52F
           .byte   $00     ; |         | $B530
           .byte   $50     ; | X X    | $B531
           .byte   $50     ; | X X    | $B532
           .byte   $50     ; | X X    | $B533
           .byte   $00     ; |         | $B534
           .byte   $50     ; | X X    | $B535
           .byte   $00     ; |         | $B536
           .byte   $00     ; |         | $B537
           .byte   $00     ; |         | $B538
LB539
           .byte   $00     ; |         | $B539
           .byte   $00     ; |         | $B53A
           .byte   $00     ; |         | $B53B
           .byte   $01     ; |        X| $B53C
           .byte   $00     ; |         | $B53D
           .byte   $01     ; |        X| $B53E
           .byte   $50     ; | X X    | $B53F
           .byte   $04     ; |      X  | $B540
           .byte   $00     ; |         | $B541
           .byte   $01     ; |        X| $B542
           .byte   $01     ; |        X| $B543
           .byte   $04     ; |      X  | $B544
           .byte   $01     ; |        X| $B545
           .byte   $04     ; |      X  | $B546
           .byte   $00     ; |         | $B547
           .byte   $09     ; |     X  X| $B548
LB549      SED               ; B549 F8
           LDY       #$00    ; B54A A0 00
           STY       $9C     ; B54C 84 9C
           STY       PieceX
           STX       PieceY
           LDX       #$0D    ; B552 A2 0D
LB554      LSR       PieceY
           ROR               ; B556 6A
           BCC       LB56A   ; B557 90 11
           TAY               ; B559 A8
           CLC               ; B55A 18
           LDA       LB573,X ; B55B BD 73 B5
           ADC       $9C     ; B55E 65 9C
           STA       $9C     ; B560 85 9C
           LDA       LB581,X ; B562 BD 81 B5
           ADC       PieceX
           STA       PieceX
           TYA               ; B569 98
LB56A      DEX               ; B56A CA
           BPL       LB554   ; B56B 10 E7
           LDA       $9C     ; B56D A5 9C
           LDX       PieceX
           CLD               ; B571 D8
           RTS               ; B572 60

LB573      .byte   $92     ; |X  X  X | $B573
           .byte   $96     ; |X  X XX | $B574
           .byte   $48     ; | X   X   | $B575
           .byte   $24     ; |  X  X  | $B576
           .byte   $12     ; |   X  X | $B577
           .byte   $56     ; | X X XX | $B578
           .byte   $28     ; |  X X   | $B579
           .byte   $64     ; | XX  X  | $B57A
           .byte   $32     ; |  XX  X | $B57B
           .byte   $16     ; |   X XX | $B57C
           .byte   $08     ; |     X   | $B57D
           .byte   $04     ; |      X  | $B57E
           .byte   $02     ; |       X | $B57F
           .byte   $01     ; |        X| $B580
LB581      .byte   $81     ; |X       X| $B581
           .byte   $40     ; | X       | $B582
           .byte   $20     ; |  X     | $B583
           .byte   $10     ; |   X    | $B584
           .byte   $05     ; |      X X| $B585
           .byte   $02     ; |       X | $B586
           .byte   $01     ; |        X| $B587
           .byte   $00     ; |         | $B588
           .byte   $00     ; |         | $B589
           .byte   $00     ; |         | $B58A
           .byte   $00     ; |         | $B58B
           .byte   $00     ; |         | $B58C
           .byte   $00     ; |         | $B58D
           .byte   $00     ; |         | $B58E
LB58F      STA       $F2     ; B58F 85 F2
           STY       $F3     ; B591 84 F3
           CLC               ; B593 18
           ADC       $F3     ; B594 65 F3
           TAY               ; B596 A8
           BCC       LB59E   ; B597 90 05
           LDA       LB7D1,Y ; B599 B9 D1 B7
           BCS       LB5A2   ; B59C B0 04
LB59E      LDA       LB6D1,Y ; B59E B9 D1 B6
           SEC               ; B5A1 38
LB5A2      STA       $F5     ; B5A2 85 F5
           LDA       LB5D1,Y ; B5A4 B9 D1 B5
           LDY       $F2     ; B5A7 A4 F2
           SBC       LB5D1,Y ; B5A9 F9 D1 B5
           STA       $F4     ; B5AC 85 F4
           LDA       $F5     ; B5AE A5 F5
           SBC       LB6D1,Y ; B5B0 F9 D1 B6
           STA       $F5     ; B5B3 85 F5
           LDY       $F3     ; B5B5 A4 F3
           TYA               ; B5B7 98
           AND       $F2     ; B5B8 25 F2
           AND       #$01    ; B5BA 29 01
           CLC               ; B5BC 18
           ADC       $F4     ; B5BD 65 F4
           BCC       LB5C3   ; B5BF 90 02
           INC       $F5     ; B5C1 E6 F5
LB5C3      SEC               ; B5C3 38
           SBC       LB5D1,Y ; B5C4 F9 D1 B5
           STA       $F4     ; B5C7 85 F4
           LDA       $F5     ; B5C9 A5 F5
           SBC       LB6D1,Y ; B5CB F9 D1 B6
           STA       $F5     ; B5CE 85 F5
           RTS               ; B5D0 60

LB5D1      .byte   $00     ; |         | $B5D1
           .byte   $01     ; |        X| $B5D2
           .byte   $02     ; |       X | $B5D3
           .byte   $05     ; |      X X| $B5D4
           .byte   $08     ; |     X   | $B5D5
           .byte   $0D     ; |     XX X| $B5D6
           .byte   $12     ; |   X  X | $B5D7
           .byte   $19     ; |   XX  X| $B5D8
           .byte   $20     ; |  X     | $B5D9
           .byte   $29     ; |  X X  X| $B5DA
           .byte   $32     ; |  XX  X | $B5DB
           .byte   $3D     ; |  XXXX X| $B5DC
           .byte   $48     ; | X   X   | $B5DD
           .byte   $55     ; | X X X X| $B5DE
           .byte   $62     ; | XX   X | $B5DF
           .byte   $71     ; | XXX   X| $B5E0
           .byte   $80     ; |X        | $B5E1
           .byte   $91     ; |X  X   X| $B5E2
           .byte   $A2     ; |X X   X | $B5E3
           .byte   $B5     ; |X XX X X| $B5E4
           .byte   $C8     ; |XX   X   | $B5E5
           .byte   $DD     ; |XX XXX X| $B5E6
           .byte   $F2     ; |XXXX  X | $B5E7
           .byte   $09     ; |     X  X| $B5E8
           .byte   $20     ; |  X     | $B5E9
           .byte   $39     ; |  XXX  X| $B5EA
           .byte   $52     ; | X X  X | $B5EB
           .byte   $6D     ; | XX XX X| $B5EC
           .byte   $88     ; |X    X   | $B5ED
           .byte   $A5     ; |X X  X X| $B5EE
           .byte   $C2     ; |XX     X | $B5EF
           .byte   $E1     ; |XXX    X| $B5F0
           .byte   $00     ; |         | $B5F1
           .byte   $21     ; |  X    X| $B5F2
           .byte   $42     ; | X     X | $B5F3
           .byte   $65     ; | XX  X X| $B5F4
           .byte   $88     ; |X    X   | $B5F5
           .byte   $AD     ; |X X XX X| $B5F6
           .byte   $D2     ; |XX X  X | $B5F7
           .byte   $F9     ; |XXXXX  X| $B5F8
           .byte   $20     ; |  X     | $B5F9
           .byte   $49     ; | X   X  X| $B5FA
           .byte   $72     ; | XXX  X | $B5FB
           .byte   $9D     ; |X  XXX X| $B5FC
           .byte   $C8     ; |XX   X   | $B5FD
           .byte   $F5     ; |XXXX X X| $B5FE
           .byte   $22     ; |  X   X | $B5FF
           .byte   $51     ; | X X   X| $B600
           .byte   $80     ; |X        | $B601
           .byte   $B1     ; |X XX   X| $B602
           .byte   $E2     ; |XXX   X | $B603
           .byte   $15     ; |   X X X| $B604
           .byte   $48     ; | X   X   | $B605
           .byte   $7D     ; | XXXXX X| $B606
           .byte   $B2     ; |X XX  X | $B607
           .byte   $E9     ; |XXX X  X| $B608
           .byte   $20     ; |  X     | $B609
           .byte   $59     ; | X XX  X| $B60A
           .byte   $92     ; |X  X  X | $B60B
           .byte   $CD     ; |XX   XX X| $B60C
           .byte   $08     ; |     X   | $B60D
           .byte   $45     ; | X    X X| $B60E
           .byte   $82     ; |X      X | $B60F
           .byte   $C1     ; |XX      X| $B610
           .byte   $00     ; |         | $B611
           .byte   $41     ; | X      X| $B612
           .byte   $82     ; |X      X | $B613
           .byte   $C5     ; |XX    X X| $B614
           .byte   $08     ; |     X   | $B615
           .byte   $4D     ; | X   XX X| $B616
           .byte   $92     ; |X  X  X | $B617
           .byte   $D9     ; |XX XX  X| $B618
           .byte   $20     ; |  X     | $B619
           .byte   $69     ; | XX X  X| $B61A
           .byte   $B2     ; |X XX  X | $B61B
           .byte   $FD     ; |XXXXXX X| $B61C
           .byte   $48     ; | X   X   | $B61D
           .byte   $95     ; |X  X X X| $B61E
           .byte   $E2     ; |XXX   X | $B61F
           .byte   $31     ; |  XX   X| $B620
           .byte   $80     ; |X        | $B621
           .byte   $D1     ; |XX X   X| $B622
           .byte   $22     ; |  X   X | $B623
           .byte   $75     ; | XXX X X| $B624
           .byte   $C8     ; |XX   X   | $B625
           .byte   $1D     ; |   XXX X| $B626
           .byte   $72     ; | XXX  X | $B627
           .byte   $C9     ; |XX   X  X| $B628
           .byte   $20     ; |  X     | $B629
           .byte   $79     ; | XXXX  X| $B62A
           .byte   $D2     ; |XX X  X | $B62B
           .byte   $2D     ; |  X XX X| $B62C
           .byte   $88     ; |X    X   | $B62D
           .byte   $E5     ; |XXX  X X| $B62E
           .byte   $42     ; | X     X | $B62F
           .byte   $A1     ; |X X    X| $B630
           .byte   $00     ; |         | $B631
           .byte   $61     ; | XX    X| $B632
           .byte   $C2     ; |XX     X | $B633
           .byte   $25     ; |  X  X X| $B634
           .byte   $88     ; |X    X   | $B635
           .byte   $ED     ; |XXX XX X| $B636
           .byte   $52     ; | X X  X | $B637
           .byte   $B9     ; |X XXX  X| $B638
           .byte   $20     ; |  X     | $B639
           .byte   $89     ; |X    X  X| $B63A
           .byte   $F2     ; |XXXX  X | $B63B
           .byte   $5D     ; | X XXX X| $B63C
           .byte   $C8     ; |XX   X   | $B63D
           .byte   $35     ; |  XX X X| $B63E
           .byte   $A2     ; |X X   X | $B63F
           .byte   $11     ; |   X   X| $B640
           .byte   $80     ; |X        | $B641
           .byte   $F1     ; |XXXX   X| $B642
           .byte   $62     ; | XX   X | $B643
           .byte   $D5     ; |XX X X X| $B644
           .byte   $48     ; | X   X   | $B645
           .byte   $BD     ; |X XXXX X| $B646
           .byte   $32     ; |  XX  X | $B647
           .byte   $A9     ; |X X X  X| $B648
           .byte   $20     ; |  X     | $B649
           .byte   $99     ; |X  XX  X| $B64A
           .byte   $12     ; |   X  X | $B64B
           .byte   $8D     ; |X    XX X| $B64C
           .byte   $08     ; |     X   | $B64D
           .byte   $85     ; |X     X X| $B64E
           .byte   $02     ; |       X | $B64F
           .byte   $81     ; |X       X| $B650
           .byte   $00     ; |         | $B651
           .byte   $81     ; |X       X| $B652
           .byte   $02     ; |       X | $B653
           .byte   $85     ; |X     X X| $B654
           .byte   $08     ; |     X   | $B655
           .byte   $8D     ; |X    XX X| $B656
           .byte   $12     ; |   X  X | $B657
           .byte   $99     ; |X  XX  X| $B658
           .byte   $20     ; |  X     | $B659
           .byte   $A9     ; |X X X  X| $B65A
           .byte   $32     ; |  XX  X | $B65B
           .byte   $BD     ; |X XXXX X| $B65C
           .byte   $48     ; | X   X   | $B65D
           .byte   $D5     ; |XX X X X| $B65E
           .byte   $62     ; | XX   X | $B65F
           .byte   $F1     ; |XXXX   X| $B660
           .byte   $80     ; |X        | $B661
           .byte   $11     ; |   X   X| $B662
           .byte   $A2     ; |X X   X | $B663
           .byte   $35     ; |  XX X X| $B664
           .byte   $C8     ; |XX   X   | $B665
           .byte   $5D     ; | X XXX X| $B666
           .byte   $F2     ; |XXXX  X | $B667
           .byte   $89     ; |X    X  X| $B668
           .byte   $20     ; |  X     | $B669
           .byte   $B9     ; |X XXX  X| $B66A
           .byte   $52     ; | X X  X | $B66B
           .byte   $ED     ; |XXX XX X| $B66C
           .byte   $88     ; |X    X   | $B66D
           .byte   $25     ; |  X  X X| $B66E
           .byte   $C2     ; |XX     X | $B66F
           .byte   $61     ; | XX    X| $B670
           .byte   $00     ; |         | $B671
           .byte   $A1     ; |X X    X| $B672
           .byte   $42     ; | X     X | $B673
           .byte   $E5     ; |XXX  X X| $B674
           .byte   $88     ; |X    X   | $B675
           .byte   $2D     ; |  X XX X| $B676
           .byte   $D2     ; |XX X  X | $B677
           .byte   $79     ; | XXXX  X| $B678
           .byte   $20     ; |  X     | $B679
           .byte   $C9     ; |XX   X  X| $B67A
           .byte   $72     ; | XXX  X | $B67B
           .byte   $1D     ; |   XXX X| $B67C
           .byte   $C8     ; |XX   X   | $B67D
           .byte   $75     ; | XXX X X| $B67E
           .byte   $22     ; |  X   X | $B67F
           .byte   $D1     ; |XX X   X| $B680
           .byte   $80     ; |X        | $B681
           .byte   $31     ; |  XX   X| $B682
           .byte   $E2     ; |XXX   X | $B683
           .byte   $95     ; |X  X X X| $B684
           .byte   $48     ; | X   X   | $B685
           .byte   $FD     ; |XXXXXX X| $B686
           .byte   $B2     ; |X XX  X | $B687
           .byte   $69     ; | XX X  X| $B688
           .byte   $20     ; |  X     | $B689
           .byte   $D9     ; |XX XX  X| $B68A
           .byte   $92     ; |X  X  X | $B68B
           .byte   $4D     ; | X   XX X| $B68C
           .byte   $08     ; |     X   | $B68D
           .byte   $C5     ; |XX    X X| $B68E
           .byte   $82     ; |X      X | $B68F
           .byte   $41     ; | X      X| $B690
           .byte   $00     ; |         | $B691
           .byte   $C1     ; |XX      X| $B692
           .byte   $82     ; |X      X | $B693
           .byte   $45     ; | X    X X| $B694
           .byte   $08     ; |     X   | $B695
           .byte   $CD     ; |XX   XX X| $B696
           .byte   $92     ; |X  X  X | $B697
           .byte   $59     ; | X XX  X| $B698
           .byte   $20     ; |  X     | $B699
           .byte   $E9     ; |XXX X  X| $B69A
           .byte   $B2     ; |X XX  X | $B69B
           .byte   $7D     ; | XXXXX X| $B69C
           .byte   $48     ; | X   X   | $B69D
           .byte   $15     ; |   X X X| $B69E
           .byte   $E2     ; |XXX   X | $B69F
           .byte   $B1     ; |X XX   X| $B6A0
           .byte   $80     ; |X        | $B6A1
           .byte   $51     ; | X X   X| $B6A2
           .byte   $22     ; |  X   X | $B6A3
           .byte   $F5     ; |XXXX X X| $B6A4
           .byte   $C8     ; |XX   X   | $B6A5
           .byte   $9D     ; |X  XXX X| $B6A6
           .byte   $72     ; | XXX  X | $B6A7
           .byte   $49     ; | X   X  X| $B6A8
           .byte   $20     ; |  X     | $B6A9
           .byte   $F9     ; |XXXXX  X| $B6AA
           .byte   $D2     ; |XX X  X | $B6AB
           .byte   $AD     ; |X X XX X| $B6AC
           .byte   $88     ; |X    X   | $B6AD
           .byte   $65     ; | XX  X X| $B6AE
           .byte   $42     ; | X     X | $B6AF
           .byte   $21     ; |  X    X| $B6B0
           .byte   $00     ; |         | $B6B1
           .byte   $E1     ; |XXX    X| $B6B2
           .byte   $C2     ; |XX     X | $B6B3
           .byte   $A5     ; |X X  X X| $B6B4
           .byte   $88     ; |X    X   | $B6B5
           .byte   $6D     ; | XX XX X| $B6B6
           .byte   $52     ; | X X  X | $B6B7
           .byte   $39     ; |  XXX  X| $B6B8
           .byte   $20     ; |  X     | $B6B9
           .byte   $09     ; |     X  X| $B6BA
           .byte   $F2     ; |XXXX  X | $B6BB
           .byte   $DD     ; |XX XXX X| $B6BC
           .byte   $C8     ; |XX   X   | $B6BD
           .byte   $B5     ; |X XX X X| $B6BE
           .byte   $A2     ; |X X   X | $B6BF
           .byte   $91     ; |X  X   X| $B6C0
           .byte   $80     ; |X        | $B6C1
           .byte   $71     ; | XXX   X| $B6C2
           .byte   $62     ; | XX   X | $B6C3
           .byte   $55     ; | X X X X| $B6C4
           .byte   $48     ; | X   X   | $B6C5
           .byte   $3D     ; |  XXXX X| $B6C6
           .byte   $32     ; |  XX  X | $B6C7
           .byte   $29     ; |  X X  X| $B6C8
           .byte   $20     ; |  X     | $B6C9
           .byte   $19     ; |   XX  X| $B6CA
           .byte   $12     ; |   X  X | $B6CB
           .byte   $0D     ; |     XX X| $B6CC
           .byte   $08     ; |     X   | $B6CD
           .byte   $05     ; |      X X| $B6CE
           .byte   $02     ; |       X | $B6CF
           .byte   $01     ; |        X| $B6D0
LB6D1      .byte   $00     ; |         | $B6D1
           .byte   $00     ; |         | $B6D2
           .byte   $00     ; |         | $B6D3
           .byte   $00     ; |         | $B6D4
           .byte   $00     ; |         | $B6D5
           .byte   $00     ; |         | $B6D6
           .byte   $00     ; |         | $B6D7
           .byte   $00     ; |         | $B6D8
           .byte   $00     ; |         | $B6D9
           .byte   $00     ; |         | $B6DA
           .byte   $00     ; |         | $B6DB
           .byte   $00     ; |         | $B6DC
           .byte   $00     ; |         | $B6DD
           .byte   $00     ; |         | $B6DE
           .byte   $00     ; |         | $B6DF
           .byte   $00     ; |         | $B6E0
           .byte   $00     ; |         | $B6E1
           .byte   $00     ; |         | $B6E2
           .byte   $00     ; |         | $B6E3
           .byte   $00     ; |         | $B6E4
           .byte   $00     ; |         | $B6E5
           .byte   $00     ; |         | $B6E6
           .byte   $00     ; |         | $B6E7
           .byte   $01     ; |        X| $B6E8
           .byte   $01     ; |        X| $B6E9
           .byte   $01     ; |        X| $B6EA
           .byte   $01     ; |        X| $B6EB
           .byte   $01     ; |        X| $B6EC
           .byte   $01     ; |        X| $B6ED
           .byte   $01     ; |        X| $B6EE
           .byte   $01     ; |        X| $B6EF
           .byte   $01     ; |        X| $B6F0
           .byte   $02     ; |       X | $B6F1
           .byte   $02     ; |       X | $B6F2
           .byte   $02     ; |       X | $B6F3
           .byte   $02     ; |       X | $B6F4
           .byte   $02     ; |       X | $B6F5
           .byte   $02     ; |       X | $B6F6
           .byte   $02     ; |       X | $B6F7
           .byte   $02     ; |       X | $B6F8
           .byte   $03     ; |       XX| $B6F9
           .byte   $03     ; |       XX| $B6FA
           .byte   $03     ; |       XX| $B6FB
           .byte   $03     ; |       XX| $B6FC
           .byte   $03     ; |       XX| $B6FD
           .byte   $03     ; |       XX| $B6FE
           .byte   $04     ; |      X  | $B6FF
           .byte   $04     ; |      X  | $B700
           .byte   $04     ; |      X  | $B701
           .byte   $04     ; |      X  | $B702
           .byte   $04     ; |      X  | $B703
           .byte   $05     ; |      X X| $B704
           .byte   $05     ; |      X X| $B705
           .byte   $05     ; |      X X| $B706
           .byte   $05     ; |      X X| $B707
           .byte   $05     ; |      X X| $B708
           .byte   $06     ; |      XX | $B709
           .byte   $06     ; |      XX | $B70A
           .byte   $06     ; |      XX | $B70B
           .byte   $06     ; |      XX | $B70C
           .byte   $07     ; |      XXX| $B70D
           .byte   $07     ; |      XXX| $B70E
           .byte   $07     ; |      XXX| $B70F
           .byte   $07     ; |      XXX| $B710
           .byte   $08     ; |     X   | $B711
           .byte   $08     ; |     X   | $B712
           .byte   $08     ; |     X   | $B713
           .byte   $08     ; |     X   | $B714
           .byte   $09     ; |     X  X| $B715
           .byte   $09     ; |     X  X| $B716
           .byte   $09     ; |     X  X| $B717
           .byte   $09     ; |     X  X| $B718
           .byte   $0A     ; |     X X | $B719
           .byte   $0A     ; |     X X | $B71A
           .byte   $0A     ; |     X X | $B71B
           .byte   $0A     ; |     X X | $B71C
           .byte   $0B     ; |     X XX| $B71D
           .byte   $0B     ; |     X XX| $B71E
           .byte   $0B     ; |     X XX| $B71F
           .byte   $0C     ; |     XX  | $B720
           .byte   $0C     ; |     XX  | $B721
           .byte   $0C     ; |     XX  | $B722
           .byte   $0D     ; |     XX X| $B723
           .byte   $0D     ; |     XX X| $B724
           .byte   $0D     ; |     XX X| $B725
           .byte   $0E     ; |     XXX | $B726
           .byte   $0E     ; |     XXX | $B727
           .byte   $0E     ; |     XXX | $B728
           .byte   $0F     ; |     XXXX| $B729
           .byte   $0F     ; |     XXXX| $B72A
           .byte   $0F     ; |     XXXX| $B72B
           .byte   $10     ; |   X    | $B72C
           .byte   $10     ; |   X    | $B72D
           .byte   $10     ; |   X    | $B72E
           .byte   $11     ; |   X   X| $B72F
           .byte   $11     ; |   X   X| $B730
           .byte   $12     ; |   X  X | $B731
           .byte   $12     ; |   X  X | $B732
           .byte   $12     ; |   X  X | $B733
           .byte   $13     ; |   X  XX| $B734
           .byte   $13     ; |   X  XX| $B735
           .byte   $13     ; |   X  XX| $B736
           .byte   $14     ; |   X X  | $B737
           .byte   $14     ; |   X X  | $B738
           .byte   $15     ; |   X X X| $B739
           .byte   $15     ; |   X X X| $B73A
           .byte   $15     ; |   X X X| $B73B
           .byte   $16     ; |   X XX | $B73C
           .byte   $16     ; |   X XX | $B73D
           .byte   $17     ; |   X XXX| $B73E
           .byte   $17     ; |   X XXX| $B73F
           .byte   $18     ; |   XX   | $B740
           .byte   $18     ; |   XX   | $B741
           .byte   $18     ; |   XX   | $B742
           .byte   $19     ; |   XX  X| $B743
           .byte   $19     ; |   XX  X| $B744
           .byte   $1A     ; |   XX X | $B745
           .byte   $1A     ; |   XX X | $B746
           .byte   $1B     ; |   XX XX| $B747
           .byte   $1B     ; |   XX XX| $B748
           .byte   $1C     ; |   XXX  | $B749
           .byte   $1C     ; |   XXX  | $B74A
           .byte   $1D     ; |   XXX X| $B74B
           .byte   $1D     ; |   XXX X| $B74C
           .byte   $1E     ; |   XXXX | $B74D
           .byte   $1E     ; |   XXXX | $B74E
           .byte   $1F     ; |   XXXXX| $B74F
           .byte   $1F     ; |   XXXXX| $B750
           .byte   $20     ; |  X     | $B751
           .byte   $20     ; |  X     | $B752
           .byte   $21     ; |  X    X| $B753
           .byte   $21     ; |  X    X| $B754
           .byte   $22     ; |  X   X | $B755
           .byte   $22     ; |  X   X | $B756
           .byte   $23     ; |  X   XX| $B757
           .byte   $23     ; |  X   XX| $B758
           .byte   $24     ; |  X  X  | $B759
           .byte   $24     ; |  X  X  | $B75A
           .byte   $25     ; |  X  X X| $B75B
           .byte   $25     ; |  X  X X| $B75C
           .byte   $26     ; |  X  XX | $B75D
           .byte   $26     ; |  X  XX | $B75E
           .byte   $27     ; |  X  XXX| $B75F
           .byte   $27     ; |  X  XXX| $B760
           .byte   $28     ; |  X X   | $B761
           .byte   $29     ; |  X X  X| $B762
           .byte   $29     ; |  X X  X| $B763
           .byte   $2A     ; |  X X X | $B764
           .byte   $2A     ; |  X X X | $B765
           .byte   $2B     ; |  X X XX| $B766
           .byte   $2B     ; |  X X XX| $B767
           .byte   $2C     ; |  X XX  | $B768
           .byte   $2D     ; |  X XX X| $B769
           .byte   $2D     ; |  X XX X| $B76A
           .byte   $2E     ; |  X XXX | $B76B
           .byte   $2E     ; |  X XXX | $B76C
           .byte   $2F     ; |  X XXXX| $B76D
           .byte   $30     ; |  XX    | $B76E
           .byte   $30     ; |  XX    | $B76F
           .byte   $31     ; |  XX   X| $B770
           .byte   $32     ; |  XX  X | $B771
           .byte   $32     ; |  XX  X | $B772
           .byte   $33     ; |  XX  XX| $B773
           .byte   $33     ; |  XX  XX| $B774
           .byte   $34     ; |  XX X  | $B775
           .byte   $35     ; |  XX X X| $B776
           .byte   $35     ; |  XX X X| $B777
           .byte   $36     ; |  XX XX | $B778
           .byte   $37     ; |  XX XXX| $B779
           .byte   $37     ; |  XX XXX| $B77A
           .byte   $38     ; |  XXX   | $B77B
           .byte   $39     ; |  XXX  X| $B77C
           .byte   $39     ; |  XXX  X| $B77D
           .byte   $3A     ; |  XXX X | $B77E
           .byte   $3B     ; |  XXX XX| $B77F
           .byte   $3B     ; |  XXX XX| $B780
           .byte   $3C     ; |  XXXX  | $B781
           .byte   $3D     ; |  XXXX X| $B782
           .byte   $3D     ; |  XXXX X| $B783
           .byte   $3E     ; |  XXXXX | $B784
           .byte   $3F     ; |  XXXXXX| $B785
           .byte   $3F     ; |  XXXXXX| $B786
           .byte   $40     ; | X       | $B787
           .byte   $41     ; | X      X| $B788
           .byte   $42     ; | X     X | $B789
           .byte   $42     ; | X     X | $B78A
           .byte   $43     ; | X     XX| $B78B
           .byte   $44     ; | X    X  | $B78C
           .byte   $45     ; | X    X X| $B78D
           .byte   $45     ; | X    X X| $B78E
           .byte   $46     ; | X    XX | $B78F
           .byte   $47     ; | X    XXX| $B790
           .byte   $48     ; | X   X   | $B791
           .byte   $48     ; | X   X   | $B792
           .byte   $49     ; | X   X  X| $B793
           .byte   $4A     ; | X   X X | $B794
           .byte   $4B     ; | X   X XX| $B795
           .byte   $4B     ; | X   X XX| $B796
           .byte   $4C     ; | X   XX  | $B797
           .byte   $4D     ; | X   XX X| $B798
           .byte   $4E     ; | X   XXX | $B799
           .byte   $4E     ; | X   XXX | $B79A
           .byte   $4F     ; | X   XXXX| $B79B
           .byte   $50     ; | X X    | $B79C
           .byte   $51     ; | X X   X| $B79D
           .byte   $52     ; | X X  X | $B79E
           .byte   $52     ; | X X  X | $B79F
           .byte   $53     ; | X X  XX| $B7A0
           .byte   $54     ; | X X X  | $B7A1
           .byte   $55     ; | X X X X| $B7A2
           .byte   $56     ; | X X XX | $B7A3
           .byte   $56     ; | X X XX | $B7A4
           .byte   $57     ; | X X XXX| $B7A5
           .byte   $58     ; | X XX   | $B7A6
           .byte   $59     ; | X XX  X| $B7A7
           .byte   $5A     ; | X XX X | $B7A8
           .byte   $5B     ; | X XX XX| $B7A9
           .byte   $5B     ; | X XX XX| $B7AA
           .byte   $5C     ; | X XXX  | $B7AB
           .byte   $5D     ; | X XXX X| $B7AC
           .byte   $5E     ; | X XXXX | $B7AD
           .byte   $5F     ; | X XXXXX| $B7AE
           .byte   $60     ; | XX     | $B7AF
           .byte   $61     ; | XX    X| $B7B0
           .byte   $62     ; | XX   X | $B7B1
           .byte   $62     ; | XX   X | $B7B2
           .byte   $63     ; | XX   XX| $B7B3
           .byte   $64     ; | XX  X  | $B7B4
           .byte   $65     ; | XX  X X| $B7B5
           .byte   $66     ; | XX  XX | $B7B6
           .byte   $67     ; | XX  XXX| $B7B7
           .byte   $68     ; | XX X   | $B7B8
           .byte   $69     ; | XX X  X| $B7B9
           .byte   $6A     ; | XX X X | $B7BA
           .byte   $6A     ; | XX X X | $B7BB
           .byte   $6B     ; | XX X XX| $B7BC
           .byte   $6C     ; | XX XX  | $B7BD
           .byte   $6D     ; | XX XX X| $B7BE
           .byte   $6E     ; | XX XXX | $B7BF
           .byte   $6F     ; | XX XXXX| $B7C0
           .byte   $70     ; | XXX    | $B7C1
           .byte   $71     ; | XXX   X| $B7C2
           .byte   $72     ; | XXX  X | $B7C3
           .byte   $73     ; | XXX  XX| $B7C4
           .byte   $74     ; | XXX X  | $B7C5
           .byte   $75     ; | XXX X X| $B7C6
           .byte   $76     ; | XXX XX | $B7C7
           .byte   $77     ; | XXX XXX| $B7C8
           .byte   $78     ; | XXXX   | $B7C9
           .byte   $79     ; | XXXX  X| $B7CA
           .byte   $7A     ; | XXXX X | $B7CB
           .byte   $7B     ; | XXXX XX| $B7CC
           .byte   $7C     ; | XXXXX  | $B7CD
           .byte   $7D     ; | XXXXX X| $B7CE
           .byte   $7E     ; | XXXXXX | $B7CF
           .byte   $7F     ; | XXXXXXX| $B7D0
LB7D1      .byte   $80     ; |X        | $B7D1
           .byte   $81     ; |X       X| $B7D2
           .byte   $82     ; |X      X | $B7D3
           .byte   $83     ; |X      XX| $B7D4
           .byte   $84     ; |X     X  | $B7D5
           .byte   $85     ; |X     X X| $B7D6
           .byte   $86     ; |X     XX | $B7D7
           .byte   $87     ; |X     XXX| $B7D8
           .byte   $88     ; |X    X   | $B7D9
           .byte   $89     ; |X    X  X| $B7DA
           .byte   $8A     ; |X    X X | $B7DB
           .byte   $8B     ; |X    X XX| $B7DC
           .byte   $8C     ; |X    XX  | $B7DD
           .byte   $8D     ; |X    XX X| $B7DE
           .byte   $8E     ; |X    XXX | $B7DF
           .byte   $8F     ; |X    XXXX| $B7E0
           .byte   $90     ; |X  X    | $B7E1
           .byte   $91     ; |X  X   X| $B7E2
           .byte   $92     ; |X  X  X | $B7E3
           .byte   $93     ; |X  X  XX| $B7E4
           .byte   $94     ; |X  X X  | $B7E5
           .byte   $95     ; |X  X X X| $B7E6
           .byte   $96     ; |X  X XX | $B7E7
           .byte   $98     ; |X  XX   | $B7E8
           .byte   $99     ; |X  XX  X| $B7E9
           .byte   $9A     ; |X  XX X | $B7EA
           .byte   $9B     ; |X  XX XX| $B7EB
           .byte   $9C     ; |X  XXX  | $B7EC
           .byte   $9D     ; |X  XXX X| $B7ED
           .byte   $9E     ; |X  XXXX | $B7EE
           .byte   $9F     ; |X  XXXXX| $B7EF
           .byte   $A0     ; |X X     | $B7F0
           .byte   $A2     ; |X X   X | $B7F1
           .byte   $A3     ; |X X   XX| $B7F2
           .byte   $A4     ; |X X  X  | $B7F3
           .byte   $A5     ; |X X  X X| $B7F4
           .byte   $A6     ; |X X  XX | $B7F5
           .byte   $A7     ; |X X  XXX| $B7F6
           .byte   $A8     ; |X X X   | $B7F7
           .byte   $A9     ; |X X X  X| $B7F8
           .byte   $AB     ; |X X X XX| $B7F9
           .byte   $AC     ; |X X XX  | $B7FA
           .byte   $AD     ; |X X XX X| $B7FB
           .byte   $AE     ; |X X XXX | $B7FC
           .byte   $AF     ; |X X XXXX| $B7FD
           .byte   $B0     ; |X XX    | $B7FE
           .byte   $B2     ; |X XX  X | $B7FF
           .byte   $B3     ; |X XX  XX| $B800
           .byte   $B4     ; |X XX X  | $B801
           .byte   $B5     ; |X XX X X| $B802
           .byte   $B6     ; |X XX XX | $B803
           .byte   $B8     ; |X XXX   | $B804
           .byte   $B9     ; |X XXX  X| $B805
           .byte   $BA     ; |X XXX X | $B806
           .byte   $BB     ; |X XXX XX| $B807
           .byte   $BC     ; |X XXXX  | $B808
           .byte   $BE     ; |X XXXXX | $B809
           .byte   $BF     ; |X XXXXXX| $B80A
           .byte   $C0     ; |XX       | $B80B
           .byte   $C1     ; |XX      X| $B80C
           .byte   $C3     ; |XX     XX| $B80D
           .byte   $C4     ; |XX    X  | $B80E
           .byte   $C5     ; |XX    X X| $B80F
           .byte   $C6     ; |XX    XX | $B810
           .byte   $C8     ; |XX   X   | $B811
           .byte   $C9     ; |XX   X  X| $B812
           .byte   $CA     ; |XX   X X | $B813
           .byte   $CB     ; |XX   X XX| $B814
           .byte   $CD     ; |XX   XX X| $B815
           .byte   $CE     ; |XX   XXX | $B816
           .byte   $CF     ; |XX   XXXX| $B817
           .byte   $D0     ; |XX X    | $B818
           .byte   $D2     ; |XX X  X | $B819
           .byte   $D3     ; |XX X  XX| $B81A
           .byte   $D4     ; |XX X X  | $B81B
           .byte   $D5     ; |XX X X X| $B81C
           .byte   $D7     ; |XX X XXX| $B81D
           .byte   $D8     ; |XX XX   | $B81E
           .byte   $D9     ; |XX XX  X| $B81F
           .byte   $DB     ; |XX XX XX| $B820
           .byte   $DC     ; |XX XXX  | $B821
           .byte   $DD     ; |XX XXX X| $B822
           .byte   $DF     ; |XX XXXXX| $B823
           .byte   $E0     ; |XXX     | $B824
           .byte   $E1     ; |XXX    X| $B825
           .byte   $E3     ; |XXX   XX| $B826
           .byte   $E4     ; |XXX  X  | $B827
           .byte   $E5     ; |XXX  X X| $B828
           .byte   $E7     ; |XXX  XXX| $B829
           .byte   $E8     ; |XXX X   | $B82A
           .byte   $E9     ; |XXX X  X| $B82B
           .byte   $EB     ; |XXX X XX| $B82C
           .byte   $EC     ; |XXX XX  | $B82D
           .byte   $ED     ; |XXX XX X| $B82E
           .byte   $EF     ; |XXX XXXX| $B82F
           .byte   $F0     ; |XXXX    | $B830
           .byte   $F2     ; |XXXX  X | $B831
           .byte   $F3     ; |XXXX  XX| $B832
           .byte   $F4     ; |XXXX X  | $B833
           .byte   $F6     ; |XXXX XX | $B834
           .byte   $F7     ; |XXXX XXX| $B835
           .byte   $F8     ; |XXXXX   | $B836
           .byte   $FA     ; |XXXXX X | $B837
           .byte   $FB     ; |XXXXX XX| $B838
           .byte   $FD     ; |XXXXXX X| $B839
           .byte   $FE     ; |XXXXXXX | $B83A
           .byte   $FF     ; |XXXXXXXX| $B83B
           .byte   $01     ; |        X| $B83C
           .byte   $02     ; |       X | $B83D
           .byte   $04     ; |      X  | $B83E
           .byte   $05     ; |      X X| $B83F
           .byte   $07     ; |      XXX| $B840
           .byte   $08     ; |     X   | $B841
           .byte   $09     ; |     X  X| $B842
           .byte   $0B     ; |     X XX| $B843
           .byte   $0C     ; |     XX  | $B844
           .byte   $0E     ; |     XXX | $B845
           .byte   $0F     ; |     XXXX| $B846
           .byte   $11     ; |   X   X| $B847
           .byte   $12     ; |   X  X | $B848
           .byte   $14     ; |   X X  | $B849
           .byte   $15     ; |   X X X| $B84A
           .byte   $17     ; |   X XXX| $B84B
           .byte   $18     ; |   XX   | $B84C
           .byte   $1A     ; |   XX X | $B84D
           .byte   $1B     ; |   XX XX| $B84E
           .byte   $1D     ; |   XXX X| $B84F
           .byte   $1E     ; |   XXXX | $B850
           .byte   $20     ; |  X     | $B851
           .byte   $21     ; |  X    X| $B852
           .byte   $23     ; |  X   XX| $B853
           .byte   $24     ; |  X  X  | $B854
           .byte   $26     ; |  X  XX | $B855
           .byte   $27     ; |  X  XXX| $B856
           .byte   $29     ; |  X X  X| $B857
           .byte   $2A     ; |  X X X | $B858
           .byte   $2C     ; |  X XX  | $B859
           .byte   $2D     ; |  X XX X| $B85A
           .byte   $2F     ; |  X XXXX| $B85B
           .byte   $30     ; |  XX    | $B85C
           .byte   $32     ; |  XX  X | $B85D
           .byte   $33     ; |  XX  XX| $B85E
           .byte   $35     ; |  XX X X| $B85F
           .byte   $36     ; |  XX XX | $B860
           .byte   $38     ; |  XXX   | $B861
           .byte   $3A     ; |  XXX X | $B862
           .byte   $3B     ; |  XXX XX| $B863
           .byte   $3D     ; |  XXXX X| $B864
           .byte   $3E     ; |  XXXXX | $B865
           .byte   $40     ; | X       | $B866
           .byte   $41     ; | X      X| $B867
           .byte   $43     ; | X     XX| $B868
           .byte   $45     ; | X    X X| $B869
           .byte   $46     ; | X    XX | $B86A
           .byte   $48     ; | X   X   | $B86B
           .byte   $49     ; | X   X  X| $B86C
           .byte   $4B     ; | X   X XX| $B86D
           .byte   $4D     ; | X   XX X| $B86E
           .byte   $4E     ; | X   XXX | $B86F
           .byte   $50     ; | X X    | $B870
           .byte   $52     ; | X X  X | $B871
           .byte   $53     ; | X X  XX| $B872
           .byte   $55     ; | X X X X| $B873
           .byte   $56     ; | X X XX | $B874
           .byte   $58     ; | X XX   | $B875
           .byte   $5A     ; | X XX X | $B876
           .byte   $5B     ; | X XX XX| $B877
           .byte   $5D     ; | X XXX X| $B878
           .byte   $5F     ; | X XXXXX| $B879
           .byte   $60     ; | XX     | $B87A
           .byte   $62     ; | XX   X | $B87B
           .byte   $64     ; | XX  X  | $B87C
           .byte   $65     ; | XX  X X| $B87D
           .byte   $67     ; | XX  XXX| $B87E
           .byte   $69     ; | XX X  X| $B87F
           .byte   $6A     ; | XX X X | $B880
           .byte   $6C     ; | XX XX  | $B881
           .byte   $6E     ; | XX XXX | $B882
           .byte   $6F     ; | XX XXXX| $B883
           .byte   $71     ; | XXX   X| $B884
           .byte   $73     ; | XXX  XX| $B885
           .byte   $74     ; | XXX X  | $B886
           .byte   $76     ; | XXX XX | $B887
           .byte   $78     ; | XXXX   | $B888
           .byte   $7A     ; | XXXX X | $B889
           .byte   $7B     ; | XXXX XX| $B88A
           .byte   $7D     ; | XXXXX X| $B88B
           .byte   $7F     ; | XXXXXXX| $B88C
           .byte   $81     ; |X       X| $B88D
           .byte   $82     ; |X      X | $B88E
           .byte   $84     ; |X     X  | $B88F
           .byte   $86     ; |X     XX | $B890
           .byte   $88     ; |X    X   | $B891
           .byte   $89     ; |X    X  X| $B892
           .byte   $8B     ; |X    X XX| $B893
           .byte   $8D     ; |X    XX X| $B894
           .byte   $8F     ; |X    XXXX| $B895
           .byte   $90     ; |X  X    | $B896
           .byte   $92     ; |X  X  X | $B897
           .byte   $94     ; |X  X X  | $B898
           .byte   $96     ; |X  X XX | $B899
           .byte   $97     ; |X  X XXX| $B89A
           .byte   $99     ; |X  XX  X| $B89B
           .byte   $9B     ; |X  XX XX| $B89C
           .byte   $9D     ; |X  XXX X| $B89D
           .byte   $9F     ; |X  XXXXX| $B89E
           .byte   $A0     ; |X X     | $B89F
           .byte   $A2     ; |X X   X | $B8A0
           .byte   $A4     ; |X X  X  | $B8A1
           .byte   $A6     ; |X X  XX | $B8A2
           .byte   $A8     ; |X X X   | $B8A3
           .byte   $A9     ; |X X X  X| $B8A4
           .byte   $AB     ; |X X X XX| $B8A5
           .byte   $AD     ; |X X XX X| $B8A6
           .byte   $AF     ; |X X XXXX| $B8A7
           .byte   $B1     ; |X XX   X| $B8A8
           .byte   $B3     ; |X XX  XX| $B8A9
           .byte   $B4     ; |X XX X  | $B8AA
           .byte   $B6     ; |X XX XX | $B8AB
           .byte   $B8     ; |X XXX   | $B8AC
           .byte   $BA     ; |X XXX X | $B8AD
           .byte   $BC     ; |X XXXX  | $B8AE
           .byte   $BE     ; |X XXXXX | $B8AF
           .byte   $C0     ; |XX       | $B8B0
           .byte   $C2     ; |XX     X | $B8B1
           .byte   $C3     ; |XX     XX| $B8B2
           .byte   $C5     ; |XX    X X| $B8B3
           .byte   $C7     ; |XX    XXX| $B8B4
           .byte   $C9     ; |XX   X  X| $B8B5
           .byte   $CB     ; |XX   X XX| $B8B6
           .byte   $CD     ; |XX   XX X| $B8B7
           .byte   $CF     ; |XX   XXXX| $B8B8
           .byte   $D1     ; |XX X   X| $B8B9
           .byte   $D3     ; |XX X  XX| $B8BA
           .byte   $D4     ; |XX X X  | $B8BB
           .byte   $D6     ; |XX X XX | $B8BC
           .byte   $D8     ; |XX XX   | $B8BD
           .byte   $DA     ; |XX XX X | $B8BE
           .byte   $DC     ; |XX XXX  | $B8BF
           .byte   $DE     ; |XX XXXX | $B8C0
           .byte   $E0     ; |XXX     | $B8C1
           .byte   $E2     ; |XXX   X | $B8C2
           .byte   $E4     ; |XXX  X  | $B8C3
           .byte   $E6     ; |XXX  XX | $B8C4
           .byte   $E8     ; |XXX X   | $B8C5
           .byte   $EA     ; |XXX X X | $B8C6
           .byte   $EC     ; |XXX XX  | $B8C7
           .byte   $EE     ; |XXX XXX | $B8C8
           .byte   $F0     ; |XXXX    | $B8C9
           .byte   $F2     ; |XXXX  X | $B8CA
           .byte   $F4     ; |XXXX X  | $B8CB
           .byte   $F6     ; |XXXX XX | $B8CC
           .byte   $F8     ; |XXXXX   | $B8CD
           .byte   $FA     ; |XXXXX X | $B8CE
           .byte   $FC     ; |XXXXXX  | $B8CF
           .byte   $FE     ; |XXXXXXX | $B8D0
InitPlayerGameVars
           LDX       PlayerIndex
           LDA       #GameStateGAMEOVER
           STA       P0GameStateFlag,X
           TXA
           ASL
           ASL
           TAX
           LDA       #$00
           STA       ScoreP0+0,X
           STA       ScoreP0+1,X
           STA       ScoreP0+2,X
           STA       ScoreP0+3,X
           STA       P0TotalLinesClearedBCD,X
           STA       P0TotalLinesClearedBCD+1,X
           STA       P0TotalLinesCleared,X
           STA       P0TotalLinesCleared+1,X
LB8F1
           JSR       LC0BF   ; B8F1 20 BF C0
           CMP       #$1C    ; B8F4 C9 1C
           BCS       LB8F1   ; B8F6 B0 F9
           AND       #$FC    ; B8F8 29 FC
           LDX       PlayerIndex
           STA       $C1,X   ; B8FC 95 C1
           TXA               ; B8FE 8A
           EOR       #$01    ; B8FF 49 01
           TAX               ; B901 AA
           LDA       P0GameStateFlag,X
           CMP       #GameStateGAMEOVER
           BNE       LB916   ; B906 D0 0E
           STX       PlayerIndex
           JSR       LB948   ; B90A 20 48 B9
           LDA       PlayerIndex
           EOR       #$01    ; B90F 49 01
           STA       PlayerIndex
           JSR       LC7D4   ; B913 20 D4 C7
LB916      LDX       PlayerIndex
           LDA       #$01    ; B918 A9 01
           STA       $C9,X   ; B91A 95 C9
           LDA       #$01    ; B91C A9 01
           STA       $CD,X   ; B91E 95 CD
           LDA       #$00    ; B920 A9 00
           STA       $CF,X   ; B922 95 CF
           STA       $CB,X   ; B924 95 CB
           STA       P0DownwardTicks,X
           STA       $D9,X   ; B928 95 D9
           STA       P0ClearRowState,X
           STA       $DD,X   ; B92C 95 DD
           STA       P0PointsScoredDelay,X
           INC       P0GameStateFlag,X       ; go from FF=GAMEOVER to 00=PLAYING
           LDA       #$01    ; B932 A9 01
           STA       P0DownwardSpeed,X       ; B934 95 D7
           LDA       #$0F    ; B936 A9 0F
           STA       $D1,X   ; B938 95 D1
           LDA       #$80    ; B93A A9 80
           STA       $D3,X   ; B93C 95 D3
           JSR       LB948   ; B93E 20 48 B9
           JSR       LB9E1   ; B941 20 E1 B9
           JSR       LC08B   ; B944 20 8B C0
           RTS               ; B947 60

LB948      LDA       #$16    ; B948 A9 16
           STA       $A4     ; B94A 85 A4
LB94C      LDA       #$00    ; B94C A9 00
           LDY       $A4     ; B94E A4 A4
           JSR       LC1FE   ; B950 20 FE C1
           LDY       $A4     ; B953 A4 A4
           DEY               ; B955 88
           STY       $A4     ; B956 84 A4
           BPL       LB94C   ; B958 10 F2
           RTS               ; B95A 60

LB95B
           LDX       PlayerIndex
           LDA       #$01    ; B95D A9 01
           STA       $DF,X   ; B95F 95 DF
           STA       P0DownwardSpeed,X
           LDA       #$04    ; B963 A9 04
           STA       P0PieceX,X
           LDA       #$00    ; B967 A9 00
           STA       P0PieceY,X
           STA       P0PieceRotation,X
           STA       P0DownwardTicks,X
           STA       $D9,X   ; B96F 95 D9
           LDA       $C1,X   ; B971 B5 C1
           PHA               ; B973 48
LB974      JSR       LC0BF   ; B974 20 BF C0
           CMP       #$1C    ; B977 C9 1C
           BCS       LB974   ; B979 B0 F9
           AND       #$FC    ; B97B 29 FC
           STA       $C1,X   ; B97D 95 C1
           PLA               ; B97F 68
           LDX       PlayerIndex
           STA       P0PieceType,X   ; B982 95 BF
           PHA               ; B984 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B989 AA
           PLA               ; B98A 68
           JSR       LC249   ; B98B 20 49 C2
           BCC       LB9A0   ; B98E 90 10
           LDX       PlayerIndex
           LDA       P0PieceType,X   ; B992 B5 BF
           PHA               ; B994 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B999 AA
           PLA               ; B99A 68
           JSR       RenderPiece
           SEC               ; B99E 38
           RTS               ; B99F 60


LB9A0      LDX       PlayerIndex
           LDA       P0PieceType,X   ; B9A2 B5 BF
           PHA               ; B9A4 48
           LDY       P0PieceY,X
           LDA       P0PieceX,X
           TAX               ; B9A9 AA
           PLA               ; B9AA 68
           JSR       RenderPiece
           LDX       PlayerIndex
           LDA       #$14    ; B9B0 A9 14
           STA       P0DownwardTicks,X
           JSR       LC633   ; B9B4 20 33 C6
           CLC               ; B9B7 18
           RTS               ; B9B8 60

LB9B9
           LDX       PlayerIndex
           LDA       P0PieceRotation,X
           AND       #$01    ; B9BD 29 01
           BNE       LB9E0   ; B9BF D0 1F
           LDA       P0PieceType,X
           CMP       #$0C    ; B9C3 C9 0C
           BEQ       LB9E0   ; B9C5 F0 19
           CMP       #$10    ; B9C7 C9 10
           BEQ       LB9D6   ; B9C9 F0 0B
           LDA       P0PieceX,X
           CMP       #$08    ; B9CD C9 08
           BNE       LB9E0   ; B9CF D0 0F
           LDA       #$07    ; B9D1 A9 07
           STA       P0PieceX,X
           RTS               ; B9D5 60

LB9D6      LDA       P0PieceX,X
           CMP       #$07    ; B9D8 C9 07
           BNE       LB9E0   ; B9DA D0 04
           LDA       #$06    ; B9DC A9 06
           STA       P0PieceX,X
LB9E0      RTS               ; B9E0 60


LB9E1
           LDX       PlayerIndex
LB9E3
           LDA       P0GameStateFlag,X
           CMP       #$09
           BCS       LB9F0
           TAY
           LDA       LinesToClearLevel,Y
           STA       P0LinesLeftInLevel,X
           RTS
LB9F0      SEC
           SBC       #$03
           JMP       LB9E3

LinesToClearLevel
           .byte   5,10,12,10,13,16,12,15,18


JoystickDecodeTable
                     ;values are directions stored as %0000RLDU, where 0=on and 1=off
                     ;     VALUE     INDEX   DIRS    ACTION
           .byte   %00001111       ; 0     LRUD    no change
           .byte   %00001111       ; 1     LRD     no change
           .byte   %00001111       ; 2     LRU     no change
           .byte   %00001111       ; 3     LR      no change
           .byte   %00001111       ; 4     RDU     no change
           .byte   %00000111       ; 5     RD      right
           .byte   %00001111       ; 6     RU      no change
           .byte   %00000111       ; 7     R       right
           .byte   %00001111       ; 8     LUD     no change
           .byte   %00001011       ; 9     LD      left
           .byte   %00001111       ; 10    LU      no change
           .byte   %00001011       ; 11    L       left
           .byte   %00001111       ; 12    UD      no change
           .byte   %00001101       ; 13    D       down
           .byte   %00001111       ; 14    U       no change
           .byte   %00001111       ; 15    -       no change

LBA0F
           .byte   $A0     ; |X X     | $BA0F
           .byte   $E0     ; |XXX     | $BA10
           .byte   $80     ; |X        | $BA11
           .byte   $42     ; | X     X | $BA12
           .byte   $54     ; | X X X  | $BA13
           .byte   $5E     ; | X XXXX | $BA14
           .byte   $20     ; |  X     | $BA15
           .byte   $90     ; |X  X    | $BA16
           .byte   $34     ; |  XX X  | $BA17
           .byte   $86     ; |X     XX | $BA18
           .byte   $90     ; |X  X    | $BA19
           .byte   $9A     ; |X  XX X | $BA1A
           .byte   $A4     ; |X X  X  | $BA1B
           .byte   $AE     ; |X X XXX | $BA1C
           .byte   $90     ; |X  X    | $BA1D
           .byte   $B8     ; |X XXX   | $BA1E
           .byte   $C2     ; |XX     X | $BA1F
           .byte   $90     ; |X  X    | $BA20
           .byte   $CC     ; |XX   XX  | $BA21
           .byte   $D6     ; |XX X XX | $BA22
           .byte   $90     ; |X  X    | $BA23
           .byte   $90     ; |X  X    | $BA24
           .byte   $E0     ; |XXX     | $BA25

LBA26
           .byte   $A0     ; |X X     | $BA26
           .byte   $E0     ; |XXX     | $BA27
           .byte   $80     ; |X        | $BA28
           .byte   $3C     ; |  XXXX  | $BA29
           .byte   $4A     ; | X   X X | $BA2A
           .byte   $5C     ; | X XXX  | $BA2B
           .byte   $1E     ; |   XXXX | $BA2C
           .byte   $8E     ; |X    XXX | $BA2D
           .byte   $32     ; |  XX  X | $BA2E
           .byte   $84     ; |X     X  | $BA2F
           .byte   $8E     ; |X    XXX | $BA30
           .byte   $98     ; |X  XX   | $BA31
           .byte   $A2     ; |X X   X | $BA32
           .byte   $AC     ; |X X XX  | $BA33
           .byte   $8E     ; |X    XXX | $BA34
           .byte   $B6     ; |X XX XX | $BA35
           .byte   $C0     ; |XX       | $BA36
           .byte   $8E     ; |X    XXX | $BA37
           .byte   $CA     ; |XX   X X | $BA38
           .byte   $D4     ; |XX X X  | $BA39
           .byte   $8E     ; |X    XXX | $BA3A
           .byte   $8E     ; |X    XXX | $BA3B
           .byte   $DE     ; |XX XXXX | $BA3C

LBA3D
           .byte   $1C     ; |   XXX  | $BA3D
           .byte   $1C     ; |   XXX  | $BA3E
           .byte   $1C     ; |   XXX  | $BA3F
           .byte   $18     ; |   XX   | $BA40
           .byte   $18     ; |   XX   | $BA41
           .byte   $18     ; |   XX   | $BA42
           .byte   $18     ; |   XX   | $BA43
           .byte   $18     ; |   XX   | $BA44
           .byte   $18     ; |   XX   | $BA45
           .byte   $18     ; |   XX   | $BA46
           .byte   $18     ; |   XX   | $BA47
           .byte   $18     ; |   XX   | $BA48
           .byte   $18     ; |   XX   | $BA49
           .byte   $18     ; |   XX   | $BA4A
           .byte   $18     ; |   XX   | $BA4B
           .byte   $18     ; |   XX   | $BA4C
           .byte   $18     ; |   XX   | $BA4D
           .byte   $18     ; |   XX   | $BA4E
           .byte   $18     ; |   XX   | $BA4F
           .byte   $18     ; |   XX   | $BA50
           .byte   $18     ; |   XX   | $BA51
           .byte   $18     ; |   XX   | $BA52
           .byte   $18     ; |   XX   | $BA53

LBA54
           .byte   $A0     ; |X X     | $BA54
           .byte   $A0     ; |X X     | $BA55
           .byte   $A0     ; |X X     | $BA56
           .byte   $80     ; |X        | $BA57
           .byte   $80     ; |X        | $BA58
           .byte   $80     ; |X        | $BA59
           .byte   $80     ; |X        | $BA5A
           .byte   $80     ; |X        | $BA5B
           .byte   $80     ; |X        | $BA5C
           .byte   $80     ; |X        | $BA5D
           .byte   $80     ; |X        | $BA5E
           .byte   $80     ; |X        | $BA5F
           .byte   $80     ; |X        | $BA60
           .byte   $80     ; |X        | $BA61
           .byte   $80     ; |X        | $BA62
           .byte   $80     ; |X        | $BA63
           .byte   $80     ; |X        | $BA64
           .byte   $80     ; |X        | $BA65
           .byte   $80     ; |X        | $BA66
           .byte   $80     ; |X        | $BA67
           .byte   $80     ; |X        | $BA68
           .byte   $80     ; |X        | $BA69
           .byte   $80     ; |X        | $BA6A
LBA6B
           .byte   $A0     ; |X X     | $BA6B
           .byte   $A0     ; |X X     | $BA6C
           .byte   $A0     ; |X X     | $BA6D
           .byte   $80     ; |X        | $BA6E
           .byte   $80     ; |X        | $BA6F
           .byte   $80     ; |X        | $BA70
           .byte   $80     ; |X        | $BA71
           .byte   $80     ; |X        | $BA72
           .byte   $80     ; |X        | $BA73
           .byte   $80     ; |X        | $BA74
           .byte   $80     ; |X        | $BA75
           .byte   $80     ; |X        | $BA76
           .byte   $80     ; |X        | $BA77
           .byte   $80     ; |X        | $BA78
           .byte   $80     ; |X        | $BA79
           .byte   $80     ; |X        | $BA7A
           .byte   $80     ; |X        | $BA7B
           .byte   $80     ; |X        | $BA7C
           .byte   $80     ; |X        | $BA7D
           .byte   $80     ; |X        | $BA7E
           .byte   $80     ; |X        | $BA7F
           .byte   $80     ; |X        | $BA80
           .byte   $80     ; |X        | $BA81
LBA82
           .byte   $40     ; | X       | $BA82
           .byte   $40     ; | X       | $BA83
           .byte   $40     ; | X       | $BA84
           .byte   $C0     ; |XX       | $BA85
           .byte   $C0     ; |XX       | $BA86
           .byte   $C0     ; |XX       | $BA87
           .byte   $C0     ; |XX       | $BA88
           .byte   $C0     ; |XX       | $BA89
           .byte   $C0     ; |XX       | $BA8A
           .byte   $C0     ; |XX       | $BA8B
           .byte   $C0     ; |XX       | $BA8C
           .byte   $C0     ; |XX       | $BA8D
           .byte   $C0     ; |XX       | $BA8E
           .byte   $C0     ; |XX       | $BA8F
           .byte   $C0     ; |XX       | $BA90
           .byte   $C0     ; |XX       | $BA91
           .byte   $C0     ; |XX       | $BA92
           .byte   $C0     ; |XX       | $BA93
           .byte   $C0     ; |XX       | $BA94
           .byte   $C0     ; |XX       | $BA95
           .byte   $C0     ; |XX       | $BA96
           .byte   $C0     ; |XX       | $BA97
           .byte   $C0     ; |XX       | $BA98
MidBufLine1Lo
           .byte   $02     ; |       X | $BA99
MidBufLine2Lo .byte        $0E     ; |     XXX | $BA9A
LBA9B      .byte   $1A     ; |   XX X | $BA9B
           .byte   $26     ; |  X  XX | $BA9C
           .byte   $32     ; |  XX  X | $BA9D
           .byte   $3E     ; |  XXXXX | $BA9E
           .byte   $4A     ; | X   X X | $BA9F
           .byte   $56     ; | X X XX | $BAA0
           .byte   $62     ; | XX   X | $BAA1
           .byte   $6E     ; | XX XXX | $BAA2
           .byte   $7A     ; | XXXX X | $BAA3
           .byte   $86     ; |X     XX | $BAA4
           .byte   $92     ; |X  X  X | $BAA5
           .byte   $9E     ; |X  XXXX | $BAA6
           .byte   $AA     ; |X X X X | $BAA7
           .byte   $B6     ; |X XX XX | $BAA8
           .byte   $C2     ; |XX     X | $BAA9
           .byte   $CE     ; |XX   XXX | $BAAA
           .byte   $DA     ; |XX XX X | $BAAB
           .byte   $E6     ; |XXX  XX | $BAAC
           .byte   $F2     ; |XXXX  X | $BAAD
           .byte   $FE     ; |XXXXXXX | $BAAE
           .byte   $0A     ; |     X X | $BAAF
           .byte   $16     ; |   X XX | $BAB0
           .byte   $22     ; |  X   X | $BAB1
MidBufLine1Hi
           .byte   $23     ; |  X   XX| $BAB2
MidBufLine2Hi .byte        $23     ; |  X   XX| $BAB3
LBAB4      .byte   $23     ; |  X   XX| $BAB4
           .byte   $23     ; |  X   XX| $BAB5
           .byte   $23     ; |  X   XX| $BAB6
           .byte   $23     ; |  X   XX| $BAB7
           .byte   $23     ; |  X   XX| $BAB8
           .byte   $23     ; |  X   XX| $BAB9
           .byte   $23     ; |  X   XX| $BABA
           .byte   $23     ; |  X   XX| $BABB
           .byte   $23     ; |  X   XX| $BABC
           .byte   $23     ; |  X   XX| $BABD
           .byte   $23     ; |  X   XX| $BABE
           .byte   $23     ; |  X   XX| $BABF
           .byte   $23     ; |  X   XX| $BAC0
           .byte   $23     ; |  X   XX| $BAC1
           .byte   $23     ; |  X   XX| $BAC2
           .byte   $23     ; |  X   XX| $BAC3
           .byte   $23     ; |  X   XX| $BAC4
           .byte   $23     ; |  X   XX| $BAC5
           .byte   $23     ; |  X   XX| $BAC6
           .byte   $23     ; |  X   XX| $BAC7
           .byte   $24     ; |  X  X  | $BAC8
           .byte   $24     ; |  X  X  | $BAC9
           .byte   $24     ; |  X  X  | $BACA
DLTableLo  .byte   $10     ; |   X    | $BACB
LBACC      .byte   $72     ; | XXX  X | $BACC
LBACD      .byte   $D4     ; |XX X X  | $BACD
           .byte   $36     ; |  XX XX | $BACE
           .byte   $98     ; |X  XX   | $BACF
           .byte   $FA     ; |XXXXX X | $BAD0
           .byte   $5C     ; | X XXX  | $BAD1
           .byte   $BE     ; |X XXXXX | $BAD2
           .byte   $20     ; |  X     | $BAD3
           .byte   $82     ; |X      X | $BAD4
           .byte   $E4     ; |XXX  X  | $BAD5
           .byte   $46     ; | X    XX | $BAD6
           .byte   $A8     ; |X X X   | $BAD7
           .byte   $0A     ; |     X X | $BAD8
           .byte   $6C     ; | XX XX  | $BAD9
           .byte   $CE     ; |XX   XXX | $BADA
           .byte   $30     ; |  XX    | $BADB
           .byte   $92     ; |X  X  X | $BADC
           .byte   $F4     ; |XXXX X  | $BADD
           .byte   $56     ; | X X XX | $BADE
           .byte   $B8     ; |X XXX   | $BADF
           .byte   $1A     ; |   XX X | $BAE0
           .byte   $2E     ; |  X XXX | $BAE1
DLTableHi  .byte   $18     ; |   XX   | $BAE2
LBAE3      .byte   $18     ; |   XX   | $BAE3
LBAE4      .byte   $18     ; |   XX   | $BAE4
           .byte   $19     ; |   XX  X| $BAE5
           .byte   $19     ; |   XX  X| $BAE6
           .byte   $19     ; |   XX  X| $BAE7
           .byte   $1A     ; |   XX X | $BAE8
           .byte   $1A     ; |   XX X | $BAE9
           .byte   $1B     ; |   XX XX| $BAEA
           .byte   $1B     ; |   XX XX| $BAEB
           .byte   $1B     ; |   XX XX| $BAEC
           .byte   $1C     ; |   XXX  | $BAED
           .byte   $1C     ; |   XXX  | $BAEE
           .byte   $1D     ; |   XXX X| $BAEF
           .byte   $1D     ; |   XXX X| $BAF0
           .byte   $1D     ; |   XXX X| $BAF1
           .byte   $1E     ; |   XXXX | $BAF2
           .byte   $1E     ; |   XXXX | $BAF3
           .byte   $1E     ; |   XXXX | $BAF4
           .byte   $1F     ; |   XXXXX| $BAF5
           .byte   $1F     ; |   XXXXX| $BAF6
           .byte   $20     ; |  X     | $BAF7
           .byte   $24     ; |  X  X  | $BAF8

DllsForScoreArea
           .byte   $C5, $E0, $24, $0C, $00 ; DL object for "shading" characters under player 1's area
           .byte   $D9, $E0, $24, $0C, $50 ; DL object for "shading" characters under player 2's area

           .byte   $00, $00        ; DL terminator

           .byte   $ED, $E0, $24, $0C, $00 ; DL object for all # values in player 1's score area
           .byte   $01, $E0, $25, $0C, $50 ; DL object for all # values in player 2's score area

           .byte   $00, $00        ; DL terminator

           .byte   $15, $E0, $25, $0C, $00 ; DL object for characters underneath player 1's score area

           .byte   $29, $E0, $25, $0C, $50 ; DL object for characters underneath player 2's score area

           .byte   $00, $00        ; DL terminator


                     ; *** These are the characters that make up the middle part of the screen, between
                     ;     the player 1 and player 2 play areas. The width of this column is 12 chars.
ScreenMiddleCharsPart1
           .byte   $00, $00, $00, $00, $68, $6A, $6C, $6E, $00, $00, $00, $00
           .byte   $00, $00, $70, $72, $74, $76, $78, $7A, $7C, $7E, $00, $00
           .byte   $80, $82, $84, $86, $88, $8A, $8C, $88, $8E, $90, $92, $94
           .byte   $96, $98, $9A, $88, $88, $9C, $9E, $88, $88, $A0, $A2, $A4
           .byte   $A6, $A8, $AA, $88, $88, $88, $88, $88, $88, $AC, $AE, $B0
           .byte   $B2, $B4, $B6, $B6, $B6, $B6, $B6, $B6, $B6, $B6, $B8, $BA
           .byte   $BC, $BE, $C0, $C2, $C4, $C6, $C0, $C2, $C4, $C6, $C8, $CA
           .byte   $CC, $CE, $D0, $D2, $D4, $D6, $D0, $D2, $D4, $D6, $D8, $08
           .byte   $CC, $EA, $DC, $DE, $E0, $E2, $DC, $DE, $E0, $E2, $FE, $08
           .byte   $CC, $EA, $E4, $E6, $E8, $E2, $E4, $E6, $E8, $E2, $FE, $08
           .byte   $CC, $EA, $EC, $EE, $F0, $E2, $EC, $EE, $F0, $E2, $FE, $08
           .byte   $44, $F2, $F4, $F6, $F8, $FA, $F4, $F6, $F8, $FA, $FC, $46
           .byte   $4A, $04, $06, $04, $06, $04, $06, $04, $06, $04, $06, $48
           .byte   $4A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $48
           .byte   $4A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $48
           .byte   $4A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $48
           .byte   $4A, $0A, $0A, $0A, $22, $24, $26, $28, $2A, $0A, $0A, $48      ; "LINES"
           .byte   $4A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $48
           .byte   $4A, $0A, $0A, $0A, $22, $28, $2C, $2E, $0A, $0A, $0A, $48      ; "LEFT"
           .byte   $4A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $48
           .byte   $42, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $DA
           .byte   $CC, $88, $88, $88
ScreenMiddleCharsPart2 .byte       $88, $88, $88, $88, $88, $88, $88, $08
           .byte   $CC, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $08
           .byte   $CC, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $08
           .byte   $CC, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $08


                     ; *** These are the characters that make up the bottom 3 lines of the screen,
                     ;     under the player 1 and 2 areas. The width is the full screen, 40 chars.
ScreenBottomChars
           .byte   $88, $88, $88, $62, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5E, $88, $4E, $50, $50, $50, $50, $50, $50, $64, $88, $62, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5E, $88, $88, $88
           .byte   $88, $88, $88, $56, $0E, $0E, $0E, $0E, $0E, $0E, $0A, $0E, $0E, $0E, $58, $88, $56, $0E, $0E, $0E, $0E, $0E, $0E, $58, $88, $56, $0E, $0E, $0E, $0E, $0E, $0E, $0A, $0E, $0E, $0E, $58, $88, $88, $88
           .byte   $88, $88, $88, $52, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $4C, $88, $52, $54, $54, $54, $54, $54, $54, $4C, $88, $52, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $4C, $88, $88, $88

ScreenInit
           LDA       #$90
           STA       CHBASE

           LDX       #$00
MiddleCharsLoop1
           LDA       ScreenMiddleCharsPart1,X
           STA       $2302,X
           INX
           BNE       MiddleCharsLoop1

           LDX       #$2C
MiddleCharsLoop2
           LDA       ScreenMiddleCharsPart2,X
           STA       $2402,X
           DEX
           BPL       MiddleCharsLoop2

           LDX       #$77
BottomCharsLoop
           LDA       ScreenBottomChars,X
           STA       $24C5,X
           DEX
           BPL       BottomCharsLoop

           LDX       #$23
LBCE8      LDA       DllsForScoreArea,X
           STA       $24A1,X
           DEX
           BPL       LBCE8

                     ; *** setup DLL entries...
           LDA       #$00
           STA       $A2
           STA       PieceRotation   ; ; likely just re-used this var. rename.
           STA       DUMMYDL ; but first setup an empty 2 byte DL, so empty DLLs can point to it.
           STA       DUMMYDL+1
           LDX       PieceRotation   ; ; likely just re-used this var. rename.

                     ; *** 8 blank scanlines
           LDA       #$07
           STA       $2200,X
           INX
           LDA       #>DUMMYDL
           STA       $2200,X
           INX
           LDA       #<DUMMYDL
           STA       $2200,X

                     ; *** 8 scanlines DL=$2490
           INX
           LDY       #$00
           LDA       #$07
           STA       $2200,X
           INX
           LDA       #$24
           STA       $2200,X
           INX
           LDA       #$90
           STA       $2200,X

                     ; *** 8 scanlines DL=$2497
           INX
           LDA       #$07
           STA       $2200,X
           INX
           LDA       #$24
           STA       $2200,X
           INX
           LDA       #$97
           STA       $2200,X

           INX
           STX       PieceRotation   ; save our position in the DLL. ; likely just re-used this var. rename.

                     ; *** In the previos code we setup the top 2 visible DLL entries in the center column to
                     ;     to point to $2490 and $2497, o now we'll take a break from the DLL and populate
                     ;     those two DLs.

           LDA       MidBufLine1Lo   ; byte0: Lo=$02
           STA       $2490
           LDA       #$E0    ; byte1: 320C characters
           STA       $2491
           LDA       MidBufLine1Hi   ; byte2: Hi=$23
           STA       $2492
           LDA       #$14    ; byte3: Palette=0, Width=12
           STA       $2493
           LDA       #$38    ; byte4: x-pos=56
           STA       $2494
           LDA       #$00    ; DL terminator
           STA       $2496

           LDA       MidBufLine2Lo   ; byte0: Lo=$0E
           STA       $2497
           LDA       #$E0    ; byte1: 320C characters
           STA       $2498
           LDA       MidBufLine2Hi   ; byte2: Hi=$23
           STA       $2499
           LDA       #$14    ; byte3: Palette=0, Width=12
           STA       $249A
           LDA       #$38    ; byte4: x-pos=56
           STA       $249B
           LDA       #$00    ; DL terminator
           STA       $249D

           LDY       #$00
           LDA       #$17
           STA       $9C
LBD7F
           LDY       #$00

           LDA       #$0A
           STA       PieceX

           LDA       #$10
           STA       PieceY

           LDA       #$0A
           STA       $9F

           LDA       #$68
           STA       PieceTypeIndex

           LDX       $A2
           LDA       DLTableLo,X
           STA       $90

           LDA       DLTableHi,X
           STA       $91

                     ; ** back to creating DLL entries...

                     ; *** 8 scanlines DL=1810 to ???
           LDX       PieceRotation   ; likely just re-used this var. rename.
           LDA       #$07    ;
           STA       $2200,X ; BDA1 9D 00 22
           INX               ; BDA4 E8
           LDA       $91     ; BDA5 A5 91
           STA       $2200,X ; BDA7 9D 00 22
           INX               ; BDAA E8
           LDA       $90     ; BDAB A5 90
           STA       $2200,X ; BDAD 9D 00 22
           INX               ; BDB0 E8

           STX       PieceRotation   ; likely just re-used this var. rename.

           LDY       #$00    ; BDB3 A0 00
           LDA       #$00    ; BDB5 A9 00
           STA       ($90),Y ; BDB7 91 90
           INY               ; BDB9 C8
           LDA       #$40    ; BDBA A9 40
           STA       ($90),Y ; BDBC 91 90
           INY               ; BDBE C8
           LDA       #$A0    ; BDBF A9 A0
           STA       ($90),Y ; BDC1 91 90
           INY               ; BDC3 C8
           LDA       #$1F    ; BDC4 A9 1F
           STA       ($90),Y ; BDC6 91 90
           INY               ; BDC8 C8
           LDA       PieceY
           STA       ($90),Y ; BDCB 91 90
           INY               ; BDCD C8
           CLC               ; BDCE 18
           LDA       PieceY
           ADC       #$04    ; BDD1 69 04
           STA       PieceY
           DEC       PieceX
LBDD7
           LDA       #$00    ; BDD7 A9 00
           STA       ($90),Y ; BDD9 91 90
           INY               ; BDDB C8
           LDA       #$1F    ; BDDC A9 1F
           STA       ($90),Y ; BDDE 91 90
           INY               ; BDE0 C8
           LDA       #$A0    ; BDE1 A9 A0
           STA       ($90),Y ; BDE3 91 90
           INY               ; BDE5 C8
           LDA       PieceY
           STA       ($90),Y ; BDE8 91 90
           INY               ; BDEA C8
           CLC               ; BDEB 18
           LDA       PieceY
           ADC       #$04    ; BDEE 69 04
           STA       PieceY
           DEC       PieceX
           BNE       LBDD7   ; BDF4 D0 E1
LBDF6
           LDA       #$00    ; BDF6 A9 00
           STA       ($90),Y ; BDF8 91 90
           INY               ; BDFA C8
           LDA       #$1F    ; BDFB A9 1F
           STA       ($90),Y ; BDFD 91 90
           INY               ; BDFF C8
           LDA       #$A0    ; BE00 A9 A0
           STA       ($90),Y ; BE02 91 90
           INY               ; BE04 C8
           LDA       PieceTypeIndex
           STA       ($90),Y ; BE07 91 90
           INY               ; BE09 C8
           CLC               ; BE0A 18
           LDA       PieceTypeIndex
           ADC       #$04    ; BE0D 69 04
           STA       PieceTypeIndex
           DEC       $9F     ; BE11 C6 9F
           BNE       LBDF6   ; BE13 D0 E1
           LDX       $A2     ; BE15 A6 A2
           LDA       LBA9B,X ; BE17 BD 9B BA
           STA       ($90),Y ; BE1A 91 90
           INY               ; BE1C C8
           LDA       #$E0    ; BE1D A9 E0
           STA       ($90),Y ; BE1F 91 90
           INY               ; BE21 C8
           LDA       LBAB4,X ; BE22 BD B4 BA
           STA       ($90),Y ; BE25 91 90
           INY               ; BE27 C8
           LDA       #$14    ; BE28 A9 14
           STA       ($90),Y ; BE2A 91 90
           INY               ; BE2C C8
           LDA       #$38    ; BE2D A9 38
           STA       ($90),Y ; BE2F 91 90
           INY               ; BE31 C8
           LDA       LBA0F,X ; BE32 BD 0F BA
           STA       ($90),Y ; BE35 91 90
           INY               ; BE37 C8
           LDA       LBA82,X ; BE38 BD 82 BA
           STA       ($90),Y ; BE3B 91 90
           INY               ; BE3D C8
           LDA       LBA54,X ; BE3E BD 54 BA
           STA       ($90),Y ; BE41 91 90
           INY               ; BE43 C8
           LDA       LBA3D,X ; BE44 BD 3D BA
           STA       ($90),Y ; BE47 91 90
           INY               ; BE49 C8
           LDA       #$00    ; BE4A A9 00
           STA       ($90),Y ; BE4C 91 90
           INY               ; BE4E C8
           LDA       LBA26,X ; BE4F BD 26 BA
           STA       ($90),Y ; BE52 91 90
           INY               ; BE54 C8
           LDA       LBA82,X ; BE55 BD 82 BA
           STA       ($90),Y ; BE58 91 90
           INY               ; BE5A C8
           LDA       LBA6B,X ; BE5B BD 6B BA
           STA       ($90),Y ; BE5E 91 90
           INY               ; BE60 C8
           LDA       LBA3D,X ; BE61 BD 3D BA
           STA       ($90),Y ; BE64 91 90
           INY               ; BE66 C8
           LDA       #$90    ; BE67 A9 90
           STA       ($90),Y ; BE69 91 90
           INY               ; BE6B C8
           LDA       #$00    ; BE6C A9 00
           INY               ; BE6E C8
           STA       ($90),Y ; BE6F 91 90
           INY               ; BE71 C8
           INX               ; BE72 E8
           STX       $A2     ; BE73 86 A2
           DEC       $9C     ; BE75 C6 9C
           BEQ       LBE7C   ; BE77 F0 03
           JMP       LBD7F   ; BE79 4C 7F BD
LBE7C      LDX       PieceRotation   ; likely just re-used this var. rename.
           LDA       #$07    ; BE7E A9 07
           STA       $2200,X ; BE80 9D 00 22
           LDA       #$24    ; BE83 A9 24
           STA       $2201,X ; BE85 9D 01 22
           LDA       #$A1    ; BE88 A9 A1
           STA       $2202,X ; BE8A 9D 02 22
           LDA       #$07    ; BE8D A9 07
           STA       $2203,X ; BE8F 9D 03 22
           LDA       #$24    ; BE92 A9 24
           STA       $2204,X ; BE94 9D 04 22
           LDA       #$AD    ; BE97 A9 AD
           STA       $2205,X ; BE99 9D 05 22
           LDA       #$87    ; BE9C A9 87
           STA       $2206,X ; BE9E 9D 06 22
           LDA       #$24    ; BEA1 A9 24
           STA       $2207,X ; BEA3 9D 07 22
           LDA       #$B9    ; BEA6 A9 B9
           STA       $2208,X ; BEA8 9D 08 22
           RTS               ; BEAB 60

                     ; *** our main game NMI
NMIMainGame
           CLD
           PHA
           TXA
           PHA
           TYA
           PHA
           INC       FrameCounter
           BNE       SkipFrameHiByteInc
           INC       FrameCounter+1
SkipFrameHiByteInc

           LDX       $C9
           BEQ       LBEBD
           DEX
LBEBD
           STX       $C9
           LDX       $CA
           BEQ       LBEC4
           DEX
LBEC4
           STX       $CA

           LDX       $CB
           BEQ       LBECB
           DEX
LBECB
           STX       $CB

           LDX       $CC
           BEQ       LBED2
           DEX
LBED2
           STX       $CC

           LDX       $CD
           BEQ       LBED9
           DEX
LBED9
           STX       $CD

           LDX       $CE
           BEQ       LBEE0
           DEX
LBEE0
           STX       $CE

           LDX       $CF
           BEQ       LBEE7
           DEX
LBEE7
           STX       $CF

           LDX       $D0
           BEQ       LBEEE
           DEX
LBEEE
           STX       $D0

           SEC
           LDA       P0DownwardTicks
           SBC       P0DownwardSpeed
           BPL       LBEF9
           LDA       #$00
LBEF9      STA       P0DownwardTicks
           LDX       $D9
           BEQ       LBF02
           DEX
           STX       $D9
LBF02

           SEC
           LDA       P1DownwardTicks
           SBC       P1DownwardSpeed
           BPL       LBF0B
           LDA       #$00
LBF0B

           STA       P1DownwardTicks
           LDX       $DA
           BEQ       LBF14
           DEX
           STX       $DA
LBF14

           LDX       P0ClearRowState
           BEQ       LBF1F
           BMI       LBF1F
           DEX
           BEQ       LBF1F
           STX       P0ClearRowState
LBF1F

           LDX       P1ClearRowState
           BEQ       DecrementPointsScoredDelay
           BMI       DecrementPointsScoredDelay
           DEX
           BEQ       DecrementPointsScoredDelay
           STX       P1ClearRowState
DecrementPointsScoredDelay
           LDA       P0PointsScoredDelay
           BEQ       P0DelayAlreadyZero
           DEC       P0PointsScoredDelay
P0DelayAlreadyZero
           LDA       P1PointsScoredDelay
           BEQ       P1DelayAlreadyZero
           DEC       P1PointsScoredDelay
P1DelayAlreadyZero

           LDA       #$90
           STA       CHBASE

           LDA       SFX0EnabledFlag
           BEQ       SFX0HandlerEnd
           LDA       SFX0SampleDuration
           BNE       SFX0SampleDurationDecrement
SFX0GetNextSample
           LDY       #$00
           LDA       (SFX0Pointer),Y
           BMI       CheckSFX0Terminator
           AND       #$3F
           STY       AUDV0   ; AUDV0=0 while we setup a new frequency
           STA       AUDF0
           INY
           LDA       (SFX0Pointer),Y
           TAX
           LSR
           LSR
           LSR
           LSR
           STA       AUDC0
           TXA
           AND       #$0F
           STA       AUDV0
           INY
           LDA       (SFX0Pointer),Y
           STA       SFX0SampleDuration
           TAX
           CLC
           LDA       SFX0Pointer
           ADC       #$03
           STA       SFX0Pointer
           BCC       SkipSFX0HiByteInc
           INC       SFX0Pointer+1
SkipSFX0HiByteInc
           TXA
           BEQ       SFX0GetNextSample
           JMP       SFX0HandlerEnd
CheckSFX0Terminator
           AND       #$7F
           BEQ       EndSFX0
           BNE       SFX0GetNextSample       ; possibly leads to an infinite loop?
SFX0SampleDurationDecrement
           DEC       SFX0SampleDuration
           BEQ       SFX0GetNextSample
           BNE       SFX0HandlerEnd
EndSFX0
           LDA       #$00
           STA       SFX0EnabledFlag
           STA       SFX0SampleDuration
SFX0HandlerEnd

           LDA       SFX1EnabledFlag
           BEQ       SFX1HandlerEnd
           LDA       SFX1SampleDuration
           BNE       SFX1SampleDurationDecrement
SFX1GetNextSample
           LDY       #$00
           LDA       (SFX1Pointer),Y
           BMI       CheckSFX1Terminator
           AND       #$3F
           STY       AUDV1
           STA       AUDF1
           INY
           LDA       (SFX1Pointer),Y
           TAX
           LSR
           LSR
           LSR
           LSR
           STA       AUDC1
           TXA
           AND       #$0F
           STA       AUDV1
           INY
           LDA       (SFX1Pointer),Y
           STA       SFX1SampleDuration
           TAX
           CLC
           LDA       SFX1Pointer
           ADC       #$03
           STA       SFX1Pointer
           BCC       SkipSFX1HiByteInc
           INC       SFX1Pointer+1
SkipSFX1HiByteInc
           TXA
           BEQ       SFX0GetNextSample       ; *** FIXME - Ken has a bug - should be SFX1GetNextSample
           JMP       SFX1HandlerEnd
CheckSFX1Terminator
           AND       #$7F
           BEQ       EndSFX1
           BNE       SFX1GetNextSample
SFX1SampleDurationDecrement
           DEC       SFX1SampleDuration
           BEQ       SFX1GetNextSample
           BNE       SFX1HandlerEnd
EndSFX1
           LDA       #$00
           STA       SFX1EnabledFlag
           STA       SFX1SampleDuration
SFX1HandlerEnd
           PLA
           TAY
           PLA
           TAX
           PLA
           RTI

SetupSFX
           PHA
           LDA       #$00
           STA       SFX0EnabledFlag,X
           STA       SFX0SampleDuration,X
           TXA
           ASL
           TAX
           PLA
           STA       SFX0Pointer,X
           TYA
           STA       SFX0Pointer+1,X
           TXA
           LSR
           TAX
           LDA       #$01
           STA       SFX0EnabledFlag,X
           RTS

SFXDropData
           .byte   $06
           .byte   $FE
           .byte   $01

           .byte   $08
           .byte   $FC
           .byte   $01

           .byte   $06
           .byte   $FA
           .byte   $01

           .byte   $08
           .byte   $F8
           .byte   $01

           .byte   $06
           .byte   $F6
           .byte   $01

           .byte   $08
           .byte   $F4
           .byte   $01

           .byte   $06
           .byte   $F2
           .byte   $01

           .byte   $00     ; silence
           .byte   $00
           .byte   $00

           .byte   $80     ; SFX terminator

SFXFourRowsClear
           .byte   $08
           .byte   $CE
           .byte   $02

           .byte   $0A
           .byte   $CC
           .byte   $02

           .byte   $09
           .byte   $C8
           .byte   $01

           .byte   $0B
           .byte   $C6
           .byte   $01

           .byte   $0A
           .byte   $C2
           .byte   $01

           .byte   $0C
           .byte   $C1
           .byte   $01

           .byte   $00     ; 2 frames silence
           .byte   $00
           .byte   $02

SFXThreeRowsClear
           .byte   $08
           .byte   $CE
           .byte   $02

           .byte   $0A
           .byte   $CC
           .byte   $02

           .byte   $09
           .byte   $C8
           .byte   $01

           .byte   $0B
           .byte   $C6
           .byte   $01

           .byte   $0A
           .byte   $C2
           .byte   $01

           .byte   $0C
           .byte   $C1
           .byte   $01

           .byte   $00     ; 2 frames silence
           .byte   $00
           .byte   $02

SFXTwoRowsClear
           .byte   $08
           .byte   $CE
           .byte   $02

           .byte   $0A
           .byte   $CC
           .byte   $02

           .byte   $09
           .byte   $C8
           .byte   $01

           .byte   $0B
           .byte   $C6
           .byte   $01

           .byte   $0A
           .byte   $C2
           .byte   $01

           .byte   $0C
           .byte   $C1
           .byte   $01

           .byte   $00     ; 2 frames silence
           .byte   $00
           .byte   $02

SFXOneRowClear
           .byte   $08
           .byte   $CE
           .byte   $02

           .byte   $0A
           .byte   $CC
           .byte   $02

           .byte   $09
           .byte   $C8
           .byte   $01

           .byte   $0B
           .byte   $C6
           .byte   $01

           .byte   $0A
           .byte   $C2
           .byte   $01

           .byte   $0C
           .byte   $C1
           .byte   $01

SFXSilence
           .byte   $00
           .byte   $00
           .byte   $00

           .byte   $80     ; SFX terminator

RowClearSFXTableLo
           .byte   <SFXSilence
           .byte   <SFXOneRowClear
           .byte   <SFXOneRowClear
           .byte   <SFXTwoRowsClear
           .byte   <SFXOneRowClear
           .byte   <SFXTwoRowsClear
           .byte   <SFXTwoRowsClear
           .byte   <SFXThreeRowsClear
           .byte   <SFXOneRowClear
           .byte   <SFXTwoRowsClear
           .byte   <SFXTwoRowsClear
           .byte   <SFXThreeRowsClear
           .byte   <SFXTwoRowsClear
           .byte   <SFXThreeRowsClear
           .byte   <SFXThreeRowsClear
           .byte   <SFXFourRowsClear

RowClearSFXTableHi
           .byte   >SFXSilence
           .byte   >SFXOneRowClear
           .byte   >SFXOneRowClear
           .byte   >SFXTwoRowsClear
           .byte   >SFXOneRowClear
           .byte   >SFXTwoRowsClear
           .byte   >SFXTwoRowsClear
           .byte   >SFXThreeRowsClear
           .byte   >SFXOneRowClear
           .byte   >SFXTwoRowsClear
           .byte   >SFXTwoRowsClear
           .byte   >SFXThreeRowsClear
           .byte   >SFXTwoRowsClear
           .byte   >SFXThreeRowsClear
           .byte   >SFXThreeRowsClear
           .byte   >SFXFourRowsClear

SetupClearRowsSFX
           TAX
           LDA       RowClearSFXTableHi,X
           TAY
           LDA       RowClearSFXTableLo,X
           LDX       PlayerIndex
           JMP       SetupSFX
LC08B      LDX       PlayerIndex
           BNE       LC0A7   ; C08D D0 18
           LDA       $E1     ; C08F A5 E1
           CMP       #$0A    ; C091 C9 0A
           LDY       #$0E    ; C093 A0 0E
           BCC       LC09C   ; C095 90 05
           LDY       #$10    ; C097 A0 10
           SEC               ; C099 38
           SBC       #$0A    ; C09A E9 0A
LC09C      STY       $23AC   ; C09C 8C AC 23
           ASL               ; C09F 0A
           CLC               ; C0A0 18
           ADC       #$0E    ; C0A1 69 0E
           STA       $23AD   ; C0A3 8D AD 23
           RTS               ; C0A6 60

LC0A7      LDA       $E2     ; C0A7 A5 E2
           CMP       #$0A    ; C0A9 C9 0A
           LDY       #$0E    ; C0AB A0 0E
           BCC       LC0B4   ; C0AD 90 05
           LDY       #$10    ; C0AF A0 10
           SEC               ; C0B1 38
           SBC       #$0A    ; C0B2 E9 0A
LC0B4      STY       $23B2   ; C0B4 8C B2 23
           ASL               ; C0B7 0A
           CLC               ; C0B8 18
           ADC       #$0E    ; C0B9 69 0E
           STA       $23B3   ; C0BB 8D B3 23
           RTS               ; C0BE 60

LC0BF
           CLC
           LDA       $B2     ; C0C0 A5 B2
           ADC       $B3     ; C0C2 65 B3
           STA       $B3     ; C0C4 85 B3
           ADC       $B4     ; C0C6 65 B4
           STA       $B4     ; C0C8 85 B4
           ADC       $B5     ; C0CA 65 B5
           STA       $B5     ; C0CC 85 B5
           CLC               ; C0CE 18
           LDA       $B2     ; C0CF A5 B2
           ADC       #$27    ; C0D1 69 27
           STA       $B2     ; C0D3 85 B2
           LDA       $B3     ; C0D5 A5 B3
           ADC       #$59    ; C0D7 69 59
           STA       $B3     ; C0D9 85 B3
           STA       $B6     ; C0DB 85 B6
           LDA       $B4     ; C0DD A5 B4
           ADC       #$41    ; C0DF 69 41
           STA       $B4     ; C0E1 85 B4
           LDA       $B5     ; C0E3 A5 B5
           ADC       #$31    ; C0E5 69 31
           STA       $B5     ; C0E7 85 B5
           LDA       $B6     ; C0E9 A5 B6
           RTS               ; C0EB 60

LC0EC      STA       $B2     ; C0EC 85 B2
           STX       $B3     ; C0EE 86 B3
           LDA       #$00    ; C0F0 A9 00
           STA       $B4     ; C0F2 85 B4
           STA       $B5     ; C0F4 85 B5
           RTS               ; C0F6 60

WaitForVblankStart
LoopUntilVlankEnds
           LDA       MSTAT
           BMI       LoopUntilVlankEnds
LoopUntilVblankStarts
           LDA       MSTAT
           BPL       LoopUntilVblankStarts
           RTS

CopyStringToBuf
           STX       PieceX
           STY       PieceY
           STA       PieceTypeIndex
LC106      LDY       #$00    ; C106 A0 00
           LDA       (PieceShapePointer),Y   ; C108 B1 92
           CMP       #$01    ; C10A C9 01
           BEQ       LC120   ; C10C F0 12
           LDX       PieceX
           LDY       PieceY
           JSR       LC5D8   ; C112 20 D8 C5
           INC       PieceX
           INC       PieceShapePointer
           BNE       LC11D   ; C119 D0 02
           INC       PieceShapePointer+1
LC11D      JMP       LC106   ; C11D 4C 06 C1
LC120      RTS               ; C120 60

RenderPiece
           STX       PieceX
           STY       PieceY
           STA       PieceTypeIndex
           TAX
           LDA       ShapePointersLo,X
           STA       PieceShapePointer
           LDA       ShapePointersHi,X
           STA       PieceShapePointer+1
           LDY       #$FF    ; C132 A0 FF
           STY       $9F     ; C134 84 9F
LC136      LDY       $9F     ; C136 A4 9F
           INY               ; C138 C8
           STY       $9F     ; C139 84 9F
           LDA       (PieceShapePointer),Y   ; C13B B1 92
           BMI       LC14E   ; C13D 30 0F
           LDX       PieceTypeIndex
           ORA       LC530,X ; C141 1D 30 C5
           LDX       PieceX
           LDY       PieceY
           JSR       LC5AC   ; C148 20 AC C5
           JMP       LC136   ; C14B 4C 36 C1
LC14E      CMP       #$FF    ; C14E C9 FF
           BEQ       LC186   ; C150 F0 34
           CMP       #$80    ; C152 C9 80
           BNE       LC15B   ; C154 D0 05
           INC       PieceX
           JMP       LC136   ; C158 4C 36 C1
LC15B      CMP       #$81    ; C15B C9 81
           BNE       LC164   ; C15D D0 05
           DEC       PieceX
           JMP       LC136   ; C161 4C 36 C1
LC164      CMP       #$82    ; C164 C9 82
           BNE       LC16D   ; C166 D0 05
           DEC       PieceY
           JMP       LC136   ; C16A 4C 36 C1
LC16D      CMP       #$83    ; C16D C9 83
           BNE       LC176   ; C16F D0 05
           INC       PieceY
           JMP       LC136   ; C173 4C 36 C1
LC176      CMP       #$84    ; C176 C9 84
           BNE       LC136   ; C178 D0 BC
           CLC               ; C17A 18
           LDA       PieceTypeIndex
           ADC       #$04    ; C17D 69 04
           AND       #$1F    ; C17F 29 1F
           STA       PieceTypeIndex
           JMP       LC136   ; C183 4C 36 C1
LC186      RTS               ; C186 60

LC187
           STX       PieceX
           STY       PieceY
           TAX               ; C18B AA
           LDA       ShapePointersLo,X       ; C18C BD 9D C2
           STA       PieceShapePointer
           LDA       ShapePointersHi,X       ; C191 BD CD C2
           STA       PieceShapePointer+1
           LDY       #$FF    ; C196 A0 FF
           STY       $9F     ; C198 84 9F
LC19A      LDY       $9F     ; C19A A4 9F
           INY               ; C19C C8
           STY       $9F     ; C19D 84 9F
           LDA       (PieceShapePointer),Y   ; C19F B1 92
           BMI       LC1AF   ; C1A1 30 0C
           LDA       #$00    ; C1A3 A9 00
           LDX       PieceX
           LDY       PieceY
           JSR       LC5AC   ; C1A9 20 AC C5
           JMP       LC19A   ; C1AC 4C 9A C1
LC1AF      CMP       #$FF    ; C1AF C9 FF
           BEQ       LC1D7   ; C1B1 F0 24
           CMP       #$80    ; C1B3 C9 80
           BNE       LC1BC   ; C1B5 D0 05
           INC       PieceX
           JMP       LC19A   ; C1B9 4C 9A C1
LC1BC      CMP       #$81    ; C1BC C9 81
           BNE       LC1C5   ; C1BE D0 05
           DEC       PieceX
           JMP       LC19A   ; C1C2 4C 9A C1
LC1C5      CMP       #$82    ; C1C5 C9 82
           BNE       LC1CE   ; C1C7 D0 05
           DEC       PieceY
           JMP       LC19A   ; C1CB 4C 9A C1
LC1CE      CMP       #$83    ; C1CE C9 83
           BNE       LC19A   ; C1D0 D0 C8
           INC       PieceY
           JMP       LC19A   ; C1D4 4C 9A C1
LC1D7      RTS               ; C1D7 60

LC1D8      LDX       #$00    ; C1D8 A2 00
           BCC       LC1DE   ; C1DA 90 02
           LDX       #$0A    ; C1DC A2 0A
LC1DE      CPY       #$17    ; C1DE C0 17
           BCS       LC1FC   ; C1E0 B0 1A
           STX       PieceX
           STY       PieceY
           LDX       #$0A    ; C1E6 A2 0A
           STA       $9F     ; C1E8 85 9F
LC1EA      LDX       PieceX
           LDY       PieceY
           CLC               ; C1EE 18
           JSR       LC560   ; C1EF 20 60 C5
           BCC       LC1FC   ; C1F2 90 08
           INC       PieceX
           DEC       $9F     ; C1F6 C6 9F
           BNE       LC1EA   ; C1F8 D0 F0
           SEC               ; C1FA 38
           RTS               ; C1FB 60

LC1FC      CLC               ; C1FC 18
           RTS               ; C1FD 60

LC1FE      CPY       #$17    ; C1FE C0 17
           BCS       LC21D   ; C200 B0 1B
           LDX       #$00    ; C202 A2 00
           STX       PieceX
           STY       PieceY
           LDX       #$0A    ; C208 A2 0A
           STX       $9F     ; C20A 86 9F
LC20C      LDX       PieceX
           LDY       PieceY
           PHA               ; C210 48
           JSR       LC5AC   ; C211 20 AC C5
           PLA               ; C214 68
           INC       PieceX
           DEC       $9F     ; C217 C6 9F
           BNE       LC20C   ; C219 D0 F1
           SEC               ; C21B 38
           RTS               ; C21C 60

LC21D      CLC               ; C21D 18
           RTS               ; C21E 60

LC21F      CPY       #$03    ; C21F C0 03
           BCC       LC248   ; C221 90 25
           LDX       #$00    ; C223 A2 00
           STX       PieceX
           STY       PieceY
           LDA       #$0A    ; C229 A9 0A
           STA       $9F     ; C22B 85 9F
LC22D      LDX       PieceX
           LDY       PieceY
           DEY               ; C231 88
           JSR       LC588   ; C232 20 88 C5
           LDX       PieceX
           LDY       PieceY
           JSR       LC5AC   ; C239 20 AC C5
           INC       PieceX
           DEC       $9F     ; C23E C6 9F
           BNE       LC22D   ; C240 D0 EB
           LDY       PieceY
           DEY               ; C244 88
           JMP       LC21F   ; C245 4C 1F C2
LC248      RTS               ; C248 60

LC249      STX       PieceX
           STY       PieceY
           TAX               ; C24D AA
           LDA       ShapePointersLo,X       ; C24E BD 9D C2
           STA       PieceShapePointer
           LDA       ShapePointersHi,X       ; C253 BD CD C2
           STA       PieceShapePointer+1
           LDY       #$FF    ; C258 A0 FF
           STY       $9F     ; C25A 84 9F
LC25C      LDY       $9F     ; C25C A4 9F
           INY               ; C25E C8
           STY       $9F     ; C25F 84 9F
           LDA       (PieceShapePointer),Y   ; C261 B1 92
           BMI       LC271   ; C263 30 0C
           LDX       PieceX
           LDY       PieceY
           JSR       LC560   ; C269 20 60 C5
           BCS       LC29B   ; C26C B0 2D
           JMP       LC25C   ; C26E 4C 5C C2
LC271      CMP       #$FF    ; C271 C9 FF
           BEQ       LC299   ; C273 F0 24
           CMP       #$80    ; C275 C9 80
           BNE       LC27E   ; C277 D0 05
           INC       PieceX
           JMP       LC25C   ; C27B 4C 5C C2
LC27E      CMP       #$81    ; C27E C9 81
           BNE       LC287   ; C280 D0 05
           DEC       PieceX
           JMP       LC25C   ; C284 4C 5C C2
LC287      CMP       #$82    ; C287 C9 82
           BNE       LC290   ; C289 D0 05
           DEC       PieceY
           JMP       LC25C   ; C28D 4C 5C C2
LC290      CMP       #$83    ; C290 C9 83
           BNE       LC25C   ; C292 D0 C8
           INC       PieceY
           JMP       LC25C   ; C296 4C 5C C2
LC299      CLC               ; C299 18
           RTS               ; C29A 60

LC29B      SEC               ; C29B 38
           RTS               ; C29C 60

ShapePointersLo
           .byte   <Piece_L_0
           .byte   <Piece_L_90
           .byte   <Piece_L_180
           .byte   <Piece_L_240

           .byte   <Piece_Z_0
           .byte   <Piece_Z_90
           .byte   <Piece_Z_0
           .byte   <Piece_Z_90

           .byte   <Piece_T_0
           .byte   <Piece_T_90
           .byte   <Piece_T_180
           .byte   <Piece_T_240

           .byte   <Piece_Square_0
           .byte   <Piece_Square_0
           .byte   <Piece_Square_0
           .byte   <Piece_Square_0

           .byte   <Piece_Stick_0
           .byte   <Piece_Stick_90
           .byte   <Piece_Stick_0
           .byte   <Piece_Stick_90

           .byte   <Piece_S_0
           .byte   <Piece_S_90
           .byte   <Piece_S_0
           .byte   <Piece_S_90

           .byte   <Piece_ReverseL_0
           .byte   <Piece_ReverseL_90
           .byte   <Piece_ReverseL_180
           .byte   <Piece_ReverseL_240

           .byte   <Piece_Logo_B
           .byte   <Piece_Logo_L
           .byte   <Piece_Logo_O
           .byte   <Piece_Logo_C

           .byte   <Piece_Logo_D
           .byte   <Piece_Logo_R
           .byte   <Piece_Logo_O
           .byte   <Piece_Logo_P

           .byte   <Piece_Logo_b
           .byte   <Piece_Logo_Y
           .byte   <Piece_Logo_R
           .byte   <Piece_Logo_s

           .byte   <Piece_Logo_K
           .byte   <Piece_Logo_E
           .byte   <Piece_Logo_N
           .byte   $00     ;

           .byte   <Piece_Logo_S
           .byte   <Piece_Logo_I
           .byte   <Piece_Logo_d
           .byte   <Piece_Logo_E

ShapePointersHi
           .byte   >Piece_L_0
           .byte   >Piece_L_90
           .byte   >Piece_L_180
           .byte   >Piece_L_240

           .byte   >Piece_Z_0
           .byte   >Piece_Z_90
           .byte   >Piece_Z_0
           .byte   >Piece_Z_90

           .byte   >Piece_T_0
           .byte   >Piece_T_90
           .byte   >Piece_T_180
           .byte   >Piece_T_240

           .byte   >Piece_Square_0
           .byte   >Piece_Square_0
           .byte   >Piece_Square_0
           .byte   >Piece_Square_0

           .byte   >Piece_Stick_0
           .byte   >Piece_Stick_90
           .byte   >Piece_Stick_0
           .byte   >Piece_Stick_90

           .byte   >Piece_S_0
           .byte   >Piece_S_90
           .byte   >Piece_S_0
           .byte   >Piece_S_90

           .byte   >Piece_ReverseL_0
           .byte   >Piece_ReverseL_90
           .byte   >Piece_ReverseL_180
           .byte   >Piece_ReverseL_240

           .byte   >Piece_Logo_B
           .byte   >Piece_Logo_L
           .byte   >Piece_Logo_O
           .byte   >Piece_Logo_C

           .byte   >Piece_Logo_D
           .byte   >Piece_Logo_R
           .byte   >Piece_Logo_O
           .byte   >Piece_Logo_P

           .byte   >Piece_Logo_b
           .byte   >Piece_Logo_Y
           .byte   >Piece_Logo_R
           .byte   >Piece_Logo_s

           .byte   >Piece_Logo_K
           .byte   >Piece_Logo_E
           .byte   >Piece_Logo_N
           .byte   $00

           .byte   >Piece_Logo_S
           .byte   >Piece_Logo_I
           .byte   >Piece_Logo_d
           .byte   >Piece_Logo_E

PieceHeights                 ; Heights for each piece, in each rotation...
Piece_L_Heights
           .byte   $01     ; C2FD
           .byte   $02
           .byte   $01
           .byte   $02

Piece_Z_Heights
           .byte   $01
           .byte   $02
           .byte   $01
           .byte   $02

Piece_T_Heights
           .byte   $01
           .byte   $02
           .byte   $01
           .byte   $02

Piece_Square_Heights
           .byte   $01
           .byte   $01
           .byte   $01
           .byte   $01

Piece_Stick_Heights
           .byte   $00
           .byte   $03
           .byte   $00
           .byte   $03

Piece_S_Heights
           .byte   $01
           .byte   $02
           .byte   $01
           .byte   $02

Piece_ReverseL_Heights
           .byte   $01
           .byte   $02
           .byte   $01
           .byte   $02


                     ; ** character/shape data...

Piece_L_0
           .byte   $08     ;
           .byte   $83     ; ###
           .byte   $04     ; #
           .byte   $82     ;
           .byte   $80
           .byte   $0A
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_L_90
           .byte   $02     ; ##
           .byte   $80     ;  #
           .byte   $09     ;  #
           .byte   $83     ;
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_L_180
           .byte   $83     ;
           .byte   $02     ;   #
           .byte   $80     ; ###
           .byte   $0A     ;
           .byte   $80
           .byte   $07
           .byte   $82
           .byte   $05
           .byte   $FF

Piece_L_240
           .byte   $05     ;
           .byte   $83     ; #
           .byte   $0B     ; #
           .byte   $83     ; ##
           .byte   $06
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_Z_0
           .byte   $02     ;
           .byte   $80     ; ##
           .byte   $09     ;  ##
           .byte   $83     ;
           .byte   $06
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_Z_90
           .byte   $80     ;  #
           .byte   $05     ; ##
           .byte   $83     ; #
           .byte   $07     ;
           .byte   $81
           .byte   $08
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_T_0
           .byte   $02     ;
           .byte   $80     ; ###
           .byte   $0D     ;  #
           .byte   $80     ;
           .byte   $03
           .byte   $81
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_T_90
           .byte   $80     ;  #
           .byte   $05     ; ##
           .byte   $83     ;  #
           .byte   $0F     ;
           .byte   $83
           .byte   $04
           .byte   $82
           .byte   $81
           .byte   $02
           .byte   $FF

Piece_T_180
           .byte   $80     ;
           .byte   $05     ;  #
           .byte   $83     ; ###
           .byte   $0C     ;
           .byte   $81
           .byte   $02
           .byte   $80
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_T_240
           .byte   $05     ; #
           .byte   $83     ; ##
           .byte   $0E     ; #
           .byte   $80     ;
           .byte   $03
           .byte   $81
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_Square_0
           .byte   $08     ;
           .byte   $80     ; ##
           .byte   $09     ; ##
           .byte   $83     ;
           .byte   $07
           .byte   $81
           .byte   $06
           .byte   $FF

Piece_Stick_0
           .byte   $02     ;
           .byte   $80     ;
           .byte   $0A     ; ####
           .byte   $80     ;
           .byte   $0A
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_Stick_90
           .byte   $80     ; #
           .byte   $05     ; #
           .byte   $83     ; #
           .byte   $0B     ; #
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_S_0
           .byte   $83     ;
           .byte   $02     ;  ##
           .byte   $80     ; ##
           .byte   $07     ;
           .byte   $82
           .byte   $08
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_S_90
           .byte   $05     ; #
           .byte   $83     ; ##
           .byte   $06     ;  #
           .byte   $80     ;
           .byte   $09
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_ReverseL_0
           .byte   $02     ;
           .byte   $80     ; ###
           .byte   $0A     ;   #
           .byte   $80     ;
           .byte   $09
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_ReverseL_90
           .byte   $80     ;  #
           .byte   $05     ;  #
           .byte   $83     ; ##
           .byte   $0B     ;
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $02
           .byte   $FF

Piece_ReverseL_180
           .byte   $05     ;
           .byte   $83     ; #
           .byte   $06     ; ###
           .byte   $80     ;
           .byte   $0A
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_ReverseL_240
           .byte   $08     ;
           .byte   $80     ; ##
           .byte   $03     ; #
           .byte   $81     ; #
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

                     ; "BLOC DROP" pieces for title...
Piece_Logo_B
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0E
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $06
           .byte   $80
           .byte   $0A
           .byte   $80
           .byte   $07
           .byte   $82
           .byte   $0B
           .byte   $82
           .byte   $09
           .byte   $81
           .byte   $0A
           .byte   $FF

Piece_Logo_L
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_Logo_O
           .byte   $83
           .byte   $83
           .byte   $08
           .byte   $80
           .byte   $0A
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $0A
           .byte   $81
           .byte   $06
           .byte   $82
           .byte   $0B
           .byte   $FF

Piece_Logo_C
           .byte   $83
           .byte   $83
           .byte   $08
           .byte   $80
           .byte   $0A
           .byte   $80
           .byte   $03
           .byte   $81
           .byte   $81
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $06
           .byte   $80
           .byte   $0A
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_Logo_D
           .byte   $80
           .byte   $80
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0F
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $0A
           .byte   $81
           .byte   $06
           .byte   $82
           .byte   $0B
           .byte   $82
           .byte   $08
           .byte   $80
           .byte   $0A
           .byte   $FF

Piece_Logo_R
           .byte   $83
           .byte   $80
           .byte   $03
           .byte   $81
           .byte   $08
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_Logo_P
           .byte   $83
           .byte   $83
           .byte   $08
           .byte   $80
           .byte   $0A
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $0A
           .byte   $81
           .byte   $0E
           .byte   $82
           .byte   $0B
           .byte   $83
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF


                     ; "BY KEN SIDERS" pieces, which were either not used yet, or abandoned for the small "by Ken Siders" text...

Piece_Logo_K
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0E
           .byte   $80
           .byte   $0F
           .byte   $82
           .byte   $08
           .byte   $80
           .byte   $07
           .byte   $82
           .byte   $05
           .byte   $83
           .byte   $83
           .byte   $83
           .byte   $81
           .byte   $06
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $04
           .byte   $81
           .byte   $81
           .byte   $04
           .byte   $82
           .byte   $0B
           .byte   $FF

Piece_Logo_E
           .byte   $83
           .byte   $83
           .byte   $08
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $0E
           .byte   $83
           .byte   $06
           .byte   $80
           .byte   $03
           .byte   $FF

Piece_Logo_N
           .byte   $83
           .byte   $83
           .byte   $83
           .byte   $83
           .byte   $04
           .byte   $82
           .byte   $0B
           .byte   $82
           .byte   $08
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_Logo_S
           .byte   $80
           .byte   $03
           .byte   $81
           .byte   $08
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $06
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $02
           .byte   $FF

Piece_Logo_I
           .byte   $01
           .byte   $83
           .byte   $83
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $04
           .byte   $FF

Piece_Logo_d
           .byte   $80
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0F
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $06
           .byte   $82
           .byte   $0B
           .byte   $82
           .byte   $08
           .byte   $FF

Piece_Logo_s
           .byte   $83
           .byte   $83
           .byte   $80
           .byte   $03
           .byte   $81
           .byte   $08
           .byte   $83
           .byte   $06
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $02
           .byte   $FF

Piece_Logo_b
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $0E
           .byte   $80
           .byte   $09
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $06
           .byte   $82
           .byte   $0B
           .byte   $FF

Piece_Logo_Y
           .byte   $83
           .byte   $83
           .byte   $05
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $06
           .byte   $80
           .byte   $0F
           .byte   $82
           .byte   $0B
           .byte   $82
           .byte   $05
           .byte   $83
           .byte   $83
           .byte   $83
           .byte   $0B
           .byte   $83
           .byte   $07
           .byte   $81
           .byte   $02
           .byte   $FF

                     ; Ken seems to have skipped the "by" string, for brevity.
string_by
           .byte   $36     ;     "b"    $C4D3
           .byte   $4D     ;     "y"
           .byte   $01     ;     EOL

string_KEN
           .byte   $24     ;     "K"
           .byte   $1E     ;     "E"
           .byte   $27     ;     "N"
           .byte   $01     ;     EOL

string_SIDERS
           .byte   $2C     ;     "S"
           .byte   $22     ;     "I"
           .byte   $1D     ;     "D"
           .byte   $1E     ;     "E"
           .byte   $51     ;     "R"
           .byte   $2C     ;     "S"
           .byte   $01     ;     EOL

string_NOT_4_SALE
           .byte   $27     ;     "N"
           .byte   $28     ;     "O"
           .byte   $2D     ;     "T"
           .byte   $00     ;     " "
           .byte   $14     ;     "4"
           .byte   $00     ;     " "
           .byte   $2C     ;     "S"
           .byte   $1A     ;     "A"
           .byte   $25     ;     "L"
           .byte   $1E     ;     "E"
           .byte   $01     ;     EOL

string_copyright_2013
           .byte   $4F     ;     "©" ½
           .byte   $50     ;     "©" ½
           .byte   $12     ;     "2"
           .byte   $10     ;     "0"
           .byte   $11     ;     "1"
           .byte   $13     ;     "3"
           .byte   $01     ;     EOL

string_demo_mar10
           .byte   $1D     ;     "D"
           .byte   $1E     ;     "E"
           .byte   $26     ;     "M"
           .byte   $28     ;     "O"
           .byte   $00     ;     " "
           .byte   $26     ;     "M"
           .byte   $35     ;     "a"
           .byte   $46     ;     "r"
           .byte   $11     ;     "1"
           .byte   $10     ;     "0"
           .byte   $01     ;     EOL

                     ; ??? doesn't seem to be accessed, either directly or indirectly ???
           .byte   $80     ; |X        | $C4FE
           .byte   $80     ; |X        | $C4FF
           .byte   $30     ; |  XX    | $C500
           .byte   $80     ; |X        | $C501
           .byte   $22     ; |  X   X | $C502
           .byte   $80     ; |X        | $C503
           .byte   $29     ; |  X X  X| $C504
           .byte   $FF     ; |XXXXXXXX| $C505
           .byte   $80     ; |X        | $C506
           .byte   $80     ; |X        | $C507
           .byte   $36     ; |  XX XX | $C508
           .byte   $4D     ; | X   XX X| $C509
           .byte   $81     ; |X       X| $C50A
           .byte   $81     ; |X       X| $C50B
           .byte   $81     ; |X       X| $C50C
           .byte   $81     ; |X       X| $C50D
           .byte   $81     ; |X       X| $C50E
           .byte   $81     ; |X       X| $C50F
           .byte   $24     ; |  X  X  | $C510
           .byte   $80     ; |X        | $C511
           .byte   $1E     ; |   XXXX | $C512
           .byte   $80     ; |X        | $C513
           .byte   $27     ; |  X  XXX| $C514
           .byte   $80     ; |X        | $C515
           .byte   $80     ; |X        | $C516
           .byte   $83     ; |X      XX| $C517
           .byte   $83     ; |X      XX| $C518
           .byte   $2C     ; |  X XX  | $C519
           .byte   $80     ; |X        | $C51A
           .byte   $22     ; |  X   X | $C51B
           .byte   $80     ; |X        | $C51C
           .byte   $1D     ; |   XXX X| $C51D
           .byte   $80     ; |X        | $C51E
           .byte   $1E     ; |   XXXX | $C51F
           .byte   $80     ; |X        | $C520
           .byte   $51     ; | X X   X| $C521
           .byte   $80     ; |X        | $C522
           .byte   $2C     ; |  X XX  | $C523
           .byte   $81     ; |X       X| $C524
           .byte   $81     ; |X       X| $C525
           .byte   $81     ; |X       X| $C526
           .byte   $81     ; |X       X| $C527
           .byte   $81     ; |X       X| $C528
           .byte   $81     ; |X       X| $C529
           .byte   $81     ; |X       X| $C52A
           .byte   $81     ; |X       X| $C52B
           .byte   $81     ; |X       X| $C52C
           .byte   $83     ; |X      XX| $C52D
           .byte   $83     ; |X      XX| $C52E
           .byte   $FF     ; |XXXXXXXX| $C52F

LC530
           .byte   $C0     ; |XX       | $C530
           .byte   $C0     ; |XX       | $C531
           .byte   $C0     ; |XX       | $C532
           .byte   $C0     ; |XX       | $C533
           .byte   $20     ; |  X     | $C534
           .byte   $20     ; |  X     | $C535
           .byte   $20     ; |  X     | $C536
           .byte   $20     ; |  X     | $C537
           .byte   $80     ; |X        | $C538
           .byte   $80     ; |X        | $C539
           .byte   $80     ; |X        | $C53A
           .byte   $80     ; |X        | $C53B
           .byte   $40     ; | X       | $C53C
           .byte   $40     ; | X       | $C53D
           .byte   $40     ; | X       | $C53E
           .byte   $40     ; | X       | $C53F
           .byte   $00     ; |         | $C540
           .byte   $00     ; |         | $C541
           .byte   $00     ; |         | $C542
           .byte   $00     ; |         | $C543
           .byte   $E0     ; |XXX     | $C544
           .byte   $E0     ; |XXX     | $C545
           .byte   $E0     ; |XXX     | $C546
           .byte   $E0     ; |XXX     | $C547
           .byte   $A0     ; |X X     | $C548
           .byte   $A0     ; |X X     | $C549
           .byte   $A0     ; |X X     | $C54A
           .byte   $A0     ; |X X     | $C54B
           .byte   $00     ; |         | $C54C
           .byte   $C0     ; |XX       | $C54D
           .byte   $20     ; |  X     | $C54E
           .byte   $E0     ; |XXX     | $C54F
           .byte   $40     ; | X       | $C550
           .byte   $A0     ; |X X     | $C551
           .byte   $20     ; |  X     | $C552
           .byte   $80     ; |X        | $C553
           .byte   $A0     ; |X X     | $C554
           .byte   $C0     ; |XX       | $C555
           .byte   $40     ; | X       | $C556
           .byte   $20     ; |  X     | $C557
           .byte   $40     ; | X       | $C558
           .byte   $20     ; |  X     | $C559
           .byte   $E0     ; |XXX     | $C55A
           .byte   $00     ; |         | $C55B
           .byte   $C0     ; |XX       | $C55C
           .byte   $80     ; |X        | $C55D
           .byte   $A0     ; |X X     | $C55E
           .byte   $E0     ; |XXX     | $C55F

LC560      LDA       #$00    ; C560 A9 00
           CPX       #$0A    ; C562 E0 0A
           BCS       LC586   ; C564 B0 20
           CPY       #$17    ; C566 C0 17
           BCS       LC586   ; C568 B0 1C
           LDA       DLTableLo,Y     ; C56A B9 CB BA
           STA       $90     ; C56D 85 90
           LDA       DLTableHi,Y     ; C56F B9 E2 BA
           STA       $91     ; C572 85 91
           LDA       PlayerIndex
           BEQ       LC57D   ; C576 F0 05
           TXA               ; C578 8A
           CLC               ; C579 18
           ADC       #$0A    ; C57A 69 0A
           TAX               ; C57C AA
LC57D      LDA       LC600,X ; C57D BD 00 C6
           TAY               ; C580 A8
           LDA       ($90),Y ; C581 B1 90
           BNE       LC586   ; C583 D0 01
           RTS               ; C585 60

LC586      SEC               ; C586 38
           RTS               ; C587 60

LC588      LDA       DLTableLo,Y     ; C588 B9 CB BA
           STA       $90     ; C58B 85 90
           LDA       DLTableHi,Y     ; C58D B9 E2 BA
           STA       $91     ; C590 85 91
           LDA       PlayerIndex
           BEQ       LC59B   ; C594 F0 05
           TXA               ; C596 8A
           CLC               ; C597 18
           ADC       #$0A    ; C598 69 0A
           TAX               ; C59A AA
LC59B      LDA       LC614,X ; C59B BD 14 C6
           TAY               ; C59E A8
           LDA       ($90),Y ; C59F B1 90
           AND       #$E0    ; C5A1 29 E0
           PHA               ; C5A3 48
           LDA       LC600,X ; C5A4 BD 00 C6
           TAY               ; C5A7 A8
           PLA               ; C5A8 68
           ORA       ($90),Y ; C5A9 11 90
           RTS               ; C5AB 60

LC5AC      STA       $9C     ; C5AC 85 9C
           LDA       DLTableLo,Y     ; C5AE B9 CB BA
           STA       $90     ; C5B1 85 90
           LDA       DLTableHi,Y     ; C5B3 B9 E2 BA
           STA       $91     ; C5B6 85 91
           LDA       PlayerIndex
           BEQ       LC5C1   ; C5BA F0 05
           TXA               ; C5BC 8A
           CLC               ; C5BD 18
           ADC       #$0A    ; C5BE 69 0A
           TAX               ; C5C0 AA
LC5C1      LDA       LC600,X ; C5C1 BD 00 C6
           TAY               ; C5C4 A8
           LDA       $9C     ; C5C5 A5 9C
           AND       #$1F    ; C5C7 29 1F
           STA       ($90),Y ; C5C9 91 90
           LDA       LC614,X ; C5CB BD 14 C6
           TAY               ; C5CE A8
           LDA       $9C     ; C5CF A5 9C
           AND       #$E0    ; C5D1 29 E0
           ORA       #$1F    ; C5D3 09 1F
           STA       ($90),Y ; C5D5 91 90
           RTS               ; C5D7 60

LC5D8      STA       $9C     ; C5D8 85 9C
           LDA       DLTableLo,Y     ; C5DA B9 CB BA
           STA       $90     ; C5DD 85 90
           LDA       DLTableHi,Y     ; C5DF B9 E2 BA
           STA       $91     ; C5E2 85 91
           LDA       PlayerIndex
           BEQ       LC5ED   ; C5E6 F0 05
           TXA               ; C5E8 8A
           CLC               ; C5E9 18
           ADC       #$0A    ; C5EA 69 0A
           TAX               ; C5EC AA
LC5ED      LDA       LC600,X ; C5ED BD 00 C6
           TAY               ; C5F0 A8
           LDA       $9C     ; C5F1 A5 9C
           STA       ($90),Y ; C5F3 91 90
           LDA       LC614,X ; C5F5 BD 14 C6
           TAY               ; C5F8 A8
           LDA       PieceTypeIndex
           ORA       #$1F    ; C5FB 09 1F
           STA       ($90),Y ; C5FD 91 90
           RTS               ; C5FF 60

LC600      .byte   $00     ; |         | $C600
           .byte   $05     ; |      X X| $C601
           .byte   $09     ; |     X  X| $C602
           .byte   $0D     ; |     XX X| $C603
           .byte   $11     ; |   X   X| $C604
           .byte   $15     ; |   X X X| $C605
           .byte   $19     ; |   XX  X| $C606
           .byte   $1D     ; |   XXX X| $C607
           .byte   $21     ; |  X    X| $C608
           .byte   $25     ; |  X  X X| $C609
           .byte   $29     ; |  X X  X| $C60A
           .byte   $2D     ; |  X XX X| $C60B
           .byte   $31     ; |  XX   X| $C60C
           .byte   $35     ; |  XX X X| $C60D
           .byte   $39     ; |  XXX  X| $C60E
           .byte   $3D     ; |  XXXX X| $C60F
           .byte   $41     ; | X      X| $C610
           .byte   $45     ; | X    X X| $C611
           .byte   $49     ; | X   X  X| $C612
           .byte   $4D     ; | X   XX X| $C613
LC614      .byte   $03     ; |       XX| $C614
           .byte   $06     ; |      XX | $C615
           .byte   $0A     ; |     X X | $C616
           .byte   $0E     ; |     XXX | $C617
           .byte   $12     ; |   X  X | $C618
           .byte   $16     ; |   X XX | $C619
           .byte   $1A     ; |   XX X | $C61A
           .byte   $1E     ; |   XXXX | $C61B
           .byte   $22     ; |  X   X | $C61C
           .byte   $26     ; |  X  XX | $C61D
           .byte   $2A     ; |  X X X | $C61E
           .byte   $2E     ; |  X XXX | $C61F
           .byte   $32     ; |  XX  X | $C620
           .byte   $36     ; |  XX XX | $C621
           .byte   $3A     ; |  XXX X | $C622
           .byte   $3E     ; |  XXXXX | $C623
           .byte   $42     ; | X     X | $C624
           .byte   $46     ; | X    XX | $C625
           .byte   $4A     ; | X   X X | $C626
           .byte   $4E     ; | X   XXX | $C627
LC628      .byte   $56     ; | X X XX | $C628
           .byte   $5B     ; | X XX XX| $C629
LC62A      .byte   $59     ; | X XX  X| $C62A
           .byte   $5E     ; | X XXXX | $C62B
LC62C      .byte   $84     ; |X     X  | $C62C
           .byte   $88     ; |X    X   | $C62D
           .byte   $8C     ; |X    XX  | $C62E
           .byte   $90     ; |X  X    | $C62F
           .byte   $94     ; |X  X X  | $C630
           .byte   $98     ; |X  XX   | $C631
           .byte   $9C     ; |X  XXX  | $C632
LC633      LDA       DLTableLo
           STA       $90
           LDA       DLTableHi
           STA       $91
           LDX       PlayerIndex
           LDY       LC628,X ; C63F BC 28 C6
           LDA       #$C0    ; C642 A9 C0
           STA       ($90),Y ; C644 91 90
           LDY       LC62A,X ; C646 BC 2A C6
           LDA       #$7C    ; C649 A9 7C
           STA       ($90),Y ; C64B 91 90
           LDA       LBACC   ; C64D AD CC BA
           STA       $90     ; C650 85 90
           LDA       LBAE3   ; C652 AD E3 BA
           STA       $91     ; C655 85 91
           LDX       PlayerIndex
           LDY       LC628,X ; C659 BC 28 C6
           LDA       $C1,X   ; C65C B5 C1
           LSR               ; C65E 4A
           LSR               ; C65F 4A
           TAX               ; C660 AA
           LDA       LC62C,X ; C661 BD 2C C6
           STA       ($90),Y ; C664 91 90
           LDX       PlayerIndex
           LDY       LC62A,X ; C668 BC 2A C6
           LDA       $C1,X   ; C66B B5 C1
           TAX               ; C66D AA
           LDA       LC530,X ; C66E BD 30 C5
           ORA       #$1C    ; C671 09 1C
           STA       ($90),Y ; C673 91 90
           LDA       LBACD   ; C675 AD CD BA
           STA       $90     ; C678 85 90
           LDA       LBAE4   ; C67A AD E4 BA
           STA       $91     ; C67D 85 91
           LDX       PlayerIndex
           LDY       LC628,X ; C681 BC 28 C6
           LDA       $C1,X   ; C684 B5 C1
           LSR               ; C686 4A
           LSR               ; C687 4A
           TAX               ; C688 AA
           LDA       LC62C,X ; C689 BD 2C C6
           ORA       #$20    ; C68C 09 20
           STA       ($90),Y ; C68E 91 90
           LDX       PlayerIndex
           LDY       LC62A,X ; C692 BC 2A C6
           LDA       $C1,X   ; C695 B5 C1
           TAX               ; C697 AA
           LDA       LC530,X ; C698 BD 30 C5
           ORA       #$1C    ; C69B 09 1C
           STA       ($90),Y ; C69D 91 90
           RTS               ; C69F 60

LC6A0      LDA       DLTableLo
           STA       $90
           LDA       DLTableHi
           STA       $91
           LDX       PlayerIndex
           LDY       LC628,X ; C6AC BC 28 C6
           LDA       #$A0    ; C6AF A9 A0
           STA       ($90),Y ; C6B1 91 90
           LDY       LC62A,X ; C6B3 BC 2A C6
           LDA       #$1C    ; C6B6 A9 1C
           STA       ($90),Y ; C6B8 91 90
           LDA       LBACC   ; C6BA AD CC BA
           STA       $90     ; C6BD 85 90
           LDA       LBAE3   ; C6BF AD E3 BA
           STA       $91     ; C6C2 85 91
           LDX       PlayerIndex
           LDY       LC628,X ; C6C6 BC 28 C6
           LDA       #$E0    ; C6C9 A9 E0
           STA       ($90),Y ; C6CB 91 90
           LDY       LC62A,X ; C6CD BC 2A C6
           LDA       #$1C    ; C6D0 A9 1C
           STA       ($90),Y ; C6D2 91 90
           LDA       LBACD   ; C6D4 AD CD BA
           STA       $90     ; C6D7 85 90
           LDA       LBAE4   ; C6D9 AD E4 BA
           STA       $91     ; C6DC 85 91
           LDX       PlayerIndex
           LDY       LC628,X ; C6E0 BC 28 C6
           LDA       #$80    ; C6E3 A9 80
           STA       ($90),Y ; C6E5 91 90
           LDY       LC62A,X ; C6E7 BC 2A C6
           LDA       #$1C    ; C6EA A9 1C
           STA       ($90),Y ; C6EC 91 90
           RTS               ; C6EE 60

LC6EF
           TAX               ; C6EF AA
           LDA       PlayerIndex
           ASL               ; C6F2 0A
           TAY               ; C6F3 A8
           TXA               ; C6F4 8A
           PHA               ; C6F5 48
           SED               ; C6F6 F8
           CLC               ; C6F7 18
           ADC       $00EB,Y ; C6F8 79 EB 00
           STA       $00EB,Y ; C6FB 99 EB 00
           LDA       $00EA,Y ; C6FE B9 EA 00
           ADC       #$00    ; C701 69 00
           STA       $00EA,Y ; C703 99 EA 00
           CLD               ; C706 D8
           PLA               ; C707 68
           CLC               ; C708 18
           ADC       $00EE,Y ; C709 79 EE 00
           STA       $00EE,Y ; C70C 99 EE 00
           LDA       $00EF,Y ; C70F B9 EF 00
           ADC       #$00    ; C712 69 00
           STA       $00EF,Y ; C714 99 EF 00
           JMP       UpdateLinesClearedDisplay
LC71A
           PHA               ; C71A 48
           STX       PieceX
           JSR       LC806   ; C71D 20 06 C8
           LDX       PieceX
           LDY       #$00    ; C722 A0 00
           LDA       PlayerIndex
           BEQ       LC72A   ; C726 F0 02
           LDY       #$04    ; C728 A0 04
LC72A      PLA
           SED
           CLC
           ADC       ScoreP0+3,Y
           STA       ScoreP0+3,Y
           TXA
           ADC       ScoreP0+2,Y
           STA       ScoreP0+2,Y
           LDA       #$00
           ADC       ScoreP0+1,Y
           STA       ScoreP0+1,Y
           LDA       #$00
           ADC       ScoreP0+0,Y
           STA       ScoreP0+0,Y
           CLD               ; C74A D8
           JSR       LC7D4   ; C74B 20 D4 C7
           LDY       #$00    ; C74E A0 00
           LDA       PlayerIndex
           BEQ       LC756   ; C752 F0 02
           LDY       #$04    ; C754 A0 04
LC756      LDA       ScoreP0+0,Y
           CMP       HiScore+0
           BCC       LC79F   ; C75C 90 41
           BEQ       LC762   ; C75E F0 02
           BCS       LC784   ; C760 B0 22
LC762      LDA       ScoreP0+1,Y
           CMP       HiScore+1
           BCC       LC79F   ; C768 90 35
           BEQ       LC76E   ; C76A F0 02
           BCS       LC784   ; C76C B0 16
LC76E      LDA       ScoreP0+2,Y
           CMP       HiScore+2
           BCC       LC79F   ; C774 90 29
           BEQ       LC77A   ; C776 F0 02
           BCS       LC784   ; C778 B0 0A
LC77A      LDA       ScoreP0+3,Y
           CMP       HiScore+3
           BCC       LC79F   ; C780 90 1D
           BEQ       LC79F   ; C782 F0 1B
LC784      LDA       ScoreP0+0,Y
           STA       HiScore+0
           LDA       ScoreP0+1,Y
           STA       HiScore+1
           LDA       ScoreP0+2,Y
           STA       HiScore+2
           LDA       ScoreP0+3,Y
           STA       HiScore+3
           JMP       LC7CE   ; C79C 4C CE C7
LC79F      RTS               ; C79F 60

UpdateLinesClearedDisplay
           LDY       #$0B
           LDA       PlayerIndex
           ASL
           TAX
           BEQ       LC7AA
           LDY       #$21
LC7AA      LDA       P0TotalLinesClearedBCD,X
           AND       #$0F
           ASL
           CLC
           ADC       #$0E
           STA       LinesClearedP0,Y
           LDA       P0TotalLinesClearedBCD+1,X
           AND       #$F0
           LSR
           LSR
           LSR
           CLC
           ADC       #$0E
           STA       LinesClearedP0+1,Y
           LDA       P0TotalLinesClearedBCD+1,X
           AND       #$0F
           ASL
           CLC
           ADC       #$0E
           STA       LinesClearedP0+2,Y
           RTS

LC7CE      LDY       #$11    ; C7CE A0 11
           LDX       #$09    ; C7D0 A2 09
           BNE       LC7E0   ; C7D2 D0 0C
LC7D4      LDY       #$04    ; C7D4 A0 04
           LDX       #$01    ; C7D6 A2 01
           LDA       PlayerIndex
           BEQ       LC7E0   ; C7DA F0 04
           LDY       #$1A    ; C7DC A0 1A
           LDX       #$05    ; C7DE A2 05
LC7E0      LDA       #$03    ; C7E0 A9 03
           STA       $9C     ; C7E2 85 9C
LC7E4      LDA       $253D,X ; C7E4 BD 3D 25
           AND       #$F0    ; C7E7 29 F0
           LSR               ; C7E9 4A
           LSR               ; C7EA 4A
           LSR               ; C7EB 4A
           CLC               ; C7EC 18
           ADC       #$0E    ; C7ED 69 0E
           STA       $24ED,Y ; C7EF 99 ED 24
           INY               ; C7F2 C8
           LDA       $253D,X ; C7F3 BD 3D 25
           AND       #$0F    ; C7F6 29 0F
           ASL               ; C7F8 0A
           CLC               ; C7F9 18
           ADC       #$0E    ; C7FA 69 0E
           STA       $24ED,Y ; C7FC 99 ED 24
           INY               ; C7FF C8
           INX               ; C800 E8
           DEC       $9C     ; C801 C6 9C
           BNE       LC7E4   ; C803 D0 DF
           RTS               ; C805 60

LC806      PHA               ; C806 48
           LDY       PlayerIndex
           LDA       $00E5,Y ; C809 B9 E5 00
           LDY       #$02    ; C80C A0 02
           LDA       PlayerIndex
           BEQ       LC814   ; C810 F0 02
           LDY       #$07    ; C812 A0 07
LC814      TXA               ; C814 8A
           AND       #$0F    ; C815 29 0F
           ASL               ; C817 0A
           BNE       LC823   ; C818 D0 09
           PLA               ; C81A 68
           BNE       LC81E   ; C81B D0 01
           RTS               ; C81D 60

LC81E      PHA               ; C81E 48
           LDA       #$0A    ; C81F A9 0A
           BNE       LC826   ; C821 D0 03
LC823      CLC               ; C823 18
           ADC       #$0E    ; C824 69 0E
LC826      STA       P0ScoreAdditionDisplay,Y
           PLA               ; C829 68
           TAX               ; C82A AA
           LSR               ; C82B 4A
           LSR               ; C82C 4A
           LSR               ; C82D 4A
           AND       #$1E    ; C82E 29 1E
           CLC               ; C830 18
           ADC       #$0E    ; C831 69 0E
           STA       P0ScoreAdditionDisplay+1,Y
           TXA               ; C836 8A
           AND       #$0F    ; C837 29 0F
           ASL               ; C839 0A
           CLC               ; C83A 18
           ADC       #$0E    ; C83B 69 0E
           STA       P0ScoreAdditionDisplay+2,Y
           RTS               ; C840 60

           PLA               ; C841 68
           RTS               ; C842 60


ClearMemory          ; (TEMP1)=location  X=#_of_pages  A=#_of_bytes
           LDY       #$00
           STA       $9C
           TXA
           BEQ       SkipToClearBytes
           TYA
           LDY       #$00
ClearPageLoop
           STA       (TEMP1),Y
           INY
           BNE       ClearPageLoop
           INC       TEMP2
           DEX
           BNE       ClearPageLoop
SkipToClearBytes
           LDX       $9C
           LDY       #$00
ClearBytesLoop
           STA       (TEMP1),Y
           INY
           DEX
           BNE       ClearBytesLoop
           RTS

           LDY       #$00    ; C862 A0 00
           TYA               ; C864 98
LC865      STA       ($90),Y ; C865 91 90
           INY               ; C867 C8
           DEX               ; C868 CA
           BNE       LC865   ; C869 D0 FA
           RTS               ; C86B 60

           ORG       $F000
           .byte   $00     ; ROM reserved

           ORG       $FF70

NMI
           JMP       (NMIPointer)

IRQ
           RTI

START
           JMP       ConsoleInit


                     ; this section can be removed after we're ready to enhance the game
ORIGINALROM =        1
           ifconst   ORIGINALROM
           .byte   $00     ; |         | $FF77
           .byte   $00     ; |         | $FF78
           .byte   $00     ; |         | $FF79
           .byte   $00     ; |         | $FF7A
           .byte   $00     ; |         | $FF7B
           .byte   $00     ; |         | $FF7C
           .byte   $00     ; |         | $FF7D
           .byte   $00     ; |         | $FF7E
           .byte   $00     ; |         | $FF7F

SIGNATURE
           .byte   $00     ; |         | $FF80
           .byte   $22     ; |  X   X | $FF81
           .byte   $38     ; |  XXX   | $FF82
           .byte   $2F     ; |  X XXXX| $FF83
           .byte   $CD     ; |XX   XX X| $FF84
           .byte   $FC     ; |XXXXXX  | $FF85
           .byte   $73     ; | XXX  XX| $FF86
           .byte   $07     ; |      XXX| $FF87
           .byte   $A3     ; |X X   XX| $FF88
           .byte   $9E     ; |X  XXXX | $FF89
           .byte   $36     ; |  XX XX | $FF8A
           .byte   $61     ; | XX    X| $FF8B
           .byte   $07     ; |      XXX| $FF8C
           .byte   $D6     ; |XX X XX | $FF8D
           .byte   $E0     ; |XXX     | $FF8E
           .byte   $10     ; |   X    | $FF8F
           .byte   $9D     ; |X  XXX X| $FF90
           .byte   $36     ; |  XX XX | $FF91
           .byte   $D1     ; |XX X   X| $FF92
           .byte   $6E     ; | XX XXX | $FF93
           .byte   $46     ; | X    XX | $FF94
           .byte   $56     ; | X X XX | $FF95
           .byte   $13     ; |   X  XX| $FF96
           .byte   $29     ; |  X X  X| $FF97
           .byte   $0B     ; |     X XX| $FF98
           .byte   $5E     ; | X XXXX | $FF99
           .byte   $2E     ; |  X XXX | $FF9A
           .byte   $EF     ; |XXX XXXX| $FF9B
           .byte   $0C     ; |     XX  | $FF9C
           .byte   $0A     ; |     X X | $FF9D
           .byte   $0D     ; |     XX X| $FF9E
           .byte   $E8     ; |XXX X   | $FF9F
           .byte   $B9     ; |X XXX  X| $FFA0
           .byte   $D4     ; |XX X X  | $FFA1
           .byte   $58     ; | X XX   | $FFA2
           .byte   $4B     ; | X   X XX| $FFA3
           .byte   $3C     ; |  XXXX  | $FFA4
           .byte   $2B     ; |  X X XX| $FFA5
           .byte   $F8     ; |XXXXX   | $FFA6
           .byte   $87     ; |X     XXX| $FFA7
           .byte   $6F     ; | XX XXXX| $FFA8
           .byte   $C6     ; |XX    XX | $FFA9
           .byte   $97     ; |X  X XXX| $FFAA
           .byte   $C0     ; |XX       | $FFAB
           .byte   $C3     ; |XX     XX| $FFAC
           .byte   $86     ; |X     XX | $FFAD
           .byte   $33     ; |  XX  XX| $FFAE
           .byte   $80     ; |X        | $FFAF
           .byte   $38     ; |  XXX   | $FFB0
           .byte   $52     ; | X X  X | $FFB1
           .byte   $56     ; | X X XX | $FFB2
           .byte   $C5     ; |XX    X X| $FFB3
           .byte   $B3     ; |X XX  XX| $FFB4
           .byte   $27     ; |  X  XXX| $FFB5
           .byte   $FB     ; |XXXXX XX| $FFB6
           .byte   $DC     ; |XX XXX  | $FFB7
           .byte   $72     ; | XXX  X | $FFB8
           .byte   $9B     ; |X  XX XX| $FFB9
           .byte   $1D     ; |   XXX X| $FFBA
           .byte   $A4     ; |X X  X  | $FFBB
           .byte   $48     ; | X   X   | $FFBC
           .byte   $AA     ; |X X X X | $FFBD
           .byte   $46     ; | X    XX | $FFBE
           .byte   $05     ; |      X X| $FFBF
           .byte   $5D     ; | X XXX X| $FFC0
           .byte   $D2     ; |XX X  X | $FFC1
           .byte   $A6     ; |X X  XX | $FFC2
           .byte   $F4     ; |XXXX X  | $FFC3
           .byte   $4B     ; | X   X XX| $FFC4
           .byte   $D0     ; |XX X    | $FFC5
           .byte   $7B     ; | XXXX XX| $FFC6
           .byte   $C1     ; |XX      X| $FFC7
           .byte   $65     ; | XX  X X| $FFC8
           .byte   $B7     ; |X XX XXX| $FFC9
           .byte   $30     ; |  XX    | $FFCA
           .byte   $9B     ; |X  XX XX| $FFCB
           .byte   $D2     ; |XX X  X | $FFCC
           .byte   $93     ; |X  X  XX| $FFCD
           .byte   $4B     ; | X   X XX| $FFCE
           .byte   $74     ; | XXX X  | $FFCF
           .byte   $64     ; | XX  X  | $FFD0
           .byte   $66     ; | XX  XX | $FFD1
           .byte   $A8     ; |X X X   | $FFD2
           .byte   $C6     ; |XX    XX | $FFD3
           .byte   $3C     ; |  XXXX  | $FFD4
           .byte   $33     ; |  XX  XX| $FFD5
           .byte   $15     ; |   X X X| $FFD6
           .byte   $4C     ; | X   XX  | $FFD7
           .byte   $12     ; |   X  X | $FFD8
           .byte   $62     ; | XX   X | $FFD9
           .byte   $E0     ; |XXX     | $FFDA
           .byte   $70     ; | XXX    | $FFDB
           .byte   $28     ; |  X X   | $FFDC
           .byte   $35     ; |  XX X X| $FFDD
           .byte   $02     ; |       X | $FFDE
           .byte   $B2     ; |X XX  X | $FFDF
           .byte   $C7     ; |XX    XXX| $FFE0
           .byte   $53     ; | X X  XX| $FFE1
           .byte   $FB     ; |XXXXX XX| $FFE2
           .byte   $E0     ; |XXX     | $FFE3
           .byte   $F9     ; |XXXXX  X| $FFE4
           .byte   $18     ; |   XX   | $FFE5
           .byte   $4A     ; | X   X X | $FFE6
           .byte   $CF     ; |XX   XXXX| $FFE7
           .byte   $8E     ; |X    XXX | $FFE8
           .byte   $BD     ; |X XXXX X| $FFE9
           .byte   $A0     ; |X X     | $FFEA
           .byte   $AC     ; |X X XX  | $FFEB
           .byte   $D5     ; |XX X X X| $FFEC
           .byte   $32     ; |  XX  X | $FFED
           .byte   $C9     ; |XX   X  X| $FFEE
           .byte   $D7     ; |XX X XXX| $FFEF
           .byte   $DC     ; |XX XXX  | $FFF0
           .byte   $20     ; |  X     | $FFF1
           .byte   $5D     ; | X XXX X| $FFF2
           .byte   $63     ; | XX   XX| $FFF3
           .byte   $95     ; |X  X X X| $FFF4
           .byte   $67     ; | XX  XXX| $FFF5
           .byte   $9D     ; |X  XXX X| $FFF6
           .byte   $20     ; |  X     | $FFF7

           endif             ; ORIGINALROM

           ORG       $FFF8

           .byte   $FF     ; region=all regions
           .byte   $F7     ; signature area is from F000 on

           .word   NMI
           .word   START
           .word   IRQ
