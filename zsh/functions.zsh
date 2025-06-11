#! /bin/zsh

# Docker
function remove-all-docker-containers() {
  docker ps -aq --no-trunc | xargs docker rm
}

function remove-all-docker-images() {
  docker images | awk '{ print $3 }' | xargs -I {} docker rmi {}
}

#Fly
function fly-watch() {
  `echo $1 | perl -p -e 's#.*/pipelines/(.*)/jobs/(.*)/builds/(.*)$#fly watch -t au -j $1/$2 -b $3#g'`
}

# Random
function jwt-decode() {
  jq -R 'split(".") | .[1] | @base64d | fromjson'
}

function wol-clifford() {
  local server_ip=$(dig +short andreaandreid.ddns.net)
  wakeonlan -i "${server_ip}" -p 42464 "2c:f0:5d:98:71:fc"
}
