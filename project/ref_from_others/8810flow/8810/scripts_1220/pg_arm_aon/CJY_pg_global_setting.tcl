#pg info setting
#site setting
set vars(site_width) [dbGet top.fplan.coreSite.size_x]
set vars(site_height) [dbGet top.fplan.coreSite.size_y]

#M2 setting
#set vars(m2_width) 0.2

#m5 setting
set vars(m5_width) 0.5
set vars(m5_spacing) 5
set vars(mem_channel_m5_spacing) 4
set vars(m5_set_set_distance) [expr 2*($vars(m5_width)+$vars(m5_spacing))]
set vars(m5_offset_left) 3

set vars(m5_track_offset_x) [dbGet [dbGet -p head.layers.name M5].offsetX]
set vars(m5_track_pitch_x) [dbGet [dbGet -p head.layers.name M5].pitchX]

#m6 setting
set vars(m6_width) 0.5
set vars(m6_spacing) 5
set vars(m6_set_set_distance) [expr 2*($vars(m6_width)+$vars(m6_spacing))]
set vars(m6_offset_top) 3

set vars(m6_track_offset_y) [dbGet [dbGet -p head.layers.name M6].offsetY]
set vars(m6_track_pitch_y) [dbGet [dbGet -p head.layers.name M6].pitchY]

#m7 setting
set vars(m7_width) 10
set vars(m7_spacing) 2
set vars(m7_set_set_distance) [expr 2*($vars(m7_width)+$vars(m7_spacing))]
set vars(m7_offset_left) 2

#m8 setting
set vars(m8_width) 10
set vars(m8_spacing) 6.5
set vars(m8_set_set_distance) [expr 2*($vars(m8_width)+$vars(m8_spacing))]
set vars(m8_offset_top) 2

#AP setting
set vars(ap_width) 10
set vars(ap_spacing) 2
set vars(ap_set_set_distance) [expr 2*($vars(ap_width)+$vars(ap_spacing))]
set vars(ap_offset_left) 2

