for i in $(cat compute-ip.txt); do
    ssh heat-admin@$i
done

nohup upgrade-non-controller.sh --upgrade compute-0 > compute-0-upgrade.log
