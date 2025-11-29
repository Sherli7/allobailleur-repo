-- Fichier de données de test pour Allo Bailleur
-- À exécuter dans l'éditeur SQL de Supabase.
-- Ce script attribue automatiquement les propriétés à l'utilisateur 'lelionlionel117@gmail.com'.

DO $$
DECLARE
    target_email TEXT := 'lelionlionel117@gmail.com';
    owner_id TEXT;
BEGIN
    -- 1. Récupérer l'UID de l'utilisateur s'il existe
    SELECT uid INTO owner_id FROM public.users WHERE email = target_email LIMIT 1;

    -- 2. Si l'utilisateur n'existe pas, on le crée avec un UID généré
    IF owner_id IS NULL THEN
        owner_id := 'LIONEL_HOST_TEST_UID'; -- UID fixe pour le test si pas de compte réel
        INSERT INTO public.users (uid, email, "firstName", "lastName", role, "isHost", bio)
        VALUES 
            (owner_id, target_email, 'Lionel', 'Bailleur', 'owner', true, 'Propriétaire Allo Bailleur')
        ON CONFLICT (uid) DO NOTHING;
        
        RAISE NOTICE 'Utilisateur % créé avec UID %', target_email, owner_id;
    ELSE
        RAISE NOTICE 'Utilisateur % trouvé avec UID %', target_email, owner_id;
    END IF;

    -- 3. Insertion des Propriétés (liées à owner_id)

    -- Propriété 1 : Appartement Haut Standing à Bastos (Yaoundé)
    INSERT INTO public.properties (
        "ownerId", title, description, type, city, district, address, country, price, 
        surface, bedrooms, bathrooms, "leaseMonths", deposit, "powerType", "waterSupplier", 
        "furnishedPeriodUnit", "isAvailable", style, amenities, latitude, longitude, 
        "imageUrls", status
    ) VALUES (
        owner_id, 
        'Appartement Luxe Bastos Vue Panoramique', 
        'Magnifique appartement haut standing situé au cœur de Bastos. Sécurité 24/7, groupe électrogène, finitions modernes. Idéal pour expatriés.', 
        'Appartement', 
        'Yaoundé', 
        'Bastos', 
        'Rue des Ambassades', 
        'Cameroun', 
        500000, 
        150, 3, 2, 12, 1000000, 
        'compteur personnel', 'camwater', 'mois', 
        true, 'Moderne', 
        ARRAY['Wifi', 'Climatisation', 'Parking', 'Groupe électrogène', 'Gardien', 'Balcon'], 
        3.8970, 11.5150, 
        ARRAY['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688'],
        'published'
    );

    -- Propriété 2 : Studio Moderne Biyem-Assi (Yaoundé)
    INSERT INTO public.properties (
        "ownerId", title, description, type, city, district, address, country, price, 
        surface, bedrooms, bathrooms, "leaseMonths", deposit, "powerType", "waterSupplier", 
        "isAvailable", style, amenities, latitude, longitude, 
        "imageUrls", status
    ) VALUES (
        owner_id, 
        'Studio Américain Biyem-Assi', 
        'Joli studio nouvellement construit, jamais habité. Compteur prépayé, eau forage. Proche du carrefour.', 
        'Studio', 
        'Yaoundé', 
        'Biyem-Assi', 
        'Carrefour Acacias', 
        'Cameroun', 
        60000, 
        35, 1, 1, 6, 120000, 
        'compteur prépayé', 'forage', 
        true, 'Minimaliste', 
        ARRAY['Eau forage', 'Parking moto'], 
        3.8350, 11.4850, 
        ARRAY['https://images.unsplash.com/photo-1554995207-c18c203602cb'],
        'published'
    );

    -- Propriété 3 : Villa avec Piscine à Bonapriso (Douala)
    INSERT INTO public.properties (
        "ownerId", title, description, type, city, district, address, country, price, 
        surface, bedrooms, bathrooms, "leaseMonths", deposit, "powerType", "waterSupplier", 
        "isAvailable", style, amenities, latitude, longitude, 
        "imageUrls", status
    ) VALUES (
        owner_id, 
        'Villa Duplex Bonapriso avec Piscine', 
        'Exceptionnelle villa 5 chambres avec piscine privée et jardin. Quartier résidentiel calme et sécurisé.', 
        'Villa', 
        'Douala', 
        'Bonapriso', 
        'Avenue des Palmiers', 
        'Cameroun', 
        1500000, 
        400, 5, 4, 12, 3000000, 
        'compteur personnel', 'camwater', 
        true, 'Luxe', 
        ARRAY['Piscine', 'Jardin', 'Garage', 'Climatisation', 'Wifi', 'Groupe électrogène'], 
        4.0150, 9.7100, 
        ARRAY['https://images.unsplash.com/photo-1613977257363-707ba9348227', 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6'],
        'published'
    );

    -- Propriété 4 : Appartement Meublé Odza (Yaoundé)
    INSERT INTO public.properties (
        "ownerId", title, description, type, city, district, address, country, price, 
        surface, bedrooms, bathrooms, "leaseMonths", deposit, "powerType", "waterSupplier", 
        "isAvailable", style, amenities, latitude, longitude, 
        "imageUrls", status
    ) VALUES (
        owner_id, 
        'Appartement Meublé Odza Borne 10', 
        '2 Chambres salon meublé. Idéal pour courts séjours. Accès facile aéroport.', 
        'Appartement', 
        'Yaoundé', 
        'Odza', 
        'Borne 10', 
        'Cameroun', 
        25000, 
        80, 2, 2, 1, 50000, 
        'compteur personnel', 'forage', 
        true, 'Classique', 
        ARRAY['Meublé', 'TV', 'Canal+', 'Cuisine équipée'], 
        3.8000, 11.5500, 
        ARRAY['https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6'],
        'published'
    );

END $$;
