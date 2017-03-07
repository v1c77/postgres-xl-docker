#!/bin/bash

server1_node=("gtm_1" "proxy_1" "coord_1" "data_1" "proxy_2" "coord_2" "data_2")  # gtm 必须在第一位。proxy 在第二位
server2_node=("proxy_2" "coord_2" "data_2")
pg_data=/var/lib/postgresql
pg_image=woailuoli993/postgres-xl
pg_cluster=postgresql-a  
create_sql=""
alter_sql=""

if [ $# -eq 1 ] && [ "$1" == "net" ];then
echo "parameter 1: $#"
exit 0 
fi

for node in ${server1_node[@]} ; do
image_type=` echo "${node}" | cut -d "_" -f1 `
    case ${image_type} in
        "gtm")
            ;;          #.....
        "proxy")
           ;;          #.....
        "coord")
        create_sql=${create_sql}$'\n'"CREATE NODE ${node} WITH (TYPE = "'coordinator'", HOST = '"${pg_cluster}-${node}"', PORT = 5432);"
           ;;          #.....
        "data")
        create_sql=${create_sql}$'\n'"CREATE NODE ${node} WITH (TYPE = "'coordinator'", HOST = '"${pg_cluster}-${node}"', PORT = 5432);"
        alter_sql="${alter_sql}""ALTER NODE ${node} WITH (TYPE = 'datanode');"$'\n'
          ;;          #.....

    esac
done 
echo " ------done."

echo "just cmd 'docker exec -it \$(docker ps -q -f name={your coords and datas nodename }) /bin/bash '"
echo "cmd >>> psql"
echo "push this code."
alter_sql=${alter_sql}"SELECT pgxc_pool_reload();"
echo "${create_sql}"
echo "${alter_sql}"
