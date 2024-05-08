
srv_setup
=========

Роль для первоначальной настройки сервера на Debian
1. `start_srv_setup.yml`

	1.1. Указание группы инвентори
	
	1.2. Запуск роли через `main.yml`
	
2.  `main.yml`

	2.1.  Инклюд задач: `packages.yml`, `repo_keys.yml`, `ssh.yml`, `docker.yml`, `node_exporter.yml`, `ohmyzsh.yml`, `iptables.yml`, `l2tp_ipsec.yml`
	
3. `packages.yml`

	3.1. Установка пакетов из переменной `install_pkgs`
	
4. `repo_keys.yml`

	4.1. Добавление GPG-ключа Docker
	
5. `ssh.yml`

	5.1. Добавление публичных SSH-ключей из локальной директории `files/ssh_keys`
	
	5.2. Запрет на SSH подключения к root с парольной и интерактивной аутентификацией
	
	5.3. Запрет на SSH подключения к обычным пользователям с парольной и интерактивной аутентификацией
	
		5.3.1. Уведомление хендлера `Restart ssh-service`
		
6. `docker.yml`

	6.1. Добавление Docker-репозитория с amd64 архитектурой
	
		6.1.1. Уведомление хендлера `Install Docker Engine`
		
	6.2. Создание директории `/srv/docker` для хранения docker-compose файлов, с правами `755` (опционально)
	
7. `node_exporter.yml`

	7.1. Распаковка `node-exporter` в `/srv` из переменной `node_exporter_pkg`
	
	7.2. Создание системного пользователя `node_exporter` с оболочкой `/bin/false`
	
	7.3. Настройка systemd-юнита `node_exporter` через шаблон `node_exporter.service.j2`
	
		7.3.1. Уведомление хендлера `Start node_exporter`
		
	7.4. Добавление нового сервера в конфиг prometheus Ansible-мастера через переменную `prometheus_config` с 
указанием хоста для доступа через VPN (см. 10.4)

		7.4.1. Уведомление хендлера `Restart prometheus`
		
8. `ohmyzsh.yml`
 
	8.1. Если у ansible-пользователя нет в домашней директории `.oh-my-zsh`, тогда устанавливается oh-my-zsh
	
		8.1.1. Уведомление хендлеров `set ohmyzsh theme`, `set zsh as default`, `edit ohmyzsh theme`
		
9. `iptables.yml`
 
	9.1. Разрешение TCP INPUT порта node_exporter из переменной `node_exporter_port` от адреса VPN-сервера указанного в переменной `vpn_gw_int_ip_mask`
	
		9.1.1. Уведомление хендлера `iptables_save`
		
	9.2. Drop all INPUT TCP на порту node_exporter из переменной `node_exporter_port`
	
		9.2.1. Уведомление хендлера `iptables_save`
		
10. `l2tp_ipsec.yml`

	10.1. Проверка наличия файла вида `ansible_hostname.pwd` с паролем в директории `files/vpn_creds` и запись результата через модуль `register` в переменную `password_file_check`
	
	10.2. Если файл не обнаружен, тогда генерируется идемпотентный 15-тизначный пароль и сохраняется в виде `ansible_hostname.pwd` в локальной директории `files/vpn_creds`
	
	10.3. Проверка наличия файла вида `ansible_hostname` в директории `files/vpn_ip` и запись результата через модуль `register` в переменную `hostname_file_check`
	
	10.4. Блок создания файла hostname и создания VPN-пользователя + внутренней DNS-записи
	
		10.4.1. Если файл не обнаружен, тогда создается пустой файл вида `ansible_hostname` в локальной директории `files/vpn_ip`
		
		10.4.2. Выполнение локального скрипта `add_vpn_client.sh` для автоматического создания VPN-пользователей, с генерацией статического IP на основе имеющихся IP, в Mikrotik и внутренних DNS-записей с припиской `-int` к хостнейму
		
	10.5. Настройка IPSec Secrets на основе шаблона `ipsec.secrets.j2`
	
	10.6. Настройка конфигурации xl2tpd на основе шаблона `xl2tpd.conf.j2`
	
	10.7. Настройка параметров xl2tpd на основе шаблона `options.l2tpd.j2`
	
		10.7.1. Уведомление хендлера `Start VPN`
		
	10.8. Настройка автоматической маршрутизации внутренней сети через VPN на основе шаблона `vpn.routes.j2`
	
		10.8.1. Уведомление хендлера `Start VPN`

Requirements
------------

1. Доступ по SSH к настраиваемым серверам по ssh (обязательно с sudo правами. либо к root)
2. Настроенный VPN L2TP/IPSec на MikroTik с уже имеющимися Secrets со статическим IP (хотя бы один)
3. Доступ по SSH к MikroTik
4. Помещенные в директорию `files/ssh_keys` публичные SSH-ключи хостов, с которых требуется удаленный доступ к настраевому серверу
5. Корректное заполнение `vars.yml`

Role Variables
--------------

|Переменная|Пояснение|Необходимость изменения
|--|--|--|
|`install_pkgs`|Список пакетов для установки, разделитель `,`|Необязательно
|`mt_ip`|Локальный IP-адрес MikroTik для SSH подключения|+
|`mt_username`|Пользователя MikroTik для SSH подключения|+
|`domain`|Домен (Верхний и второй уровень) для настройки DNS-записей|+
|`vpn_gw_int_ip_mask`|Внутренний IP MikroTik в VPN сети с маской|+
|`vpn_gw_int_ip`|Внутренний IP MikroTik в VPN сети без маски|+
|`vpn_gw_ext_ip`|Внешний IP/домен MikroTik для подключения VPN|+
|`remote_ips`|Локальная сеть для настройки маршрутизации (см. 10.8.)|+
|`vpn_gw_port`|Порт для подключения VPN|+
|`vpn_client_ip`|Статический IP VPN нового сервера (см. 10.4.2.)|-
|`encr_algorithm`|Алгоритмы шифрования VPN. Узнать: `/ip/ipsec/profile/print`|+
|`connect_encr_algorithm`|Алгоритмы шифрования подключения IPSec. Узнать: `/ip/ipsec/profile/print`|+
|`conn_name`|Имя подключения VPN. Используется в шаблонах xl2tpd|Необязательно
|`ipsec_key`|Ключ IPSec|+
|`vpn_pass`|Сгенерированный PPP secret нового сервера (см. 10.2. и 10.4.2.)|-
|`node_exporter_port`|Порт для node_exporter|+
|`node_exporter_pkg`|Ссылка на архив node_exporter с официального GitHub|Необязательно
|`node_exporter_version`|Версия node_exporter из переменной `node_exporter_pkg` |Необязательно
|`prometheus_path`|Директория, где хранится `docker-compose.yml` сервиса Prometheus|+
|`prometheus_config`|Абсолютный путь до конфигурации, где хранятся **только** ноды, т.к. в конфиг добавляется только строка `- targets: ['hostname-int:node_exporter_port']`|+
|`prometheus_service_name`|Имя сервиса Prometheus в `docker-compose.yml`|+

Handlers
------------
1. `Install Docker Engine`

	1.1. Установка пакетов - `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
	
2. `edit ohmyzsh theme`

	2.1. Замена `☮` на `@` в теме `fox`

3. `set ohmyzsh theme`

	3.1. Замена стандартной темы на тему `fox`

4. `set zsh as default`

	4.5. Установка zsh как оболочку по-умолчанию

5. `Restart ssh-service`

	5.1. Перезагрузка сервисов `ssh` и `sshd` 

6. `iptables_save`

	6.1. Сохранение правил `iptables`

7. `Start VPN`

	7.1.  Перезагрузка сервисов `strongswan-starter` и `xl2tpd` и установка автозапуска

8. `Start node_exporter`

	8.1. Подтягивание нового systemd-юнита и перезагрузка сервиса  `node_exporter`

9. `Restart prometheus`
 
	9.1. Локальный перезапуск Docker-сервиса Prometheus

Files
------------

### scripts
`add_vpn_client.sh` - На каждый хост в директории `files/vpn_ip`, если файл хоста пуст, тогда подключается к MikroTik, берет последний IP клиентов из `/ppp/secret` и добавляет к нему следующий IP - этот IP будет статическим адресом VPN хоста. Затем создается новый `secret` с этим IP-адресом и паролем из `files_vpn_creds` и именем хоста + создается внутренняя DNS A-запись вида `host-int.example.com` с указанием на IP-адрес VPN-клиента

### ssh-keys
Хранятся публичные SSH-ключи хостов, с которых требуется удаленный доступ к настраевому серверу

### vpn_creds
Директория для сгенерированных паролей VPN-клиентов

### vpn_ip
Директория для сгенерированных IP-адресов хостов

Dependencies
------------

Отсутствуют

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:
```yml
- name: 'Start srv_setup role'
hosts: "servers"
become: yes
gather_facts: yes
roles:
- { role: srv_setup, when: ansible_system == 'Linux' }
```

Usage: 
----------------
```bash
┌[ansible@example.com]-(~)
└> ansible-playbook /etc/ansible/roles/srv_setup/tasks/start_srv_setup.yml
```
License
-------

BSD

Author Information
------------------

sdnv's role

@sdnv_funkhole, adm-sdnv.ru
