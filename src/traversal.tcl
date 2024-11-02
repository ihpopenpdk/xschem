#
#  File: traversal.tcl
#  
#  This file is part of XSCHEM,
#  a schematic capture and Spice/Vhdl/Verilog netlisting tool for circuit 
#  simulation.
#  Copyright (C) 1998-2023 Stefan Frederik Schippers
# 
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

# This script traverses the hierarchy and prints all instances in design.

proc traversal {file {only_subckts {}}} {
  if { $file eq {} || [file exists $file] } {
    puts stderr "empty or existing file..."
    return
  }
  xschem unselect_all
  xschem set no_draw 1 ;# disable screen update
  xschem set no_undo 1 ;# disable undo 
  set fd [open $file "w"]
  hier_traversal $fd 0 $only_subckts
  xschem set no_draw 0
  xschem set no_undo 0
  close $fd
}

# return "$n * $indent" spaces
proc spaces {n} {
  set indent 4
  set n [expr {$n * $indent}]
  # return [format %${n}s {}]
  return [string repeat { } $n]
}

# recursive procedure
proc hier_traversal {fd {level 0} only_subckts} {
  global nolist_libs
  set done_print 0
  set schpath [xschem get sch_path]
  set instances  [xschem get instances]
  set current_level [xschem get currsch]
  for {set i 0} { $i < $instances} { incr i} {
    set instname [xschem getprop instance $i name]
    set symbol [xschem getprop instance $i cell::name]
    set abs_symbol [abs_sym_path $symbol]
    set type [xschem getprop symbol $symbol type]
    if {$only_subckts && ($type ne {subcircuit})} { continue }

    set skip 0
    foreach j $nolist_libs {
      if {[regexp $j $abs_symbol]} {
        set skip 1
        break
      }
    }
    if {$skip} { continue }
    puts $fd "[spaces $level]$schpath$instname symbol: $symbol, type: $type"
    set done_print 1
    if {$type eq {subcircuit}} {
      set ninst [lindex [split [xschem expandlabel $instname] { }] 1]
      for {set n 1} {$n <= $ninst} { incr n} {
        # set dp 0
        xschem select instance $i
        # descending ninst times is extremely inefficient
        set descended [xschem descend $n notitle]
        # ensure previous descend was successful
        if {$descended} {
          incr level
          set dp [hier_traversal $fd $level $only_subckts]
          xschem go_back notitle
          incr level -1
        }
        if {!$dp} { break } ;# nothing printed so skip all other vector instances
      }
    }
  }
  return $done_print
}


