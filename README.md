# Effective-Goggles Anticheat

Un système anticheat complet pour FiveM qui détecte les triches de noclip et autres exploits.

## Fonctionnalités

### Détection de Noclip
- **Analyse de vitesse** : Détecte les mouvements anormalement rapides
- **Détection de téléportation** : Identifie les déplacements instantanés sur de grandes distances
- **Vérification de hauteur** : Détecte les joueurs qui flottent sans support
- **Contournement de collision** : Détecte les mouvements à travers les murs et objets
- **Analyse de motifs de mouvement** : Identifie les changements de direction non naturels

### Autres Détections
- **God Mode** : Détecte l'invincibilité
- **Speed Hack** : Détecte les modifications de vitesse des véhicules
- **Manipulation de l'environnement** : Détecte les changements de temps/météo
- **Injection de menus** : Détecte les tentatives d'injection de menus de triche
- **Spawn de véhicules** : Détecte le spawn excessif de véhicules (NOUVEAU)
- **Invisibilité** : Détecte les manipulations de transparence/visibilité (NOUVEAU)
- **Manipulation d'entités** : Détecte le spawn d'objets/props (NOUVEAU)
- **Manipulation de modèle** : Détecte les changements de modèle de joueur non autorisés (NOUVEAU)

### Système de Validation de Position
- **Zones interdites** : Vérification des positions dans des zones blacklistées
- **Limite de hauteur** : Empêche les joueurs d'aller trop haut
- **Validation souterraine** : Détecte les joueurs sous la map
- **Immunité de spawn** : Protège les joueurs des faux positifs lors du spawn (NOUVEAU)

## Installation

1. Placez le dossier `effective-goggles` dans votre répertoire `resources`
2. Ajoutez `start effective-goggles` à votre `server.cfg`
3. Configurez le fichier `config.lua` selon vos besoins
4. Redémarrez votre serveur

## Configuration

### Configuration de base
```lua
Config.Detection.Noclip = {
    enabled = true,
    checkInterval = 250, -- Intervalle de vérification en millisecondes (plus fréquent)
    speedThreshold = 8.0, -- Seuil de vitesse en m/s (plus strict)
    heightThreshold = 2.5, -- Hauteur maximale sans support (plus strict)
    teleportDistance = 20.0, -- Distance de téléportation suspecte (plus strict)
    maxWarnings = 1, -- Nombre d'avertissements avant sanction (plus strict)
    punishment = "kick" -- Type de sanction : "kick", "ban", "warn"
}

-- Nouvelle détection de spawn de véhicules
Config.Detection.VehicleSpawning = {
    enabled = true,
    maxVehiclesPerPlayer = 3,
    spawnRateLimit = 1, -- Max 1 véhicule par minute
    detectionRadius = 50.0,
    punishment = "ban"
}

-- Nouvelle détection d'invisibilité
Config.Detection.Invisibility = {
    enabled = true,
    minAlphaThreshold = 50, -- Valeur alpha minimale (0-255)
    punishment = "kick"
}
```

### Zones interdites
```lua
Config.Detection.Position.blacklistedZones = {
    {x = 0, y = 0, z = -1000, radius = 8000, name = "Underground"},
    -- Ajoutez d'autres zones selon vos besoins
}

-- Configuration de l'immunité de spawn (NOUVEAU)
Config.Detection.Position.spawnImmunity = {
    enabled = true,
    duration = 15000, -- 15 secondes d'immunité après spawn/respawn
    undergroundOnly = true -- Applique l'immunité uniquement à la zone souterraine
}
```

### Liste blanche
```lua
Config.Whitelist.players = {
    "steam:110000000000000", -- ID Steam
    "license:abc123def456"   -- ID License
}
```

## Système de Logging

Le système génère des logs détaillés dans `logs/anticheat.log` incluant :
- Détections avec horodatage
- Actions prises
- Informations sur les joueurs
- Identifiants uniques de détection

### Rotation des logs
Les logs sont automatiquement archivés lorsque la taille dépasse 10MB.

## Notifications Discord

Configurez un webhook Discord pour recevoir des notifications :
```lua
Config.Admin.notifyDiscord = true
Config.Admin.discordWebhook = "https://discord.com/api/webhooks/..."
```

## Commandes Admin

Les joueurs avec les permissions appropriées peuvent :
- Recevoir des notifications en temps réel
- Accéder aux logs via les permissions ACE

### Permissions requises
```
admin
mod
anticheat.admin
```

## Méthodes de Détection

### 1. Analyse de Vitesse
- Monitore la vitesse de déplacement du joueur
- Compare avec les seuils configurés
- Exclut les déplacements en véhicule

### 2. Détection de Téléportation
- Calcule la distance parcourue entre deux mises à jour
- Détecte les déplacements instantanés impossibles
- Prend en compte le lag réseau

### 3. Vérification de Collision
- Utilise des raycasts pour vérifier les collisions
- Détecte les mouvements à travers les objets solides
- Analyse multiple directions autour du joueur

### 4. Analyse de Motifs
- Suit les patterns de mouvement anormaux
- Détecte les changements de vitesse/direction impossibles
- Accumule les données sur plusieurs frames

### 5. Validation de Position
- Vérifie si le joueur est dans des zones autorisées
- Contrôle les limites de hauteur
- Détecte les positions impossibles (sous la map)
- **Protection de spawn** : Immunité temporaire contre la détection souterraine

### 6. Système d'Immunité de Spawn
- **Prévention des faux positifs** : Évite les sanctions lors du spawn légitime
- **Durée configurable** : Par défaut 15 secondes d'immunité
- **Ciblage spécifique** : Appliqué uniquement aux zones souterraines
- **Réinitialisation automatique** : Se réactive après respawn ou téléportation

## Système de Sanctions

### Niveaux d'avertissement
1. **Premier avertissement** : Log + notification admin
2. **Deuxième avertissement** : Log + téléportation corrective
3. **Troisième avertissement** : Sanction selon configuration

### Types de sanctions
- **warn** : Avertissement simple
- **kick** : Expulsion du serveur
- **ban** : Bannissement (nécessite intégration avec votre système de ban)

## Performance

- Vérifications optimisées avec intervalles configurables
- Système de cache pour éviter les calculs redondants
- Thread séparés pour différents types de vérifications
- Impact minimal sur les performances serveur

## Compatibilité

- Compatible avec la plupart des ressources FiveM
- Fonctionne avec les systèmes de permissions ACE
- Intégrable avec les systèmes de ban existants

## Support

Pour des questions ou des problèmes :
1. Vérifiez la configuration
2. Consultez les logs d'erreur
3. Testez avec le mode debug activé

## Avertissements

- Testez en mode debug avant déploiement en production
- Configurez une liste blanche pour les admins
- Surveillez les faux positifs dans les premiers jours
- Ajustez les seuils selon votre serveur

## Licence

Ce projet est sous licence libre. Vous pouvez le modifier et le redistribuer selon vos besoins.