set cellPith 116

if {[info exists vars(cpf_file}] && $vars(cpf_file) != " "} {
        set vars(power_damins) [userGetPowerDomains]
        foreach domain $vars(power_domains) {
                if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]] > 0} {
                        addWellTap -cell $vars(welltap_cell) -cellInterval $cellPith -prefix WELLTAP_$domain -checkerBoard -powerDomain $domain
                }
        }
} else {
        addWellTap -cell $vars(welltap_cell) -cellInterval $cellPith -prefix WELLTAP_ -checkerBoard
}
