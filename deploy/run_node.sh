#!/bin/bash
# ***************************
# start psql-xl docker cluter on other node.  
#  !! Be sure run this server before the master one . 
# 
# ***************************

# ******* global args *********
pg_cluster=postgresql    # network name. 
server2_node=("proxy_2" "coord_2" "data_6" "data_7" "data_8" "data_9" "data_10")
pg_data=/var/lib/postgresql
pg_image="registry.cn-qingdao.aliyuncs.com/kingsoft/postgres-xl"
gtm_name_1=${pg_cluster}_gtm_1
create_sql=""
alert_sql=""


# prapare all images
docker pull ${pg_image}-gtm:0.1.0 
docker pull ${pg_image}-proxy:0.1.0
docker pull ${pg_image}-coord:0.1.0
docker pull ${pg_image}-data:0.1.0
# init node volume in server2.
echo "[+] init server1  . "

sleep 1

for node in ${server2_node[@]} ; do
    image_type=` echo "${node}" | cut -d "_" -f1 `
echo " |- [+] create ${pg_cluster}_${node} node in ${image_type} type. "
    case ${image_type} in
        "gtm")
            gtm_name_1=${pg_cluster}_${node}    # 理论上是不存在第二个gtm节点的。。

            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_GTM_NODE=${node}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1
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

           ;;          #.....
        "coord")

            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_COORD_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1

           ;;          #.....
        "data")
            docker run \
                -v ${pg_cluster}_${node}:${pg_data} \
                --env "PG_DATA_NODE=${node}" \
                --env "PG_GTM_HOST=${proxy_name_1}" \
                --rm ${pg_image}-${image_type}:0.1.0 \
                ./init.sh
                
            sleep 1
          ;;          #.....

    esac
    sleep 2
done 
echo " |-done."

