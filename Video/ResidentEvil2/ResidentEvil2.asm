// N64 'Bare Metal' 320x240 YUV DCT 8-Bit LZSS DIFF RLE Video Decode Demo by krom (Peter Lemon):
arch n64.cpu
endian msb
output "ResidentEvil2.N64", create
fill 1052672 // Set ROM Size

constant DCTQ($80200000) // DCTQ Frame DRAM Offset
constant RLE($80300000)  // RLE  Frame DRAM Offset
constant YUV($80380000)  // YUV  Frame DRAM Offset

constant FRAMES(4162) // Number Of Frames

origin $00000000
base $80000000 // Entry Point Of Code
include "LIB/N64.INC" // Include N64 Definitions
include "LIB/N64_HEADER.ASM" // Include 64 Byte Header & Vector Table
insert "LIB/N64_BOOTCODE.BIN" // Include 4032 Byte Boot Code

Start:
  include "LIB/N64_GFX.INC" // Include Graphics Macros
  include "LIB/N64_RSP.INC" // Include RSP Macros
  N64_INIT() // Run N64 Initialisation Routine

  ScreenNTSC(320, 240, BPP32|AA_MODE_2, $A0100000) // Screen NTSC: 320x240, 32BPP, Resample Only, DRAM Origin $A0100000

  // Load RSP Data To DMEM
  DMASPRD(RSPData, RSPDataEnd, SP_DMEM) // DMA Data Read DRAM->RSP MEM: Start Address, End Address, Destination RSP MEM Address
  DMASPWait() // Wait For RSP DMA To Finish

  // Load RSP Init Code To IMEM
  DMASPRD(RSPInitCode, RSPInitCodeEnd, SP_IMEM) // DMA Data Read DRAM->RSP MEM: Start Address, End Address, Destination RSP MEM Address
  DMASPWait() // Wait For RSP DMA To Finish

  SetSPPC(RSPStart) // Set RSP Program Counter: Start Address
  StartSP() // Start RSP Execution: RSP Status = Clear Halt, Broke, Interrupt, Single Step, Interrupt On Break

  // Load RSP Code To IMEM
  DMASPRD(RSPCode, RSPCodeEnd, SP_IMEM) // DMA Data Read DRAM->RSP MEM: Start Address, End Address, Destination RSP MEM Address
  DMASPWait() // Wait For RSP DMA To Finish

  lui a0,AI_BASE // A0 = AI Base Register ($A4500000)
  ori t0,r0,1 // T0 = AI Control DMA Enable Bit (1)
  sw t0,AI_CONTROL(a0) // Store AI Control DMA Enable Bit To AI Control Register ($A4500008)
  ori t0,r0,15 // T0 = Sample Bit Rate (Bitrate-1)
  sw t0,AI_BITRATE(a0) // Store Sample Bit Rate To AI Bit Rate Register ($A4500014)
  li t0,(VI_NTSC_CLOCK/22050)-1 // T0 = Sample Frequency: (VI_NTSC_CLOCK(48681812) / FREQ(22050)) - 1
  sw t0,AI_DACRATE(a0) // Store Sample Frequency To AI DAC Rate Register ($A4500010)

LoopVideo:
  // Clear DCTQ Frame
  lui a0,DCTQ>>16
  li t0,(320*240) - 1
  ClearDCTQ:
    sw r0,0(a0)
    addiu a0,4
    bnez t0,ClearDCTQ
    subiu t0,1 // T0-- (Delay Slot)

  la t6,Sample // T6 = Sample DRAM Offset
  la t7,$10000000|(Sample&$FFFFFFF) // T7 = Sample Aligned Cart Physical ROM Offset ($10000000..$1FFFFFFF 256MB)

  ori t9,r0,FRAMES-1 // T9 = Frame Count - 1
  la a3,$B0000000|(LZVideo&$FFFFFFF) // A3 = Aligned Cart ROM Offset ($B0000000..$BFFFFFFF 256MB)

  LoopFrames:
  // Decode LZSS Data
  lui a1,RLE>>16 // A1 = Destination Address (DRAM Start Offset)

  lw t1,0(a3) // T1 = Data Length Word
  srl t0,t1,16 // T0 = T1 >> 16
  andi t0,$00FF // T0 = LO Data Length Byte
  andi t2,t1,$FF00 // T2 = T1 & $FF00
  or t0,t2 // T0 = MID/LO Data Length Bytes
  andi t1,$00FF // T1 &= $00FF
  sll t1,16 // T1 <<= 16
  or t0,t1 // T0 = Data Length
  addu t0,a1 // T0 = Destination End Offset (DRAM End Offset)

  ori s0,r0,3 // S0 = Word Byte Counter
  lw s1,4(a3) // S1 = ROM Word
  addiu a3,8  // Source Address += 8

  LZLoop:
    sll t1,s0,3   // T1 = Word Byte Counter * 8
    srlv t1,s1,t1 // T1 = Flag Data For Next 8 Blocks (0 = Uncompressed Byte, 1 = Compressed Bytes)
    andi t1,$00FF // T1 &= $00FF
    bnez s0,LZSkipA // IF (Word Byte Counter != 0) LZ Skip A
    subiu s0,1  // Word Byte Counter-- (Delay Slot)
    ori s0,r0,3 // S0 = Word Byte Counter
    lw s1,0(a3) // S1 = ROM Word
    addiu a3,4  // Source Address += 4
    LZSkipA:

    ori t2,r0,%10000000 // T2 = Flag Data Block Type Shifter
    LZBlockLoop:
      beq a1,t0,LZEnd // IF (Destination Address == Destination End Offset) LZEnd
      and t4,t1,t2 // Test Block Type (Delay Slot)
      beqz t2,LZLoop // IF (Flag Data Block Type Shifter == 0) LZLoop
      srl t2,1 // Shift T2 To Next Flag Data Block Type (Delay Slot)

      sll t3,s0,3   // T3 = Word Byte Counter * 8
      srlv t3,s1,t3 // T3 = Copy Uncompressed Byte / Number Of Bytes To Copy & Disp MSB's
      andi t3,$00FF // T3 &= $00FF
      bnez s0,LZSkipB // IF (Word Byte Counter != 0) LZ Skip B
      subiu s0,1  // Word Byte Counter-- (Delay Slot)
      ori s0,r0,3 // S0 = Word Byte Counter
      lw s1,0(a3) // S1 = ROM Word
      addiu a3,4  // Source Address += 4
      LZSkipB:

      bnez t4,LZDecode // IF (BlockType != 0) LZDecode Bytes
      nop // Delay Slot
      sb t3,0(a1) // Store Uncompressed Byte To Destination
      j LZBlockLoop
      addiu a1,1 // Add 1 To DRAM Offset (Delay Slot)

      LZDecode:
        sll t4,s0,3   // T4 = Word Byte Counter * 8
        srlv t4,s1,t4 // T4 = Disp LSB's
        andi t4,$00FF // T4 &= $00FF
        bnez s0,LZSkipC // IF (Word Byte Counter != 0) LZ Skip C
        subiu s0,1  // Word Byte Counter-- (Delay Slot)
        ori s0,r0,3 // S0 = Word Byte Counter
        lw s1,0(a3) // S1 = ROM Word
        addiu a3,4  // Source Address += 4
        LZSkipC:

        sll t5,t3,8 // T5 = Disp MSB's
        or t4,t5 // T4 = Disp 16-Bit
        andi t4,$FFF // T4 &= $FFF (Disp 12-Bit)
        not t4 // T4 = -Disp - 1
        addu t4,a1 // T4 = Destination - Disp - 1
        srl t3,4 // T3 = Number Of Bytes To Copy (Minus 3)
        addiu t3,3 // T3 = Number Of Bytes To Copy
        LZCopy:
          lbu t5,0(t4) // T5 = Byte To Copy
          addiu t4,1 // Add 1 To T4 Offset
          sb t5,0(a1) // Store Byte To DRAM
          subiu t3,1 // Number Of Bytes To Copy -= 1
          bnez t3,LZCopy // IF (Number Of Bytes To Copy != 0) LZCopy Bytes
          addiu a1,1 // Add 1 To DRAM Offset (Delay Slot)
          j LZBlockLoop
          nop // Delay Slot
  LZEnd:
    ori t0,r0,3 // T0 = 3
    bne s0,t0,LZEOF // IF (Word Byte Counter != 3) LZEOF
    nop // Delay Slot
    subiu a3,4 // ELSE Source Address -= 4
  LZEOF:


  // Buffer Sound
  lui a0,AI_BASE // A0 = AI Base Register ($A4500000)
  AIBusy:
    lb t0,AI_STATUS(a0) // T0 = AI Status Register Byte ($A450000C)
    andi t0,$40 // AND AI Status With AI Status DMA Busy Bit ($40XXXXXX)
    bnez t0,AIBusy // IF TRUE AI DMA Is Busy
    nop // Delay Slot

  lui a0,PI_BASE // A0 = PI Base Register ($A4600000)
  sw t6,PI_DRAM_ADDR(a0) // Store RAM Offset To PI DRAM Address Register ($A4600000)
  sw t7,PI_CART_ADDR(a0) // Store ROM Offset To PI Cart Address Register ($A4600004)
  ori t0,r0,(Sample.size/FRAMES)-1 // T0 = Length Of DMA Transfer In Bytes - 1
  sw t0,PI_WR_LEN(a0) // Store DMA Length To PI Write Length Register ($A460000C)

  lui a0,AI_BASE // A0 = AI Base Register ($A4500000)
  sw t6,AI_DRAM_ADDR(a0) // Store Sample DRAM Offset To AI DRAM Address Register ($A4500000)
  sw t0,AI_LEN(a0) // Store Length Of Sample Buffer To AI Length Register ($A4500004)

  addiu t7,(Sample.size/FRAMES) // Sample ROM Offset += Sample Length


  // Decode RLE DIFF Data
  la a0,RLE+4  // A0 = Source Address (ROM Start Offset) ($B0000000..$B3FFFFFF)
  lui a1,DCTQ>>16   // A1 = Destination Address (DRAM Start Offset)
  la t0,DCTQ+307200 // T0 = Destination End Offset (DRAM End Offset)

  RLELoop:
    beq a1,t0,RLEEnd // IF (Destination Address == Destination End Offset) RLEEnd
    nop // Delay Slot

    lbu t1,0(a0) // T1 = RLE Flag Data (Bit 0..6 = Expanded Data Length: Uncompressed N-1, Compressed N-3, Bit 7 = Flag: 0 = Uncompressed, 1 = Compressed)
    addiu a0,1 // Add 1 To RLE Offset

    andi t2,t1,%10000000 // T2 = RLE Flag
    andi t1,%01111111 // T1 = Expanded Data Length
    bnez t2,RLEDecode // IF (BlockType != 0) RLE Decode Bytes
    nop // Delay Slot

    RLECopy: // ELSE Copy Uncompressed Bytes
      lb t2,0(a0) // T2 = Difference Signed Byte
      addiu a0,1 // Add 1 To RLE Offset
      lh t3,0(a1) // T3 = Source Data Byte
      add t3,t2 // Add Signed Byte (T2) To Data Byte (T3)
      sh t3,0(a1) // Store Uncompressed Byte To Destination
      addiu a1,2 // Add 2 To DRAM Offset
      bnez t1,RLECopy // IF (Expanded Data Length != 0) RLECopy
      subiu t1,1 // Expanded Data Length -= 1 (Delay Slot)
      j RLELoop
      nop // Delay Slot

    RLEDecode:
      addiu t1,2 // Expanded Data Length += 2
      lb t2,0(a0) // T2 = Difference Signed Byte
      bnez t2,RLEDecodeByte // IF (Difference Signed Byte != 0) RLEDecodeByte
      addiu a0,1 // Add 1 To RLE Offset (Delay Slot)
      addu a1,t1 // Add T1 To DRAM Offset // ELSE Skip RLEDecodeByte
      addu a1,t1 // Add T1 To DRAM Offset
      j RLELoop
      addiu a1,2 // DRAM Offset += 2 (Delay Slot)

      RLEDecodeByte:
        lh t3,0(a1) // T3 = Source Data Byte
        add t3,t2 // Add Signed Byte (T2) To Data Byte (T3)
        sh t3,0(a1) // Store Uncompressed Byte To Destination
        addiu a1,2 // Add 2 To DRAM Offset
        bnez t1,RLEDecodeByte // IF (Expanded Data Length != 0) RLEDecodeByte
        subiu t1,1 // Expanded Data Length -= 1 (Delay Slot)
        j RLELoop
        nop // Delay Slot
    RLEEnd:


  // Flush Data Cache: Index Writeback Invalidate
  la a0,$80000000    // A0 = Cache Start
  la a1,$80002000-16 // A1 = Cache End
  LoopCache:
    cache $0|1,0(a0) // Data Cache: Index Writeback Invalidate
    bne a0,a1,LoopCache
    addiu a0,16 // Address += Data Line Size (Delay Slot)


  // Wait For RDP To Finish
  lui a0,DPC_BASE // A0 = Reality Display Processer Control Interface Base Register ($A4100000)
  RDPLoop:
    lw t0,DPC_STATUS(a0) // T0 = CMD Status ($0410000C)
    andi t0,%101100000 // Wait For RDP DMA Busy Bit 8, Command Busy Bit 6, & RDP Pipeline Busy Bit 5 To Clear
    bnez t0,RDPLoop // IF (T0 != 0) RDPLoop
    nop // Delay Slot


  // Perform Inverse ZigZag Transformation On DCT Blocks Using RDP
  DPC(RDPZigZagBuffer, RDPZigZagBufferEnd) // Run DPC Command Buffer: Start, End

  // Wait For RDP To Inverse ZigZag Some Blocks Before Running RSP
  li a1,((RDPZigZagBuffer+(128*8)) & $FFFFFF) // Wait For 128 RDP Commands
  ZigZagLoop:
    lwu t0,DPC_CURRENT(a0) // T0 = CMD DMA Current ($04100008)
    blt t0,a1,ZigZagLoop // IF (A2 < A1) ZigZagLoop
    nop // Delay Slot


  SetSPPC(RSPStart) // Set RSP Program Counter: Start Address
  StartSP() // Start RSP Execution: RSP Status = Clear Halt, Broke, Interrupt, Single Step, Interrupt On Break


  // Wait For RDP To Finish
  lui a0,DPC_BASE // A0 = Reality Display Processer Control Interface Base Register ($A4100000)
  RDPEndLoop:
    lw t0,DPC_STATUS(a0) // T0 = CMD Status ($0410000C)
    andi t0,%101100000 // Wait For RDP DMA Busy Bit 8, Command Busy Bit 6, & RDP Pipeline Busy Bit 5 To Clear
    bnez t0,RDPEndLoop // IF (T0 != 0) RDPEndLoop
    nop // Delay Slot


  WaitScanline($1E0) // Wait For Scanline To Reach Vertical Blank


  // Draw YUV 8x8 Tiles Using RDP
  DPC(RDPYUVBuffer, RDPYUVBufferEnd) // Run DPC Command Buffer: Start, End


  bnez t9,LoopFrames
  subiu t9,1 // Frame Count -- (Delay Slot)
  j LoopVideo
  nop // Delay Slot


align(8) // Align 64-Bit
RSPInitCode:
arch n64.rsp
base $0000 // Set Base Of RSP Code Object To Zero

RSPInitStart:
// Load Fixed Point Signed Fractions LUT
  lqv v14[e0],FIX_LUT(r0)    // V14 = Look Up Table 0..7  (128-Bit Quad)
  lqv v15[e0],FIX_LUT+16(r0) // V15 = Look Up Table 8..15 (128-Bit Quad)

// Load Integer Chrominance Quantization LUT
  lqv v16[e0],QC(r0)     // V16 = Chrominance Quantization Row 1
  lqv v17[e0],QC+16(r0)  // V17 = Chrominance Quantization Row 2
  lqv v18[e0],QC+32(r0)  // V18 = Chrominance Quantization Row 3
  lqv v19[e0],QC+48(r0)  // V19 = Chrominance Quantization Row 4
  lqv v20[e0],QC+64(r0)  // V20 = Chrominance Quantization Row 5
  lqv v21[e0],QC+80(r0)  // V21 = Chrominance Quantization Row 6
  lqv v22[e0],QC+96(r0)  // V22 = Chrominance Quantization Row 7
  lqv v23[e0],QC+112(r0) // V23 = Chrominance Quantization Row 8

// Load Integer Luminance Quantization LUT
  lqv v24[e0],QL(r0)     // V24 = Luminance Quantization Row 1
  lqv v25[e0],QL+16(r0)  // V25 = Luminance Quantization Row 2
  lqv v26[e0],QL+32(r0)  // V26 = Luminance Quantization Row 3
  lqv v27[e0],QL+48(r0)  // V27 = Luminance Quantization Row 4
  lqv v28[e0],QL+64(r0)  // V28 = Luminance Quantization Row 5
  lqv v29[e0],QL+80(r0)  // V29 = Luminance Quantization Row 6
  lqv v30[e0],QL+96(r0)  // V30 = Luminance Quantization Row 7
  lqv v31[e0],QL+112(r0) // V31 = Luminance Quantization Row 8

  break // Set SP Status Halt, Broke & Check For Interrupt
align(8) // Align 64-Bit
base RSPInitCode+pc() // Set End Of RSP Code Object
RSPInitCodeEnd:


align(8) // Align 64-Bit
RSPCode:
arch n64.rsp
base $0000 // Set Base Of RSP Code Object To Zero

RSPStart:
la a1,YUV // A1 = YUV DCT Input  Aligned DRAM Physical RAM Offset ($00000000..$007FFFFF 8MB)
la a2,YUV // A2 = YUV DCT Output Aligned DRAM Physical RAM Offset ($00000000..$007FFFFF 8MB)

ori s1,r0,((320*240*2) / 2048) - 1 // S1 = Loop DMA Count - 1

LoopDMA:
  lui a0,$0000 // A0 = DCTQ 8x8 Matrix DMEM Address

// DMA 4096 Bytes Of YUV DCT Quantized Blocks (Y Channel 2KB, U Channel 1KB, V Channel 1KB)
  ori t0,r0,4096-1 // T0 = Length Of DMA Transfer In Bytes - 1
  mtc0 r0,c0 // Store Memory Offset ($000) To SP Memory Address Register ($A4040000)
  mtc0 a1,c1 // Store RAM Offset To SP DRAM Address Register ($A4040004)
  mtc0 t0,c2 // Store DMA Length To SP Read Length Register ($A4040008)

  // Wait For RSP To DMA Y Channel Bytes
  and t0,r0 // T0 = 0
  ori s0,r0,2048 // S0 = 2048
  WaitRSPDMA:
    ble t0,s0,WaitRSPDMA
    mfc0 t0,c0 // T0 = SP Memory Address Register ($A4040000) (Delay Slot)


  ori s0,r0,15 // S0 = DMEM Luminance Block Count - 1

LoopLuminanceBlocks: // Y Blocks
// DCT Block Decode (Inverse Quantization)
  // Interleave VU & SU Instruction For Dual Issue Optimization
  lqv v0[e0],$00(a0) // V0 = DCTQ Row 1
  vmudn v0,v24[e0]   // DCTQ *= Luminance Quantization Row 1
  lqv v1[e0],$10(a0) // V1 = DCTQ Row 2
  vmudn v1,v25[e0]   // DCTQ *= Luminance Quantization Row 2
  lqv v2[e0],$20(a0) // V2 = DCTQ Row 3
  vmudn v2,v26[e0]   // DCTQ *= Luminance Quantization Row 3
  lqv v3[e0],$30(a0) // V3 = DCTQ Row 4
  vmudn v3,v27[e0]   // DCTQ *= Luminance Quantization Row 4
  lqv v4[e0],$40(a0) // V4 = DCTQ Row 5
  vmudn v4,v28[e0]   // DCTQ *= Luminance Quantization Row 5
  lqv v5[e0],$50(a0) // V5 = DCTQ Row 6
  vmudn v5,v29[e0]   // DCTQ *= Luminance Quantization Row 6
  lqv v6[e0],$60(a0) // V6 = DCTQ Row 7
  vmudn v6,v30[e0]   // DCTQ *= Luminance Quantization Row 7
  lqv v7[e0],$70(a0) // V7 = DCTQ Row 8
  vmudn v7,v31[e0]   // DCTQ *= Luminance Quantization Row 8

// Decode DCT 8x8 Block Using IDCT
  // Fast IDCT Block Decode
  // Pass 1: Process Columns From Input, Store Into Work Array.

  // Even part: Reverse The Even Part Of The Forward DCT. The Rotator Is SQRT(2)*C(-6).
  // V2 = Z2 = DCT[CTR + 8*2]
  // V6 = Z3 = DCT[CTR + 8*6]
  vadd v8,v2,v6[e0] // Z1 = (Z2 + Z3) * 0.541196100
  vmulf v8,v14[e10] // V8 = Z1

  vmulf v10,v6,v14[e15] // TMP2 = Z1 + (Z3 * -1.847759065)
  vsub v10,v6[e0]
  vadd v9,v10,v8[e0]    // V9 = TMP2

  vmulf v10,v2,v14[e11] // TMP3 = Z1 + (Z2 * 0.765366865)
  vadd v10,v8[e0]       // V10 = TMP3

  // V0 = Z2 = DCT[CTR + 8*0]
  // V4 = Z3 = DCT[CTR + 8*4]
  vadd v8,v0,v4[e0]  // V8 = TMP0 = Z2 + Z3
  vsub v11,v0,v4[e0] // V11 = TMP1 = Z2 - Z3

  vadd v0,v8,v10[e0] // V0 = TMP10 = TMP0 + TMP3
  vadd v6,v11,v9[e0] // V6 = TMP11 = TMP1 + TMP2
  vsub v2,v11,v9[e0] // V2 = TMP12 = TMP1 - TMP2
  vsub v4,v8,v10[e0] // V4 = TMP13 = TMP0 - TMP3

  // Odd Part Per Figure 8; The Matrix Is Unitary And Hence Its Transpose Is Its Inverse.
  // V7 = TMP0 = DCT[CTR + 8*7]
  // V3 = TMP2 = DCT[CTR + 8*3]
  vadd v8,v7,v3[e0] // V8 = Z3 = TMP0 + TMP2

  // V5 = TMP1 = DCT[CTR + 8*5]
  // V1 = TMP3 = DCT[CTR + 8*1]
  vadd v9,v5,v1[e0] // V9 = Z4 = TMP1 + TMP3

  vadd v10,v8,v9[e0] // Z5 = (Z3 + Z4) * 1.175875602 # SQRT(2) * C3
  vmulf v11,v10,v14[e13]
  vadd v10,v11[e0]   // V10 = Z5

  vmulf v11,v8,v15[e8] // Z3 *= -1.961570560 # SQRT(2) * (-C3-C5)
  vsub v8,v11,v8[e0]   // V8 = Z3

  vmulf v9,v14[e9] // Z4 *= -0.390180644 # SQRT(2) * (C5-C3)

  vadd v8,v10[e0] // Z3 += Z5
  vadd v9,v10[e0] // Z4 += Z5

  vadd v10,v7,v1[e0] // V10 = Z1 = TMP0 + TMP3
  vadd v11,v5,v3[e0] // V11 = Z2 = TMP1 + TMP2

  vmulf v10,v14[e12] // Z1 *= -0.899976223 # SQRT(2) * (C7-C3)

  vmulf v12,v11,v15[e10] // Z2 *= -2.562915447 # SQRT(2) * (-C1-C3)
  vsub v12,v11[e0]
  vsub v11,v12,v11[e0]   // V11 = Z2

  vmulf v7,v14[e8] // TMP0 *= 0.298631336 # SQRT(2) * (-C1+C3+C5-C7)

  vmulf v12,v5,v15[e9] // TMP1 *= 2.053119869 # SQRT(2) * (C1+C3-C5+C7)
  vadd v12,v5[e0]
  vadd v5,v12,v5[e0]   // V5 = TMP1

  vmulf v12,v3,v15[e11] // TMP2 *= 3.072711026 # SQRT(2) * ( C1+C3+C5-C7)
  vadd v12,v3[e0]
  vadd v12,v3[e0]
  vadd v3,v12,v3[e0]    // V3 = TMP2

  vmulf v12,v1,v14[e14] // TMP3 *= 1.501321110 # SQRT(2) * ( C1+C3-C5-C7)
  vadd v1,v12,v1[e0]    // V1 = TMP3

  vadd v12,v7,v8[e0] // TMP0 += Z1 + Z3
  vadd v12,v10[e0]   // V12 = TMP0
  vadd v13,v3,v8[e0] // TMP2 += Z2 + Z3
  vadd v13,v11[e0]   // V13 = TMP2
  vadd v8,v1,v9[e0]  // TMP3 += Z1 + Z4
  vadd v8,v10[e0]    // V8 = TMP3
  vadd v10,v5,v9[e0] // TMP1 += Z2 + Z4
  vadd v10,v11[e0]   // V10 = TMP1

  // Final Output Stage: Inputs Are TMP10..TMP13, TMP0..TMP3
  vsub v7,v0,v8[e0]  // DCT[CTR + 8*7] = TMP10 - TMP3
  vadd v0,v0,v8[e0]  // DCT[CTR + 8*0] = TMP10 + TMP3
  vadd v1,v6,v13[e0] // DCT[CTR + 8*1] = TMP11 + TMP2
  vsub v6,v6,v13[e0] // DCT[CTR + 8*6] = TMP11 - TMP2
  vsub v5,v2,v10[e0] // DCT[CTR + 8*5] = TMP12 - TMP1
  vadd v2,v2,v10[e0] // DCT[CTR + 8*2] = TMP12 + TMP1
  vadd v3,v4,v12[e0] // DCT[CTR + 8*3] = TMP13 + TMP0
  vsub v4,v4,v12[e0] // DCT[CTR + 8*4] = TMP13 - TMP0

  // Store Transposed Matrix From Row Ordered Vector Register Block (V0 = Block Base Register)
  stv v0[e0],$00(a0)  // Store 1st Element Diagonals From Vector Register Block
  stv v0[e2],$10(a0)  // Store 2nd Element Diagonals From Vector Register Block
  stv v0[e4],$20(a0)  // Store 3rd Element Diagonals From Vector Register Block
  stv v0[e6],$30(a0)  // Store 4th Element Diagonals From Vector Register Block
  stv v0[e8],$40(a0)  // Store 5th Element Diagonals From Vector Register Block
  stv v0[e10],$50(a0) // Store 6th Element Diagonals From Vector Register Block
  stv v0[e12],$60(a0) // Store 7th Element Diagonals From Vector Register Block
  stv v0[e14],$70(a0) // Store 8th Element Diagonals From Vector Register Block 

  ltv v0[e14],$10(a0) // Load 8th Element Diagonals To Vector Register Block
  ltv v0[e12],$20(a0) // Load 7th Element Diagonals To Vector Register Block
  ltv v0[e10],$30(a0) // Load 6th Element Diagonals To Vector Register Block
  ltv v0[e8],$40(a0)  // Load 5th Element Diagonals To Vector Register Block
  ltv v0[e6],$50(a0)  // Load 4th Element Diagonals To Vector Register Block
  ltv v0[e4],$60(a0)  // Load 3rd Element Diagonals To Vector Register Block
  ltv v0[e2],$70(a0)  // Load 2nd Element Diagonals To Vector Register Block


  // Pass 2: Process Rows From Work Array, Store Into Output Array.

  // Even part: Reverse The Even Part Of The Forward DCT. The Rotator Is SQRT(2)*C(-6).
  // V2 = Z2 = DCT[CTR*8 + 2]
  // V6 = Z3 = DCT[CTR*8 + 6]
  vadd v8,v2,v6[e0] // Z1 = (Z2 + Z3) * 0.541196100
  vmulf v8,v14[e10] // V8 = Z1

  vmulf v10,v6,v14[e15] // TMP2 = Z1 + (Z3 * -1.847759065)
  vsub v10,v6[e0]
  vadd v9,v10,v8[e0]    // V9 = TMP2

  vmulf v10,v2,v14[e11] // TMP3 = Z1 + (Z2 * 0.765366865)
  vadd v10,v8[e0]       // V10 = TMP3

  // V0 = Z2 = DCT[CTR*8 + 0]
  // V4 = Z3 = DCT[CTR*8 + 4]
  vadd v8,v0,v4[e0]  // V8 = TMP0 = Z2 + Z3
  vsub v11,v0,v4[e0] // V11 = TMP1 = Z2 - Z3

  vadd v0,v8,v10[e0] // V0 = TMP10 = TMP0 + TMP3
  vadd v6,v11,v9[e0] // V6 = TMP11 = TMP1 + TMP2
  vsub v2,v11,v9[e0] // V2 = TMP12 = TMP1 - TMP2
  vsub v4,v8,v10[e0] // V4 = TMP13 = TMP0 - TMP3

  // Odd Part Per Figure 8; The Matrix Is Unitary And Hence Its Transpose Is Its Inverse.
  // V7 = TMP0 = DCT[CTR*8 + 7]
  // V3 = TMP2 = DCT[CTR*8 + 3]
  vadd v8,v7,v3[e0] // V8 = Z3 = TMP0 + TMP2

  // V5 = TMP1 = DCT[CTR*8 + 5]
  // V1 = TMP3 = DCT[CTR*8 + 1]
  vadd v9,v5,v1[e0] // V9 = Z4 = TMP1 + TMP3

  vadd v10,v8,v9[e0] // Z5 = (Z3 + Z4) * 1.175875602 # SQRT(2) * C3
  vmulf v11,v10,v14[e13]
  vadd v10,v11[e0]   // V10 = Z5

  vmulf v11,v8,v15[e8] // Z3 *= -1.961570560 # SQRT(2) * (-C3-C5)
  vsub v8,v11,v8[e0]   // V8 = Z3

  vmulf v9,v14[e9] // Z4 *= -0.390180644 # SQRT(2) * (C5-C3)

  vadd v8,v10[e0] // Z3 += Z5
  vadd v9,v10[e0] // Z4 += Z5

  vadd v10,v7,v1[e0] // V10 = Z1 = TMP0 + TMP3
  vadd v11,v5,v3[e0] // V11 = Z2 = TMP1 + TMP2

  vmulf v10,v14[e12] // Z1 *= -0.899976223 # SQRT(2) * (C7-C3)

  vmulf v12,v11,v15[e10] // Z2 *= -2.562915447 # SQRT(2) * (-C1-C3)
  vsub v12,v11[e0]
  vsub v11,v12,v11[e0]   // V11 = Z2

  vmulf v7,v14[e8] // TMP0 *= 0.298631336 # SQRT(2) * (-C1+C3+C5-C7)

  vmulf v12,v5,v15[e9] // TMP1 *= 2.053119869 # SQRT(2) * (C1+C3-C5+C7)
  vadd v12,v5[e0]
  vadd v5,v12,v5[e0]   // V5 = TMP1

  vmulf v12,v3,v15[e11] // TMP2 *= 3.072711026 # SQRT(2) * ( C1+C3+C5-C7)
  vadd v12,v3[e0]
  vadd v12,v3[e0]
  vadd v3,v12,v3[e0]    // V3 = TMP2

  vmulf v12,v1,v14[e14] // TMP3 *= 1.501321110 # SQRT(2) * ( C1+C3-C5-C7)
  vadd v1,v12,v1[e0]    // V1 = TMP3

  vadd v12,v7,v8[e0] // TMP0 += Z1 + Z3
  vadd v12,v10[e0]   // V12 = TMP0
  vadd v13,v3,v8[e0] // TMP2 += Z2 + Z3
  vadd v13,v11[e0]   // V13 = TMP2
  vadd v8,v1,v9[e0]  // TMP3 += Z1 + Z4
  vadd v8,v10[e0]    // V8 = TMP3
  vadd v10,v5,v9[e0] // TMP1 += Z2 + Z4
  vadd v10,v11[e0]   // V10 = TMP1

  // Final Output Stage: Inputs Are TMP10..TMP13, TMP0..TMP3
  vsub v7,v0,v8[e0]  // DCT[CTR + 8*7] = (TMP10 - TMP3) * 0.125
  vmulu v7,v15[e12]  // Produce Unsigned Result
  vadd v0,v0,v8[e0]  // DCT[CTR + 8*0] = (TMP10 + TMP3) * 0.125
  vmulu v0,v15[e12]  // Produce Unsigned Result
  vadd v1,v6,v13[e0] // DCT[CTR + 8*1] = (TMP11 + TMP2) * 0.125
  vmulu v1,v15[e12]  // Produce Unsigned Result
  vsub v6,v6,v13[e0] // DCT[CTR + 8*6] = (TMP11 - TMP2) * 0.125
  vmulu v6,v15[e12]  // Produce Unsigned Result
  vsub v5,v2,v10[e0] // DCT[CTR + 8*5] = (TMP12 - TMP1) * 0.125
  vmulu v5,v15[e12]  // Produce Unsigned Result
  vadd v2,v2,v10[e0] // DCT[CTR + 8*2] = (TMP12 + TMP1) * 0.125
  vmulu v2,v15[e12]  // Produce Unsigned Result
  vadd v3,v4,v12[e0] // DCT[CTR + 8*3] = (TMP13 + TMP0) * 0.125
  vmulu v3,v15[e12]  // Produce Unsigned Result
  vsub v4,v4,v12[e0] // DCT[CTR + 8*4] = (TMP13 - TMP0) * 0.125
  vmulu v4,v15[e12]  // Produce Unsigned Result

  // Store Transposed Matrix From Row Ordered Vector Register Block (V0 = Block Base Register)
  sqv v0[e0],$00(a0) // Store 1st Row From Transposed Matrix Vector Register Block
  sqv v1[e0],$10(a0) // Store 2nd Row From Transposed Matrix Vector Register Block
  sqv v2[e0],$20(a0) // Store 3rd Row From Transposed Matrix Vector Register Block
  sqv v3[e0],$30(a0) // Store 4th Row From Transposed Matrix Vector Register Block
  sqv v4[e0],$40(a0) // Store 5th Row From Transposed Matrix Vector Register Block
  sqv v5[e0],$50(a0) // Store 6th Row From Transposed Matrix Vector Register Block
  sqv v6[e0],$60(a0) // Store 7th Row From Transposed Matrix Vector Register Block
  sqv v7[e0],$70(a0) // Store 8th Row From Transposed Matrix Vector Register Block

  addiu a0,128 // A0 += Block Size
  bnez s0,LoopLuminanceBlocks // IF (DMEM Luminance Block Count != 0) Loop Luminance Blocks
  subiu s0,1 // DMEM Luminance Block Count-- (Delay Slot)


  ori s0,r0,15 // S0 = DMEM Chrominance Block Count - 1

LoopChrominanceBlocks: // U & V Blocks
// DCT Block Decode (Inverse Quantization)
  // Interleave VU & SU Instruction For Dual Issue Optimization
  lqv v0[e0],$00(a0) // V0 = DCTQ Row 1
  vmudn v0,v16[e0]   // DCTQ *= Chrominance Quantization Row 1
  lqv v1[e0],$10(a0) // V1 = DCTQ Row 2
  vmudn v1,v17[e0]   // DCTQ *= Chrominance Quantization Row 2
  lqv v2[e0],$20(a0) // V2 = DCTQ Row 3
  vmudn v2,v18[e0]   // DCTQ *= Chrominance Quantization Row 3
  lqv v3[e0],$30(a0) // V3 = DCTQ Row 4
  vmudn v3,v19[e0]   // DCTQ *= Chrominance Quantization Row 4
  lqv v4[e0],$40(a0) // V4 = DCTQ Row 5
  vmudn v4,v20[e0]   // DCTQ *= Chrominance Quantization Row 5
  lqv v5[e0],$50(a0) // V5 = DCTQ Row 6
  vmudn v5,v21[e0]   // DCTQ *= Chrominance Quantization Row 6
  lqv v6[e0],$60(a0) // V6 = DCTQ Row 7
  vmudn v6,v22[e0]   // DCTQ *= Chrominance Quantization Row 7
  lqv v7[e0],$70(a0) // V7 = DCTQ Row 8
  vmudn v7,v23[e0]   // DCTQ *= Chrominance Quantization Row 8

// Decode DCT 8x8 Block Using IDCT
  // Fast IDCT Block Decode
  // Pass 1: Process Columns From Input, Store Into Work Array.

  // Even part: Reverse The Even Part Of The Forward DCT. The Rotator Is SQRT(2)*C(-6).
  // V2 = Z2 = DCT[CTR + 8*2]
  // V6 = Z3 = DCT[CTR + 8*6]
  vadd v8,v2,v6[e0] // Z1 = (Z2 + Z3) * 0.541196100
  vmulf v8,v14[e10] // V8 = Z1

  vmulf v10,v6,v14[e15] // TMP2 = Z1 + (Z3 * -1.847759065)
  vsub v10,v6[e0]
  vadd v9,v10,v8[e0]    // V9 = TMP2

  vmulf v10,v2,v14[e11] // TMP3 = Z1 + (Z2 * 0.765366865)
  vadd v10,v8[e0]       // V10 = TMP3

  // V0 = Z2 = DCT[CTR + 8*0]
  // V4 = Z3 = DCT[CTR + 8*4]
  vadd v8,v0,v4[e0]  // V8 = TMP0 = Z2 + Z3
  vsub v11,v0,v4[e0] // V11 = TMP1 = Z2 - Z3

  vadd v0,v8,v10[e0] // V0 = TMP10 = TMP0 + TMP3
  vadd v6,v11,v9[e0] // V6 = TMP11 = TMP1 + TMP2
  vsub v2,v11,v9[e0] // V2 = TMP12 = TMP1 - TMP2
  vsub v4,v8,v10[e0] // V4 = TMP13 = TMP0 - TMP3

  // Odd Part Per Figure 8; The Matrix Is Unitary And Hence Its Transpose Is Its Inverse.
  // V7 = TMP0 = DCT[CTR + 8*7]
  // V3 = TMP2 = DCT[CTR + 8*3]
  vadd v8,v7,v3[e0] // V8 = Z3 = TMP0 + TMP2

  // V5 = TMP1 = DCT[CTR + 8*5]
  // V1 = TMP3 = DCT[CTR + 8*1]
  vadd v9,v5,v1[e0] // V9 = Z4 = TMP1 + TMP3

  vadd v10,v8,v9[e0] // Z5 = (Z3 + Z4) * 1.175875602 # SQRT(2) * C3
  vmulf v11,v10,v14[e13]
  vadd v10,v11[e0]   // V10 = Z5

  vmulf v11,v8,v15[e8] // Z3 *= -1.961570560 # SQRT(2) * (-C3-C5)
  vsub v8,v11,v8[e0]   // V8 = Z3

  vmulf v9,v14[e9] // Z4 *= -0.390180644 # SQRT(2) * (C5-C3)

  vadd v8,v10[e0] // Z3 += Z5
  vadd v9,v10[e0] // Z4 += Z5

  vadd v10,v7,v1[e0] // V10 = Z1 = TMP0 + TMP3
  vadd v11,v5,v3[e0] // V11 = Z2 = TMP1 + TMP2

  vmulf v10,v14[e12] // Z1 *= -0.899976223 # SQRT(2) * (C7-C3)

  vmulf v12,v11,v15[e10] // Z2 *= -2.562915447 # SQRT(2) * (-C1-C3)
  vsub v12,v11[e0]
  vsub v11,v12,v11[e0]   // V11 = Z2

  vmulf v7,v14[e8] // TMP0 *= 0.298631336 # SQRT(2) * (-C1+C3+C5-C7)

  vmulf v12,v5,v15[e9] // TMP1 *= 2.053119869 # SQRT(2) * (C1+C3-C5+C7)
  vadd v12,v5[e0]
  vadd v5,v12,v5[e0]   // V5 = TMP1

  vmulf v12,v3,v15[e11] // TMP2 *= 3.072711026 # SQRT(2) * ( C1+C3+C5-C7)
  vadd v12,v3[e0]
  vadd v12,v3[e0]
  vadd v3,v12,v3[e0]    // V3 = TMP2

  vmulf v12,v1,v14[e14] // TMP3 *= 1.501321110 # SQRT(2) * ( C1+C3-C5-C7)
  vadd v1,v12,v1[e0]    // V1 = TMP3

  vadd v12,v7,v8[e0] // TMP0 += Z1 + Z3
  vadd v12,v10[e0]   // V12 = TMP0
  vadd v13,v3,v8[e0] // TMP2 += Z2 + Z3
  vadd v13,v11[e0]   // V13 = TMP2
  vadd v8,v1,v9[e0]  // TMP3 += Z1 + Z4
  vadd v8,v10[e0]    // V8 = TMP3
  vadd v10,v5,v9[e0] // TMP1 += Z2 + Z4
  vadd v10,v11[e0]   // V10 = TMP1

  // Final Output Stage: Inputs Are TMP10..TMP13, TMP0..TMP3
  vsub v7,v0,v8[e0]  // DCT[CTR + 8*7] = TMP10 - TMP3
  vadd v0,v0,v8[e0]  // DCT[CTR + 8*0] = TMP10 + TMP3
  vadd v1,v6,v13[e0] // DCT[CTR + 8*1] = TMP11 + TMP2
  vsub v6,v6,v13[e0] // DCT[CTR + 8*6] = TMP11 - TMP2
  vsub v5,v2,v10[e0] // DCT[CTR + 8*5] = TMP12 - TMP1
  vadd v2,v2,v10[e0] // DCT[CTR + 8*2] = TMP12 + TMP1
  vadd v3,v4,v12[e0] // DCT[CTR + 8*3] = TMP13 + TMP0
  vsub v4,v4,v12[e0] // DCT[CTR + 8*4] = TMP13 - TMP0

  // Store Transposed Matrix From Row Ordered Vector Register Block (V0 = Block Base Register)
  stv v0[e0],$00(a0)  // Store 1st Element Diagonals From Vector Register Block
  stv v0[e2],$10(a0)  // Store 2nd Element Diagonals From Vector Register Block
  stv v0[e4],$20(a0)  // Store 3rd Element Diagonals From Vector Register Block
  stv v0[e6],$30(a0)  // Store 4th Element Diagonals From Vector Register Block
  stv v0[e8],$40(a0)  // Store 5th Element Diagonals From Vector Register Block
  stv v0[e10],$50(a0) // Store 6th Element Diagonals From Vector Register Block
  stv v0[e12],$60(a0) // Store 7th Element Diagonals From Vector Register Block
  stv v0[e14],$70(a0) // Store 8th Element Diagonals From Vector Register Block 

  ltv v0[e14],$10(a0) // Load 8th Element Diagonals To Vector Register Block
  ltv v0[e12],$20(a0) // Load 7th Element Diagonals To Vector Register Block
  ltv v0[e10],$30(a0) // Load 6th Element Diagonals To Vector Register Block
  ltv v0[e8],$40(a0)  // Load 5th Element Diagonals To Vector Register Block
  ltv v0[e6],$50(a0)  // Load 4th Element Diagonals To Vector Register Block
  ltv v0[e4],$60(a0)  // Load 3rd Element Diagonals To Vector Register Block
  ltv v0[e2],$70(a0)  // Load 2nd Element Diagonals To Vector Register Block


  // Pass 2: Process Rows From Work Array, Store Into Output Array.

  // Even part: Reverse The Even Part Of The Forward DCT. The Rotator Is SQRT(2)*C(-6).
  // V2 = Z2 = DCT[CTR*8 + 2]
  // V6 = Z3 = DCT[CTR*8 + 6]
  vadd v8,v2,v6[e0] // Z1 = (Z2 + Z3) * 0.541196100
  vmulf v8,v14[e10] // V8 = Z1

  vmulf v10,v6,v14[e15] // TMP2 = Z1 + (Z3 * -1.847759065)
  vsub v10,v6[e0]
  vadd v9,v10,v8[e0]    // V9 = TMP2

  vmulf v10,v2,v14[e11] // TMP3 = Z1 + (Z2 * 0.765366865)
  vadd v10,v8[e0]       // V10 = TMP3

  // V0 = Z2 = DCT[CTR*8 + 0]
  // V4 = Z3 = DCT[CTR*8 + 4]
  vadd v8,v0,v4[e0]  // V8 = TMP0 = Z2 + Z3
  vsub v11,v0,v4[e0] // V11 = TMP1 = Z2 - Z3

  vadd v0,v8,v10[e0] // V0 = TMP10 = TMP0 + TMP3
  vadd v6,v11,v9[e0] // V6 = TMP11 = TMP1 + TMP2
  vsub v2,v11,v9[e0] // V2 = TMP12 = TMP1 - TMP2
  vsub v4,v8,v10[e0] // V4 = TMP13 = TMP0 - TMP3

  // Odd Part Per Figure 8; The Matrix Is Unitary And Hence Its Transpose Is Its Inverse.
  // V7 = TMP0 = DCT[CTR*8 + 7]
  // V3 = TMP2 = DCT[CTR*8 + 3]
  vadd v8,v7,v3[e0] // V8 = Z3 = TMP0 + TMP2

  // V5 = TMP1 = DCT[CTR*8 + 5]
  // V1 = TMP3 = DCT[CTR*8 + 1]
  vadd v9,v5,v1[e0] // V9 = Z4 = TMP1 + TMP3

  vadd v10,v8,v9[e0] // Z5 = (Z3 + Z4) * 1.175875602 # SQRT(2) * C3
  vmulf v11,v10,v14[e13]
  vadd v10,v11[e0]   // V10 = Z5

  vmulf v11,v8,v15[e8] // Z3 *= -1.961570560 # SQRT(2) * (-C3-C5)
  vsub v8,v11,v8[e0]   // V8 = Z3

  vmulf v9,v14[e9] // Z4 *= -0.390180644 # SQRT(2) * (C5-C3)

  vadd v8,v10[e0] // Z3 += Z5
  vadd v9,v10[e0] // Z4 += Z5

  vadd v10,v7,v1[e0] // V10 = Z1 = TMP0 + TMP3
  vadd v11,v5,v3[e0] // V11 = Z2 = TMP1 + TMP2

  vmulf v10,v14[e12] // Z1 *= -0.899976223 # SQRT(2) * (C7-C3)

  vmulf v12,v11,v15[e10] // Z2 *= -2.562915447 # SQRT(2) * (-C1-C3)
  vsub v12,v11[e0]
  vsub v11,v12,v11[e0]   // V11 = Z2

  vmulf v7,v14[e8] // TMP0 *= 0.298631336 # SQRT(2) * (-C1+C3+C5-C7)

  vmulf v12,v5,v15[e9] // TMP1 *= 2.053119869 # SQRT(2) * (C1+C3-C5+C7)
  vadd v12,v5[e0]
  vadd v5,v12,v5[e0]   // V5 = TMP1

  vmulf v12,v3,v15[e11] // TMP2 *= 3.072711026 # SQRT(2) * ( C1+C3+C5-C7)
  vadd v12,v3[e0]
  vadd v12,v3[e0]
  vadd v3,v12,v3[e0]    // V3 = TMP2

  vmulf v12,v1,v14[e14] // TMP3 *= 1.501321110 # SQRT(2) * ( C1+C3-C5-C7)
  vadd v1,v12,v1[e0]    // V1 = TMP3

  vadd v12,v7,v8[e0] // TMP0 += Z1 + Z3
  vadd v12,v10[e0]   // V12 = TMP0
  vadd v13,v3,v8[e0] // TMP2 += Z2 + Z3
  vadd v13,v11[e0]   // V13 = TMP2
  vadd v8,v1,v9[e0]  // TMP3 += Z1 + Z4
  vadd v8,v10[e0]    // V8 = TMP3
  vadd v10,v5,v9[e0] // TMP1 += Z2 + Z4
  vadd v10,v11[e0]   // V10 = TMP1

  // Final Output Stage: Inputs Are TMP10..TMP13, TMP0..TMP3 (Create Packed Unsigned Bytes For UV Packing)
  vsub v7,v0,v8[e0]  // DCT[CTR + 8*7] = (TMP10 - TMP3) * 0.125 * 128 (* 16)
  vmudn v7,v15[e13]  // Produce Unsigned Result
  vadd v0,v0,v8[e0]  // DCT[CTR + 8*0] = (TMP10 + TMP3) * 0.125 * 128 (* 16)
  vmudn v0,v15[e13]  // Produce Unsigned Result
  vadd v1,v6,v13[e0] // DCT[CTR + 8*1] = (TMP11 + TMP2) * 0.125 * 128 (* 16)
  vmudn v1,v15[e13]  // Produce Unsigned Result
  vsub v6,v6,v13[e0] // DCT[CTR + 8*6] = (TMP11 - TMP2) * 0.125 * 128 (* 16)
  vmudn v6,v15[e13]  // Produce Unsigned Result
  vsub v5,v2,v10[e0] // DCT[CTR + 8*5] = (TMP12 - TMP1) * 0.125 * 128 (* 16)
  vmudn v5,v15[e13]  // Produce Unsigned Result
  vadd v2,v2,v10[e0] // DCT[CTR + 8*2] = (TMP12 + TMP1) * 0.125 * 128 (* 16)
  vmudn v2,v15[e13]  // Produce Unsigned Result
  vadd v3,v4,v12[e0] // DCT[CTR + 8*3] = (TMP13 + TMP0) * 0.125 * 128 (* 16)
  vmudn v3,v15[e13]  // Produce Unsigned Result
  vsub v4,v4,v12[e0] // DCT[CTR + 8*4] = (TMP13 - TMP0) * 0.125 * 128 (* 16)
  vmudn v4,v15[e13]  // Produce Unsigned Result

  // Store Transposed Matrix From Row Ordered Vector Register Block (V0 = Block Base Register)
  suv v0[e0],$00(a0) // Store 1st Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v1[e0],$10(a0) // Store 2nd Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v2[e0],$20(a0) // Store 3rd Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v3[e0],$30(a0) // Store 4th Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v4[e0],$40(a0) // Store 5th Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v5[e0],$50(a0) // Store 6th Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v6[e0],$60(a0) // Store 7th Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)
  suv v7[e0],$70(a0) // Store 8th Row From Transposed Matrix Vector Register Block (Packed Unsigned Bytes)

  addiu a0,128 // A0 += Block Size
  bnez s0,LoopChrominanceBlocks // IF (DMEM Chrominance Block Count != 0) Loop Chrominance Blocks
  subiu s0,1 // DMEM Chrominance Block Count-- (Delay Slot)


  // Pack N64 RDP Native UYVY Bytes To Y Region (2048 Bytes: 16 * 8x8 YUV Tiles)
  ori t0,r0,0    // T0 = Y Channel SP Memory Offset
  ori t1,r0,2048 // T1 = U Channel SP Memory Offset
  ori t2,r0,3072 // T2 = V Channel SP Memory Offset
  ori s0,r0,2048 // S0 = Y Channel End SP Memory Offset
  LoopY:
    lpv v8[e0],$00(t1) // Load U Row 1 Values To Upper Element Bytes Of Vector Register
    lqv v0[e0],$00(t0) // Load Y Row 1 Values To Vector Register Block
    vor v0,v8[e0]      // Y Row 1 |= U Row 1
    lpv v8[e0],$00(t2) // Load V Row 1 Values To Upper Element Bytes Of Vector Register
    lqv v1[e0],$10(t0) // Load Y Row 2 Values To Vector Register Block
    vor v1,v8[e0]      // Y Row 2 |= V Row 1
    lpv v8[e0],$10(t1) // Load U Row 2 Values To Upper Element Bytes Of Vector Register
    lqv v2[e0],$20(t0) // Load Y Row 3 Values To Vector Register Block
    vor v2,v8[e0]      // Y Row 3 |= U Row 2
    lpv v8[e0],$10(t2) // Load V Row 2 Values To Upper Element Bytes Of Vector Register
    lqv v3[e0],$30(t0) // Load Y Row 4 Values To Vector Register Block
    vor v3,v8[e0]      // Y Row 4 |= V Row 2
    lpv v8[e0],$20(t1) // Load U Row 3 Values To Upper Element Bytes Of Vector Register
    lqv v4[e0],$40(t0) // Load Y Row 5 Values To Vector Register Block
    vor v4,v8[e0]      // Y Row 5 |= U Row 3
    lpv v8[e0],$20(t2) // Load V Row 3 Values To Upper Element Bytes Of Vector Register
    lqv v5[e0],$50(t0) // Load Y Row 6 Values To Vector Register Block
    vor v5,v8[e0]      // Y Row 6 |= V Row 3
    lpv v8[e0],$30(t1) // Load U Row 4 Values To Upper Element Bytes Of Vector Register
    lqv v6[e0],$60(t0) // Load Y Row 7 Values To Vector Register Block
    vor v6,v8[e0]      // Y Row 7 |= U Row 4
    lpv v8[e0],$30(t2) // Load V Row 4 Values To Upper Element Bytes Of Vector Register
    lqv v7[e0],$70(t0) // Load Y Row 8 Values To Vector Register Block
    vor v7,v8[e0]      // Y Row 8 |= V Row 4

    // Store Transposed Matrix From Row Ordered Vector Register Block (V0 = Block Base Register)
    stv v0[e0],$00(t0)  // Store 1st Element Diagonals From Vector Register Block
    stv v0[e2],$10(t0)  // Store 2nd Element Diagonals From Vector Register Block
    stv v0[e4],$20(t0)  // Store 3rd Element Diagonals From Vector Register Block
    stv v0[e6],$30(t0)  // Store 4th Element Diagonals From Vector Register Block
    stv v0[e8],$40(t0)  // Store 5th Element Diagonals From Vector Register Block
    stv v0[e10],$50(t0) // Store 6th Element Diagonals From Vector Register Block
    stv v0[e12],$60(t0) // Store 7th Element Diagonals From Vector Register Block
    stv v0[e14],$70(t0) // Store 8th Element Diagonals From Vector Register Block

    ltv v0[e14],$10(t0) // Load 8th Element Diagonals To Vector Register Block
    ltv v0[e12],$20(t0) // Load 7th Element Diagonals To Vector Register Block
    ltv v0[e10],$30(t0) // Load 6th Element Diagonals To Vector Register Block
    ltv v0[e8],$40(t0)  // Load 5th Element Diagonals To Vector Register Block
    ltv v0[e6],$50(t0)  // Load 4th Element Diagonals To Vector Register Block
    ltv v0[e4],$60(t0)  // Load 3rd Element Diagonals To Vector Register Block
    ltv v0[e2],$70(t0)  // Load 2nd Element Diagonals To Vector Register Block

    sqv v0[e0],$00(t0) // Store 1st Row From Transposed Matrix Vector Register Block
    sqv v1[e0],$10(t0) // Store 2nd Row From Transposed Matrix Vector Register Block
    sqv v2[e0],$20(t0) // Store 3rd Row From Transposed Matrix Vector Register Block
    sqv v3[e0],$30(t0) // Store 4th Row From Transposed Matrix Vector Register Block
    sqv v4[e0],$40(t0) // Store 5th Row From Transposed Matrix Vector Register Block
    sqv v5[e0],$50(t0) // Store 6th Row From Transposed Matrix Vector Register Block
    sqv v6[e0],$60(t0) // Store 7th Row From Transposed Matrix Vector Register Block
    sqv v7[e0],$70(t0) // Store 8th Row From Transposed Matrix Vector Register Block

    addiu t0,128 // Y Channel SP Memory Offset += 128
    addiu t1,64  // U Channel SP Memory Offset += 64
    bne t0,s0,LoopY
    addiu t2,64  // V Channel SP Memory Offset += 64 (Delay Slot)


  // DMA 2048 Bytes of YUV Channel Data To RDRAM
  ori t0,r0,2048-1 // T0 = Length Of DMA Transfer In Bytes - 1
  mtc0 r0,c0 // Store Memory Offset To SP Memory Address Register ($A4040000)
  mtc0 a2,c1 // Store RAM Offset To SP DRAM Address Register ($A4040004)
  mtc0 t0,c3 // Store DMA Length To SP Write Length Register ($A404000C)

  addiu a1,4096 // YUV DCT Input  Offset += 4096
  addiu a2,2048 // YUV DCT Output Offset += 2048

  bnez s1,LoopDMA // IF (Loop DMA Count != 0) Loop DMA
  subiu s1,1 // Loop DMA Count-- (Delay Slot)

  Finished:
  break // Set SP Status Halt, Broke & Check For Interrupt
align(8) // Align 64-Bit
base RSPCode+pc() // Set End Of RSP Code Object
RSPCodeEnd:

align(8) // Align 64-Bit
RSPData:
base $0000 // Set Base Of RSP Data Object To Zero

FIX_LUT: // Signed Fractions (S1.15) (Float * 32768)
  dh 9786   //  0.298631336 FIX( 0.298631336) Vector Register A[0]
  dh -12785 // -0.390180644 FIX(-0.390180644) Vector Register A[1]
  dh 17734  //  0.541196100 FIX( 0.541196100) Vector Register A[2]
  dh 25080  //  0.765366865 FIX( 0.765366865) Vector Register A[3]
  dh -29490 // -0.899976223 FIX(-0.899976223) Vector Register A[4]
  dh 5763   //  0.175875602 FIX( 1.175875602) Vector Register A[5]
  dh 16427  //  0.501321110 FIX( 1.501321110) Vector Register A[6]
  dh -27779 // -0.847759065 FIX(-1.847759065) Vector Register A[7]

  dh -31509 // -0.961570560 FIX(-1.961570560) Vector Register B[0]
  dh 1741   //  0.053119869 FIX( 2.053119869) Vector Register B[1]
  dh -18446 // -0.562915447 FIX(-2.562915447) Vector Register B[2]
  dh 2383   //  0.072711026 FIX( 3.072711026) Vector Register B[3]
  dh 4096   //  0.125       FIX( 0.125)       Vector Register B[4]
  dh $0010  //  0.125 * 128 FIX(16.0)         Vector Register B[5]
  dh 0      //  Zero Padding                  Vector Register B[6]
  dh 0      //  Zero Padding                  Vector Register B[7]

QC: // JPEG Standard Chrominance Quantization 8x8 Result Matrix (Quality = 50)
  dh 17,18,24,47,99,99,99,99
  dh 18,21,26,66,99,99,99,99
  dh 24,26,56,99,99,99,99,99
  dh 47,66,99,99,99,99,99,99
  dh 99,99,99,99,99,99,99,99
  dh 99,99,99,99,99,99,99,99
  dh 99,99,99,99,99,99,99,99
  dh 99,99,99,99,99,99,99,99

QL: // JPEG Standard Luminance Quantization 8x8 Result Matrix (Quality = 50)
  dh 16,11,10,16,24,40,51,61
  dh 12,12,14,19,26,58,60,55
  dh 14,13,16,24,40,57,69,56
  dh 14,17,22,29,51,87,80,62
  dh 18,22,37,56,68,109,103,77
  dh 24,35,55,64,81,104,113,92
  dh 49,64,78,87,103,121,120,101
  dh 72,92,95,98,112,100,103,99

align(8) // Align 64-Bit
base RSPData+pc() // Set End Of RSP Data Object
RSPDataEnd:

ZigZagTexture: // RDP 8-Bit Color Index Texture (256x1), For Inverse ZigZag Transformation Of 4 DCT Blocks
  db 0,1,5,6,14,15,27,28
  db 2,4,7,13,16,26,29,42
  db 3,8,12,17,25,30,41,43
  db 9,11,18,24,31,40,44,53
  db 10,19,23,32,39,45,52,54
  db 20,22,33,38,46,51,55,60
  db 21,34,37,47,50,56,59,61
  db 35,36,48,49,57,58,62,63

  db 64,65,69,70,78,79,91,92
  db 66,68,71,77,80,90,93,106
  db 67,72,76,81,89,94,105,107
  db 73,75,82,88,95,104,108,117
  db 74,83,87,96,103,109,116,118
  db 84,86,97,102,110,115,119,124
  db 85,98,101,111,114,120,123,125
  db 99,100,112,113,121,122,126,127

  db 128,129,133,134,142,143,155,156
  db 130,132,135,141,144,154,157,170
  db 131,136,140,145,153,158,169,171
  db 137,139,146,152,159,168,172,181
  db 138,147,151,160,167,173,180,182
  db 148,150,161,166,174,179,183,188
  db 149,162,165,175,178,184,187,189
  db 163,164,176,177,185,186,190,191

  db 192,193,197,198,206,207,219,220
  db 194,196,199,205,208,218,221,234
  db 195,200,204,209,217,222,233,235
  db 201,203,210,216,223,232,236,245
  db 202,211,215,224,231,237,244,246
  db 212,214,225,230,238,243,247,252
  db 213,226,229,239,242,248,251,253
  db 227,228,240,241,249,250,254,255

align(8) // Align 64-Bit
RDPZigZagBuffer:
arch n64.rdp
  Set_Scissor 0<<2,0<<2, 0,0, 256<<2,600<<2 // Set Scissor: XH 0.0,YH 0.0, Scissor Field Enable Off,Field Off, XL 256.0,YL 600.0
  Set_Color_Image IMAGE_DATA_FORMAT_RGBA,SIZE_OF_PIXEL_16B,256-1, YUV // Set Color Image: FORMAT RGBA,SIZE 16B,WIDTH 256, DRAM ADDRESS
  Set_Other_Modes CYCLE_TYPE_COPY|EN_TLUT // Set Other Modes

  Set_Tile IMAGE_DATA_FORMAT_COLOR_INDX,SIZE_OF_PIXEL_8B,32, $000, 0,0, 0,0,0,0, 0,0,0,0 // Set Tile: FORMAT COLOR INDEX,SIZE 8B,Tile Line Size 32 (64bit Words), TMEM Address $000, Tile 0
  Set_Texture_Image IMAGE_DATA_FORMAT_COLOR_INDX,SIZE_OF_PIXEL_8B,256-1, ZigZagTexture // Set Texture Image: FORMAT COLOR INDEX,SIZE 8B,WIDTH 256, Sample DRAM ADDRESS
  Load_Tile 0<<2,0<<2, 0, 255<<2,0<<2 // Load_Tile: SL 0.0,TL 0.0, Tile 0, SH 255.0,TH 0.0

  define t(0)
  define y(0)
  while {y} < 600 {
    Sync_Tile // Sync Tile
    Set_Texture_Image IMAGE_DATA_FORMAT_RGBA,SIZE_OF_PIXEL_16B,1-1, DCTQ+{t} // Set Texture Image: FORMAT RGBA,SIZE 16B,WIDTH 1, Tlut DRAM ADDRESS
    Set_Tile 0,0,0, $100, 0,0, 0,0,0,0, 0,0,0,0 // Set Tile: TMEM Address $100, Tile 0
    Load_Tlut 0<<2,0<<2, 0, 255<<2,0<<2 // Load Tlut: SL 0.0,TL 0.0, Tile 0, SH 255.0,TH 0.0
    Sync_Tile // Sync Tile
    Set_Tile IMAGE_DATA_FORMAT_COLOR_INDX,SIZE_OF_PIXEL_8B,32, $000, 0,0, 0,0,0,0, 0,0,0,0 // Set Tile: FORMAT COLOR INDEX,SIZE 8B,Tile Line Size 32 (64bit Words), TMEM Address $000, Tile 0
    Texture_Rectangle 255<<2,{y}<<2, 0, 0<<2,{y}<<2, 0<<5,0<<5, 4<<10,1<<10 // Texture Rectangle: XL 255.0,YL 0.0, Tile 0, XH 0.0,YH 0.0, S 0.0,T 0.0, DSDX 4.0,DTDY 1.0
    evaluate t({t} + 512)
    evaluate y({y} + 1)
  }
  Sync_Full // Ensure Entire Scene Is Fully Drawn
RDPZigZagBufferEnd:


align(8) // Align 64-Bit
RDPYUVBuffer:
arch n64.rdp
  Set_Scissor 0<<2,0<<2, 0,0, 320<<2,240<<2 // Set Scissor: XH 0.0,YH 0.0, Scissor Field Enable Off,Field Off, XL 320.0,YL 240.0
  Set_Color_Image IMAGE_DATA_FORMAT_RGBA,SIZE_OF_PIXEL_32B,320-1, $00100000 // Set Color Image: FORMAT RGBA,SIZE 32B,WIDTH 320, DRAM ADDRESS

  Set_Other_Modes MID_TEXEL|SAMPLE_TYPE|ALPHA_DITHER_SEL_NO_DITHER|RGB_DITHER_SEL_NO_DITHER // Set Other Modes
  Set_Combine_Mode $0,$00, 0,0, $6,$01, $0,$F, 1,0, 0,0,0, 7,7,7 // Set Combine Mode: SubA RGB0,MulRGB0, SubA Alpha0,MulAlpha0, SubA RGB1,MulRGB1, SubB RGB0,SubB RGB1, SubA Alpha1,MulAlpha1, AddRGB0,SubB Alpha0,AddAlpha0, AddRGB1,SubB Alpha1,AddAlpha1

  Set_Convert 175,-43,-89,222,114,42 // Set Convert: K0 175,K1 -43,K2 -89,K3 222,K4 114,K5 42 (Coefficients For Converting YUV Pixels To RGB)

// BG Column 0..39 / Row 0..29
  Set_Tile IMAGE_DATA_FORMAT_YUV,SIZE_OF_PIXEL_16B,1, $000, 0,0, 0,0,0,0, 0,0,0,0 // Set Tile: FORMAT YUV,SIZE 16B,Tile Line Size 1 (64bit Words), TMEM Address $000, Tile 0

  define y(0)
  while {y} < 30 {
    define x(0)
    while {x} < 40 {
      Set_Texture_Image IMAGE_DATA_FORMAT_RGBA,SIZE_OF_PIXEL_16B,8-1, YUV+(128*(({y}*40)+{x})) // Set Texture Image: FORMAT RGBA,SIZE 16B,WIDTH 8, DRAM ADDRESS
      Load_Tile 0<<2,0<<2, 0, 7<<2,7<<2 // Load Tile: SL 0.0,TL 0.0, Tile 0, SH 7.0,TH 7.0
      Texture_Rectangle (8+({x}*8))<<2,(8+({y}*8))<<2, 0, ({x}*8)<<2,({y}*8)<<2, 0<<5,0<<5, 1<<10,1<<10 // Texture Rectangle: XL,YL, Tile, XH,YH, S,T, DSDX,DTDY
      Sync_Tile // Sync Tile

      evaluate x({x} + 1)
    }
    evaluate y({y} + 1)
  }
  Sync_Full // Ensure Entire Scene Is Fully Drawn
RDPYUVBufferEnd:

insert Sample, "Sample.bin" // 16-Bit 22050Hz Signed Big-Endian Stereo Sound Sample
insert LZVideo, "Video.lz" // 4162 320x240 LZ DIFF RLE Compressed YUV Frames 