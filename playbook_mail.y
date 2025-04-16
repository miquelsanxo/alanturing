- name: Instal·lació de Postfix i Dovecot per al domini campus.local
  hosts: mailservers
  become: true

  vars:
    mail_domain: campus.local
    mail_hostname: mail

  tasks:

    - name: Instal·lar paquets de Postfix i Dovecot
      apt:
        name:
          - postfix
          - dovecot-imapd
          - dovecot-pop3d
        state: present
        update_cache: yes

    - name: Configurar el nom del host
      hostname:
        name: "{{ mail_hostname }}"

    - name: Configurar /etc/mailname
      copy:
        dest: /etc/mailname
        content: "{{ mail_domain }}"

    - name: Configurar Postfix
      copy:
        dest: /etc/postfix/main.cf
        content: |
          myhostname = {{ mail_hostname }}.{{ mail_domain }}
          mydomain = {{ mail_domain }}
          myorigin = /etc/mailname
          inet_interfaces = all
          inet_protocols = ipv4
          mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
          relayhost =
          mailbox_size_limit = 0
          recipient_delimiter = +
          home_mailbox = Maildir/
          smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
          smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
          smtpd_use_tls=yes
          smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
          smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
          smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
        notify: Reiniciar Postfix

    - name: Configurar Dovecot per usar Maildir
      lineinfile:
        path: /etc/dovecot/conf.d/10-mail.conf
        regexp: '^mail_location ='
        line: 'mail_location = maildir:~/Maildir'

    - name: Permetre l’autenticació per IMAP
      lineinfile:
        path: /etc/dovecot/conf.d/10-auth.conf
        regexp: '^#?disable_plaintext_auth ='
        line: 'disable_plaintext_auth = no'

    - name: Activar autenticació amb fitxers passwd
      lineinfile:
        path: /etc/dovecot/conf.d/10-auth.conf
        regexp: '^#?auth_mechanisms ='
        line: 'auth_mechanisms = plain login'

    - name: Reiniciar Dovecot
      service:
        name: dovecot
        state: restarted
        enabled: true

  handlers:
    - name: Reiniciar Postfix
      service:
        name: postfix
        state: restarted
        enabled: true