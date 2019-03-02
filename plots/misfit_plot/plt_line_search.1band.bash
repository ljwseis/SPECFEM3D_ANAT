#!/bin/bash
#        ! KEY: write misfit function values to file (two for each window)
#        ! Here are the 20 columns of the vector window_chi
#        !  1: MT-TT chi,    2: MT-dlnA chi,    3: XC-TT chi,    4: XC-dlnA chi
#        !  5: MT-TT meas,   6: MT-dlnA meas,   7: XC-TT meas,   8: XC-dlnA meas
#        !  9: MT-TT error, 10: MT-dlnA error, 11: XC-TT error, 12: XC-dlnA error
#        ! WINDOW     : 13: data power, 14: syn power, 15: (data-syn) power, 16: window duration
#        ! FULL RECORD: 17: data power, 18: syn power, 19: (data-syn) power, 20: record duration
#        ! Example of a reduced file: awk '{print $2,$3,$4,$5,$6,$31,$32}' window_chi > window_chi_sub
 
#gmtset ANOT_FONT_SIZE_PRIMARY 10
#gmtset LABEL_FONT_SIZE 12
mod=$1
out=mis_${mod}_linesearch.ps
range=-R-0.01/0.16/0.0/2.0
xtick=a0.04f0.01
ytick=a0.4
xc=`echo $range |awk '{print substr($1,3)}' |awk -F/ '{print ($2+$1)/2}'`
yc=`echo $range |awk '{print substr($1,3)}' |awk -F/ '{print $4*1.05}'`
newmod=`echo $mod |awk -FM '{printf"M%s\n",$2+1}'`
iternum=`echo $mod |awk -FM '{printf"%d\n",$2-15}'`

for band in T020_T050;do
  echo $band
  cat /dev/null >$mod.$band.mis
# calculate misfit of step 0.00
  sumf=0.0
  sumn=0
  cat ../../src_rec/sources_ls.dat |awk '{printf"%s.%s\n",$2,$1}' >eid.dat
  for eid in `cat eid.dat`;do
    #eid=`echo $line |awk '{printf"%s.%s",$2,$1}'`
    misf=`cat ../../output/misfits/$mod/${mod}.set*_${band}_${eid}_window_chi |awk 'BEGIN{sum=0;} {if($29!=0) {sum=sum+$29}} END{print sum}' `
    nmeas=`cat ../../output/misfits/$mod/${mod}.set*_${band}_${eid}_window_chi |awk 'BEGIN{n=0;} {if($29!=0) {n=n+1}} END{print n}' `
    sumf=`echo $sumf + $misf |bc -l`
    sumn=`echo $sumn + $nmeas |bc -l`
    echo $eid $sumf $sumn
  done

  echo $band $sumf $sumn
  sum=`echo $sumf $sumn |awk '{print $1/$2}'`
  echo 0.0 $sum $sumf $sumn >>$mod.$band.mis
  #for step in `seq 0.02 0.02 0.14`;do
  for step in 0.02 0.04 0.06 0.08;do
    input=chi_${mod}_slen${step}_${band}.dat
    cat /dev/null >$input
    for file in `ls ../../output/misfits/${mod}/${mod}_slen${step}_${band}_*_chi`;do
      evt=`echo $file |awk -F../../output/misfits/${mod}/ '{print $2}' |awk -F_ '{print $4 }'`
# MTTT dT & sigma
#    cat $file |awk '{print a,$1,$13,$17}' a=$evt >>$input.all
#    cat $file |awk '{if($15*$15>0) print a,$1,$13,$17}' a=$evt >>$input
# XCTT dT & sigma
#    cat $file |awk '{print a,$1,$15,$19}' a=$evt >>$input.all
#    cat $file |awk '{if($15*$15>0) print a,$1,$15,$19}' a=$evt >>$input
## MTTT
#      cat $file |awk '{print a,$1,$9}' a=$evt >>$input.all
#      cat $file |awk '{if($9>0) print a,$1,$9}' a=$evt >>$input
## XCTT
#      cat $file |awk '{print a,$1,$11}' a=$evt >>$input.all
#      cat $file |awk '{if($9>0) print a,$1,$11}' a=$evt >>$input
## chi value final (MTTT & XCTT)
      cat $file |awk '{print a,$1,$29}' a=$evt >>$input.all
      cat $file |awk '{if($29!=0) print a,$1,$29}' a=$evt >>$input
#
    done 
    sc=chi_${mod}_slen${step}_${band}*.dat
### For MTTT/XCTT chi value
    misf=`cat $sc |awk 'BEGIN{sum=0;n=0} {if($3>0) {sum=sum+$3;n=n+1}} END{print sum/n}'`
### MTTT/XCTTT dt and sigma, chi value 
#    misf=`cat $sc |awk 'BEGIN{sum=0;n=0} {if($3*$3>0) {sum=sum+$3*$3/$4/$4;n=n+1}} END{print sum/n}'`
    echo $step $misf >>$mod.$band.mis
  done
done 
rm chi_${mod}_slen*_${band}*

#psbasemap -JX9 $range -B"$xtick":"step length":/"$ytick":"misfits (s)":WSne -K -P -X4 -Y18 > $out
psbasemap -JX11.7/8.3 $range -B"$xtick":"step length":/"$ytick":"misfits (s)":WSne -K -P -X4 -Y18 > $out
pstext -J -R -N -K -O >>$out <<eof
$xc $yc 16 0 0 CM ${iternum}stIT: $mod to $newmod 
eof

cat $mod.T020_T050.mis |awk '{print $1,$2}' |psxy -JX -R -St0.25 -Gred -O -K >> $out
### plot legend
pslegend -J -R -D0.0/2.1/7.7/0.7/LT -F -O <<eof >>$out
S 0.3c t 0.15i red black 0.6c 20_50 s band
S 0.3c d 0.15i blue black 0.6c 10_50 s band
S 0.3c c 0.15i yellow black 0.6c 5_50 s band
S 0.3c a 0.15i darkgreen black 0.6c 20_50 and 10_50 s band
S 0.3c h 0.15i purple black 0.6c 20_50, 10_50 and 5-50 s band
eof
cat /dev/null |psxy -J -R -O >> $out

exit
ifig=1
for band in T020_T050;do
  #echo ifig=$ifig: $band
  if [ $ifig -eq 1 ];then
     #psbasemap -JX9 $range -B"$xtick":"step length":/"$ytick":"misfits (s)":WSne -K -P -Y18 > $out
     psbasemap -JX11.7/8.3 $range -B"$xtick":"step length":/"$ytick":"misfits (s)":WSne -K -P -Y18 > $out
     pstext -J -R -N -K -O >>$out <<eof
$xc $yc 12 0 0 CM $iternum: $mod to $newmod 
eof
     cat $mod.$band.mis |psxy -JX -R -St0.25 -Gred -O -K >> $out
  elif [ $ifig -lt 3 ];then
     psbasemap -JX5 $range -B"$xtick":"step length":/"$ytick":"misfits (s)":wSne -K -O -X5.5 >> $out
     pstext -J -R -N -K -O >>$out <<eof
$xc $yc 12 0 0 CM $band
eof
     cat $mod.$band.mis |psxy -JX -R -Sa0.25 -Gblue -O -K >> $out
  else
     psbasemap -JX5 $range -B"$xtick":"step length":/"$ytick":"misfits (s)":wSnE -K -O -X5.5 >> $out
     pstext -J -R -N -K -O >>$out <<eof
$xc $yc 12 0 0 CM $band
eof
     cat $mod.$band.mis |psxy -JX -R -Sa0.25 -Gblue -O -K >> $out
  fi
  let ifig=ifig+1
  cat $mod.$band.mis |awk '{print $1}' |sort -n >slen.dat
done

cat /dev/null |psxy -J -R -O >> $out

