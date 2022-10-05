FROM nginx:1.23.1

RUN groupadd nginx-fs -g 1005 && useradd --no-log-init -u 2005 -g nginx-fs nginx-fs
RUN mkdir /app
RUN chown -R nginx-fs:nginx-fs /usr/share/nginx/html && \
        chown -R nginx-fs:nginx-fs /var/cache/nginx && \
        chown -R nginx-fs:nginx-fs /var/log/nginx && \
        chown -R nginx-fs:nginx-fs /app && \
        chown -R nginx-fs:nginx-fs /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
        chown -R nginx-fs:nginx-fs /var/run/nginx.pid
# USER nginx-fs
COPY nginx.conf /etc/nginx/
EXPOSE 9736
CMD ["nginx", "-g", "daemon off;"]

