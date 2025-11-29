# Documentation des Fonctionnalités et Cas d'Utilisation - Allô Bailleur

Ce document recense les fonctionnalités actuelles de l'application et décrit les parcours utilisateurs (Use Cases).

## 1. Authentification et Gestion de Compte
**Acteurs :** Tous les utilisateurs (Locataires et Bailleurs).

*   **Inscription / Connexion :**
    *   L'utilisateur peut créer un compte ou se connecter via Email/Mot de passe ou via Google (Social Login).
    *   Le système gère les sessions utilisateurs et la persistance des données via Supabase/Firebase.
*   **Profil Utilisateur :**
    *   Consultation et modification des informations personnelles.
    *   Gestion de l'avatar (photo de profil).

## 2. Recherche et Découverte (Côté Locataire)
**Acteurs :** Locataire.

*   **Recherche de Biens :**
    *   **Recherche en Langage Naturel Avancée (Natural Language Search) :**
        *   L'utilisateur saisit une demande libre : *"Je cherche un studio meublé avec wifi et parking à Bastos, sans caution"*.
        *   Le système analyse sémantiquement la phrase pour extraire :
            *   **Critères de base :** Prix (min/max), Surface, Chambres, Salles de bain.
            *   **Localisation :** Ville, Quartier, ou **"Proche de moi"** (utilise le GPS).
            *   **Type & Standing :** Appartement, Studio, Villa, Haut standing, Meublé.
            *   **Équipements (Amenities) :** Wifi, Parking, Piscine, Clim, Cuisine.
            *   **Conditions Spécifiques :** Compteur prépayé, Forage, Pas de caution.
    *   **Recherche par Mots-clés :** Recherche textuelle standard sur le titre et la description.
    *   **Filtres Manuels :** Interface graphique pour filtrer par Ville, Prix, Type, Chambres, etc.
*   **Consultation des Détails :**
    *   Visualisation complète (Photos, Description, Équipements, Carte).
    *   Visualisation de la localisation.
*   **Favoris :**
    *   Gestion d'une liste de favoris.

## 3. Système de Réservation (Booking)
**Acteurs :** Locataire (Demandeur) et Bailleur (Valideur).

*   **Vérification de la Disponibilité (Calendrier Visuel) :**
    *   Calendrier interactif affichant les dates occupées en grisé.
*   **Demande de Réservation :**
    *   **Location Courte Durée :** Sélection Date début / Date fin.
    *   **Location Longue Durée :** Sélection Date début + Option "Indéterminée".
    *   Calcul automatique du prix estimé.
*   **Gestion du Statut :**
    *   Suivi du statut "En attente", "Confirmé", "Refusé".

## 4. Messagerie et Communication
**Acteurs :** Locataire et Bailleur.

*   **Messagerie Instantanée :**
    *   Chat temps réel (Firestore).
    *   Déclenchement depuis la fiche bien ("Message").
*   **Notifications Push :**
    *   Alertes pour nouveaux messages et changements de statut de réservation.

## 5. Gestion Immobilière (Côté Bailleur)
**Acteurs :** Bailleur.

*   **Publication d'Annonces Complète :**
    *   Saisie détaillée : Informations, Photos, Localisation (Carte), Résumé.
    *   Spécification des conditions (Caution, Type de courant/eau, Durée min).
    *   Sélection des équipements (Wifi, Parking, etc.).
*   **Gestion des Disponibilités :**
    *   Blocage automatique des dates réservées.

## 6. Fonctionnalités Techniques Transverses
*   **Synchronisation :** Temps réel.
*   **Stockage :** Cloud (Images).
*   **Géolocalisation :** Calcul de distance pour le tri des résultats.
