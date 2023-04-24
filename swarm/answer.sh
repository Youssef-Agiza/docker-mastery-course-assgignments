# !/bin/bash


create(){

#networks
docker network create -d overlay  frontend &
docker network create -d overlay backend & 
wait
echo "====created networks backend/frontend========="


# Services (names below should be service names)

# vote
     # bretfisher/examplevotingapp_vote
     # web frontend for users to vote dog/cat
     # ideally published on TCP 80. Container listens on 80
     # on frontend network
     # 2+ replicas of this container

docker service create --name vote --network frontend -p 8080:80 --replicas 2 bretfisher/examplevotingapp_vote &



# redis
     # redis:3.2
     # key-value storage for incoming votes
     # no public ports
     # on frontend network
     # 1 replica NOTE VIDEO SAYS TWO BUT ONLY ONE NEEDED

docker service create --name redis --network frontend --replicas 1 redis:3.2 &

# worker
     # bretfisher/examplevotingapp_worker
     # backend processor of redis and storing results in postgres
     # no public ports
     # on frontend and backend networks
     # 1 replica
docker service create --name worker --network frontend --replicas 1  bretfisher/examplevotingapp_worker&&
 docker service update --network-add backend worker &

# db
     # postgres:9.4
     # one named volume needed, pointing to /var/lib/postgresql/data
     # on backend network
     # 1 replica
     # remember set env for password-less connections -e POSTGRES_HOST_AUTH_METHOD=trust

docker service create --name db\
     --network backend --replicas 1\
     --mount type=volume,src=db-data,target=/var/lib/postgresql/data\
     -e POSTGRES_HOST_AUTH_METHOD=trust\
       postgres:14 &


# result
     # bretfisher/examplevotingapp_result
     # web app that shows results
     # runs on high port since just for admins (lets imagine)
     # so run on a high port of your choosing (I choose 5001), container listens on 80
     # on backend network
     # 1 replica

docker service create --name result --network backend --replicas 1\
     -p 5001:80  bretfisher/examplevotingapp_result &
wait 

echo "====== created services ======"
docker service ls | grep -E "vote|redis|worker|db|result"

echo "====== created networks ======"
docker network ls | grep -E "frontend|backend"


}
delete(){
     if [[ $(docker service ls | grep -E "vote|redis|worker|db|result" | wc -l) -eq 0 ]]
     then
          echo "No services to delete"
     else
          echo "Deleting services..."
          docker service rm vote redis worker db result
     fi

     if [[ $(docker network ls | grep -E "frontend|backend" | wc -l) -eq 0 ]]
     then
          echo "No networks to delete"
     else
          echo "Deleting networks..."
          docker network rm frontend backend
     fi
}

read -p "Would you like to create[C/c] the services or delete[D/d] them?" ACTION

if [[ $ACTION = "C" ]]  || [[ $ACTION = "c" ]]
then
     echo "creating..."
     create
else
     echo "deleting..."
     delete
fi
