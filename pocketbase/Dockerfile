# PocketBase publishes binaries, not an image: this builds one from its release, as its docs suggest.
FROM alpine:3.22

# The PocketBase release to run. Change it to upgrade (and read its changelog first).
ARG PB_VERSION=0.40.5

RUN apk add --no-cache ca-certificates unzip wget \
 && case "$(uname -m)" in \
      x86_64) arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      armv7l) arch=armv7 ;; \
      *) echo "PocketBase has no build for $(uname -m)" >&2; exit 1 ;; \
    esac \
 && wget -q -O /tmp/pb.zip "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${arch}.zip" \
 && unzip -q /tmp/pb.zip -d /pb \
 && rm /tmp/pb.zip \
 && chmod +x /pb/pocketbase

EXPOSE 8090

# Makes sure the superuser from the environment exists (creating it, or setting its password again),
# then serves. Data lives in /pb/pb_data: mount a volume there.
CMD ["sh", "-c", "if [ -n \"$PB_ADMIN_EMAIL\" ] && [ -n \"$PB_ADMIN_PASSWORD\" ]; then /pb/pocketbase superuser upsert \"$PB_ADMIN_EMAIL\" \"$PB_ADMIN_PASSWORD\" --dir=/pb/pb_data; fi; exec /pb/pocketbase serve --http=0.0.0.0:8090 --dir=/pb/pb_data"]
