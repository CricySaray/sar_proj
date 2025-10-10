addInst -cell CX200A_SOC_AFE_PAD_TOP -inst CX200A_SOC_AFE_PAD_TOP_PAD -physical -loc {0 0}
set IP CX200A_SOC_AFE_PAD_TOP_PAD
set IP_terms_name {QSPI_CLK_PAD QSPI_CSN_PAD QSPI_DATA0_PAD QSPI_DATA1_PAD QSPI_DATA2_PAD QSPI_DATA3_PAD DVDDIO VSS_IO}
foreach a $IP_terms_name {
	        foreach i [dbGet [dbGet top.insts.name $IP -p].pgInstTerms.name $a -p] {
	                set term [dbGet $i.name]
	                set rect_all [dbTransform -inst $IP -localPt [dbGet [dbGet $i.term.pins.allShapes.layer.name AP -p2].shapes.rect]]
			foreach rect $rect_all {
	                	lassign [join $rect] llx lly urx ury        
				if {$llx> 500 && $lly > 500} {
					set box [text_pin $llx $lly $urx $ury 39]
					createPlaceBlockage -type hard -box $box -name pad_blk
				}
			}
		}
	}
set IP u_afe_core
set IP_terms_name {DVDDIO_FLASH}
foreach a $IP_terms_name {
	        foreach i [dbGet [dbGet top.insts.name $IP -p].pgInstTerms.name $a -p] {
	                set term [dbGet $i.name]
	                set rect_all [dbTransform -inst $IP -localPt [dbGet [dbGet $i.term.pins.allShapes.layer.name AP -p2].shapes.rect]]
			foreach rect $rect_all {
	                	lassign [join $rect] llx lly urx ury        
				if {$llx> 500 && $lly > 500} {
					set box [text_pin $llx $lly $urx $ury 39]
					createPlaceBlockage -type hard -box $box -name pad_blk
				}
			}
		}
	}
deleteInst CX200A_SOC_AFE_PAD_TOP_PAD

