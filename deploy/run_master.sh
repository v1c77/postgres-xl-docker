#!/bin/bash
# ***************************
# start psql-xl docker cluter
# 
# ***************************

# ******* global args *********
pg_cluster=postgresql    # network name. 
server1_node=("gtm_1" "proxy_1" "coord_1" "data_1" "data_2" "data_3" "data_4" "data_5")  # gtm 必须在第一位。proxy 在第二位
server2_node=("proxy_2" "coord_2" "data_6" "data_7" "data_8" "data_9" "data_10")    # [!!!]  THIS VARIABLE MUST BE EQUAL TO THE ‘run_node.sh’ ONE . 
pg_data=/var/lib/postgresql
pg_image="registry.cn-qingdao.aliyuncs.com/kingsoft/postgres-xl"
pg_server1="buvrerm18upec1098ywnen85f"
pg_server2="cczydk502cu8j5d2qt72iwhku"
pg_port=25432
create_sql=""
alert_sql=""

# prapare all images
docker pull ${pg_image}-gtm:0.1.0 
docker pull ${pg_image}-proxy:0.1.0
docker pull ${pg_image}-coord:0.1.0
docker pull ${pg_image}-data:0.1.0

 
if [ $# -eq 1 ] && [ "$1" == "net" ];then
# step 1. create overlay network 
    echo "[+] create ${pg_cluster} overlay network . "
    docker network create \
        -d overlay \
        --internal \
        --opt encrypted \
        $pg_cluster
    
    sleep 1
    echo "-- done . "
    exit 0 
fi

# step 2. create cluster node on master swarm nodo
echo "[+] init server1  . "

sleep 1

for node in ${server1_node[@]} ; do
    image_type=` echo "${node}" | cut -d "_" -f1 `
echo " |- [+] create ${pg_cluster}_${node} node in ${image_type} type. "
    case ${image_type} in
        "gtm")
            gtm_name_1=${pg_cluster}_${node} 

            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_GTM_NODE=${node}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1

            docker service create \
               --name ${pg_cluster}_${node} \
               --network ${pg_cluster} \
               --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server1}" \
               --env "PG_GTM_NODE=${node}" \
               ${pg_image}-${image_type}:0.1.0

            ;;          
        "proxy")
            proxy_name_1=${pg_cluster}_${node}

            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_PROXY_NODE=${node}" \
                --env "PG_GTM_HOST=${gtm_name_1}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1

            docker service create \
               --name ${pg_cluster}_${node} \
               --network ${pg_cluster} \
               --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server1}" \
               --env "PG_PROXY_NODE=${node}" \
               --env "PG_GTM_HOST=${gtm_name_1}" \
               ${pg_image}-${image_type}:0.1.0
           ;;          #.....
        "coord")

            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_COORD_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1

            docker service create \
                --name ${pg_cluster}_${node} \
                --network ${pg_cluster} \
                --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server1}" \
                --env "PG_COORD_NODE=${node}" \
                --publish $pg_port:5432 \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                ${pg_image}-${image_type}:0.1.0

            pg_port=$(($pg_port+1))

            create_sql=${create_sql}$'\n'"CREATE NODE ${node} WITH (TYPE = "'coordinator'", HOST = '"${pg_cluster}_${node}"', PORT = 5432);"
           ;;          #.....
        "data")
            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_DATA_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1

            docker service create \
                --name ${pg_cluster}_${node} \
                --network ${pg_cluster} \
                --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server1}" \
                --env "PG_DATA_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                ${pg_image}-${image_type}:0.1.0

            create_sql=${create_sql}$'\n'"CREATE NODE ${node} WITH (TYPE = "'coordinator'", HOST = '"${pg_cluster}_${node}"', PORT = 5432);"
            alter_sql="${alter_sql}""ALTER NODE ${node} WITH (TYPE = 'datanode');"$'\n'

          ;;          #.....

    esac
    sleep 2
done 
echo " |-done."


# step 3. create cluster node on second swarm node

for node in ${server2_node[@]} ; do
    image_type=` echo "${node}" | cut -d "_" -f1 `
echo " |- [+] create ${pg_cluster}_${node} node in ${image_type} type. "
    case ${image_type} in
        "gtm")
            gtm_name_1=${pg_cluster}_${node} 

            docker service create \
                --name ${pg_cluster}_${node} \
                --network ${pg_cluster} \
                --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server2}" \
                --env "PG_GTM_NODE=${node}" \
               ${pg_image}-${image_type}:0.1.0

            ;;          
        "proxy")
            proxy_name_1=${pg_cluster}_${node}

            docker service create \
               --name ${pg_cluster}_${node} \
               --network ${pg_cluster} \
               --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server2}" \
               --env "PG_PROXY_NODE=${node}" \
               --env "PG_GTM_HOST=${gtm_name_1}" \
               ${pg_image}-${image_type}:0.1.0
           ;;          #.....
        "coord")

            docker service create \
                --name ${pg_cluster}_${node} \
                --network ${pg_cluster} \
                --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server2}" \
                --env "PG_COORD_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                --publish $pg_port:5432 \
                ${pg_image}-${image_type}:0.1.0


            pg_port=$(($pg_port+1))
            create_sql=${create_sql}$'\n'"CREATE NODE ${node} WITH (TYPE = "'coordinator'", HOST = '"${pg_cluster}_${node}"', PORT = 5432);"
           ;;          #.....
        "data")

            docker service create \
                --name ${pg_cluster}_${node} \
                --network ${pg_cluster} \
                --mount type=volume,src=${pg_cluster}_${node},dst=$pg_data \
                --constraint "node.id==${pg_server2}" \
                --env "PG_DATA_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                ${pg_image}-${image_type}:0.1.0

            create_sql=${create_sql}$'\n'"CREATE NODE ${node} WITH (TYPE = "'coordinator'", HOST = '"${pg_cluster}_${node}"', PORT = 5432);"
            alter_sql="${alter_sql}""ALTER NODE ${node} WITH (TYPE = 'datanode');"$'\n'

          ;;          #.....

    esac
    sleep 2
done
# test module


echo "***************************************************************"
echo "just cmd 'docker exec -it \$(docker ps -q -f name={your coords and datas nodename }) /bin/bash '"
echo "cmd >>> psql"
echo "push this code."
alter_sql=${alter_sql}"SELECT pgxc_pool_reload();"$'\n'
alter_sql=${alter_sql}"SELECT * FROM pgxc_node;" 

echo "${create_sql}"
echo "${alter_sql}"
echo "***************************************************************"