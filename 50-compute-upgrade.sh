for i in $(cat compute-ip.txt); do
    ssh heat-admin@$i
    nohup upgrade-non-controller.sh --upgrade $i > ~/compute-${i}-upgrade.log &
    disown
done
