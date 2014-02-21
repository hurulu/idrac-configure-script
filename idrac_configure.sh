#Tested on Dell R620 server with iDRAC 7, this script is run under a winxp with racadm installed
host=$1

echo "#################################Deleting the existing vdisks#########################################"
#Deleting the existing vdisks
for i in 0 1 2 3 4 5
do
        echo "############## $i ##############"
        racadm -r $host -u root -p calvin raid deletevd:Disk.Virtual.$i:RAID.Integrated.1-1
        sleep 10
done
racadm -r $host -u root -p calvin jobqueue create RAID.Integrated.1-1
racadm -r $host -u root -p calvin serveraction powercycle
sleep 600

echo "#################################Create new vdisks#########################################"
#Create new vdisks
for i in 0 1 2 3 4 5
do
        echo "############## $i ##############"
        racadm -r $host -u root -p calvin raid createvd:RAID.Integrated.1-1 -rl r0 -wp wb -rp ara -ss 64k -pdkey:Disk.Bay.$i:Enclosure.Internal.0-1:RAID.Integrated.1-1
        sleep 30
done
racadm -r $host -u root -p calvin jobqueue create RAID.Integrated.1-1
racadm -r $host -u root -p calvin serveraction powercycle
sleep 600


echo "#################################Init vdisks#########################################"
#init vdisks
for i in 0 1 2 3 4 5
do
        echo "############## $i ##############"
        racadm -r $host -u root -p calvin raid init:Disk.Virtual.$i:RAID.Integrated.1-1
        sleep 30
done
racadm -r $host -u root -p calvin jobqueue create RAID.Integrated.1-1
racadm -r $host -u root -p calvin serveraction powercycle


sleep 600


#partition vflash SD
echo "#################################Init vflashSD#########################################"
racadm -r $host -u root -p calvin vflashsd initialize
sleep 300
echo "#################################Create vflashSD partitions#########################################"
index=1
for i in ROOT VAR LOG LOCAL
do
        echo "############## $i ##############"
        if [ $i == "LOCAL" ];then
                size=2500
        else
                size=4096
        fi
        racadm -r $host -u root -p calvin vflashpartition create -i $index -o $i -e HDD -t empty -f ext3 -s $size
        index=`expr $index + 1 `
        sleep 100
done
sleep 1200
#Attach vflash paritions to system
echo "#################################Attach vflashSD partitions#########################################"
for i in 1 2 3 4
do
        echo "############## $i ##############"
        racadm -r $host -u root -p calvin set iDRAC.vflashpartition.$i.AttachState 1
        sleep 100
done

sleep 100
echo "#################################Setting NIC LegacyBootProto#########################################"
for i in 1 2 3 4
do
        echo "############## $i ##############"
        if [ $i -eq 3 ];then
                value="PXE"
        else
                value="NONE"
        fi
        racadm -r $host -u root -p calvin set NIC.NICConfig.$i.LegacyBootProto $value
        sleep 30
        #racadm -r $host -u root -p calvin get NIC.NICConfig.$i.LegacyBootProto
        racadm -r $host -u root -p calvin jobqueue create NIC.Integrated.1-$i-1
done
sleep 10
racadm -r $host -u root -p calvin serveraction powercycle
sleep 600

echo "#################################Setting Boot from flashSD root#########################################"
racadm -r $host -u root -p calvin set BIOS.BiosBootSettings.HddSeq Disk.vFlash.ROOT-1,RAID.Integrated.1-1,,Disk.vFlash.VAR-1,Disk.vFlash.LOG-1,Disk.vFlash.LOCAL-1
racadm -r $host -u root -p calvin jobqueue create BIOS.Setup.1-1
sleep 10
racadm -r $host -u root -p calvin serveraction powercycle

#sleep 600
#echo "#################################Set Next boot PXE#########################################"
#Set next boot from PXE
#racadm -r $host -u root -p calvin set iDRAC.serverboot.FirstBootDevice PXE
#sleep 10
#racadm -r $host -u root -p calvin serveraction powercycle
