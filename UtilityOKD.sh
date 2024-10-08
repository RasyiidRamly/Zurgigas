#!/bin/bash

# Telegram Bot Token and Chat ID
telegram_bot_token="Bot Token"  # Replace with your Telegram bot token
chat_id="Chat id"  # Replace with your chat ID

# Get all worker nodes
worker_nodes=$(oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=":metadata.name")

# SSH user (change this to your user or ensure that root access works)
ssh_user="core"

# Initialize output message
output_message="Node Usage Report:\n"

# Loop through each worker node
for node_name in $worker_nodes; do
  # Get disk usage of /var using SSH
  disk_usage=$(ssh "$ssh_user@$node_name" "df -h /var | tail -1 | awk '{print \$5}'")

  # Get CPU and memory usage from oc adm top nodes
  read cpu_usage memory_usage <<< $(oc adm top nodes --no-headers | grep "$node_name" | awk '{print $3, $5}')

  # Get total pods
  pods=$(oc describe node "$node_name" | awk '/Non-terminated Pods:/ {getline; getline; print $1}')

  # Calculate pod percentage
  pod_percentage=$(echo "$pods 250" | awk '{printf "%.2f" , ($1 / $2) * 100}')

  # Format the output
  output_message+="$node_name: $pods pods $pod_percentage%, Memory: $memory_usage, CPU: $cpu_usage, Disk /var: $disk_usage\n" 
done

# Print the final output message
printf "$output_message"


# Send the message to the Telegram group
curl -s -X POST "https://api.telegram.org/bot$telegram_bot_token/sendMessage" \
     -d chat_id="$chat_id" \
     -d text="$(printf "%b" "$output_message")"
