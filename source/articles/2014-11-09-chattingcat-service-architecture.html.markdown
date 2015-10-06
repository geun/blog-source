---
title: ChattingCat Service Architecture
date: 2014-11-09 20:17 UTC
tags:
---

## 채팅캣 서비스 아키텍처 관하여

채팅캣은 지금까지 3번의 변화를 거쳐 현재 서비스에 이르게 되었습니다. 초창기 Node.js 가 막뜨던 시기에, Node.js + mongoDB 조합으로 시작되었다가, Rails 개발자를 만나 다른 버전으로 변경되었다가, 제가 맡게 되면서 지금의 Torquebox + Rails 버전에 이르기까지 다사다난한 과정을 겪으며 성장하고 있습니다. 한 해를 마치며 지난 것들을 정리하는 의미를 가지고 글을 쓰게 되었습니다. 또, 지금 적은 인원으로 시작하는 많은 스타트업들에게 작게나마 도움이 되었으면 좋겠습니다.

## OS / Hosting 
Ubuntu 13.10 버전을 사용하며 일본 도쿄 리전의 Amazone EC2에서 서비스 중입니다. 한동안 일본 linode의 VPS 통해 서비스했습니다만, AWS 일본과의 ping이 100ms 이하로 떨어지는 것을 보고 변경하게 되었습니다. 

## LoadBalancing
채팅캣은 한국, 일본의 아시아권과 학생들과 미국, 유럽의 영국의 국가들 튜터를 연결하는 서비스입니다. 현재는 ELB 아래 revers-proxy 로 사용하는 nginx 2대에 Round-Robin(이하 RR) 방식으로 연결하여 이중화되어 있습니다. 또 그 아래 haproxy 를 이용하여 was와 websocket 서버를 scale-out 가능한 구조로 구성하였습니다. 특히 was를 jboss 를 사용하여 AJP프로토콜을 사용하는 Nginx - Apach 구조에 대해서도 고심을 하였습니다만, 결국 websocket의 scale-out 구조를 위해서라도 Haproxy가 필요했습니다. ELB - Nginx - Haproxy - WAS 형태를 띠고 있습니다.

다만, 현재는 모든 서버가 일본 리전에 있고, 미국과 영국에 접속하는 튜터들은 체감삼 사이트가 느리다는 느낌을 받게 됩니다. 해서 가급적 static으로 뺄 수 있는 부분은 다 빼서 서비스하고, Dynamic 부분은 Route 53의 DNS 기반의 RR으로 통해 해결을 꾀하고 있습니다. 최종적으로는 Route 53(DNS RR) ->  미국, 일본, 유럽 리전의 ELB -> Nginx -> Haproxy -> Was 형태의  구성하게 됩니다 .

**Update 1)** nginx와 haproxy를 같이 쓰는 것에 대해서 문의를 많이 주셔서 업데이트 합니다. 원래는 Nginx만을 사용해서Jboss 를 로드벨런싱 하는 것이 목표였습니다만, 소스를 업데이트한 후에 서버를 재시작 할 경우 Jboss의 모든 모듈이 로드 되기전에, nginx 에서는 이를 online 상태인식하게 되어 4xx 에러를 발생하게 됩니다. 모듈이 완료된 후에는 괜찮아지지만 서버 1대당 2분가량의 로드 시간이 필요한데 그 시간동안 수많은 에러를 발생하게 됩니다. Zero downtime deployment을 목표로 구성된 스택에 큰 오류가 아닐 수 없습니다.  이를 nginx만으로 커버하기 위해서는 nginx plus 라이센스를 구입 후 Application health check 의 기능을 사용해야 합니다. /status, /ping 등의 url을 통해 health check 하는 기능인데 이 라이센스의 가격이 상당합니다. 이와  유사 기능을 haproxy에서 지원되어 사용하고 있습니다. 그럼 반대로 nginx 를 제거하면 아니되는가 하는 물음에는 저희의 static 파일을 nginx가 배포하고 있고, 로드밸런싱 뿐 만 아니라 리버스 프록시 기능 또한 사용하고 있습니다. 특히 angular JS의 경우 검색엔진에서 크롤링을 못하는 문제가 발생하게 되는데 이 경우에도 Nginx가 한 역활을 합니다. 또, websockets의 SSL teminations 도 담당하고 있습니다. ELB의 경우 websockets 연결시 handshake 문제가 발생하여 사용하기 어렵습니다. 

## Front-end

### Nginx와 AngularJS
Angular JS는 베타 버전 부터 관심을 두고 보고 있다가, 1.0릴리즈 되면서부터 바로 서비스에 적용해 써오고 있습니다. 현재는 1.2.26 버전으로 사용하고 있고, 향후 2.0 버전이 정식 릴리즈가 되면 마이그레이션을 하려합니다. Angular JS를 사용하면서 가장 처음 겪은 문제는 Rails 프레임 워크 자체에서 해결해주던 CORS, 세션을 이용한 로그인 처리 등 비즈니스 로직 구현과는 상관없이 진행되어야 하는 개발이 많은 점이였습니다. 해서 초기에는 Rails의 assets의 일부분으로 사용해서 문제를 최소화하려 노력했으며, 지금은 Rails에서는 완전히 분리하여  yoman 구성을 통해 별도의 저장소에서 저장되고, 배포 또한 개별적으로 진행되고 있습니다. 

그리고 Aws의 CloudFront를 이용해 배포하는 경우  ajax call을 할 ELB단에서 헤더 전송 문제 때문에 CORS 문제를 겪게 됩니다. CloudFront가 아닌 타사의 CDN을 쓸경우 해결이 가능하지만,  Nginx의 static 처리가 우수하여 현재는 Nginx에서 배포하고 있습니다.

## Back-end

### Application Server
초기 버전의 채팅캣에서는 ruby + unicorn + rails3 + redis + sidekiq + faye 조합으로 스택이 구성이 되었습니다만, 여러가지 문제가 있었습니다. 일단 버전 업이 잦아서 마이그레이션 비용이 상당하고, HA 환경에서의 background job 처리나 failover 처리나 clustering 구성 등을 위해서는 상당 부분을 직접 개발해야 합니다. 또 사용하는 오픈소스가 많다 보니 학습량이 어마어마했습니다.

현 버전은 Jruby + Jboss +  Torquebox3 + rails4 의 구성으로 운용중에 있으며, 상당히 만족스럽습니다. 서브 노트북에, cd-rom달고, 외장하드 달고, 주렁주렁 들고 다니다가 올인원 노트북을 사용하는 느낌입니다. 간단히 말해 개발은 ruby로 하되 속도는 java라고 생각하시면 됩니다. 하지만 이전 스택에 비해 레퍼런스가 부족하고, Java클래스 이용 시 Ruby에서는 전혀 문제가 되지 않는 것들이 문제가 되는 점등 허찔리는 버그들로 인해 괴로운 점이 많습니다. 또, Ruby의 Rack 서버들에 비해서, Jboss의 설정이 복잡한 편이고, 자잘한 설정 값 튜닝 등 SE업무가 상당히 증가하는 단점이 있습니다.

2015년에는 Torquebox4의 릴리즈 일정에 맞춰 업그레이드 할 예정이 있으며,  Jboss 7.2 에서 wildfly 8.2로, undertow기반의 torquebox로 변경하면서 scala에 대적하는 개발 편의성과 Java 솔루션들이 가진 운영의 안정성을 기대하고 있습니다. 

### Messaging
초기 버전에서는 faye의 ruby 버전을 이용해서 실시간 기능을 구현했습니다. 도입 당시 pubnub이나 pusher.com의 솔루션과 고민하였습니다만, faye가 설정하고 쓰기에 그리 어렵지 않은 점과 퍼포먼스 또한 node.js 버전으로 변경 할 시 30~50만 커넥션도 무난하게 처리한다는 후기들을 확인하고 일단 사용하게 됩니다. 특별히 웹상에서는 문제를 없이 사용하였습니다만, 채팅캣의 모바일 App 버전을 논하게 되면서 문제가 생기기 시작했습니다. 일단 Bayeux protocol을 구현한 faye가 상당히 부담되었습니다. Bayeux protocol의 사용한 레퍼런스가 흔치 않고, 모바일 디바이스에 해당 프로토콜에 적합한 라이브러리를 확보하기도 쉽지 않았습니다. 또 Redis를 이용하여 Clustering을 구성하게 되는데, 당시에는 Redis 자체의 clustering 구성 자체도 만만치 않은 문제였습니다. 

이러한 배경에 Torquebox 스택을 도입하게 되는데, 실시간 메시징 처리에 대한 부분과, 내부적으로 model 에 구현되어 있던 비즈니스 로직을 service layer로 분리하게 되면서 Message Queue가 필요했기 때문입니다.  Torquebox는 JMS(HornetQ)를 이용해서 내부적인 메시지를 처리하고, 중간에 브릿지를 구현해서 외부와는 Stomp protocol로 통신합니다. 현재의 채팅캣 서비스는 이러한 구조로 messaging 하고 있습니다. 하지만, 모바일 환경에서의 connection 관리 문제가 크고, 기타 자잘한 문제들이 있어서, 모바일 단말기용을 위한 Broker시스템을 따로 구성하고 있습니다. 현재의 JMS에서 -> MQTT Broker 로 연결하는 형태가 될 예정입니다.

### Microservice Architecture
SOA의 재탄생이라고 부르는 MA입니다. 사실, SOA이후 RESTful의 개념이 유행하는 시기에 채팅캣이 탄생했고, 지극히 RESTful 적인 서비스로 시작했습니다. 하지만 채팅캣이 발전 할 수록 커져만 가는 Model class를 보면서, 리팩토링의 욕구가 샘솟았고,  Torquebox의 도입은 이를 MA 형태로 발전시키는데 큰 역할을 하였습니다. 대게 Controller에 business logic을 구현하다가, 그것이 잘못되었다는 것을 알게 되면 Model에 넣기 시작합니다. 그러다보니 Model class가 비대해지는데, 이를 해결하기 위해서 Rails 에서는 concern 이라는 개념을 사용하기도 합니다. 하지만 이 또한 Testcase 작성 시 심심찮은 문제를 일으키게 되는데, 이를 Service object를 만들어 바꾸어 나가고 있습니다.  1차적으로는 Rails 폴더 구조 안에, Service Class를 만들어 Controller에서 불러 쓰기도 하고, 이것을 그대로 Torquebox의 singleton service 기능을 이용해서 Layer 단으로 올리기도 합니다. 

관리자 페이지를 만들기 시작하면 Rails engine 개념을 이용해서 분리하거나, 하나의 Rails에 폴더구조를 나누기 시작합니다. 하지만 이런 방법들은 분리된 것처럼 보이나 결국 종속적인 서비스 개발이 이어질 뿐입니다. 특히 배포 단계에 이르게 되면, 결국 monolithic의 약점을 고스란히 가져가게 됩니다. 관리자 페이지를 업데이트 하기위해 전체 CI를 돌린다고 생각해보면 답은 금방나옵니다. 저희는 이 부분을 Jboss의 특성과 에코시스템을 통해서 rack/rails/sinatra를 독립적으로 개발/배포 하고 있습니다. 이들 간의 통신은 JMS를 통해서 이루어 집니다. 

### Oauth2와 API
현재 서비스 중인 채팅캣의 Core 부분은 API 로 추상화 되어 있습니다. 이 API 위에 AngularJS로 제작된 WebClient가 있고 iOS, Android App들 그리고 Chrome extension이나 데스크탑 클라이언트 등으로 서비스 될 예정입니다. 모든 통신은 HTTPS 통해서 이루어지고, 각 클라이언트에서 사용자 인증을 위해서 Oauth2 방식으로 구현되었습니다. Oauth2는 Doorkeeper Gem을 사용하고 있습니다. 또 한가지 특징적인 점은 기존의 Session 중심의 인증에서, Token 중심으로 변경하여 사용하고 있습니다. 일단 Oauth2를 이용해서 인증이 이루어지고 나면, 발행된 token을 가지고 서비스를 이용하게 됩니다. 일단 적당한 Gem 이 있어 구현이 어렵지 않은 점과 채팅캣 서비스가 B2B쪽으로 발전해 나가기 위한 사전 포석, 또 차기 서비스에 대한 준비이기도 합니다. 

## Data storage
메인 스토리지로 postgreSQL을  Master-Salve의 Query-Off 구조로 사용하고 있습니다. 도입당시 CouchBase와 함께 검토하였습니다만, Rails4가 postgreSQL의 Array 나 Hash를 적극 지원하면서, 둘간의 궁합이 좋아 쓰게 되었습니다. ID 칼럼을 UUID 로 구성하고 DATA 필드하나만 사용하여, NoSQL처럼 사용 가능하다는 점도 매력적이였습니다. 기본적으로 원문과 교정문을 저장하게 되는데, 이는 Instagram의 sharding 방법을 사용하였습니다. 메인 스토리지는 말 그대로 저장해서 보관하는 역할을 하고, Cache는 Infinispan을 사용합니다. Infinispan은  consistent hash로 clustering되어 있는 memory data grid로 로그인시 사용하는 Session 이라든지, 생성된 원문을 cache 해두고 사용합니다. 

채팅캣의 서비스 구조상 학생이 원문을 올리면, 여러 튜터에게 알림 메시지가 가게 됩니다. 이때 다수의 사용자가 한번에 해당 원문을 조회하게 되고, 같은 쿼리가 여러 번 가지 않도록 Cache를 꼭해야 합니다.  따라서 원문이 작성되면 Cache를 일단 만들고, 튜터에게 알리는 구조로 짜여져있습니다. Infinispan은 expires 설정이 가능하여, 개별적으로 flush 하지 않아도 되는 장점이 있습니다. 작성된 Cache는 일정 시간 이후에는 자동 삭제됩니다. 이 외에 현재 교정문의 수라던지, 읽지 않은 이벤트의 수라든지 하는 카운팅을 목적과 부수적인 기능을 위해서 Redis를 별도로 사용하고 있습니다. 그리고 Elastic search를 사용해 각종 로그 자료를 모으고, postgreSQL 대신하여 원문과 교정문들의 Full-text-serarch 기능을 수행하고 있습니다.

Rails에서 master-salve 구조를 쓰기 위해 Octopus Gem 을 사용하고, Infinispan은 torquebox에서 제공하는 드라이버를, Redis는 Redis-Object를 사용합니다.

## Deployment
배포는 capistrano를 이용합니다. capistarno3로 업데이트 되면서, remote ssh 가 확실히 편해진 느낌입니다. Docker는 0.4 버전 때부터 지켜보고 있으나, 한 대가 아닌 클러스터 환경에서 운용하기에는 orchestra구성이 쉽지 않아 보류 중에 있습니다. 최근 1.0 버전으로 올라오고 인프라 업체에서의 해결방안을 만들어 내는 것을 보며, 조금 더 기다리면 되겠다는 생각을 하고 있습니다
궁극적으로는 Continuous Integration 이후 Continuous Delivery 까지 보고 있습니다. 그간 진행하고 있는 개발에서 배포까지의 프로세스를 정리하면 vagrant를 통해 개발 하고, packer를 통해 packaging 후에 AMI를 이용하여 AWS에서 Rolling Deployment 입니다.  

특히 packer는 정말 유용한 툴로 AMI 이미지, vagrant 이미지를 구울 때 아주 유용합니다. docker 이미지 또한 초기부터 지원했고, 같은 제작그룹이 만든 serf라는 orchestra 툴로 docker 간의 클러스터링도 꾀해 볼 수 있습니다. 

## Monitoring 
요즘 소위 말하는 ELK 스택을 사용해 nginx의 access log와 rails의 로그를 모으고 있습니다. jboss의 경우 7.2버전부터 별도의 플러그인 없이 syslog로 보내주는 설정이 가능해서 syslog로 기록하고, 이를 logstash 파싱해서 elastic search 서버로 보냅니다. 이전에는 각 서버에 logstash를 설치하고 Redis broker로 사용했습니다만, 복잡한 설정과 메모리사용 때문에 현재 Was에는 logstash forwarder라는 경량화된 collector를 설치해 사용합니다. 이를 logstash cluster 에 보내 Elastic search나 graphite 등으로 보내 사용하고 있습니다. 이렇게 모인 로그 데이터는 Kibana를 통해 모니터링 하고 있습니다. 또, 사용자 분석을 위해서 Google Analytics를 사용합니다. 

갑작스런 프로세서 종료를 위해 루비 개발자들은 보통 god나, monit을 사용한다고 알고 있습니다. god 과 monit 은 둘다 편하긴합니다만, 개인적으로 munin 또한 편하게 잘 쓰고 있습니다. 특히 이전의 시스템에서는 god의 존재감이 굉장히 컸으나, torquebox로 이전하고 또, aws의 auto-scale 기능을 활용하면서 failover에 보다 유연하게 대처할 수 있습니다. munin의 경우 jboss plugin인이 있고, rails 만 쓸 경우에도 별도의 gem 이 있습니다.

전반적인 네트워크 관리등을 위해서 zabbix의 사용도 많이 고려해보았습니다만, SE 업무 경험이 적다보니 상용인 newrelic 을 사용하고 있습니다. 처음에는 가격이 비싸다는 느낌이였는데, 여러가지 프로파일링이나 모니터링 기능을 사용하다보니 지금은 제값 주고 사용하는 느낌입니다. 모니터링을 newrelic + cloud watch + elastic search의 세개 서비스를 다 활용한다고 보시면 됩니다.

## 마치며 
지난 일년간 많은 것들을 해왔다고 생각했는데, 막상 적고보니 A4용지 한두장 분량이라 어째 조금은 섭섭한 느낌까지도 듭니다. 위에 적힌 업무들은 저 혼자 했던 것들이고, 큰 회사에서의 DevOps와는 다른(!!!?) DevOps를 해오고 있습니다. 아마존이나 구글이 없었다면, 또 그 수많은 오픈소스들이 없던 몇년 전을 생각해보면, 참 많이 달라졌습니다. 

채팅캣은 긴 터널을 벗어나 급격하게 성장하고 있습니다. 이 글을 보시고, 보다 나은 시스템에 대해서 이야기 해주신다면 경청해 듣겠습니다. 이 모든 것들을 함께 하고 싶은 분들이 계신다면, jobs@chattingcat.com 으로 연락주십시오. 함께 한다면 더 재미있게 개발 할 수 있을 거라고 생각하고, 그런 개발자분들 열렬히 찾고 있습니다. 

[로켓펀치 채팅캣 구인공고](http://rocketpun.ch/recruit/2051/)

**Update 2014. 12. 19**
[2014년 RORLab에서 발표한 채팅캣 아키텍처 발표 슬라이드](http://www.slideshare.net/chattingcat/chattingcat-ac-deployed)