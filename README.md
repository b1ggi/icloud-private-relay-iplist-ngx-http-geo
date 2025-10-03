# iCloud Private Relay Egress IP Address List

![iCloud Private Relay](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/icloud/icloud-private-relay-how-private-relay-works-path-through-relays.png)

This project provides a comprehensive list of auto-generated iCloud Private Relay egress IP addresses in NGINX Geo Format for easy integration into your network infrastructure.

## What is iCloud Private Relay?

[iCloud Private Relay](https://developer.apple.com/support/prepare-your-network-for-icloud-private-relay) is a privacy-focused feature offered by Apple Inc. It enhances the security and privacy of your internet connections by providing an additional layer of encryption and anonymity when browsing the web. This feature routes your internet traffic through two separate servers, making it difficult for anyone, including Apple, to identify your IP address or the websites you visit.

## Purpose of this Repository

This repository aims to provide an up-to-date and automatically generated (from [original IP feed](https://mask-api.icloud.com/egress-ip-ranges.csv)) list of iCloud Private Relay egress IP addresses in various formats. By using these IP address lists, you can easily integrate iCloud Private Relay support into your network infrastructure, such as firewalls, proxy servers, or load balancers.

## Dependencies

[CIDR Merger 1.1.3](https://github.com/zhanhb/cidr-merger) is a dependency of the project.

## Directory Structure

The repository is organized as follows:

- **ip-ranges-geo.txt**: IP address list in plain text format containing both IPv4 and IPv6 addresses.
- **ipv4**: Subdirectory containing IPv4-specific IP address lists.
  - **ipv4-ranges-geo.txt**: IP address list in plain text format containing only IPv4 addresses.
- **ipv6**: Subdirectory containing IPv6-specific IP address lists.
  - **ipv6-ranges-geo.txt**: IP address list in plain text format containing only IPv6 addresses.
- **swag**: optional Subdirectory containing [linuxserver/swag](https://github.com/linuxserver/docker-swag)-specific cron script to download the file ip-ranges-geo.txt daily.
  - **update-icloud-geo**

## How to Use

```nginx
http {
    geo $icloud_relay {
        include /etc/nginx/ip-ranges-geo.txt;
    }

    server {
        listen 443 ssl http2;
        server_name example.com;

        # Zugriff nur erlauben, wenn iCloud Private Relay IP
        if ($icloud_relay = no) {
            return 403;
        }

        root /var/www/html;
        index index.html;
    }
}
```

## Long Example for SWAG Container

### Create "periodic" folder in $SWAG_CONFIG_FOLDER/etc

```bash
sudo mkdir etc/periodic
```

### Create updateicloudgeo file with 755 and root owner

```bash
sudo touch etc/periodic/updateicloudgeo
sudo chown root:root etc/periodic/updateicloudgeo
sudo chmod 755 etc/periodic/updateicloudgeo
```

### Content of updateicloudgeo

```bash
#!/bin/sh
set -eu

URL="https://raw.githubusercontent.com/b1ggi/icloud-private-relay-iplist-ngx-http-geo/refs/heads/main/ip-ranges-geo.txt"
TARGET_FILE="/config/nginx/icloud-ip-ranges.txt"
TARGET_USER="abc"
TARGET_GROUP="abc"
TARGET_MODE="664"

#Make sure TARGET_FILE Folder is existent:
mkdir -p "$(dirname "$TARGET_FILE")"

#Create temporary file
TMP_FILE="$(mktemp)"
# If File can be downloaded:
if curl -fsSL --retry 3 "$URL" -o "$TMP_FILE"; then
    #If Target File not existent   or   Tempfile and Targetfile different:
    if [ ! -f "$TARGET_FILE" ] || ! cmp -s "$TMP_FILE" "$TARGET_FILE"; then
        # move Tempfile to /config/nginx/icloud-ip-ranges.txt
        mv "$TMP_FILE" "$TARGET_FILE"
        echo "[$(date)] Updated iCloud IP ranges in $TARGET_FILE"
        # SWAG monitors /config/nginx/, reloads automatically on file changes
        # Set Owner, Group and Rights
        chown "$TARGET_USER:$TARGET_GROUP" "$TARGET_FILE"
        chmod "$TARGET_MODE" "$TARGET_FILE"

    else
        #Delete Tempfile
        rm -f "$TMP_FILE"
        echo "[$(date)] No change in iCloud IP ranges"
    fi
#If Download fails:
else
    rm -f "$TMP_FILE"
    echo "[$(date)] ERROR: Could not fetch $URL" >&2
fi
```

### Mount Script into a file in the daily cron folder in your docker_stack.yml

```yaml
volumes:
  - ./swagconfig/etc/periodic/updateicloudgeo:/etc/periodic/daily/updateicloudgeo
```

### Include the file for example in your maxmind.conf

```nginx
geoip2 /config/geoip2db/GeoLite2-City.mmdb {

...

geo $lan-ip {
    default no;
    10.0.0.0/8 yes;
    172.16.0.0/12 yes;
    192.168.0.0/16 yes;
    127.0.0.1 yes;
    fd00::/8 yes;
}

geo $icloud-relay {
    default no;
    include /config/nginx/icloud-ip-ranges.txt;
}
```

### Include condition in a ../proxy-conf/*.subdomain.conf

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name _template.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    #conditional whitelist for icloud-private-relay egress ip
    if ($lan-ip = yes) { set $geo-whitelist yes; }
    if ($icloud-relay = yes) { set $geo-whitelist yes; }
    if ($geo-whitelist = no) { return 404; }
...
```

## Updates and Maintenance

This repository is automatically updated at regular intervals to ensure the IP address lists remain up-to-date with the latest iCloud Private Relay egress IP addresses. The update process involves querying official sources and automated validation to provide accurate and reliable information.

## Contributing

Contributions to this project are welcome! If you have suggestions, improvements, or updates to the iCloud Private Relay egress IP address list, feel free to open an issue or submit a pull request.

## Disclaimer

This project is not affiliated with Apple Inc. The provided iCloud Private Relay egress IP address lists are generated based on available public information and might not cover all possible IP ranges used by iCloud Private Relay. Please use this information responsibly and verify it against official sources.

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use the provided IP address lists for personal or commercial purposes, but please refer to the license file for more details.

Thank you for using the Auto-Generated iCloud Private Relay Egress IP Address List! If you find this project useful, consider giving it a star to show your support. If you encounter any issues or have any questions, don't hesitate to reach out. Happy coding!
