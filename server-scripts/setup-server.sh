# Script to push changes to git. (Original logic written by myself in GO, adapted to shell script with GPT-4o)

pack_url="https://<your-server>/pack.toml" # set this to the url of your hosted pack.toml
shared_args="--name mc -d -it -p 25565:25565 -v /root/ServerData -e PACKWIZ_URL=$pack_url -e EULA=TRUE -e USE_AIKAR_FLAGS=true -e WHITELIST_FILE/data/init-wl.json -e OPS=c0372460-acf6-4c19-8feb-08b303c4f4c7 -e MEMORY=6G -e TYPE=FORGE"

mkdir /root/ServerData
cp /root/mc-setup/server.properties /root/ServerData/server.properties
cp /root/mc-setup/whitelist.json /root/ServerData/init-wl.json
echo "Pulling pack.toml"
curl -s $pack_url -o pack.toml

# Extract the required variables (we don't need all of them but they're here.)
name=$(grep -E '^name\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
pack_format=$(grep -E '^pack-format\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
author=$(grep -E '^author\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
description=$(grep -E '^description\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
version=$(grep -E '^version\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
minecraft_version=$(grep -E 'minecraft\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
fabric_version=$(grep -E 'fabric\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
forge_version=$(grep -E 'forge\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
liteloader_version=$(grep -E 'liteloader\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
quilt_version=$(grep -E 'quilt\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')

echo "Got pack '$name' by '$author' on mc version '$minecraft_version'"

# Create a backup directory if it doesn't exist
backup_dir="/root/ServerBackup"
mkdir -p $backup_dir

if [ -d "$backup_dir" ]; then
    recent_backup=$(find $backup_dir -type f -name "*.zip" -mmin -180 | sort | tail -n 1)
else
    recent_backup=""
fi

if [ -z "$recent_backup" ]; then
    # Get the current date and time in the specified format
    timestamp=$(date +"backup-%Y-%m-%dT%H-%M-%S%z")

    # Create the zip file
    zip_file="$backup_dir/$timestamp.zip"
    zip -r $zip_file /root/ServerData

    echo "Backup created at $zip_file"

    # Limit the number of backups to 10
    backup_count=$(ls -1 $backup_dir/*.zip | wc -l)
    if [ $backup_count -gt 10 ]; then
        # Remove the oldest backup(s) if there are more than 10
        ls -1t $backup_dir/*.zip | tail -n +11 | xargs rm -f
    fi
else
    echo "A backup from the last 3 hours already exists: $recent_backup"
fi


# Check if the container 'mc' exists and stop and remove it if it does
if [ "$(docker ps -a -q -f name=mc)" ]; then
    echo "Stopping and removing existing container 'mc' - data will persist"
    docker stop mc
    docker rm mc
else
    echo "No existing container 'mc' found"
fi

if [ -n "$forge_version" ]; then
    echo "Pack runs forge $forge_version"
    # Replace the following line with the actual command you want to run
    docker run $shared_args -e TYPE=FORGE -e VERSION=$minecraft_version -e FORGE_VERSION=$forge_version itzg/minecraft-server
elif [ -n "$fabric_version" ]; then
    echo "Pack runs fabric loader $fabric_version"
    # Replace the following line with the actual command you want to run
     docker run $shared_args -e TYPE=FABRIC -e VERSION=$minecraft_version -e FABRIC_LOADER_VERSION=$fabric_version itzg/minecraft-server
fi

docker update --restart unless-stopped mc

echo "Done."
