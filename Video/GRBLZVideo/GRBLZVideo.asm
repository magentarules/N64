; N64 'Bare Metal' 320x240 GRB LZ Video Decode Demo by krom (Peter Lemon):
  include LIB\N64.INC ; Include N64 Definitions
  dcb 19922944,$00 ; Set ROM Size
  org $80000000 ; Entry Point Of Code
  include LIB\N64_HEADER.ASM  ; Include 64 Byte Header & Vector Table
  incbin LIB\N64_BOOTCODE.BIN ; Include 4032 Byte Boot Code

GRB: equ $A0300000 ; GRB Frame DRAM Offset

Start:
  include LIB\N64_GFX.INC  ; Include Graphics Macros
  N64_INIT ; Run N64 Initialisation Routine

  ScreenNTSC 320, 240, BPP16, $A0100000 ; Screen NTSC: 320x240, 16BPP, DRAM Origin $A0100000

LoopVideo:
  lui t8,$A010 ; T8 = Double Buffer Frame Offset = Frame A
  li t9,(520-1) ; T9 = Frame Count - 1
  la a3,$10000000|(LZVideo&$3FFFFFF) ; A0 = Aligned Cart Physical ROM Offset ($10000000..$13FFFFFF 64MB)
  
  LoopFrames:
    lui a0,PI_BASE ; A0 = PI Base Register ($A4600000)
    la t0,(LZVideo&$7FFFFF) ; T0 = Aligned DRAM Physical RAM Offset ($00000000..$007FFFFF 8MB)
    sw t0,PI_DRAM_ADDR(a0) ; Store RAM Offset To PI DRAM Address Register ($A4600000)
    sw a3,PI_CART_ADDR(a0) ; Store ROM Offset To PI Cart Address Register ($A4600004)
    la t0,57035 ; T0 = Length Of DMA Transfer In Bytes - 1
    sw t0,PI_WR_LEN(a0) ; Store DMA Length To PI Write Length Register ($A460000C)

    WaitScanline $0 ; Wait For Scanline To Reach Vertical Start
    WaitScanline $200 ; Wait For Scanline To Reach Vertical Blank

    ; Double Buffer Screen
    lui a0,VI_BASE ; A0 = VI Base Register ($A4400000)
    sw t8,VI_ORIGIN(a0) ; Store Origin To VI Origin Register ($A4400004)
    lui t0,$A010
    beq t0,t8,FrameEnd
    lui t8,$A020 ; T8 = Double Buffer Frame Offset = Frame B
    lui t8,$A010 ; T8 = Double Buffer Frame Offset = Frame A
    FrameEnd:
    la a0,$A0000000|(DoubleBuffer&$3FFFFF)
    sw t8,4(a0)

    la a0,LZVideo ; A0 = Source Address (ROM Start Offset) ($B0000000..$B3FFFFFF)
    lui a1,$A030 ; A1 = Destination Address (DRAM Start Offset)

    lbu t0,3(a0) ; T0 = HI Data Length Byte
    sll t0,8
    lbu t1,2(a0) ; T1 = MID Data Length Byte
    or t0,t1
    sll t0,8
    lbu t1,1(a0) ; T1 = LO Data Length Byte
    or t0,t1 ; T0 = Data Length
    addu t0,a1 ; T0 = Destination End Offset (DRAM End Offset)
    addiu a0,4 ; Add 4 To LZ Offset

  LZLoop:
    lbu t1,0(a0) ; T1 = Flag Data For Next 8 Blocks (0 = Uncompressed Byte, 1 = Compressed Bytes)
    addiu a0,1 ; Add 1 To LZ Offset
    li t2,%10000000 ; T2 = Flag Data Block Type Shifter
    LZBlockLoop:
      beq a1,t0,LZEnd ; IF (Destination Address == Destination End Offset) LZEnd
      nop ; Delay Slot
      beqz t2,LZLoop ; IF (Flag Data Block Type Shifter == 0) LZLoop
      nop ; Delay Slot
      and t3,t1,t2 ; Test Block Type
      srl t2,1 ; Shift T2 To Next Flag Data Block Type
      bnez t3,LZDecode ; IF (BlockType != 0) LZDecode Bytes
      nop ; Delay Slot
      lbu t3,0(a0) ; ELSE Copy Uncompressed Byte
      addiu a0,1 ; Add 1 To LZ Offset
      sb t3,0(a1) ; Store Uncompressed Byte To Destination
      addiu a1,1 ; Add 1 To DRAM Offset
      j LZBlockLoop
      nop ; Delay Slot

      LZDecode:
        lbu t3,0(a0) ; T3 = Number Of Bytes To Copy & Disp MSB's
        addiu a0,1 ; Add 1 To LZ Offset
        lbu t4,0(a0) ; T4 = Disp LSB's
        addiu a0,1 ; Add 1 To LZ Offset
        sll t5,t3,8 ; T5 = Disp MSB's
        or t4,t5
        andi t4,$FFF ; T4 = Disp
        addiu t4,1    ; T4 = Disp + 1
        subu t4,a1,t4 ; T4 = Destination - Disp - 1
        srl t3,4  ; T3 = Number Of Bytes To Copy (Minus 3)
        addiu t3,3 ; T3 = Number Of Bytes To Copy
        LZCopy:
          lbu t5,0(t4) ; T5 = Byte To Copy
          addiu t4,1 ; Add 1 To T4 Offset
          sb t5,0(a1) ; Store Byte To DRAM
          addiu a1,1 ; Add 1 To DRAM Offset
          subiu t3,1 ; Number Of Bytes To Copy -= 1
          bnez t3,LZCopy ; IF (Number Of Bytes To Copy != 0) LZCopy Bytes
          nop ; Delay Slot
          j LZBlockLoop
          nop ; Delay Slot
    LZEnd:

    ; Skip Zero's At End Of LZ77 Compressed File
    andi t0,a0,3  ; Compare LZ77 Offset To A Multiple Of 4
    beqz t0,LZEOF ; Run LZEOF IF Not Multiple Of 4
    nop ; Delay Slot
    addiu a0,1 ; Add 1 To the LZ77 Offset If not a Multiple Of 4 (Delay Slot)

    andi t0,a0,3  ; Compare LZ77 Offset To A Multiple Of 4
    beqz t0,LZEOF ; Run LZEOF IF Not Multiple Of 4
    nop ; Delay Slot
    addiu a0,1 ; Add 1 To the LZ77 Offset If not a Multiple Of 4 (Delay Slot)

    andi t0,a0,3  ; Compare LZ77 Offset To A Multiple Of 4
    beqz t0,LZEOF ; Run LZEOF IF Not Multiple Of 4
    nop ; Delay Slot
    addiu a0,1 ; Add 1 To the LZ77 Offset If not a Multiple Of 4 (Delay Slot)
    LZEOF:

    la a1,LZVideo
    subu a0,a1
    addu a3,a0 ; A3 += LZ End Offset 

  ; Decode GRB Frame Using RDP
  lui a1,DPC_BASE ; A1 = Reality Display Processer Control Interface Base Register ($A4100000)
  la a2,RDPBuffer ; A2 = DPC Command Start Address
  sw a2,DPC_START(a1) ; Store DPC Command Start Address To DP Start Register ($A4100000)
  addi a2,RDPBufferEnd-RDPBuffer ; A2 = DPC Command End Address
  sw a2,DPC_END(a1) ; Store DPC Command End Address To DP End Register ($A4100004)

  bnez t9,LoopFrames
  subiu t9,1 ; Frame Count -- (Delay Slot)
  j LoopVideo
  nop ; Delay Slot

  align 8 ; Align 64-Bit
RDPBuffer:
  Set_Scissor 0<<2,0<<2, 320<<2,240<<2, 0 ; Set Scissor: XH 0.0, YH 0.0, XL 320.0, YL 240.0, Scissor Field Enable Off
  Set_Other_Modes CYCLE_TYPE_FILL, 0 ; Set Other Modes
DoubleBuffer:
  Set_Color_Image SIZE_OF_PIXEL_16B|(320-1), $00100000 ; Set Color Image: SIZE 16B, WIDTH 320, DRAM ADDRESS $00100000
  Set_Fill_Color $00010001 ; Set Fill Color: PACKED COLOR 16B R5G5B5A1 Pixel
  Fill_Rectangle 319<<2,239<<2, 0<<2,0<<2 ; Fill Rectangle: XL 319.0, YL 239.0, XH 0.0, YH 0.0

  Set_Other_Modes EN_TLUT|SAMPLE_TYPE|BI_LERP_0|ALPHA_DITHER_SEL_NO_DITHER|RGB_DITHER_SEL_NO_DITHER, B_M2B_0_2|B_M2A_0_1|FORCE_BLEND|IMAGE_READ_EN ; Set Other Modes
  Set_Combine_Mode $0, $00, 0, 0, $1, $07, $0, $F, 1, 0, 0, 0, 0, 7, 7, 7 ; Set Combine Mode: SubA RGB0, MulRGB0, SubA Alpha0, MulAlpha0, SubA RGB1, MulRGB1, SubB RGB0, SubB RGB1, SubA Alpha1, MulAlpha1, AddRGB0, SubB Alpha0, AddAlpha0, AddRGB1, SubB Alpha1, AddAlpha1

  Set_Texture_Image SIZE_OF_PIXEL_16B, TLUTG ; Set Texture Image: SIZE 16B, DRAM ADDRESS TLUTG
  Set_Tile $100, 0<<24 ; Set Tile: TMEM Address $100, Tile 0
  Load_Tlut 0<<2,0<<2, 0, 31<<2,0<<2 ; Load Tlut: SL 0.0, TL 0.0, Tile 0, SH 31.0, TH 0.0
  Sync_Load ; Sync Load

  Set_Tile IMAGE_DATA_FORMAT_COLOR_INDX|IMAGE_DATA_FORMAT_I|SIZE_OF_PIXEL_8B|(40<<9)|$000, 0<<24 ; Set Tile: COLOR INDEX, SIZE 8B, Tile Line Size 40 (64bit Words), TMEM Address $000, Tile 0

  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), GRB ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 0
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,6<<2, 0, 0<<2,0<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 6.0, Tile 0, XH 0.0, YH 0.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+(320*6)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 1
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,12<<2, 0, 0<<2,6<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 12.0, Tile 0, XH 0.0, YH 6.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*2)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 2
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,18<<2, 0, 0<<2,12<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 18.0, Tile 0, XH 0.0, YH 12.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*3)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 3
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,24<<2, 0, 0<<2,18<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 24.0, Tile 0, XH 0.0, YH 18.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*4)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 4
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,30<<2, 0, 0<<2,24<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 30.0, Tile 0, XH 0.0, YH 24.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*5)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 5
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,36<<2, 0, 0<<2,30<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 36.0, Tile 0, XH 0.0, YH 30.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*6)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 6
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,42<<2, 0, 0<<2,36<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 42.0, Tile 0, XH 0.0, YH 36.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*7)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 7
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,48<<2, 0, 0<<2,42<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 48.0, Tile 0, XH 0.0, YH 42.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*8)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 8
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,54<<2, 0, 0<<2,48<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 54.0, Tile 0, XH 0.0, YH 48.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*9)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 9
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,60<<2, 0, 0<<2,54<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 60.0, Tile 0, XH 0.0, YH 54.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*10)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 10
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,66<<2, 0, 0<<2,60<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 66.0, Tile 0, XH 0.0, YH 60.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*11)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 11
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,72<<2, 0, 0<<2,66<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 72.0, Tile 0, XH 0.0, YH 66.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*12)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 12
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,78<<2, 0, 0<<2,72<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 78.0, Tile 0, XH 0.0, YH 72.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*13)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 13
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,84<<2, 0, 0<<2,78<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 84.0, Tile 0, XH 0.0, YH 78.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*14)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 14
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,90<<2, 0, 0<<2,84<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 90.0, Tile 0, XH 0.0, YH 84.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*15)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 15
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,96<<2, 0, 0<<2,90<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 96.0, Tile 0, XH 0.0, YH 90.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*16)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 16
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,102<<2, 0, 0<<2,96<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 102.0, Tile 0, XH 0.0, YH 96.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*17)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 17
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,108<<2, 0, 0<<2,102<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 108.0, Tile 0, XH 0.0, YH 102.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*18)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 18
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,114<<2, 0, 0<<2,108<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 114.0, Tile 0, XH 0.0, YH 108.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*19)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 19
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,120<<2, 0, 0<<2,114<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 120.0, Tile 0, XH 0.0, YH 114.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*20)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 20
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,126<<2, 0, 0<<2,120<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 126.0, Tile 0, XH 0.0, YH 120.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*21)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 21
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,132<<2, 0, 0<<2,126<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 132.0, Tile 0, XH 0.0, YH 126.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*22)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 22
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,138<<2, 0, 0<<2,132<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 138.0, Tile 0, XH 0.0, YH 132.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*23)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 23
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,144<<2, 0, 0<<2,138<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 144.0, Tile 0, XH 0.0, YH 138.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*24)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 24
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,150<<2, 0, 0<<2,144<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 150.0, Tile 0, XH 0.0, YH 144.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*25)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 25
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,156<<2, 0, 0<<2,150<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 156.0, Tile 0, XH 0.0, YH 150.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*26)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 26
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,162<<2, 0, 0<<2,156<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 162.0, Tile 0, XH 0.0, YH 156.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*27)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 27
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,168<<2, 0, 0<<2,162<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 168.0, Tile 0, XH 0.0, YH 162.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*28)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 28
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,174<<2, 0, 0<<2,168<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 174.0, Tile 0, XH 0.0, YH 168.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*29)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 29
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,180<<2, 0, 0<<2,174<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 180.0, Tile 0, XH 0.0, YH 174.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*30)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 30
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,186<<2, 0, 0<<2,180<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 186.0, Tile 0, XH 0.0, YH 180.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*31)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 31
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,192<<2, 0, 0<<2,186<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 192.0, Tile 0, XH 0.0, YH 186.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*32)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 32
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,198<<2, 0, 0<<2,192<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 198.0, Tile 0, XH 0.0, YH 192.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*33)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 33
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,204<<2, 0, 0<<2,198<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 204.0, Tile 0, XH 0.0, YH 198.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*34)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 34
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,210<<2, 0, 0<<2,204<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 210.0, Tile 0, XH 0.0, YH 204.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*35)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 35
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,216<<2, 0, 0<<2,210<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 216.0, Tile 0, XH 0.0, YH 210.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*36)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 36
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,222<<2, 0, 0<<2,216<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 222.0, Tile 0, XH 0.0, YH 216.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*37)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 37
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,228<<2, 0, 0<<2,222<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 228.0, Tile 0, XH 0.0, YH 222.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*38)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 38
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,234<<2, 0, 0<<2,228<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 234.0, Tile 0, XH 0.0, YH 228.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(320-1), (GRB+((320*6)*39)) ; Set Texture Image: SIZE 8B, WIDTH 320, DRAM ADDRESS G Tile 39
  Load_Tile 0<<2,0<<2, 0, 319<<2,5<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 319.0, TH 5.0
  Texture_Rectangle 320<<2,240<<2, 0, 0<<2,234<<2, 0<<5,0<<5, 1<<10,1<<10 ; Texture Rectangle: XL 320.0, YL 240.0, Tile 0, XH 0.0, YH 234.0, S 0.0, T 0.0, DSDX 1.0, DTDY 1.0


  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_16B, TLUTR ; Set Texture Image: SIZE 16B, DRAM ADDRESS TLUTR
  Set_Tile $100, 0<<24 ; Set Tile: TMEM Address $100, Tile 0
  Load_Tlut 0<<2,0<<2, 0, 31<<2,0<<2 ; Load Tlut: SL 0.0, TL 0.0, Tile 0, SH 31.0, TH 0.0
  Sync_Load ; Sync Load

  Set_Tile IMAGE_DATA_FORMAT_COLOR_INDX|IMAGE_DATA_FORMAT_I|SIZE_OF_PIXEL_8B|(20<<9)|$000, 0<<24 ; Set Tile: COLOR INDEX, SIZE 8B, Tile Line Size 20 (64bit Words), TMEM Address $000, Tile 0

  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 0
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,24<<2, 0, 0<<2,0<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 24.0, Tile 0, XH 0.0, YH 0.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+(160*12)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 1
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,48<<2, 0, 0<<2,24<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 48.0, Tile 0, XH 0.0, YH 24.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*2)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 2
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,72<<2, 0, 0<<2,48<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 72.0, Tile 0, XH 0.0, YH 48.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*3)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 3
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,96<<2, 0, 0<<2,72<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 96.0, Tile 0, XH 0.0, YH 72.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*4)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 4
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,120<<2, 0, 0<<2,96<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 120.0, Tile 0, XH 0.0, YH 96.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*5)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 5
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,144<<2, 0, 0<<2,120<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 144.0, Tile 0, XH 0.0, YH 120.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*6)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 6
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,168<<2, 0, 0<<2,144<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 168.0, Tile 0, XH 0.0, YH 144.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*7)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 7
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,192<<2, 0, 0<<2,168<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 192.0, Tile 0, XH 0.0, YH 168.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*8)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 8
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,216<<2, 0, 0<<2,192<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 216.0, Tile 0, XH 0.0, YH 192.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(160-1), (GRB+((320*6)*40)+((160*12)*9)) ; Set Texture Image: SIZE 8B, WIDTH 160, DRAM ADDRESS R Tile 9
  Load_Tile 0<<2,0<<2, 0, 159<<2,11<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 159.0, TH 11.0
  Texture_Rectangle 320<<2,240<<2, 0, 0<<2,216<<2, 0<<5,0<<5, $200,$200 ; Texture Rectangle: XL 320.0, YL 240.0, Tile 0, XH 0.0, YH 216.0, S 0.0, T 0.0, DSDX 0.5, DTDY 0.5


  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_16B, TLUTB ; Set Texture Image: SIZE 16B, DRAM ADDRESS TLUTB
  Set_Tile $100, 0<<24 ; Set Tile: TMEM Address $100, Tile 0
  Load_Tlut 0<<2,0<<2, 0, 31<<2,0<<2 ; Load Tlut: SL 0.0, TL 0.0, Tile 0, SH 31.0, TH 0.0
  Sync_Load ; Sync Load

  Set_Tile IMAGE_DATA_FORMAT_COLOR_INDX|IMAGE_DATA_FORMAT_I|SIZE_OF_PIXEL_8B|(10<<9)|$000, 0<<24 ; Set Tile: COLOR INDEX, SIZE 8B, Tile Line Size 10 (64bit Words), TMEM Address $000, Tile 0

  Set_Texture_Image SIZE_OF_PIXEL_8B|(80-1), (GRB+((320*6)*40)+((160*12)*10)) ; Set Texture Image: SIZE 8B, WIDTH 80, DRAM ADDRESS B Tile 0
  Load_Tile 0<<2,0<<2, 0, 79<<2,20<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 79.0, TH 20.0
  Texture_Rectangle 320<<2,80<<2, 0, 0<<2,0<<2, 0<<5,0<<5, $100,$100 ; Texture Rectangle: XL 320.0, YL 80.0, Tile 0, XH 0.0, YH 0.0, S 0.0, T 0.0, DSDX 0.25, DTDY 0.25

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(80-1), (GRB+((320*6)*40)+((160*12)*10)+(80*20)) ; Set Texture Image: SIZE 8B, WIDTH 80, DRAM ADDRESS B Tile 1
  Load_Tile 0<<2,0<<2, 0, 79<<2,20<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 79.0, TH 20.0
  Texture_Rectangle 320<<2,160<<2, 0, 0<<2,80<<2, 0<<5,0<<5, $100,$100 ; Texture Rectangle: XL 320.0, YL 160.0, Tile 0, XH 0.0, YH 80.0, S 0.0, T 0.0, DSDX 0.25, DTDY 0.25

  Sync_Tile ; Sync Tile
  Set_Texture_Image SIZE_OF_PIXEL_8B|(80-1), (GRB+((320*6)*40)+((160*12)*10)+((80*20)*2)) ; Set Texture Image: SIZE 8B, WIDTH 80, DRAM ADDRESS B Tile 2
  Load_Tile 0<<2,0<<2, 0, 79<<2,20<<2 ; Load Tile: SL 0.0, TL 0.0, Tile 0, SH 79.0, TH 20.0
  Texture_Rectangle 320<<2,240<<2, 0, 0<<2,160<<2, 0<<5,0<<5, $100,$100 ; Texture Rectangle: XL 320.0, YL 240.0, Tile 0, XH 0.0, YH 160.0, S 0.0, T 0.0, DSDX 0.25, DTDY 0.25

  Sync_Full ; Ensure Entire Scene Is Fully Drawn
RDPBufferEnd:

TLUTG: ; 32x16B = 64 Bytes
  dh $0001
  dh $0041
  dh $0081
  dh $00C1
  dh $0101
  dh $0141
  dh $0181
  dh $01C1
  dh $0201
  dh $0241
  dh $0281
  dh $02C1
  dh $0301
  dh $0341
  dh $0381
  dh $03C1
  dh $0401
  dh $0441
  dh $0481
  dh $04C1
  dh $0501
  dh $0541
  dh $0581
  dh $05C1
  dh $0601
  dh $0641
  dh $0681
  dh $06C1
  dh $0701
  dh $0741
  dh $0781
  dh $07C1

TLUTR: ; 32x16B = 64 Bytes
  dh $0001
  dh $0801
  dh $1001
  dh $1801
  dh $2001
  dh $2801
  dh $3001
  dh $3801
  dh $4001
  dh $4801
  dh $5001
  dh $5801
  dh $6001
  dh $6801
  dh $7001
  dh $7801
  dh $8001
  dh $8801
  dh $9001
  dh $9801
  dh $A001
  dh $A801
  dh $B001
  dh $B801
  dh $C001
  dh $C801
  dh $D001
  dh $D801
  dh $E001
  dh $E801
  dh $F001
  dh $F801

TLUTB: ; 32x16B = 64 Bytes
  dh $0001
  dh $0003
  dh $0005
  dh $0007
  dh $0009
  dh $000B
  dh $000D
  dh $000F
  dh $0011
  dh $0013
  dh $0015
  dh $0017
  dh $0019
  dh $001B
  dh $001D
  dh $001F
  dh $0021
  dh $0023
  dh $0025
  dh $0027
  dh $0029
  dh $002B
  dh $002D
  dh $002F
  dh $0031
  dh $0033
  dh $0035
  dh $0037
  dh $0039
  dh $003B
  dh $003D
  dh $003F

LZVideo:
  incbin Video.lz