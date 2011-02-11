#!/bin/sh
echo "educ_kerberos_settings.sh - v0.1 ("`date`")"

echo "[libdefaults]
	default_realm = dce.psu.edu
	dns_fallback = yes
[domain_realm]
	.educ.psu.edu = EDUC.PSU.EDU
        .pass.psu.edu = dce.psu.edu
        cifs.pass.psu.edu = dce.psu.edu
		nfs.pass.psu.edu = dce.psu.edu
        udrive.win.psu.edu = dce.psu.edu
        .win.psu.edu = dce.psu.edu
[logging]
	kdc = FILE:/var/log/krb5kdc/kdc.log
	admin_server = FILE:/var/log/krb5kdc/kadmin.log" > /Library/Preferences/edu.mit.kerberos

echo "educ_kerberos_settings.sh - end"
exit 0
