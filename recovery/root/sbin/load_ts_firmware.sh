#!/system/bin/sh

module_path=/sbin/modules

touch_class_path=/sys/class/touchscreen
touch_path=
firmware_path=/vendor/firmware
firmware_file=
device=$(getprop ro.boot.device)

wait_for_poweron()
{
	local wait_nomore
	local readiness
	local count
	wait_nomore=60
	count=0
	while true; do
		readiness=$(cat $touch_path/poweron)
		if [ "$readiness" == "1" ]; then
			break;
		fi
		count=$((count+1))
		[ $count -eq $wait_nomore ] && break
		sleep 1
	done
	if [ $count -eq $wait_nomore ]; then
		return 1
	fi
	return 0
}

# Load all needed modules
insmod $module_path/sensors_class.ko
insmod $module_path/fpc1020_mmi.ko
insmod $module_path/utags.ko
insmod $module_path/exfat.ko
insmod $module_path/mmi_annotate.ko
insmod $module_path/mmi_info.ko
insmod $module_path/mmi_sys_temp.ko
insmod $module_path/moto_f_usbnet.ko
insmod $module_path/qpnp-power-on-mmi.ko
insmod $module_path/qpnp-smbcharger-mmi.ko
insmod $module_path/tas2562.ko
insmod $module_path/tps61280.ko

if [ $device = "rav" ] || [ $device = "rav_t" ]
then
        insmod $module_path/focaltech_0flash_mmi_rav.ko
else
        insmod $module_path/focaltech_0flash_mmi.ko
fi

insmod $module_path/nova_0flash_mmi.ko
insmod $module_path/himax_v2_mmi_hx83112.ko
insmod $module_path/himax_v2_mmi.ko

is_auo=$(cat /proc/cmdline | grep "ft8756_auo")

cd $firmware_path
touch_product_string=$(ls $touch_class_path)
case $touch_product_string in
    ft8756)
        case $device in
            sofia)
                insmod $module_path/aw8695.ko
                firmware_file="focaltech-tianma-ft8756-0b-01-sofia.bin"
                ;;
            sofiar)
                insmod $module_path/aw8624.ko
                firmware_file="focaltech-ft8756-0d-01-sofiar.bin"
                ;;
            sofiap | sofiap_ao | sofia_t)
                insmod $module_path/aw8695.ko
                insmod $module_path/bu520xx_pen.ko
                if [ -z "$is_auo" ]; then
                    firmware_file="focaltech-tianma-ft8756-11-01-sofiap.bin"
                else
                    firmware_file="focaltech-auo-ft8756-0b-01-sofiap.bin"
                fi
        esac
        ;;
    himax_touchscreen)
        case $device in
            rav | rav_t)
                insmod $module_path/aw8695.ko
                firmware_file="inxr_Himax_firmware.bin"
                ;;
        esac
        ;;
    ft8009)
        case $device in
            rav | rav_t)
                insmod $module_path/aw8695.ko
                firmware_file="focaltech-boev-ft8009-0e-0000-rav.bin"
                ;;
        esac
        ;;
    *)
        if [ $device = "rav" ] || [ $device = "rav_t" ]
        then
            mv novatek_ts_fw_rav.bin novatek_ts_fw.bin
            mv novatek_ts_mp_rav.bin novatek_ts_mp.bin
        else
            mv novatek_ts_fw_sofia.bin novatek_ts_fw.bin
            mv novatek_ts_mp_sofia.bin novatek_ts_mp.bin
        fi
        firmware_file="novatek_ts_fw.bin"
        echo 1 > /proc/nvt_update
        ;;
esac

touch_path=/sys$(cat $touch_class_path/$touch_product_string/path | awk '{print $1}')
wait_for_poweron
echo $firmware_file > $touch_path/doreflash
echo 1 > $touch_path/forcereflash
sleep 5
echo 1 > $touch_path/reset

return 0

