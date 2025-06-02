# 2-cfgmgmt-documentatie
## 2.1 
### Ip addresses 
```
NAT: 10.0.2.15/24
Host-Only: 172.16.128.253/16
```

### Disto information
```
LSB Version:	n/a
Distributor ID:	AlmaLinux
Description:	AlmaLinux 9.4 (Seafoam Ocelot)
Release:	9.4
Codename:	n/a
```

### Linux Kernel
```
2024 x86_64 x86_64 x86_64 GNU/Linux
```

### Contents of /vagrant/
```
ansible  LICENSE  README.md  scripts  test  Vagrantfile  vagrant-hosts.yml
```

<br>

# 2.2 Adding a managed node
### SSH
maak gerbuik volgende lijn om te verwijzen naar de file met private de private key:
<br>

```ansible_ssh_private_key_file: ../.vagrant/machines/VMNAME/virtualbox/private_key```

<br>

# 2.3 Applying a role to a managed node
## Installeren en toepassen van een role

### installeren van één enkele role:
```
ansible-galaxy install bertvv.rh-base
```
### installeren van eventueel meerdere roles
aanpassen/of aanmaken van het bestand(wanneer dit nog niet aangemaakt is) `ansible/requirements.yml`

<br>

### Installeren van meerdere roles uit het bestand `ansible/requirements.yml`
```
ansible-galaxy install -r requirements.yml
```
### Toepassen:
aanpassen van bestand `ansible/site.yml`

```yaml
---
- name: Configure srv100 # Each task should have a name
  hosts: srv100          # Indicates hosts this applies to (host or group name)
  roles:                 # Enumerate roles to be applied
    - bertvv.rh-base
```



# 2.4. Web application server
## toevoegen van packages
pas het gepaste bestand voor de server aan in de map `ansible/host_vars/GEPASTE_SERVER`

onder `rhbase_install_packages` plaats je de package die je wilt installeren met ansible.

## 2.4.1. Installing Apache and MariaDB & 2.4.2. Make services available
`ansible/host_vars/srv100.yml` ziet er als volgt uit na alle nodige stappen:

```yaml
#ansible/host_vars/srv100.yml
---
rhbase_install_packages:
  - bash-completion
  - vim-enhanced
  - bind-utils
  - git
  - nano
  - setroubleshoot-server
  - tree
  - wget
  - mariadb-server
  - httpd
  - mod_ssl
  - php
  - php-mysqlnd
  - python3-libselinux
  - python3-libsemanage
  - python3-netaddr
  - python3-pip
  - python3-PyMySQL
rhbase_start_services:
  - mariadb
  - httpd
rhbase_firewall_allow_services:
  - http
  - https
```

## 2.4.3. PHP application
1. Copy the database creation script (db.sql) to the server
    Use module ansible.builtin.copy
    Put the file in /tmp/

    ````yaml
    - name: Copy db.sql to /tmp/
      ansible.builtin.copy: 
        src: /vagrant/ansible/files/db.sql
        dest: /tmp/db.sql
    ````

2. Install the PHP script test.php
    Use the copy module again
    Put the file in the appropriate directory and rename it to index.php
    Verify that you can see the PHP file in a web browser. It won't show the database contents yet, but you should at least see the page title.

    ````yaml
    - name: Copy test.php to /var/www/html and rename to index.html
      ansible.builtin.copy:
        src: /vagrant/ansible/files/test.php
        dest: /var/www/html/index.php
    ````

3. Create the database
    Use module community.mysql.mysql_db
    As database name, specify a variable db_name. The variable is initialised in host_vars/srv100.yml. The PHP script contains the expected name for the database.
    The syntax for using a variable is {{ VARIABLE_NAME }}, so {{ db_name }} in this case

    - Use the suitable module parameters to specify that the database shouls be initialised from the db.sql script.
  
    - Since we're on the same host as the database, it isn't necessary to specify a host, username or password. We can connect using the parameter login_unix_socket and specify the socket file. On RedHat-like systems, this is /var/lib/mysql/mysql.sock.
    
    - Verify that the database was created correctly by logging in to the database server with sudo mysql and executing the command show databases; and a select query on one of the tables.

    ````yaml
    - name: Create database
      community.mysql.mysql_db:
        name: "{{ db_name }}"
        state: import
        target: /tmp/db.sql
        login_unix_socket: /var/lib/mysql/mysql.sock
    ````

4. Create a database user
    - Use module community.mysql.mysql_user
    - As name and password, use the variables db_user and db_password respectively. These are initialised in host_vars/srv100.yml with the expected values found in the PHP script.
    - Ensure that this user has all privileges on the database specified by variable db_name
    - Connect using the login_unix_socket parameter
    - Verify that the database user exists and that it can be used log in to the database with mysql -uUSER -pPASSWORD DATABASE (replace USER, PASSWORD and DATABASE with the correct values), and that you can show the tables and contents.

    ````yaml
    - name: Create database user 
      community.mysql.mysql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}
        priv: "{{ db_name}}.*:ALL,GRANT"
        login_unix_socket: /var/lib/mysql/mysql.sock
    ````

## 2.4.4. SSL certificate
  Installeer de rol bertvv.httpd door deze toe te voegen aan de requirements en dan de requirements te installeren met:
  ````yaml
  ansible-galaxy install -r requirements.yml
  ````

## 2.4.5. Idempotency
Ik heb gekozen om dit te doen met handlers en notify:

````yaml
tasks:
  - name: Copy db.sql to /tmp/
    ansible.builtin.copy: 
      src: /vagrant/ansible/files/db.sql
      dest: /tmp/db.sql
    notify:
      - Create database
    .....
    .....

handlers:
  - name: Create database
    community.mysql.mysql_db:
      name: "{{ db_name }}"
      state: import
      target: /tmp/db.sql
      login_unix_socket: /var/lib/mysql/mysql.sock
````


# 2.5. DNS
## 2.5.1. Adding a new VM


## 2.5.2. Caching name server

````yaml
#ansible/host_vars/srv001.yml
---
rhbase_install_packages:
  - bash-completion
  - vim-enhanced
  - bind-utils
  - git
  - nano
  - setroubleshoot-server
  - tree
  - wget
rhbase_start_services:
  - named
rhbase_firewall_allow_services:
 - dns
bind_allow_query:
  - "any"
bind_recursion: true  
bind_allow_recursion:
  - "any"
bind_forward_only: true
bind_forwarders: 
  - 8.8.8.8
  - 8.8.4.4
bind_dnssec_enable: false
bind_listen_ipv4:
  - 127.0.0.1
  - 172.16.128.1
bind_query_log: "data/query.log"
````

## 2.5.3. Authoritative name server
````yaml
bind_zones:
  - name: 'infra.lan'
    primaries:
      - 172.16.128.1
    networks:
      - '172.16'
    name_servers:
      - srv001.infra.lan.
    hosts:
      - name: srv001
        ip: 172.16.128.1
        aliases:
          - ns
          - ns1
      - name: srv100
        ip: 172.16.128.100
        aliases:
          - www
      - name: '@'
        ip: 172.16.128.100
````
- what changed in the main config file?
  ````
  zone "infra.lan" IN {
    type master;
    file "/var/named/infra.lan";
    notify yes;
    allow-update { none; };
  };

  zone "16.172.in-addr.arpa" IN {
    type master;
    file "/var/named/16.172.in-addr.arpa";
    notify yes;
    allow-update { none; };
  };
  ````

## 2.5.4. Secondary name server

- host_vars/srv002.yml configuratie:
  ````yaml
  # ansible/host_vars/srv002.yml
  ---
  rhbase_firewall_allow_services:
    - dns
  bind_allow_query:
    - "any"
  bind_recursion: true
  bind_allow_recursion:
    - "any"
  bind_forward_only: true
  bind_forwarders:
    - 8.8.8.8
    - 8.8.4.4
  bind_dnssec_enable: false
  bind_listen_ipv4:
    - 127.0.0.1
    - 172.16.128.2
  bind_query_log: "data/query.log"
  bind_zones:
    - name: 'infra.lan'
      type: secondary
      primaries:
        - 172.16.128.1
      networks:
        - '172.16'

  ````

<br>

# 2.6. DHCP

````yaml
  #ansible/host_vars/srv003.yml
---
rhbase_firewall_allow_services:
  - dhcp
  - dns

dhcp_global_domain_name: 'infra.lan'
dhcp_global_domain_name_servers: 
  - 172.16.128.1
  - 172.16.128.2
dhcp_global_routers: 172.16.255.254

dhcp_global_default_lease_time: 14400
dhcp_global_max_lease_time: 14400

dhcp_subnets:
  - ip: 172.16.0.0
    netmask: 255.255.0.0
    range_begin: 172.16.0.2
    range_end: 172.16.127.254
#  - ip: 172.16.192.0
    #netmask: 255.255.192.0
    #range_begin: 172.16.192.1
    #range_end: 172.16.255.253

#dhcp_hosts:
#  - name:
#    mac: ''
#    ip: 
````


## 2.7. Managing a router with Ansible (vyos versie)
Configuratie van `ansible/router-config.yml`

```yaml
---
- name: Configure Router
  hosts: r001
  gather_facts: no
  connection: network_cli

  tasks:
    - name: Set IP address of internal interface
      vyos_config:
        lines:
          - set interfaces ethernet eth1 address '172.16.255.254/16'

    - name: Add description to interfaces
      vyos_config:
        lines:
          - set interfaces ethernet eth0 description 'LAN'
          - set interfaces ethernet eth1 description 'WAN'

    - name: Set host name of the router
      vyos_config:
        lines:
          - set system host-name 'r001'

    - name: Enable NAT on the router
      vyos_config:
        lines:
          - set nat source rule 10 outbound-interface name 'eth0'
          - set nat source rule 10 source address '172.16.0.0/16'
          - set nat source rule 10 translation address 'masquerade'

    - name: Save configuration
      vyos_config:
        save: true
```

# 2.8. Integration: a working LAN

## 2.8.1. Adding a "workstation" VM

## 2.8.2. Reproducibility


