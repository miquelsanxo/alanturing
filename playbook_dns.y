---
- name: Configura servidor DNS con zonas campus.local, hospital.local y soeasy.local
  hosts: dns
  become: yes

  vars:
    zonas:
      - nombre: "campus.local"
      - nombre: "hospital.local"
      - nombre: "soeasy.local"
    dns_ip: "10.0.2.10"
    mx_ip: "10.0.2.30"

  tasks:
    - name: Instalar bind9
      apt:
        name: bind9
        state: present
        update_cache: yes

    - name: Crear archivo named.conf.local
      copy:
        dest: /etc/bind/named.conf.local
        content: |
          zone "campus.local" {
              type master;
              file "/etc/bind/db.campus.local";
          };

          zone "hospital.local" {
              type master;
              file "/etc/bind/db.hospital.local";
          };

          zone "soeasy.local" {
              type master;
              file "/etc/bind/db.soeasy.local";
          };

          zone "2.0.10.in-addr.arpa" {
              type master;
              file "/etc/bind/db.10";
          };

    - name: Crear zona directa para cada dominio
      loop: "{{ zonas }}"
      copy:
        dest: "/etc/bind/db.{{ item.nombre }}"
        content: |
          $TTL 604800
          @   IN  SOA ns.{{ item.nombre }}. admin.{{ item.nombre }}. (
                      2         ; Serial
                      604800     ; Refresh
                      86400      ; Retry
                      2419200    ; Expire
                      604800 )   ; Negative Cache TTL
          ;
          @   IN  NS  ns.{{ item.nombre }}.
          ns  IN  A   {{ dns_ip }}
          mail IN  A  {{ mx_ip }}
          @   IN  MX  10 mail.{{ item.nombre }}.

    - name: Crear zona inversa
      copy:
        dest: /etc/bind/db.10
        content: |
          $TTL 604800
          @   IN  SOA ns.campus.local. admin.campus.local. (
                      2         ; Serial
                      604800     ; Refresh
                      86400      ; Retry
                      2419200    ; Expire
                      604800 )   ; Negative Cache TTL
          ;
          @   IN  NS  ns.campus.local.
          10  IN  PTR ns.campus.local.

    - name: Comprobar configuración de bind
      command: named-checkconf

    - name: Comprobar archivos de zona
      loop: "{{ zonas }}"
      command: named-checkzone {{ item.nombre }} /etc/bind/db.{{ item.nombre }}

    - name: Comprobar zona inversa
      command: named-checkzone 2.0.10.in-addr.arpa /etc/bind/db.10

    - name: Reiniciar bind9
      service:
        name: bind9
        state: restarted