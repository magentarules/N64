// N64 'Bare Metal' CP1 32BPP 320x240 Mandelbrot Fractal Input Demo by krom (Peter Lemon):
// A = Zoom In
// B = Zoom Out
// R = Iteration Up
// L = Iteration Down
// DPad = X/Y Translation
// Start = Reset All Settings
arch n64.cpu
endian msb
output "MandelbrotInput32BPP320X240.N64", create
fill 1052672 // Set ROM Size

origin $00000000
base $80000000 // Entry Point Of Code
include "LIB/N64.INC" // Include N64 Definitions
include "LIB/N64_HEADER.ASM" // Include 64 Byte Header & Vector Table
insert "LIB/N64_BOOTCODE.BIN" // Include 4032 Byte Boot Code

Start:
  include "LIB/N64_GFX.INC" // Include Graphics Macros
  include "LIB/N64_INPUT.INC" // Include Input Macros
  N64_INIT() // Run N64 Initialisation Routine

  ScreenNTSC(320, 240, BPP32, $A0100000) // Screen NTSC: 320x240, 32BPP, DRAM Origin $A0100000

  la a0,DATA // A0 = Double Data Offset
  ldc1 f0,0(a0) // F0 = X%
  ldc1 f1,8(a0) // F1 = Y%
  ldc1 f2,0(a0) // F2 = SX
  ldc1 f3,8(a0) // F3 = SY
  ldc1 f4,16(a0) // F4 = XMax
  ldc1 f5,24(a0) // F5 = YMax
  ldc1 f6,32(a0) // F6 = XMin
  ldc1 f7,40(a0) // F7 = YMin
  ldc1 f8,48(a0) // F8 = RMax
  ldc1 f9,56(a0) // F9 = 1.0
  ldc1 f16,64(a0) // F16 = 0.0
  ldc1 f17,72(a0) // F17 = X/Y TRANSLATE/ZOOM ANIM

  div.d f20,f9,f2 // F20 = (1.0 / SX)
  div.d f21,f9,f3 // F21 = (1.0 / SY)

  ori t8,r0,25 // T8 = Iterations
  li t9,$231AF900 // T9 = Multiply Colour

  InitController(PIF1) // Initialize Controller

Refresh:
  ReadController(PIF2) // T0 = Controller Buttons, T1 = Analog X, T2 = Analog Y

  sub.d f18,f4,f6 // F18 = (XMAX - XMIN) / SX
  div.d f18,f2
  mul.d f18,f17

  andi t3,t0,JOY_START // Test JOY START
  beqz t3,Iteration_Up
  nop // Delay Slot
  la a0,DATA // A0 = Double Data Offset
  ldc1 f4,16(a0) // F4 = XMax
  ldc1 f5,24(a0) // F5 = YMax
  ldc1 f6,32(a0) // F6 = XMin
  ldc1 f7,40(a0) // F7 = YMin

  ori t8,r0,25 // T8 = Iterations

Iteration_Up:
  andi t3,t0,JOY_R // Test JOY R
  beqz t3,Iteration_Down
  nop // Delay Slot
  addi t8,1
  andi t8,$FF

Iteration_Down:
  andi t3,t0,JOY_L // Test JOY L
  beqz t3,Up
  nop // Delay Slot
  subi t8,1
  andi t8,$FF

Up:
  andi t3,t0,JOY_UP // Test JOY UP
  beqz t3,Down
  nop // Delay Slot
  add.d f5,f18
  add.d f7,f18

Down:
  andi t3,t0,JOY_DOWN // Test JOY DOWN
  beqz t3,Left
  nop // Delay Slot
  sub.d f5,f18
  sub.d f7,f18

Left:
  andi t3,t0,JOY_LEFT // Test JOY LEFT
  beqz t3,Right
  nop // Delay Slot
  add.d f4,f18
  add.d f6,f18

Right:
  andi t3,t0,JOY_RIGHT // Test JOY RIGHT
  beqz t3,Zoom_In
  nop // Delay Slot
  sub.d f4,f18
  sub.d f6,f18

Zoom_In:
  andi t3,t0,JOY_A // Test JOY A
  beqz t3,Zoom_Out
  nop // Delay Slot
  sub.d f4,f18
  add.d f6,f18
  sub.d f5,f18
  add.d f7,f18

Zoom_Out:
  andi t3,t0,JOY_B // Test JOY B
  beqz t3,Render
  nop // Delay Slot
  add.d f4,f18
  sub.d f6,f18
  add.d f5,f18
  sub.d f7,f18

Render:
  sub.d f18,f4,f6 // F18 = XMax - XMin
  sub.d f19,f5,f7 // F19 = YMax - YMin

  li a0,$A0100000+((320*240*4)-4) // A0 = Frame Buffer Pointer Last Pixel
  mov.d f1,f3 // F1 = Y%
  LoopY:
    mov.d f0,f2 // F0 = X%
    LoopX:
      mul.d f10,f0,f18 // CX = XMin + ((X% * (XMax - XMin)) * (1.0 / SX))
      mul.d f10,f20
      add.d f10,f6 // F10 = CX

      mul.d f11,f1,f19 // CY = YMin + ((Y% * (YMax - YMin)) * (1.0 / SY))
      mul.d f11,f21
      add.d f11,f7 // F11 = CY

      move t1,t8 // T1 = IT (Iterations)
      sub.d f12,f12 // F12 = ZX
      sub.d f13,f13 // F13 = ZY

      Iterate:
        mul.d f14,f12,f12 // XN = ((ZX * ZX) - (ZY * ZY)) + CX
        mul.d f15,f13,f13
        sub.d f14,f15
        add.d f14,f10 // F14 = XN

        mul.d f15,f12,f13 // YN = (2 * ZX * ZY) + CY
        add.d f15,f15
        add.d f15,f11 // F15 = YN

        mov.d f12,f14 // Copy XN & YN To ZX & ZY For Next Iteration
        mov.d f13,f15

        mul.d f14,f12,f12 // R = (XN * XN) + (YN * YN)
        mul.d f15,f13,f13
        add.d f14,f15 // F14 = R

        c.le.d f14,f8 // IF (R > 4) Plot
        bc1f Plot // Branch On FP False
        nop // Delay Slot

        bnez t1,Iterate // IF (IT != 0) Iterate
        subi t1,1 // IT = IT - 1

      Plot:
        mul t1,t9 // Set The Colour To RGBA 32 bit
        sw t1,0(a0) // Store Pixel Colour To Frame Buffer

        sub.d f0,f9 // Decrement X%
        c.eq.d f0,f16
        bc1f LoopX // IF (X% != 0) LoopX
        subi a0,4 // Sub 4 To RDRAM Offset

        sub.d f1,f9 // Decrement Y%
        c.eq.d f1,f16
        bc1f LoopY // IF (Y% != 0) LoopY
        nop // Delay Slot

      j Refresh
      nop // Delay Slot

align(8) // Align 64-Bit
DATA:
  float64 320.0 // SCREEN X
  float64 240.0 // SCREEN Y
  float64   2.0 // XMAX
  float64   2.0 // YMAX
  float64  -2.0 // XMIN
  float64  -2.0 // YMIN
  float64   4.0 // RMAX
  float64   1.0 // ONE
  float64   0.0 // ZERO
  float64  10.0 // X/Y TRANSLATE/ZOOM ANIM

PIF1:
  dw $FF010401,0
  dw 0,0
  dw 0,0
  dw 0,0
  dw $FE000000,0
  dw 0,0
  dw 0,0
  dw 0,1

PIF2:
  fill 64 // Generate 64 Bytes Containing $00