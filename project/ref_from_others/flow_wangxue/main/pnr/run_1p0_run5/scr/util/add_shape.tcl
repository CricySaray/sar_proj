proc slk_extend_IpTerm {args } {
      parse_proc_arguments -args $args slk
      set pin $slk(-pin)
      set layer $slk(-layer)
      set depth $slk(-depth)
      set direction $slk(-direction)
      set width $slk(-width)
      set ipterms [get_db pins -if {.layer.name == $layer && .name == $pin }]
      foreach term $ipterms {
      set location [get_db $term .location]
      set net [get_db $term .net.name]
      set ptx [lindex [lindex $location 0] 0]
      set pty [lindex [lindex $location 0] 1]
         if {![regexp PAD $term aa]} {
            if {$direction eq "up"} {
             set x1 $ptx 
             set y1 $pty
             set x2 $ptx 
             set y2 [expr $y1 + $depth]
             } elseif {$direction eq "down"} {
             set x1 $ptx 
             set y1 $pty
             set x2 $ptx 
             set y2 [expr $y1 - $depth]
             } elseif {$direction eq "left"} {
             set x1 $ptx 
             set y1 $pty
             set x2 [expr $ptx - $depth]
             set y2 $pty
            } elseif {$direction eq "right"} {
             set x1 $ptx 
             set y1 $pty
             set x2 [expr $ptx + $depth]
             set y2 $pty
            }
            add_shape \
               -layer $layer \
               -net $net \
               -pathSeg $x1 $y1 $x2 $y2 \
               -shape STRIPE \
               -status FIXED \
               -width $width \
               -user_class USEREXTENDIPTERM 
            }
            }
}

define_proc_arguments slk_extend_IpTerm -info "extend IP term to core" \
	-define_args { \
        {-pin "specify user extend pin name"} \
	{-layer "extendIP layer" "" string required} \
        {-depth "the depth of extend length" "" string required } \
        {-direction "the direction of extend shape , u can fed up/down/left/right" "" string required } \
        {-width "the width of extended pin " "" string required }
	}

deselect_obj -all

##afe 
if {1} {
foreach term [get_db pins  -if {.layer.name == M7}] {
       if {![regexp PAD $term aa bb]} {
         set location [get_db $term .location]
         set net [get_db $term .net.name]
         selectNet $net
         editDelete -net $net
         set ptx [lindex [lindex $location 0] 0]
         set pty [lindex [lindex $location 0] 1]
           if {$ptx < 2000} {
               set direction down 
           } elseif {$ptx >= 2000 } {
               set direction left
           }
        slk_extend_IpTerm -depth 22 -direction $direction -layer M7 -width 0.5 -pin [get_db $term .name]
           }
}
}

