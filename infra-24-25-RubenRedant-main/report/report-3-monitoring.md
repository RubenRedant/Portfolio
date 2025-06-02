# Lab 3: Monitoring
## 3.1. Install prerequisites

```yaml
---
roles:
  - name: bertvv.rh-base
  - name: bertvv.httpd
  - name: bertvv.bind
  - name: bertvv.dhcp
collections:
  - name: prometheus.prometheus
  - name: grafana.grafana
```

## 3.2. Install Node Exporter
```yaml
- name: Install Node Exporter
  hosts: all
  become: yes
  roles:
    - prometheus.prometheus.node_exporter
- name: Open port 9100/tcp on all servers
  hosts: all
  roles:
  - bertvv.rh-base
  tasks:
    - name: open port
      ansible.posix.firewalld:
        port: 9100/tcp
        permanent: true
        state: enabled
    - name: reload firewall
      service:
        name: firewalld
        state: reloaded
```

## 3.3. Set up the monitoring server

installatie van prometheus op srv004 in `/site.yml`:

```yaml
- name: Install Prometheus on srv004
  hosts: srv004
  become: yes
  roles:
    - role: prometheus.prometheus.prometheus
```

## 3.3.1. Scraping metrics from other VMs

```yaml
# ansible/host_vars/srv004.yml
---
prometheus_scrape_configs:
  - job_name: 'node_exporter'
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - '172.16.128.100:9100'
          - '172.16.128.1:9100'
          - '172.16.128.2:9100'
          - '172.16.128.3:9100'
          - '172.16.128.4:9100'
```

### 3.3.1. Using our own DNS server - Ansible as an orchestration tool

## 3.4. Create a Dashboard with Grafana
1. go to http://172.16.128.4:3000 and select dashboard.
2. add new dashboard
3. Select as datasoruce Prometheus (automatically made in site.yml)
4. choose a metric to monitor
5. save dashboard.
  