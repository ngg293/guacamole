#!/bin/sh
#
# 도커가 구동중인지 확인합니다
if ! (docker ps >/dev/null 2>&1)
then
	echo "도커 프로그램이 실행중이지 않거나 권한이 부족합니다."
	exit
fi
echo "폴더 초기화 및 생성 ./init/initdb.sql"
mkdir ./init >/dev/null 2>&1
mkdir -p ./nginx/ssl >/dev/null 2>&1
chmod -R +x ./init
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > ./init/initdb.sql
echo "기록 폴더 생성 및 권한부여"
mkdir ./record >/dev/null 2>&1
chmod -R 777 ./record
echo "준비가 끝났습니다."
