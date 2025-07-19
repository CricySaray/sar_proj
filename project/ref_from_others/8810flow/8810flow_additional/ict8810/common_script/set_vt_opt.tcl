setOptMode -highEffortOptCells    ""
set_dont_use *ZTL_* false
set vars(dont_use_cells)       "INV*SGCAP* BUF*SGCAP* FRICG* DFF*QL_* DFF*QNL_* SDFF*QL_* SDFF*QNL_* SDFFQH* SDFFQNH* SDFFRPQH* SDFFRPQNH* SDFFSQH* SDFFSQNH* SDFFSRPQH* SDFFY* *DRFF* HEAD* FOOT* *X0* *DLY* SDFFX* XOR3* XNOR3* *ECO*  *ZTEH* *ZTUH* *ZTUL* *ISO* *LVL* *G33* ANTENNA* *AND*_X11* *AND*_X8* *AO21A    1AI2_X8* *AOI21B_X8* *AOI21_X11* *AOI21_X8* *AOI22BB_X8* *AOI22_X11* *AOI22_X8* *AOI2XB1_X8* *AOI31_X8* *ENDCAP FILL* GP* MXGL* OA*_X8* OR*_X11* NOR*_X11* OR*_X8* NOR*_X8* *_X20* *QN* ICT_CDMSTD" ; # *X1M* *X1G* *X1B* *X1A*  *_X*B_A*PP140*

set_dont_use $vars(dont_use_cells)  true
setOptMode -highEffortOptCells [dbGet head.allCells.name *ZTL_*]
set_dont_use *ZTL_* true
