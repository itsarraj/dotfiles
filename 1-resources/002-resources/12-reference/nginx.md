```conf
server {
    listen 443 ssl;
    http2 on;
    server_name seekersconnect.xyz www.seekersconnect.xyz matchmyresume.xyz www.matchmyresume.xyz;
    client_max_body_size 64m;

    ssl_certificate     /etc/letsencrypt/live/seekersconnect.xyz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seekersconnect.xyz/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    add_header Strict-Transport-Security "max-age=63072000" always;

    location ^~ /api/v1/auth/ {
        proxy_pass http://127.0.0.1:14681;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_he.............
        .................................
    }
}
```

In config above, we have 

ssl_certificate     /etc/letsencrypt/live/seekersconnect.xyz/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/seekersconnect.xyz/privkey.pem;

| File                                                     | Purpose                                 |
| -------------------------------------------------------- | --------------------------------------- |
| `/etc/letsencrypt/live/seekersconnect.xyz/fullchain.pem` | Public certificate + intermediate chain |
| `/etc/letsencrypt/live/seekersconnect.xyz/privkey.pem`   | Private key                             |


---

certificate is stored under:
/etc/letsencrypt/live/seekersconnect.xyz/

sudo certbot --nginx \
  -d seekersconnect.xyz \
  -d www.seekersconnect.xyz \
  -d matchmyresume.xyz \
  -d www.matchmyresume.xyz
  
Certbot will:
1.Verify ownership using HTTP challenge.
2.Generate certificate files.
3.Save them under /etc/letsencrypt/live/seekersconnect.xyz/.
4.Optionally update Nginx automatically.


6. Verify Certificate
sudo certbot certificates
You should see all domains listed.



