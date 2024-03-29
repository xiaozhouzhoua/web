#!/bin/bash

name=${JOB_NAME}
image=$(cat ${WORKSPACE}/IMAGE)
host=${HOST}

echo "deploying ... name: ${name}, image: ${image}, host: ${host}"

cp $(dirname "${BASH_SOURCE[0]}")/template/web.yaml .

sed -i "s,{{name}},${name},g" web.yaml
sed -i "s,{{image}},${image},g" web.yaml
sed -i "s,{{host}},${host},g" web.yaml

kubectl apply -f web.yaml

cat web.yaml

# 健康检查
success=0
count=60
IFS=","
sleep 10

while [ ${count} -gt 0 ]
do
    replicas=$(kubectl get deploy ${name} -o go-template="{{.status.replicas}},{{.status.updatedReplicas}},{{.status.readyReplicas}},{{.status.availableReplicas}}")
    echo "replicas: ${replicas}"
    arr=(${replicas})
    echo "${arr[*]}"
    if [[ "${arr[0]}" == "${arr[1]}" && "${arr[1]}" == "${arr[2]}" && "${arr[2]}" == "${arr[3]}" ]];then        
        echo "health check success!"
        success=1
        break
    fi   
    ((count--))
    sleep 2
done

if [ ${success} -ne 1 ];then
    echo "health check failed!"
    exit 1
fi
