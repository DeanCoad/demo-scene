#!/bin/zsh

for i in {01..10}; do
    ip=$(aws2 ecs list-container-instances --cluster qcon-ldn-workshop-$i|jq '.containerInstanceArns[]'|\
    xargs -IFOO aws2 ecs describe-container-instances --container-instances FOO --cluster qcon-ldn-workshop-$i|jq '.containerInstances[].ec2InstanceId'|\
    xargs -IFOO aws2 ec2 describe-instances --filter "Name=instance-id,Values=FOO" | jq -r '.Reservations[].Instances[].PublicIpAddress')

    echo -e "\n👾 IP: " $ip " (cluster "$i")"
    ssh_alive=$(nc -vz -G 10 $ip 22 2>&1)
    ssh_alive_result=$?
    if [ $ssh_alive_result -eq 0 ]; then
        echo $ip "✅✅UP ssh (22) " $ssh_alive
        kibana_alive=$(nc -vz -G 10 $ip 5601 2>&1)
        kibana_alive_result=$?
        if [ $kibana_alive_result -eq 0 ]; then
            echo $ip "✅✅UP kibana (5601) " $kibana_alive

            kibana_api_status=$(curl -s http://$ip:5601/api/kibana/settings)
            if [[ $kibana_api_status == 'Kibana server is not ready yet' ]] ; then
                echo $ip "❌❌DOWN kibana (api) " $kibana_api_status
            else
                echo $ip "✅✅UP kibana (api) " $kibana_api_status
            fi
        else
            echo $ip "❌❌DOWN kibana (5601) " $kibana_alive
        fi
    else
        echo $ip "❌❌DOWN ssh (22) " $ssh_alive
    fi
done
