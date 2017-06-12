to run:

1.
ssh into beaglebone as root: (ssh 192.168.7.2 -l root)
navigate to home pru_adc folder : (cd ~/pru_adc)

2.
run these commands in ordeR:
  make clean  
  make  
  cp BB-BONE-HSADC-00A0.dtbo /lib/firmware/  
  source install_hsadc_cape.sh

3.  
Then run this to run the app:
  ./adc_app


The code is setup to automaticaly run the code without cnvst. This can be changed
to use the older code with cnvst by running 'cp prefinal_code.p prucode_adc.p'
