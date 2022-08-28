:: setup postgres
::
docker run -d -p 5432:5432 --name=pg-server --network=wb-net -e POSTGRES_USER=wb-user -e POSTGRES_PASSWORD=password postgres:alpine