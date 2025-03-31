# Apache Guacamole를 Docker Compose로 구성합니다.
기본 프로젝트에서 NGINX를 제거한 버전입니다. (별개로 운용 하기 위하여)

## 과카몰리에 대하여
웹환경으로 접속 가능하며 rdp, ssh 등 다양한 원격을 지원합니다.

[Apache Guacamole](https://guacamole.incubator.apache.org/)

## 사전준비
Docker와 Docker Compose가 설치되어 있어야 합니다.

## 빠른시작
깃 저장소를 로컬에 복제합니다.

~~~bash
git clone "https://github.com/ngg293/guacamole.git"
cd guacamole

./prepare.sh

docker compose up -d
~~~
`https://ip of your server:8443/` 에서 접속할수 있습니다. 기본 아이디는 `guacadmin` 비밀번호는 `guacadmin` 입니다.

## 세부사항


### 네트워크
다음 부분의 docker-compose.yml은 guacnetwork_compose 네트워크를 브릿지 모드로 만듭니다.

~~~python
...
# networks
# create a network 'guacnetwork_compose' in mode 'bridged'
networks:
  guacnetwork_compose:
    driver: bridge
...
~~~

### 서비스
#### guacd
다음 부분의 docker-compose.yml은 guacd 서비스를 생성합니다. guacd는 Guacamole의 핵심으로, 원격 데스크탑 프로토콜을 동적으로 로드하고 웹 애플리케이션으로부터 받은 지침에 따라 원격 데스크탑에 연결합니다. 이 컨테이너는 guacamole/guacd 도커 이미지를 기반으로 하며, 이전에 생성한 네트워크 guacnetwork_compose에 연결됩니다. 또한 두 개의 로컬 폴더 ./drive와 ./record를 컨테이너에 마운트합니다. 이 폴더들은 나중에 사용자 드라이브를 매핑하거나 세션 녹화물을 저장하는 데 사용할 수 있습니다.

~~~python
...
services:
  # guacd
  guacd:
    container_name: guacd_compose
    image: guacamole/guacd
    networks:
      guacnetwork_compose:
    restart: always
    volumes:
    - ./drive:/drive:rw
    - ./record:/record:rw
...
~~~

#### PostgreSQL
다음 부분의 docker-compose.yml은 공식 도커 이미지를 사용하여 PostgreSQL 인스턴스를 생성합니다. 이 이미지는 환경 변수를 사용하여 높은 수준의 구성 가능성을 제공합니다. 예를 들어, /docker-entrypoint-initdb.d 폴더 내에 초기화 스크립트가 있으면 데이터베이스를 초기화합니다. 로컬 폴더 ./init을 컨테이너 내의 docker-entrypoint-initdb.d로 마운트하므로, 우리는 자신의 스크립트(./init/initdb.sql)를 사용하여 Guacamole 데이터베이스를 초기화할 수 있습니다.

~~~python
...
  postgres:
    container_name: postgres_guacamole_compose
    environment:
      PGDATA: /var/lib/postgresql/data/guacamole
      POSTGRES_DB: guacamole_db
      POSTGRES_PASSWORD: ChooseYourOwnPasswordHere1234
      POSTGRES_USER: guacamole_user
    image: postgres
    networks:
      guacnetwork_compose:
    restart: always
    volumes:
    - ./init:/docker-entrypoint-initdb.d:ro
    - ./data:/var/lib/postgresql/data:rw
...
~~~

#### 과카몰리
다음 부분의 docker-compose.yml은 Docker Hub의 guacamole 도커 이미지를 사용하여 Guacamole 인스턴스를 생성합니다. 이 이미지는 환경 변수를 사용하여 높은 수준의 구성 가능성을 제공합니다. 이 설정에서는 이전에 생성된 PostgreSQL 인스턴스에 사용자 이름과 비밀번호, 그리고 데이터베이스 guacamole_db를 사용하여 연결하도록 구성되어 있습니다. 포트 8080은 로컬에서만 노출됩니다! 다음 단계에서 이 인스턴스를 공개적으로 노출하기 위해 nginx 인스턴스를 연결할 예정입니다.

~~~python
...
  guacamole:
    container_name: guacamole_compose
    depends_on:
    - guacd
    - postgres
    environment:
      GUACD_HOSTNAME: guacd
      POSTGRES_DATABASE: guacamole_db
      POSTGRES_HOSTNAME: postgres
      POSTGRES_PASSWORD: ChooseYourOwnPasswordHere1234
      POSTGRES_USER: guacamole_user
    image: guacamole/guacamole
    links:
    - guacd
    networks:
      guacnetwork_compose:
    ports:
    - 8080/tcp
    restart: always
...
~~~


## prepare.sh
prepare.sh는 guacamole/guacamole 도커 이미지를 다운로드하고, 이를 다음과 같이 실행하여 ./init/initdb.sql을 생성하는 작은 스크립트입니다.

~~~bash
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > ./init/initdb.sql
~~~

prepare.sh는 PostgreSQL에 필요한 데이터베이스 초기화 파일을 생성합니다.

또한 prepare.sh는 nginx에서 https를 사용하기 위해 필요한 자체 서명된 인증서 ./nginx/ssl/self.cert와 개인 키 ./nginx/ssl/self-ssl.key를 생성합니다.

## reset.sh
처음으로 돌아가고 싶다면(초기화) `./reset.sh` 를 실행할 수 있습니다.

