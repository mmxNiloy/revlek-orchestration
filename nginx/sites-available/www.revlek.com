server {
    server_name revlek.com www.revlek.com;

    location / {
        proxy_pass http://127.0.0.1:3000;  # Localhost will route via Swarm's routing mesh
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 180s;
        proxy_connect_timeout 180s;
        proxy_send_timeout 180s;
        # proxy_request_buffering off;
        client_max_body_size 100M;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
}
