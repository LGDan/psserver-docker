# Part 1
FROM pandoc/alpine


FROM nginx:alpine

COPY --from=0 /usr/local/bin/pandoc /usr/local/bin/pandoc
COPY --from=0 /usr/local/bin/pandoc-citeproc /usr/local/bin/pandoc-citeproc

RUN apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl \
    fcgiwrap \
    spawn-fcgi \
    jq \
    gmp \
    lua5.3 \
    libffi

RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust

# Download the powershell '.tar.gz' archive
RUN curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/powershell-7.1.3-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz

# Create the target folder where powershell will be placed
RUN mkdir -p /opt/microsoft/powershell/7

# Expand powershell to the target folder, delete download
RUN tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && rm /tmp/powershell.tar.gz

# Set execute permissions
RUN chmod +x /opt/microsoft/powershell/7/pwsh

# Create the symbolic link that points to pwsh
RUN ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./index.html /usr/share/nginx/html/index.html
COPY ./cgi-bin/. /usr/share/nginx/cgi-bin/.

RUN find /usr/share/nginx/cgi-bin/ -type f -iname "*.cgi" -exec chmod +x {} \;

CMD spawn-fcgi -F 16 -s /run/fcgi.sock /usr/bin/fcgiwrap && nginx -g "daemon off;"
