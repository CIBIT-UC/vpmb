
# Flirt using corrratio
flirt -in funcImage-bold -ref refImage-t1w -cost corratio -omat func2ref_corratio -out func2ref_corratio

# Flirt using normmmi
flirt -in funcImage-bold -ref refImage-t1w -cost normmi -omat func2ref_normmi -out func2ref_normmi

# Flirt using bbr
flirt -in funcImage-bold -ref refImage-t1w -cost bbr -wmseg wmMask -omat func2ref_bbr -out func2ref_bbr

### MEASURE
# (1,1)
flirt -in funcImage-bold -ref refImage-t1w -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost corratio -init func2ref_corratio
# (1,2)
flirt -in funcImage-bold -ref refImage-t1w -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost normmi -init func2ref_corratio
# (1,3)
flirt -in funcImage-bold -ref refImage-t1w -wmseg wmMask -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost bbr -init func2ref_corratio
# (2,1)
flirt -in funcImage-bold -ref refImage-t1w -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost corratio -init func2ref_normmi
# (2,2)
flirt -in funcImage-bold -ref refImage-t1w -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost normmi -init func2ref_normmi
# (2,3)
flirt -in funcImage-bold -ref refImage-t1w -wmseg wmMask -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost bbr -init func2ref_normmi
# (3,1)
flirt -in funcImage-bold -ref refImage-t1w -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost corratio -init func2ref_bbr
# (3,2)
flirt -in funcImage-bold -ref refImage-t1w -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost normmi -init func2ref_bbr
# (3,3)
flirt -in funcImage-bold -ref refImage-t1w -wmseg wmMask -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost bbr -init func2ref_bbr
