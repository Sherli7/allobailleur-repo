import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/ticket.dart';

class TicketService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Créer un nouveau ticket
  /// Vérifie d'abord s'il existe une réservation confirmée pour cette propriété par cet utilisateur.
  Future<Ticket> createTicket({
    required String title,
    required String description,
    required String priority,
    required String propertyId,
    required String userId,
    List<String>? images,
  }) async {
    // Étape 1: Vérifier l'existence d'une réservation payée
    final bookingCheck = await _supabase
        .from('bookings')
        .select('id')
        .eq('property_id', propertyId)
        .eq('tenant_id', userId)
        .eq('status', 'confirmed') // Statut indiquant un paiement réussi
        .limit(1);

    if (bookingCheck.isEmpty) {
      throw Exception(
        'Paiement requis: Vous devez avoir une réservation confirmée pour contacter le propriétaire.',
      );
    }

    // Étape 2: Si la vérification passe, créer le ticket
    final response = await _supabase
        .from('tickets')
        .insert({
          'title': title,
          'description': description,
          'priority': priority,
          'status': 'open',
          'created_by': userId,
          'property_id': propertyId,
          'images': images ?? [],
        })
        .select()
        .single();

    // Envoyer une notification au propriétaire (Simulation)
    await _sendNotificationToOwner(propertyId, "Nouveau ticket : $title");

    return Ticket.fromJson(response);
  }

  /// Récupérer les tickets créés par l'utilisateur (Locataire)
  Future<List<Ticket>> getUserTickets(String userId) async {
    try {
      final response = await _supabase
          .from('tickets')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erreur getUserTickets: $e');
      return [];
    }
  }

  /// Récupérer les tickets pour un propriétaire (Bailleur)
  /// Récupère tous les tickets liés aux propriétés dont il est le owner.
  Future<List<Ticket>> getOwnerTickets(String ownerId) async {
    try {
      // On fait une jointure sur la table properties pour filtrer par owner_id
      final response = await _supabase
          .from('tickets')
          .select('*, properties!inner(owner_id, title)')
          .eq('properties.owner_id', ownerId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erreur getOwnerTickets: $e');
      // Fallback: essayer de récupérer par assigned_to si la jointure échoue
      try {
        final response = await _supabase
            .from('tickets')
            .select()
            .eq('assigned_to', ownerId)
            .order('created_at', ascending: false);
        
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  /// Mettre à jour le statut d'un ticket
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    await _supabase.from('tickets').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);

    // Simulation de notification
    _sendNotificationForStatusChange(ticketId, newStatus);
  }

  /// Ajouter un commentaire à un ticket
  Future<void> addComment(String ticketId, String userId, String content) async {
    try {
      await _supabase.from('ticket_comments').insert({
        'ticket_id': ticketId,
        'user_id': userId,
        'content': content,
      });
    } catch (e) {
      debugPrint('Erreur addComment: $e');
      // Fallback: si la table n'existe pas encore, on log juste
      debugPrint('Simulation ajout commentaire: $content');
    }
  }

  /// Récupérer les commentaires d'un ticket
  Future<List<Map<String, dynamic>>> getTicketComments(String ticketId) async {
    try {
      final response = await _supabase
          .from('ticket_comments')
          .select('*, profiles(first_name, last_name, avatar_url)') // Suppose une table profiles liée
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Erreur getTicketComments: $e');
      return [];
    }
  }

  // --- Méthodes Privées de Simulation ---

  Future<void> _sendNotificationToOwner(String propertyId, String message) async {
    // TODO: Implémenter un vrai service de Push Notification (FCM / OneSignal)
    // Ici, on simule une appel API ou une insertion en base 'notifications'
    debugPrint("🔔 NOTIFICATION pour Proprio (Bien $propertyId) : $message");
  }

  Future<void> _sendNotificationForStatusChange(String ticketId, String status) async {
    debugPrint("🔔 NOTIFICATION Ticket $ticketId : Statut changé à $status");
  }
}
