set inputFile "vio_summary.rpt"
set outputFile "vio_summary1.csv"
set fin [open $inputFile r]
set fout [open $outputFile w]

while {[gets $fin line] != -1} {
	set fields [split $line] 
	set csvLine ""
	foreach field $fields {
		regsub -all {"} $field {""} fieldEscaped
		if {$csvLine eq ""} {
			set csvLine $fieldEscaped
		} else {

			append $csvLine "," fieldEscaped
		}
	}
	puts $fout "$csvLine\n"
}
close $fin
close $fout
