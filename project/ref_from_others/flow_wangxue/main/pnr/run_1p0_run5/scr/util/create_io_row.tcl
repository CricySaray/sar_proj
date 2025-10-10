deleteRow -all
changeFloorplan -coreToBottom 130 -coreToLeft 130 -coreToTop 130
createIoRow -side {N} -site tphn28hpcpgv2od3_pad_v -name ioRow_top -orientation R180
createIoRow -side {S} -site tphn28hpcpgv2od3_pad_v -name ioRow_bottom  -orientation R0
createIoRow -side {W} -site tphn28hpcpgv2od3_pad_h -name ioRow_left -orientation R270
createIoRow -corner BL -site tphn28hpcpgv2od3_corner -name ioRow_BL -orientation R0
createIoRow -corner TL -site tphn28hpcpgv2od3_corner -name ioRow_TL -orientation R270
initCoreRow

