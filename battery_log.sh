#!/bin/sh

function print_battery_status {
  # force ADC enable for battery voltage and current
  /usr/sbin/i2cset -y -f 0 0x34 0x82 0xC3

  ################################
  #read Power status register @00h
  POWER_STATUS=$(/usr/sbin/i2cget -y -f 0 0x34 0x00)
  #echo $POWER_STATUS

  BAT_STATUS=$(($(($POWER_STATUS&0x02))/2))  # divide by 2 is like shifting rigth 1 times
  #echo $(($POWER_STATUS&0x02))
  #echo "BAT_STATUS="$BAT_STATUS
  # echo $BAT_STATUS

  ################################
  #read Power OPERATING MODE register @01h
  POWER_OP_MODE=$(/usr/sbin/i2cget -y -f 0 0x34 0x01)
  #echo $POWER_OP_MODE

  CHARG_IND=$(($(($POWER_OP_MODE&0x40))/64))  # divide by 64 is like shifting rigth 6 times
  #echo $(($POWER_OP_MODE&0x40))
  #echo "CHARG_IND="$CHARG_IND
  # echo $CHARG_IND

  BAT_EXIST=$(($(($POWER_OP_MODE&0x20))/32))  # divide by 32 is like shifting rigth 5 times
  #echo $(($POWER_OP_MODE&0x20))
  #echo "BAT_EXIST="$BAT_EXIST
  # echo $BAT_EXIST

  ################################
  #read Charge control register @33h
  CHARGE_CTL=$(/usr/sbin/i2cget -y -f 0 0x34 0x33)
  #echo "CHARGE_CTL="$CHARGE_CTL
  # echo $CHARGE_CTL


  ################################
  #read Charge control register @34h
  CHARGE_CTL2=$(/usr/sbin/i2cget -y -f 0 0x34 0x34)
  #echo "CHARGE_CTL2="$CHARGE_CTL2
  # echo $CHARGE_CTL2


  ################################
  #read battery voltage	79h, 78h	0 mV -> 000h,	1.1 mV/bit	FFFh -> 4.5045 V
  BAT_VOLT_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x78)
  BAT_VOLT_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x79)

  #echo $BAT_VOLT_MSB $BAT_VOLT_LSB
  # bash math -- converts hex to decimal so `bc` won't complain later...
  # MSB is 8 bits, LSB is lower 4 bits
  BAT_BIN=$(( $(($BAT_VOLT_MSB << 4)) | $(($(($BAT_VOLT_LSB & 0x0F)) )) ))

  BAT_VOLT=$(echo "($BAT_BIN*1.1)"|bc)

  ###################
  #read Battery Discharge Current	7Ch, 7Dh	0 mV -> 000h,	0.5 mA/bit	1FFFh -> 1800 mA
  #AXP209 datasheet is wrong, discharge current is in registers 7Ch 7Dh
  #13 bits
  BAT_IDISCHG_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7C)
  BAT_IDISCHG_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7D)

  #echo $BAT_IDISCHG_MSB $BAT_IDISCHG_LSB

  BAT_IDISCHG_BIN=$(( $(($BAT_IDISCHG_MSB << 5)) | $(($(($BAT_IDISCHG_LSB & 0x1F)) )) ))

  BAT_IDISCHG=$(echo "($BAT_IDISCHG_BIN*0.5)"|bc)

  ###################
  #read Battery Charge Current	7Ah, 7Bh	0 mV -> 000h,	0.5 mA/bit	FFFh -> 1800 mA
  #AXP209 datasheet is wrong, charge current is in registers 7Ah 7Bh
  #(12 bits)
  BAT_ICHG_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7A)
  BAT_ICHG_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7B)

  BAT_ICHG_BIN=$(( $(($BAT_ICHG_MSB << 4)) | $(($(($BAT_ICHG_LSB & 0x0F)) )) ))

  BAT_ICHG=$(echo "($BAT_ICHG_BIN*0.5)"|bc)

  ###################
  #read internal temperature 	5eh, 5fh	-144.7c -> 000h,	0.1c/bit	FFFh -> 264.8c
  TEMP_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x5e)
  TEMP_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x5f)

  # bash math -- converts hex to decimal so `bc` won't complain later...
  # MSB is 8 bits, LSB is lower 4 bits
  TEMP_BIN=$(( $(($TEMP_MSB << 4)) | $(($(($TEMP_LSB & 0x0F)) )) ))
  TEMP_C=$(echo "($TEMP_BIN*0.1-144.7)"|bc)

  ###################
  #read fuel gauge B9h
  BAT_GAUGE_HEX=$(/usr/sbin/i2cget -y -f 0 0x34 0xb9)

  # bash math -- converts hex to decimal so `bc` won't complain later...
  # MSB is 8 bits, LSB is lower 4 bits
  BAT_GAUGE_DEC=$(($BAT_GAUGE_HEX))

  #echo "Battery discharge current = "$BAT_IDISCHG"mA"
  ##echo "Battery charge current = "$BAT_ICHG"mA"
  #echo "Internal temperature = "$TEMP_C"c"
  #echo "Battery voltage = "$BAT_VOLT"mV"
  #echo "Battery gauge = "$BAT_GAUGE_DEC"%"

  echo $BAT_IDISCHG $BAT_ICHG $TEMP_C $BAT_VOLT $BAT_GAUGE_DEC
}

date
while true; do
  print_battery_status
  sleep 60
done
