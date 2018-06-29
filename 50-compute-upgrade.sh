./timestamp-ping.sh 50-compute-upgrade-$i-begin
for i in $(cat ~/compute-ip.txt); do
    grep -q ${i} ~/.ssh/known_hosts || ssh-keyscan -t rsa ${i} >> ~/.ssh/known_hosts
    nohup upgrade-non-controller.sh --upgrade $i > ~/compute-${i}-upgrade.log &
done
wait
./timestamp-ping.sh 50-compute-upgrade-$i-end
