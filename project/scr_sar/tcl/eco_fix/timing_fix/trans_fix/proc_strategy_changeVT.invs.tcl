#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : strategy of fixing transition: change VT type of a cell. you can specify the weight of every VT type and speed index of VT. weight:0 will be forbidden to use
# update    : 2025/07/15 16:51:34 Tuesday
#             1) add switch $ifForceValid: if you turn on it, it will change vt to one which weight is not 0. That is legalize VT
#             2) if available vt list that is remove weight:0 vt is only now vt type, return now celltype
#             3) if have no faster VT, return original celltype
# ref       : link url
# --------------------------
# TODO: consider mix fluence between speed and weight!!!
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
proc strategy_changeVT {{celltype ""} {weight {{SVT 3} {LVT 1} {ULVT 0}}} {speed {ULVT LVT SVT}} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} {ifForceValid 1}} {
  # $weight:0 is stand for no using
  # $speed: the fastest must be in front. like ULVT must be the first
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1" 
  } else {
    # get now VTtype
    set runError [catch {regexp $regExp $celltype wholeName driveLevel VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0:2"; # check if $regExp pattern is correct 
    } else {
      set processType [whichProcess_fromStdCellPattern $celltype]
      if {$VTtype == ""} {set VTtype "SVT"; puts "notice: blank vt type"} 
      set weight0VTList [lmap vt_weight [lsort -unique -index 0 [lsearch -all -inline -index 1 -regexp $weight "0"]] {set vt [lindex $vt_weight 0]}]
      set avaiableVT [lsearch -all -inline -index 1 -regexp $weight "\[1-9\]"]; # remove weight:0 VT
      # user-defined avaiable VT type
      set availableVTsorted [lsort -index 1 -integer -decreasing $avaiableVT]
      set ifInAvailableVTList [lsearch -index 0 $availableVTsorted $VTtype]
      set availableVTnameList [lmap vt_weight $availableVTsorted {set temp [lindex $vt_weight 0]}]

#puts "-ifInAvailabeVTList $ifInAvailableVTList VTtype $VTtype $celltype -"
      if {$availableVTnameList == $VTtype} {
        return $celltype; # if list only have now vt type, return now celltype
      } elseif {$ifInAvailableVTList == -1} {
        if {$ifForceValid} {
          if {[lsearch -inline $weight0VTList $VTtype] != ""} {
            set speedList_notWeight0 $speed
            foreach weight0 $weight0VTList {
              set speedList_notWeight0 [lsearch -exact -inline -all -not $speedList_notWeight0 $weight0]
            }
#puts "$celltype -$speedList_notWeight0- "
            if {$processType == "TSMC"} {
              set useVT [lindex $speedList_notWeight0 end]
              if {$useVT == ""} {
                return "0x0:4"; # don't have faster VT
              } else {
                #return $useVT 
                if {$useVT == "SVT"} {
                  return [regsub "$VTtype" $celltype ""]
                } elseif {$VTtype == "SVT"} {
                  return [regsub "$" $celltype $useVT] 
                } else {
                  return [regsub $VTtype $celltype $useVT] 
                }
              }
            } elseif {$processType == "HH"} {
              return [regsub $VTtype $celltype [lindex $speedList_notWeight0 end]] 
            }
          } 
        } else {
          return "0x0:3"; # cell type can't be allowed to use, don't change VT type
        }
      } else {
        # get changeable VT type according to provided cell type 
        set changeableVT [lsearch -exact -index 0 -all -inline -not $availableVTsorted $VTtype]
        #puts $changeableVT
        # judge if changeable VT types have faster type than nowVTtype of provided cell type
        set nowSpeedIndex [lsearch -exact $speed $VTtype]
        set moreFastVTinSpeed [lreplace $speed $nowSpeedIndex end]
        set useVT ""
        foreach vt $changeableVT {
          if {[lsearch -exact $moreFastVTinSpeed [lindex $vt 0]] > -1} {
            set useVT "[lindex $vt 0]"
            break
          } else {
            return $celltype ; # if have no faster vt, it will return original celltype
          }
        }
        if {$processType == "TSMC"} {
          # NOTE: these VT type set now is only for TSMC cell pattern
          # TSMC cell VT type pattern: (special situation!!!)
          #   SVT: xxxCPD
          #   LVT: xxxCPDLVT
          #   ULVT: xxxCPDULVT
          if {$useVT == ""} {
            return "0x0:4"; # don't have faster VT
          } else {
            #return $useVT 
            if {$useVT == "SVT"} {
              return [regsub "$VTtype" $celltype ""]
            } elseif {$VTtype == "SVT"} {
              return [regsub "$" $celltype $useVT] 
            } else {
              return [regsub $VTtype $celltype $useVT] 
            }
          }
        } elseif {$processType == "HH"} {
          # HH40 :
          # AR9 AL9 AH9
          return [regsub $VTtype $celltype $useVT] 
        }
      }
    }
  }
}
