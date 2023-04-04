ansible-playbook -l proxy1.de.nc -i inventories/srcflare apply-basic-settings-playbook.yml
ansible-playbook -l proxy1.de.nc -i inventories/srcflare install-docker-playbook.yml
ansible-playbook -l proxy1.de.nc -i inventories/srcflare install-nginx-proxy-playbook.yml
