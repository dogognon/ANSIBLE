#!/bin/bash

# Vérification si la clé privée existe déjà
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Génération de la clé SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
else
    echo "La clé SSH existe déjà."
fi

# Liste des workers et des clés associées
declare -A WORKERS_KEYS
WORKERS_KEYS["192.168.50.21"]="AnsibleWorker1"
WORKERS_KEYS["192.168.50.22"]="AnsibleWorker2"

# Copier les clés privées si elles n'existent pas
if [ ! -f ./AnsibleWorker1 ]; then
    cp .vagrant/machines/AnsibleWorker1/virtualbox/private_key ./AnsibleWorker1
    chmod 600 ./AnsibleWorker1
fi

if [ ! -f ./AnsibleWorker2 ]; then
    cp .vagrant/machines/AnsibleWorker2/virtualbox/private_key ./AnsibleWorker2
    chmod 600 ./AnsibleWorker2
fi

# Connexion aux workers avec la clé appropriée
for WORKER in "${!WORKERS_KEYS[@]}"; do
    KEY="${WORKERS_KEYS[$WORKER]}"
    echo "Ajout de la clé publique au worker $WORKER..."
    ssh -i ./$KEY vagrant@$WORKER "mkdir -p ~/.ssh && echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys"
    if [ $? -eq 0 ]; then
        echo "Clé publique ajoutée avec succès à $WORKER."
    else
        echo "Échec de l'ajout de la clé publique à $WORKER."
    fi
done



# Restriction de l'accès SSH aux workers
#MASTER_IP=$(hostname -I | awk '{print $2}')
#for WORKER in "${!WORKERS_KEYS[@]}"; do
#    echo "Restriction de l'accès SSH sur $WORKER à $MASTER_IP..."
#    if ! ssh vagrant@$WORKER "echo 'AllowUsers vagrant@$MASTER_IP' | sudo tee -a /etc/ssh/sshd_config"; then
#        echo "Échec de la restriction d'accès sur $WORKER"
#        exit 1
#    fi
#    if ! ssh vagrant@$WORKER "sudo systemctl restart sshd"; then
#        echo "Échec du redémarrage SSH sur $WORKER"
#        exit 1
#    fi
#done



# Suppression des clés privées des workers
echo "Suppression des clés privées des workers..."
rm -f ./AnsibleWorker1 ./AnsibleWorker2

echo "Configuration terminée. Le master peut maintenant se connecter aux workers via SSH sans mot de passe et les clés ont été supprimées."
