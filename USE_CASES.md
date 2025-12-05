# Cas d'Utilisation (USE CASES) - Mise à jour

Ce document décrit les cas d'utilisation mis à jour après la phase de maturation des fonctionnalités.

## 1. Gestion du Compte et des Paramètres

### 1.1. Configurer ses préférences
L'utilisateur peut accéder à la page "Paramètres" depuis son profil.

- **Changer le thème** : L'utilisateur peut activer ou désactiver le **Thème Sombre**. Le choix est sauvegardé et appliqué à toute l'application, même après redémarrage.
- **Gérer la langue** : L'utilisateur voit une option pour changer la langue (fonctionnalité future).
- **Gérer la sécurité** : Un accès vers une future page de gestion de mot de passe est disponible.

### 1.2. Supprimer son compte
L'utilisateur dispose d'une option "Supprimer mon compte".
- Un clic sur ce bouton affiche une **boîte de dialogue de confirmation** pour éviter toute suppression accidentelle.
- La logique de suppression effective est à implémenter.

## 2. Gestion des Biens Immobiliers

### 2.1. Comparer les biens favoris
Depuis la page "Favoris", l'utilisateur peut sélectionner plusieurs biens pour les comparer.

- **Tableau Comparatif** : Les biens sélectionnés sont affichés côte à côte avec leurs caractéristiques principales (prix, surface, chambres, etc.).
- **Navigation vers les détails** : Un bouton **"Voir"** dans le tableau permet à l'utilisateur de naviguer directement vers la page de détails du bien concerné.
- **Affichage complet** : Tous les équipements d'un bien sont visibles pour une comparaison exhaustive.

## 3. Système de Réservation (Booking)

### 3.1. Effectuer une réservation
Le processus de réservation inclut désormais une logique financière de base.

- **Calcul de la commission** : Le prix total affiché à l'utilisateur inclut une **commission de plateforme de 10%**.
- **Simulation de paiement** : Le système simule un processus de paiement, préparant l'intégration d'une passerelle de paiement réelle.

### 3.2. Annuler une réservation
Une logique d'annulation a été implémentée.

- **Politique de remboursement** : Le service `BookingService` contient une méthode qui simule une politique de remboursement (par exemple, remboursement complet si l'annulation a lieu plus de 48h avant).

## 4. Système de Support et d'Incidents (Ticketing)

### 4.1. Signaler un incident
Un locataire peut créer un "ticket" pour signaler un problème concernant une propriété.

- **Formulaire de création** : L'utilisateur remplit un formulaire avec un titre, une description, une priorité et peut joindre des images.
- **Tables en Base de Données** : Les tickets sont stockés dans la table `public.tickets`.

### 4.2. Discuter d'un incident
Le locataire et le propriétaire peuvent discuter au sein d'un ticket pour résoudre le problème.

- **Fil de discussion** : Chaque ticket possède un fil de discussion où des messages peuvent être ajoutés.
- **Stockage des messages** : Les commentaires sont stockés dans la table `public.ticket_comments`.
- **Sécurité** : Les politiques RLS garantissent que seuls le créateur du ticket et le propriétaire du bien concerné peuvent voir et ajouter des commentaires.

### 4.3. Suivre le statut d'un incident
L'utilisateur peut voir le statut de ses tickets (Ouvert, En cours, Résolu).
- Le service `TicketService` contient la logique pour mettre à jour le statut, et une notification (simulée) peut être envoyée lors d'un changement.
