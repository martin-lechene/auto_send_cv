#!/bin/bash

# Fonction pour afficher la prévisualisation du mail
preview_mail() {
    echo "Prévisualisation du mail :"
    echo "-----------------------------------"
    echo "Destinataire: $recipient"
    echo "Sujet: $subject"
    echo "Pièce jointe: $attachment"
    echo "Société: $company"
    echo "-----------------------------------"
    echo "Corps du mail :"
    echo "$body"
    echo "-----------------------------------"
}

# Demande des informations de connexion au serveur mail
smtp_config_file="smtp_config.txt"

if [ -f "$smtp_config_file" ]; then
    echo "Fichier de configuration SMTP trouvé."
    source "$smtp_config_file"
else
    echo "Veuillez entrer les informations de connexion SMTP :"
    read -p "Serveur SMTP: " smtp_server
    read -p "Port: " smtp_port
    read -p "Nom d'utilisateur: " username
    read -sp "Mot de passe: " password
    echo ""

    echo "smtp_server=\"$smtp_server\"" > "$smtp_config_file"
    echo "smtp_port=\"$smtp_port\"" >> "$smtp_config_file"
    echo "username=\"$username\"" >> "$smtp_config_file"
    echo "password=\"$password\"" >> "$smtp_config_file"
    echo "Fichier de configuration SMTP enregistré."
fi

# Demande des informations pour le mail
read -p "Destinataire: " recipient
read -p "Sujet: " subject
read -p "URL du CV (PDF) : " cv_url

# Téléchargement du CV depuis l'URL
cv_filename=$(basename "$cv_url")
curl -o "$cv_filename" "$cv_url" 2>/dev/null

if [ -f "$cv_filename" ]; then
    attachment="$cv_filename"
else
    echo "Aucun CV n'a été trouvé à l'URL spécifiée."
    read -p "Voulez-vous ajouter un CV manuellement ? (Oui/Non): " add_cv

    if [[ $add_cv =~ ^[Oo](ui)?$ ]]; then
        read -p "Chemin vers le fichier CV (PDF) : " attachment
    fi
fi

# Demande du nom de la société
read -p "Nom de la société (laissez vide si non applicable) : " company

# Corps du mail prédéfini (modifier le contenu si nécessaire)
body="Bonjour,"

if [ -n "$company" ]; then
    body+="

Je vous envoie ma candidature spontanée pour un poste au sein de $company. Veuillez trouver ci-joint mon CV pour plus d'informations."
else
    body+="
    
Je vous envoie ma candidature spontanée pour un poste au sein de votre entreprise. Veuillez trouver ci-joint mon CV pour plus d'informations."
fi

body+="

Cordialement,
Votre Nom"

# Affichage de la prévisualisation du mail
preview_mail

# Demande de confirmation avant l'envoi
read -p "Voulez-vous envoyer le mail ? (Oui/Non): " confirmation

if [[ $confirmation =~ ^[Oo](ui)?$ ]]; then
    # Envoi du mail avec pièce jointe
    echo "Envoi du mail..."
    (
        echo "Subject: $subject"
        echo "To: $recipient"
        echo "From: $username"
        echo "Content-Type: text/plain"
        echo "Content-Disposition: inline"
        echo "smtp-use-starttls"
        echo "smtp-auth=login"
        echo "smtp-auth-user=$username"
        echo "smtp-auth-password=$password"
        echo
        echo "$body"
    ) | /usr/sbin/sendmail -f "$username" -X "$smtp_server:$smtp_port" "$recipient"
    echo "Mail envoyé avec succès !"

    # Enregistrement du mail envoyé dans un fichier HTML
    html_file="mails_envoyes.html"

    if [ ! -f "$html_file" ]; then
        touch "$html_file"
        echo "<html><body><h1>Mails envoyés</h1><ul>" > "$html_file"
    fi

    echo "<li>Date: $(date +"%Y-%m-%d %H:%M:%S")</li>" >> "$html_file"
    echo "<ul><li>Destinataire: $recipient</li><li>Sujet: $subject</li><li>Pièce jointe: $attachment</li><li>Société: $company</li></ul>" >> "$html_file"
    echo "<p>$body</p>" >> "$html_file"
    echo "</ul></body></html>" >> "$html_file"
    echo "Mail enregistré dans $html_file."

    # Création du dossier pour les mails envoyés s'il n'existe pas
    mail_folder="mails_envoyes"
    if [ ! -d "$mail_folder" ]; then
        mkdir "$mail_folder"
    fi

    # Déplacer le mail envoyé dans le dossier des mails envoyés
    mv "$html_file" "$mail_folder/"

    # Déplacer le CV envoyé dans le dossier des mails envoyés
    if [ -f "$attachment" ]; then
        mv "$attachment" "$mail_folder/"
    fi

    echo "Mail et pièce jointe (le cas échéant) enregistrés dans le dossier $mail_folder."
else
    # Suppression du fichier CV téléchargé
    if [ -f "$cv_filename" ]; then
        rm "$cv_filename"
    fi

    echo "Envoi du mail annulé."
fi
