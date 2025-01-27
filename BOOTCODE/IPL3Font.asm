// IPL3 Font Data (1-BPP, 13x14 Characters, With 2 Bits Of Padding, 23 Bytes Each)
// Special Thanks To Zoinkity For The IPL3 Font Documentation

macro IPL3FontConvert(char) {
  db ({char}00 >> 5)
  db ({char}00 << 3) + ({char}01 >> 10)
  db ({char}01 >> 2)
  db ({char}01 << 6) + ({char}02 >> 7)
  db ({char}02 << 1) + ({char}03 >> 12)
  db ({char}03 >> 4)
  db ({char}03 << 4) + ({char}04 >> 9)
  db ({char}04 >> 1)
  db ({char}04 << 7) + ({char}05 >> 6)
  db ({char}05 << 2) + ({char}06 >> 11)
  db ({char}06 >> 3)
  db ({char}06 << 5) + ({char}07 >> 8)
  db {char}07
  db ({char}08 >> 5)
  db ({char}08 << 3) + ({char}09 >> 10)
  db ({char}09 >> 2)
  db ({char}09 << 6) + ({char}10 >> 7)
  db ({char}10 << 1) + ({char}11 >> 12)
  db ({char}11 >> 4)
  db ({char}11 << 4) + ({char}12 >> 9)
  db ({char}12 >> 1)
  db ({char}12 << 7) + ({char}13 >> 6)
  db ({char}13 << 2)
}

constant IPL3A00(%0000001000000) // "A"
constant IPL3A01(%0000001000000)
constant IPL3A02(%0000010100000)
constant IPL3A03(%0000010100000)
constant IPL3A04(%0000100010000)
constant IPL3A05(%0000100010000)
constant IPL3A06(%0000100010000)
constant IPL3A07(%0001000001000)
constant IPL3A08(%0001000001000)
constant IPL3A09(%0011111111100)
constant IPL3A10(%0010000000100)
constant IPL3A11(%0010000000100)
constant IPL3A12(%0100000000010)
constant IPL3A13(%0100000000010)
IPL3FontConvert(IPL3A)

constant IPL3B00(%0111111100000) // "B"
constant IPL3B01(%0100000010000)
constant IPL3B02(%0100000001000)
constant IPL3B03(%0100000001000)
constant IPL3B04(%0100000001000)
constant IPL3B05(%0100000010000)
constant IPL3B06(%0111111110000)
constant IPL3B07(%0100000001000)
constant IPL3B08(%0100000000100)
constant IPL3B09(%0100000000100)
constant IPL3B10(%0100000000100)
constant IPL3B11(%0100000000100)
constant IPL3B12(%0100000001000)
constant IPL3B13(%0111111110000)
IPL3FontConvert(IPL3B)

constant IPL3C00(%0000011100000) // "C"
constant IPL3C01(%0001100011000)
constant IPL3C02(%0010000000100)
constant IPL3C03(%0100000000010)
constant IPL3C04(%0100000000010)
constant IPL3C05(%1000000000000)
constant IPL3C06(%1000000000000)
constant IPL3C07(%1000000000000)
constant IPL3C08(%1000000000000)
constant IPL3C09(%0100000000010)
constant IPL3C10(%0100000000010)
constant IPL3C11(%0010000000100)
constant IPL3C12(%0001100011000)
constant IPL3C13(%0000011100000)
IPL3FontConvert(IPL3C)

constant IPL3D00(%0111111000000) // "D"
constant IPL3D01(%0100000110000)
constant IPL3D02(%0100000001000)
constant IPL3D03(%0100000000100)
constant IPL3D04(%0100000000100)
constant IPL3D05(%0100000000010)
constant IPL3D06(%0100000000010)
constant IPL3D07(%0100000000010)
constant IPL3D08(%0100000000010)
constant IPL3D09(%0100000000100)
constant IPL3D10(%0100000000100)
constant IPL3D11(%0100000001000)
constant IPL3D12(%0100000110000)
constant IPL3D13(%0111111000000)
IPL3FontConvert(IPL3D)

constant IPL3E00(%0111111111100) // "E"
constant IPL3E01(%0100000000000)
constant IPL3E02(%0100000000000)
constant IPL3E03(%0100000000000)
constant IPL3E04(%0100000000000)
constant IPL3E05(%0100000000000)
constant IPL3E06(%0111111111000)
constant IPL3E07(%0100000000000)
constant IPL3E08(%0100000000000)
constant IPL3E09(%0100000000000)
constant IPL3E10(%0100000000000)
constant IPL3E11(%0100000000000)
constant IPL3E12(%0100000000000)
constant IPL3E13(%0111111111100)
IPL3FontConvert(IPL3E)

constant IPL3F00(%0111111111100) // "F"
constant IPL3F01(%0100000000000)
constant IPL3F02(%0100000000000)
constant IPL3F03(%0100000000000)
constant IPL3F04(%0100000000000)
constant IPL3F05(%0100000000000)
constant IPL3F06(%0111111111000)
constant IPL3F07(%0100000000000)
constant IPL3F08(%0100000000000)
constant IPL3F09(%0100000000000)
constant IPL3F10(%0100000000000)
constant IPL3F11(%0100000000000)
constant IPL3F12(%0100000000000)
constant IPL3F13(%0100000000000)
IPL3FontConvert(IPL3F)

constant IPL3G00(%0000011100000) // "G"
constant IPL3G01(%0001100011000)
constant IPL3G02(%0010000000100)
constant IPL3G03(%0100000000010)
constant IPL3G04(%0100000000010)
constant IPL3G05(%1000000000000)
constant IPL3G06(%1000000000000)
constant IPL3G07(%1000000000000)
constant IPL3G08(%1000001111110)
constant IPL3G09(%0100000000010)
constant IPL3G10(%0100000000010)
constant IPL3G11(%0010000000110)
constant IPL3G12(%0001100011010)
constant IPL3G13(%0000011100010)
IPL3FontConvert(IPL3G)

constant IPL3H00(%0100000000010) // "H"
constant IPL3H01(%0100000000010)
constant IPL3H02(%0100000000010)
constant IPL3H03(%0100000000010)
constant IPL3H04(%0100000000010)
constant IPL3H05(%0100000000010)
constant IPL3H06(%0111111111110)
constant IPL3H07(%0100000000010)
constant IPL3H08(%0100000000010)
constant IPL3H09(%0100000000010)
constant IPL3H10(%0100000000010)
constant IPL3H11(%0100000000010)
constant IPL3H12(%0100000000010)
constant IPL3H13(%0100000000010)
IPL3FontConvert(IPL3H)

constant IPL3I00(%0000011100000) // "I"
constant IPL3I01(%0000001000000)
constant IPL3I02(%0000001000000)
constant IPL3I03(%0000001000000)
constant IPL3I04(%0000001000000)
constant IPL3I05(%0000001000000)
constant IPL3I06(%0000001000000)
constant IPL3I07(%0000001000000)
constant IPL3I08(%0000001000000)
constant IPL3I09(%0000001000000)
constant IPL3I10(%0000001000000)
constant IPL3I11(%0000001000000)
constant IPL3I12(%0000001000000)
constant IPL3I13(%0000011100000)
IPL3FontConvert(IPL3I)

constant IPL3J00(%0000000001000) // "J"
constant IPL3J01(%0000000001000)
constant IPL3J02(%0000000001000)
constant IPL3J03(%0000000001000)
constant IPL3J04(%0000000001000)
constant IPL3J05(%0000000001000)
constant IPL3J06(%0000000001000)
constant IPL3J07(%0000000001000)
constant IPL3J08(%0000000001000)
constant IPL3J09(%0100000001000)
constant IPL3J10(%0100000001000)
constant IPL3J11(%0100000001000)
constant IPL3J12(%0010000010000)
constant IPL3J13(%0001111100000)
IPL3FontConvert(IPL3J)

constant IPL3K00(%0100000000100) // "K"
constant IPL3K01(%0100000001000)
constant IPL3K02(%0100000010000)
constant IPL3K03(%0100000100000)
constant IPL3K04(%0100001000000)
constant IPL3K05(%0100010000000)
constant IPL3K06(%0100100000000)
constant IPL3K07(%0101010000000)
constant IPL3K08(%0110001000000)
constant IPL3K09(%0100000100000)
constant IPL3K10(%0100000010000)
constant IPL3K11(%0100000001000)
constant IPL3K12(%0100000000100)
constant IPL3K13(%0100000000010)
IPL3FontConvert(IPL3K)

constant IPL3L00(%0100000000000) // "L"
constant IPL3L01(%0100000000000)
constant IPL3L02(%0100000000000)
constant IPL3L03(%0100000000000)
constant IPL3L04(%0100000000000)
constant IPL3L05(%0100000000000)
constant IPL3L06(%0100000000000)
constant IPL3L07(%0100000000000)
constant IPL3L08(%0100000000000)
constant IPL3L09(%0100000000000)
constant IPL3L10(%0100000000000)
constant IPL3L11(%0100000000000)
constant IPL3L12(%0100000000000)
constant IPL3L13(%0111111111100)
IPL3FontConvert(IPL3L)

constant IPL3M00(%1000000000001) // "M"
constant IPL3M01(%1000000000001)
constant IPL3M02(%1100000000011)
constant IPL3M03(%1010000000101)
constant IPL3M04(%1010000000101)
constant IPL3M05(%1001000001001)
constant IPL3M06(%1001000001001)
constant IPL3M07(%1000100010001)
constant IPL3M08(%1000100010001)
constant IPL3M09(%1000010100001)
constant IPL3M10(%1000010100001)
constant IPL3M11(%1000001000001)
constant IPL3M12(%1000001000001)
constant IPL3M13(%1000000000001)
IPL3FontConvert(IPL3M)

constant IPL3N00(%0100000000100) // "N"
constant IPL3N01(%0110000000100)
constant IPL3N02(%0101000000100)
constant IPL3N03(%0101000000100)
constant IPL3N04(%0100100000100)
constant IPL3N05(%0100010000100)
constant IPL3N06(%0100010000100)
constant IPL3N07(%0100001000100)
constant IPL3N08(%0100001000100)
constant IPL3N09(%0100000100100)
constant IPL3N10(%0100000010100)
constant IPL3N11(%0100000010100)
constant IPL3N12(%0100000001100)
constant IPL3N13(%0100000000100)
IPL3FontConvert(IPL3N)

constant IPL3O00(%0000111100000) // "O"
constant IPL3O01(%0011000011000)
constant IPL3O02(%0100000000100)
constant IPL3O03(%0100000000100)
constant IPL3O04(%1000000000010)
constant IPL3O05(%1000000000010)
constant IPL3O06(%1000000000010)
constant IPL3O07(%1000000000010)
constant IPL3O08(%1000000000010)
constant IPL3O09(%1000000000010)
constant IPL3O10(%0100000000100)
constant IPL3O11(%0100000000100)
constant IPL3O12(%0011000011000)
constant IPL3O13(%0000111100000)
IPL3FontConvert(IPL3O)

constant IPL3P00(%0111111110000) // "P"
constant IPL3P01(%0100000001000)
constant IPL3P02(%0100000000100)
constant IPL3P03(%0100000000100)
constant IPL3P04(%0100000000100)
constant IPL3P05(%0100000000100)
constant IPL3P06(%0100000001000)
constant IPL3P07(%0111111110000)
constant IPL3P08(%0100000000000)
constant IPL3P09(%0100000000000)
constant IPL3P10(%0100000000000)
constant IPL3P11(%0100000000000)
constant IPL3P12(%0100000000000)
constant IPL3P13(%0100000000000)
IPL3FontConvert(IPL3P)

constant IPL3Q00(%0000111100000) // "Q"
constant IPL3Q01(%0011000011000)
constant IPL3Q02(%0100000000100)
constant IPL3Q03(%0100000000100)
constant IPL3Q04(%1000000000010)
constant IPL3Q05(%1000000000010)
constant IPL3Q06(%1000000000010)
constant IPL3Q07(%1000000000010)
constant IPL3Q08(%1000000000010)
constant IPL3Q09(%1000001000010)
constant IPL3Q10(%0100000100100)
constant IPL3Q11(%0100000010100)
constant IPL3Q12(%0011000011000)
constant IPL3Q13(%0000111100100)
IPL3FontConvert(IPL3Q)

constant IPL3R00(%0111111110000) // "R"
constant IPL3R01(%0100000001000)
constant IPL3R02(%0100000000100)
constant IPL3R03(%0100000000100)
constant IPL3R04(%0100000000100)
constant IPL3R05(%0100000001000)
constant IPL3R06(%0111111110000)
constant IPL3R07(%0100000100000)
constant IPL3R08(%0100000010000)
constant IPL3R09(%0100000010000)
constant IPL3R10(%0100000001000)
constant IPL3R11(%0100000001000)
constant IPL3R12(%0100000000100)
constant IPL3R13(%0100000000100)
IPL3FontConvert(IPL3R)

constant IPL3S00(%0001111110000) // "S"
constant IPL3S01(%0010000001000)
constant IPL3S02(%0100000000100)
constant IPL3S03(%0100000000100)
constant IPL3S04(%0100000000000)
constant IPL3S05(%0010000000000)
constant IPL3S06(%0001110000000)
constant IPL3S07(%0000001110000)
constant IPL3S08(%0000000001000)
constant IPL3S09(%0000000000100)
constant IPL3S10(%0100000000100)
constant IPL3S11(%0100000000100)
constant IPL3S12(%0010000001000)
constant IPL3S13(%0001111110000)
IPL3FontConvert(IPL3S)

constant IPL3T00(%0111111111110) // "T"
constant IPL3T01(%0000001000000)
constant IPL3T02(%0000001000000)
constant IPL3T03(%0000001000000)
constant IPL3T04(%0000001000000)
constant IPL3T05(%0000001000000)
constant IPL3T06(%0000001000000)
constant IPL3T07(%0000001000000)
constant IPL3T08(%0000001000000)
constant IPL3T09(%0000001000000)
constant IPL3T10(%0000001000000)
constant IPL3T11(%0000001000000)
constant IPL3T12(%0000001000000)
constant IPL3T13(%0000001000000)
IPL3FontConvert(IPL3T)

constant IPL3U00(%0100000000100) // "U"
constant IPL3U01(%0100000000100)
constant IPL3U02(%0100000000100)
constant IPL3U03(%0100000000100)
constant IPL3U04(%0100000000100)
constant IPL3U05(%0100000000100)
constant IPL3U06(%0100000000100)
constant IPL3U07(%0100000000100)
constant IPL3U08(%0100000000100)
constant IPL3U09(%0100000000100)
constant IPL3U10(%0010000001000)
constant IPL3U11(%0010000001000)
constant IPL3U12(%0001000010000)
constant IPL3U13(%0000111100000)
IPL3FontConvert(IPL3U)

constant IPL3V00(%0100000000010) // "V"
constant IPL3V01(%0100000000010)
constant IPL3V02(%0010000000100)
constant IPL3V03(%0010000000100)
constant IPL3V04(%0010000000100)
constant IPL3V05(%0001000001000)
constant IPL3V06(%0001000001000)
constant IPL3V07(%0000100010000)
constant IPL3V08(%0000100010000)
constant IPL3V09(%0000100010000)
constant IPL3V10(%0000010100000)
constant IPL3V11(%0000010100000)
constant IPL3V12(%0000001000000)
constant IPL3V13(%0000001000000)
IPL3FontConvert(IPL3V)

constant IPL3W00(%1000001000001) // "W"
constant IPL3W01(%1000001000001)
constant IPL3W02(%1000001000001)
constant IPL3W03(%0100010100010)
constant IPL3W04(%0100010100010)
constant IPL3W05(%0100010100010)
constant IPL3W06(%0100010100010)
constant IPL3W07(%0010100010100)
constant IPL3W08(%0010100010100)
constant IPL3W09(%0010100010100)
constant IPL3W10(%0010100010100)
constant IPL3W11(%0001000001000)
constant IPL3W12(%0001000001000)
constant IPL3W13(%0001000001000)
IPL3FontConvert(IPL3W)

constant IPL3X00(%0100000000010) // "X"
constant IPL3X01(%0010000000100)
constant IPL3X02(%0001000001000)
constant IPL3X03(%0001000001000)
constant IPL3X04(%0000100010000)
constant IPL3X05(%0000010100000)
constant IPL3X06(%0000001000000)
constant IPL3X07(%0000001000000)
constant IPL3X08(%0000010100000)
constant IPL3X09(%0000100010000)
constant IPL3X10(%0001000001000)
constant IPL3X11(%0001000001000)
constant IPL3X12(%0010000000100)
constant IPL3X13(%0100000000010)
IPL3FontConvert(IPL3X)

constant IPL3Y00(%0100000000010) // "Y"
constant IPL3Y01(%0010000000100)
constant IPL3Y02(%0010000000100)
constant IPL3Y03(%0001000001000)
constant IPL3Y04(%0000100010000)
constant IPL3Y05(%0000100010000)
constant IPL3Y06(%0000010100000)
constant IPL3Y07(%0000001000000)
constant IPL3Y08(%0000001000000)
constant IPL3Y09(%0000001000000)
constant IPL3Y10(%0000001000000)
constant IPL3Y11(%0000001000000)
constant IPL3Y12(%0000001000000)
constant IPL3Y13(%0000001000000)
IPL3FontConvert(IPL3Y)

constant IPL3Z00(%0111111111100) // "Z"
constant IPL3Z01(%0000000000100)
constant IPL3Z02(%0000000001000)
constant IPL3Z03(%0000000010000)
constant IPL3Z04(%0000000010000)
constant IPL3Z05(%0000000100000)
constant IPL3Z06(%0000001000000)
constant IPL3Z07(%0000010000000)
constant IPL3Z08(%0000100000000)
constant IPL3Z09(%0001000000000)
constant IPL3Z10(%0001000000000)
constant IPL3Z11(%0010000000000)
constant IPL3Z12(%0100000000000)
constant IPL3Z13(%0111111111100)
IPL3FontConvert(IPL3Z)

constant IPL3000(%0000111110000) // "0"
constant IPL3001(%0001000001000)
constant IPL3002(%0010000000100)
constant IPL3003(%0010000000100)
constant IPL3004(%0010000000100)
constant IPL3005(%0010000000100)
constant IPL3006(%0010000000100)
constant IPL3007(%0010000000100)
constant IPL3008(%0010000000100)
constant IPL3009(%0010000000100)
constant IPL3010(%0010000000100)
constant IPL3011(%0010000000100)
constant IPL3012(%0001000001000)
constant IPL3013(%0000111110000)
IPL3FontConvert(IPL30)

constant IPL3100(%0000001000000) // "1"
constant IPL3101(%0000011000000)
constant IPL3102(%0000101000000)
constant IPL3103(%0000001000000)
constant IPL3104(%0000001000000)
constant IPL3105(%0000001000000)
constant IPL3106(%0000001000000)
constant IPL3107(%0000001000000)
constant IPL3108(%0000001000000)
constant IPL3109(%0000001000000)
constant IPL3110(%0000001000000)
constant IPL3111(%0000001000000)
constant IPL3112(%0000001000000)
constant IPL3113(%0000001000000)
IPL3FontConvert(IPL31)

constant IPL3200(%0000111100000) // "2"
constant IPL3201(%0001000010000)
constant IPL3202(%0010000001000)
constant IPL3203(%0010000001000)
constant IPL3204(%0000000001000)
constant IPL3205(%0000000001000)
constant IPL3206(%0000000010000)
constant IPL3207(%0000000100000)
constant IPL3208(%0000001000000)
constant IPL3209(%0000010000000)
constant IPL3210(%0000100000000)
constant IPL3211(%0001000000000)
constant IPL3212(%0010000000000)
constant IPL3213(%0011111111000)
IPL3FontConvert(IPL32)

constant IPL3300(%0000111100000) // "3"
constant IPL3301(%0001000010000)
constant IPL3302(%0010000001000)
constant IPL3303(%0010000001000)
constant IPL3304(%0000000001000)
constant IPL3305(%0000000010000)
constant IPL3306(%0000011100000)
constant IPL3307(%0000000010000)
constant IPL3308(%0000000001000)
constant IPL3309(%0000000001000)
constant IPL3310(%0010000001000)
constant IPL3311(%0010000001000)
constant IPL3312(%0001000010000)
constant IPL3313(%0000111100000)
IPL3FontConvert(IPL33)

constant IPL3400(%0000000100000) // "4"
constant IPL3401(%0000001100000)
constant IPL3402(%0000001100000)
constant IPL3403(%0000010100000)
constant IPL3404(%0000100100000)
constant IPL3405(%0000100100000)
constant IPL3406(%0001000100000)
constant IPL3407(%0010000100000)
constant IPL3408(%0010000100000)
constant IPL3409(%0100000100000)
constant IPL3410(%0111111111100)
constant IPL3411(%0000000100000)
constant IPL3412(%0000000100000)
constant IPL3413(%0000000100000)
IPL3FontConvert(IPL34)

constant IPL3500(%0001111110000) // "5"
constant IPL3501(%0010000000000)
constant IPL3502(%0010000000000)
constant IPL3503(%0010000000000)
constant IPL3504(%0010000000000)
constant IPL3505(%0010111100000)
constant IPL3506(%0011000010000)
constant IPL3507(%0010000001000)
constant IPL3508(%0000000001000)
constant IPL3509(%0000000001000)
constant IPL3510(%0010000001000)
constant IPL3511(%0010000001000)
constant IPL3512(%0001000010000)
constant IPL3513(%0000111100000)
IPL3FontConvert(IPL35)

constant IPL3600(%0000111100000) // "6"
constant IPL3601(%0001000010000)
constant IPL3602(%0010000001000)
constant IPL3603(%0010000001000)
constant IPL3604(%0010000000000)
constant IPL3605(%0010000000000)
constant IPL3606(%0010111100000)
constant IPL3607(%0011000010000)
constant IPL3608(%0010000001000)
constant IPL3609(%0010000001000)
constant IPL3610(%0010000001000)
constant IPL3611(%0010000001000)
constant IPL3612(%0001000010000)
constant IPL3613(%0000111100000)
IPL3FontConvert(IPL36)

constant IPL3700(%0011111111000) // "7"
constant IPL3701(%0000000001000)
constant IPL3702(%0000000010000)
constant IPL3703(%0000000010000)
constant IPL3704(%0000000100000)
constant IPL3705(%0000000100000)
constant IPL3706(%0000000100000)
constant IPL3707(%0000001000000)
constant IPL3708(%0000001000000)
constant IPL3709(%0000001000000)
constant IPL3710(%0000010000000)
constant IPL3711(%0000010000000)
constant IPL3712(%0000010000000)
constant IPL3713(%0000010000000)
IPL3FontConvert(IPL37)

constant IPL3800(%0000111100000) // "8"
constant IPL3801(%0001000010000)
constant IPL3802(%0010000001000)
constant IPL3803(%0010000001000)
constant IPL3804(%0010000001000)
constant IPL3805(%0001000010000)
constant IPL3806(%0000111100000)
constant IPL3807(%0001000010000)
constant IPL3808(%0010000001000)
constant IPL3809(%0010000001000)
constant IPL3810(%0010000001000)
constant IPL3811(%0010000001000)
constant IPL3812(%0001000010000)
constant IPL3813(%0000111100000)
IPL3FontConvert(IPL38)

constant IPL3900(%0000111100000) // "9"
constant IPL3901(%0001000010000)
constant IPL3902(%0010000001000)
constant IPL3903(%0010000001000)
constant IPL3904(%0010000001000)
constant IPL3905(%0010000001000)
constant IPL3906(%0001000011000)
constant IPL3907(%0000111101000)
constant IPL3908(%0000000001000)
constant IPL3909(%0000000001000)
constant IPL3910(%0010000001000)
constant IPL3911(%0010000001000)
constant IPL3912(%0001000010000)
constant IPL3913(%0000111100000)
IPL3FontConvert(IPL39)

constant IPL3Exclamation00(%0000001000000) // "!"
constant IPL3Exclamation01(%0000001000000)
constant IPL3Exclamation02(%0000001000000)
constant IPL3Exclamation03(%0000001000000)
constant IPL3Exclamation04(%0000001000000)
constant IPL3Exclamation05(%0000001000000)
constant IPL3Exclamation06(%0000001000000)
constant IPL3Exclamation07(%0000001000000)
constant IPL3Exclamation08(%0000001000000)
constant IPL3Exclamation09(%0000001000000)
constant IPL3Exclamation10(%0000000000000)
constant IPL3Exclamation11(%0000000000000)
constant IPL3Exclamation12(%0000001000000)
constant IPL3Exclamation13(%0000001000000)
IPL3FontConvert(IPL3Exclamation)

constant IPL3DoubleQuote00(%1101100000000) // '"'
constant IPL3DoubleQuote01(%1101100000000)
constant IPL3DoubleQuote02(%0100100000000)
constant IPL3DoubleQuote03(%1001000000000)
constant IPL3DoubleQuote04(%0000000000000)
constant IPL3DoubleQuote05(%0000000000000)
constant IPL3DoubleQuote06(%0000000000000)
constant IPL3DoubleQuote07(%0000000000000)
constant IPL3DoubleQuote08(%0000000000000)
constant IPL3DoubleQuote09(%0000000000000)
constant IPL3DoubleQuote10(%0000000000000)
constant IPL3DoubleQuote11(%0000000000000)
constant IPL3DoubleQuote12(%0000000000000)
constant IPL3DoubleQuote13(%0000000000000)
IPL3FontConvert(IPL3DoubleQuote)

constant IPL3Hash00(%0000010001000) // "'"
constant IPL3Hash01(%0000010001000)
constant IPL3Hash02(%0000010001000)
constant IPL3Hash03(%0000010001000)
constant IPL3Hash04(%0111111111110)
constant IPL3Hash05(%0000100010000)
constant IPL3Hash06(%0000100010000)
constant IPL3Hash07(%0000100010000)
constant IPL3Hash08(%0000100010000)
constant IPL3Hash09(%0111111111110)
constant IPL3Hash10(%0001000100000)
constant IPL3Hash11(%0001000100000)
constant IPL3Hash12(%0001000100000)
constant IPL3Hash13(%0001000100000)
IPL3FontConvert(IPL3Hash)

constant IPL3SingleQuote00(%1100000000000) // "'"
constant IPL3SingleQuote01(%1100000000000)
constant IPL3SingleQuote02(%0100000000000)
constant IPL3SingleQuote03(%1000000000000)
constant IPL3SingleQuote04(%0000000000000)
constant IPL3SingleQuote05(%0000000000000)
constant IPL3SingleQuote06(%0000000000000)
constant IPL3SingleQuote07(%0000000000000)
constant IPL3SingleQuote08(%0000000000000)
constant IPL3SingleQuote09(%0000000000000)
constant IPL3SingleQuote10(%0000000000000)
constant IPL3SingleQuote11(%0000000000000)
constant IPL3SingleQuote12(%0000000000000)
constant IPL3SingleQuote13(%0000000000000)
IPL3FontConvert(IPL3SingleQuote)

constant IPL3Asterisk00(%0000000000000) // "*"
constant IPL3Asterisk01(%0000000000000)
constant IPL3Asterisk02(%0000001000000)
constant IPL3Asterisk03(%0010001000100)
constant IPL3Asterisk04(%0001001001000)
constant IPL3Asterisk05(%0000101010000)
constant IPL3Asterisk06(%0000011100000)
constant IPL3Asterisk07(%0000001000000)
constant IPL3Asterisk08(%0000011100000)
constant IPL3Asterisk09(%0000101010000)
constant IPL3Asterisk10(%0001001001000)
constant IPL3Asterisk11(%0010001000100)
constant IPL3Asterisk12(%0000001000000)
constant IPL3Asterisk13(%0000000000000)
IPL3FontConvert(IPL3Asterisk)

constant IPL3Plus00(%0000000000000) // "+"
constant IPL3Plus01(%0000000000000)
constant IPL3Plus02(%0000001000000)
constant IPL3Plus03(%0000001000000)
constant IPL3Plus04(%0000001000000)
constant IPL3Plus05(%0000001000000)
constant IPL3Plus06(%0000001000000)
constant IPL3Plus07(%0111111111110)
constant IPL3Plus08(%0000001000000)
constant IPL3Plus09(%0000001000000)
constant IPL3Plus10(%0000001000000)
constant IPL3Plus11(%0000001000000)
constant IPL3Plus12(%0000001000000)
constant IPL3Plus13(%0000000000000)
IPL3FontConvert(IPL3Plus)

constant IPL3Comma00(%0000000000000) // ","
constant IPL3Comma01(%0000000000000)
constant IPL3Comma02(%0000000000000)
constant IPL3Comma03(%0000000000000)
constant IPL3Comma04(%0000000000000)
constant IPL3Comma05(%0000000000000)
constant IPL3Comma06(%0000000000000)
constant IPL3Comma07(%0000000000000)
constant IPL3Comma08(%0000000000000)
constant IPL3Comma09(%0000000000000)
constant IPL3Comma10(%1100000000000)
constant IPL3Comma11(%1100000000000)
constant IPL3Comma12(%0100000000000)
constant IPL3Comma13(%1000000000000)
IPL3FontConvert(IPL3Comma)

constant IPL3Minus00(%0000000000000) // "-"
constant IPL3Minus01(%0000000000000)
constant IPL3Minus02(%0000000000000)
constant IPL3Minus03(%0000000000000)
constant IPL3Minus04(%0000000000000)
constant IPL3Minus05(%0000000000000)
constant IPL3Minus06(%0000000000000)
constant IPL3Minus07(%0111111111110)
constant IPL3Minus08(%0000000000000)
constant IPL3Minus09(%0000000000000)
constant IPL3Minus10(%0000000000000)
constant IPL3Minus11(%0000000000000)
constant IPL3Minus12(%0000000000000)
constant IPL3Minus13(%0000000000000)
IPL3FontConvert(IPL3Minus)

constant IPL3FullStop00(%0000000000000) // "."
constant IPL3FullStop01(%0000000000000)
constant IPL3FullStop02(%0000000000000)
constant IPL3FullStop03(%0000000000000)
constant IPL3FullStop04(%0000000000000)
constant IPL3FullStop05(%0000000000000)
constant IPL3FullStop06(%0000000000000)
constant IPL3FullStop07(%0000000000000)
constant IPL3FullStop08(%0000000000000)
constant IPL3FullStop09(%0000000000000)
constant IPL3FullStop10(%1100000000000)
constant IPL3FullStop11(%1100000000000)
constant IPL3FullStop12(%0000000000000)
constant IPL3FullStop13(%0000000000000)
IPL3FontConvert(IPL3FullStop)

constant IPL3Slash00(%0000000000000) // "/"
constant IPL3Slash01(%0000000000001)
constant IPL3Slash02(%0000000000010)
constant IPL3Slash03(%0000000000100)
constant IPL3Slash04(%0000000001000)
constant IPL3Slash05(%0000000010000)
constant IPL3Slash06(%0000000100000)
constant IPL3Slash07(%0000001000000)
constant IPL3Slash08(%0000010000000)
constant IPL3Slash09(%0000100000000)
constant IPL3Slash10(%0001000000000)
constant IPL3Slash11(%0010000000000)
constant IPL3Slash12(%0100000000000)
constant IPL3Slash13(%1000000000000)
IPL3FontConvert(IPL3Slash)

constant IPL3Colon00(%0000000000000) // ":"
constant IPL3Colon01(%0000000000000)
constant IPL3Colon02(%0000000000000)
constant IPL3Colon03(%0000011000000)
constant IPL3Colon04(%0000011000000)
constant IPL3Colon05(%0000000000000)
constant IPL3Colon06(%0000000000000)
constant IPL3Colon07(%0000000000000)
constant IPL3Colon08(%0000000000000)
constant IPL3Colon09(%0000000000000)
constant IPL3Colon10(%0000011000000)
constant IPL3Colon11(%0000011000000)
constant IPL3Colon12(%0000000000000)
constant IPL3Colon13(%0000000000000)
IPL3FontConvert(IPL3Colon)

constant IPL3Equal00(%0000000000000) // "="
constant IPL3Equal01(%0000000000000)
constant IPL3Equal02(%0000000000000)
constant IPL3Equal03(%0000000000000)
constant IPL3Equal04(%0000000000000)
constant IPL3Equal05(%0111111111110)
constant IPL3Equal06(%0000000000000)
constant IPL3Equal07(%0000000000000)
constant IPL3Equal08(%0000000000000)
constant IPL3Equal09(%0111111111110)
constant IPL3Equal10(%0000000000000)
constant IPL3Equal11(%0000000000000)
constant IPL3Equal12(%0000000000000)
constant IPL3Equal13(%0000000000000)
IPL3FontConvert(IPL3Equal)

constant IPL3Question00(%0000011100000) // "?"
constant IPL3Question01(%0000100010000)
constant IPL3Question02(%0001000001000)
constant IPL3Question03(%0001000001000)
constant IPL3Question04(%0000000001000)
constant IPL3Question05(%0000000010000)
constant IPL3Question06(%0000000100000)
constant IPL3Question07(%0000001000000)
constant IPL3Question08(%0000001000000)
constant IPL3Question09(%0000001000000)
constant IPL3Question10(%0000000000000)
constant IPL3Question11(%0000000000000)
constant IPL3Question12(%0000001000000)
constant IPL3Question13(%0000001000000)
IPL3FontConvert(IPL3Question)

constant IPL3At00(%0000011100000) // "@"
constant IPL3At01(%0001100011000)
constant IPL3At02(%0010000000100)
constant IPL3At03(%0100000000010)
constant IPL3At04(%0100001100010)
constant IPL3At05(%1000010010010)
constant IPL3At06(%1000100010010)
constant IPL3At07(%1000100100010)
constant IPL3At08(%1000100100100)
constant IPL3At09(%0100011011000)
constant IPL3At10(%0100000000001)
constant IPL3At11(%0010000000010)
constant IPL3At12(%0001100001100)
constant IPL3At13(%0000011110000)
IPL3FontConvert(IPL3At)

db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 18 Bytes Of Padding