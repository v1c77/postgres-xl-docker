# postgres-xl-docker 自动化部署。
-------

 


```                                                                                                    
                                                                                                    +-------------------------+
                                                                                                    |                         |
                                                                                                    |                         |
                                                                                                    |         clients         |
                                                +--------------+                                    |                         |
                                                |              |                                    |                         |
                                                |    gtm_1     |                                    +----------+XX+-----------+
                                                |              |                                              XXX
                                                +------^-------+                                             XX
                                                       |                                                    XX
                                                       |                                                 XXX
                                                       |                                                XX
                                +--------------+       |       +--------------+                       XXX
                                |              |       |       |              |                    XXX
                                | gtm_proxy_1  <-------+------->  gtm_proxy_2 |                XXXXX
                                |              |               |              |        XXXXXXXXX
                                +-----^--------+               +-------^------+      XXX
                                      |                                |            XX
                     ^----------------v-----^-------------------------^v----------+XX+-----^
                     |                      |                         |                    |
                     |                      |                         |                    |
              +------v-------+       +------v-------+          +------v-------+      +-----v--------+
              |              |       |              |          |              |      |              |
              |   coord_1    |       |   coord_2    |          |   coord_3    |      |    coord_4   |        +    +    +
              |              |       |              |          |              |      |              |
              +------+-------+       +------+-------+          +------+-------+      +------+-------+
                     |                      |                         |                     |
             +-------+-------+--------------+--+------------------+---+---------------+-----+----------+
             |               |                 |                  |                   |                |
        +----v-----+    +----v-----+     +-----v---+          +---v-----+        +----v----+       +---v-----+
        |          |    |          |     |         |          |         |        |         |       |         |
        |  data_1  |    |  data_2  |     |  data3  |          |  data4  |        |  data5  |       |  data6  |       +    +    +
        |          |    |          |     |         |          |         |        |         |       |         |
        +----------+    +----------+     +---------+          +---------+        +---------+       +---------+


```

## Change log
- ️⌚️ 2017-3-3
    - 完成 v0.1 脚本，增加必要的步骤控制。并按节点拆分。
    - 完善 部署文档及测试文档。


- ️⌚️ 2017-2-28
    - test new version of postgre-xl docker(0.2.0)

- ️⌚️ 2017-2-22
    - init 
    - add `pg_xl_*` files, 无参数构建方式。

## 说明
- 脚本默认配置为 1 gtm， 2 proxy, 2coord，10 data, 集群。
- 默认 起始 coord 端口 25432，依次顺延。

## 依赖：

- docker, docker swarm 集群


## 部署 （脚本位于`deploy`文件夹）
> 运行前 可以调整 `run_master.sh` 及 `run_onde.sh` 脚本中的集群节点启动个数。 及 swarm 节点id。

### 1. 初始化集群网络
```bash
./run_master.sh net
```
### 2. 初始化子节点

在子节点服务器上运行：
```
./run_node.sh
```

### 3. 注册集群节点。
返回集master_node, 运行
```
./run_master.sh
```
如果运行成功，脚本将会返回psql节点更新语句。

更新方法为：

节点注册成功后使用 ` docker exec -it $(docker ps -q -f name=***) /bin/bash` 命令, 依次进入集群中全部coord及data 节点，更新集群。







## 功能测试

测试可以直接参考postgres-xl 官方文档教程。
<http://files.postgres-xl.org/documentation/tutorial-createcluster.html>.

以下是测试样例。

在任意一个coordinator节点运行:

```sql
CREATE TABLE disttab (col1 int, col2 int, col3 text) DISTRIBUTE BY HASH(col1);
\d+ disttab
CREATE TABLE repltab (col1 int, col2 int) DISTRIBUTE BY REPLICATION;
\d+ repltab
INSERT INTO disttab SELECT generate_series(1, 100), generate_series(101, 200), 'foo';
INSERT INTO repltab SELECT generate_series(1, 100), generate_series(101, 200);
SELECT count(*) FROM disttab;
SELECT xc_node_id, count(*) FROM disttab GROUP BY xc_node_id;
SELECT count(*) FROM repltab;
SELECT xc_node_id, count(*) FROM repltab GROUP BY xc_node_id;
```