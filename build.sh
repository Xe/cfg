#!/bin/sh

(docker build -t xena/cfg . | prefix cadey) &
(docker build -t xena/cfg:mai \
        --build-arg=username=mai \
        --build-arg=gecos="Ma Insa" \
        --build-arg=email="mainsa.worldbuilder@gmail.com" . | prefix mai) &

wait

docker push xena/cfg
