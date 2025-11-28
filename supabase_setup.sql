-- SQL script to create the required tables in Supabase
-- Run this in your Supabase SQL editor

-- IMPORTANT: After running this script, you MUST also:
-- 1. Create a storage bucket named 'images' in Supabase Dashboard > Storage
-- 2. Make it public
-- 3. Run the following SQL to set storage policies:

-- Storage policies for 'images' bucket (run after creating the bucket)
INSERT INTO storage.buckets (id, name, public) VALUES ('images', 'images', true) ON CONFLICT DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read access on images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own images" ON storage.objects;

CREATE POLICY "Allow public read access on images" ON storage.objects FOR SELECT USING (bucket_id = 'images');
CREATE POLICY "Allow authenticated users to upload images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'images' AND auth.role() = 'authenticated');
CREATE POLICY "Allow users to update their own images" ON storage.objects FOR UPDATE USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Allow users to delete their own images" ON storage.objects FOR DELETE USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Drop existing tables if they exist (to fix column name issues)
DROP TABLE IF EXISTS public.images CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.bookings CASCADE;
DROP TABLE IF EXISTS public.favorites CASCADE;
DROP TABLE IF EXISTS public.properties CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Create users table
CREATE TABLE public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    uid TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    role TEXT DEFAULT 'tenant',
    "profileImageUrl" TEXT,
    "isHost" BOOLEAN DEFAULT false,
    city TEXT,
    country TEXT,
    bio TEXT,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ
);

-- Create properties table
CREATE TABLE public.properties (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "ownerId" TEXT NOT NULL REFERENCES users(uid),
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT,
    address TEXT,
    country TEXT NOT NULL,
    price NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'XAF',
    surface NUMERIC,
    bedrooms INTEGER,
    bathrooms INTEGER,
    balconies INTEGER,
    "leaseMonths" INTEGER,
    deposit NUMERIC,
    "powerType" TEXT,
    "waterSupplier" TEXT,
    "furnishedPeriodUnit" TEXT,
    "furnishedNoDeposit" BOOLEAN,
    "listingPurpose" TEXT,
    style TEXT,
    conditions JSONB,
    rating NUMERIC DEFAULT 0,
    "reviewCount" INTEGER DEFAULT 0,
    "imageUrls" TEXT[],
    amenities TEXT[],
    latitude NUMERIC,
    longitude NUMERIC,
    status TEXT DEFAULT 'published',
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "isAvailable" BOOLEAN DEFAULT true
);

-- Create favorites table
CREATE TABLE public.favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES users(uid),
    "propertyId" UUID NOT NULL REFERENCES properties(id),
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE("userId", "propertyId")
);

-- Create bookings table
CREATE TABLE public.bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guest_id TEXT NOT NULL REFERENCES users(uid),
    property_id UUID NOT NULL REFERENCES properties(id),
    host_id TEXT NOT NULL REFERENCES users(uid),
    check_in_date TIMESTAMPTZ NOT NULL,
    check_out_date TIMESTAMPTZ NOT NULL,
    total_price NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create reviews table
CREATE TABLE public.reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "propertyId" UUID NOT NULL REFERENCES properties(id),
    "userId" TEXT NOT NULL REFERENCES users(uid),
    rating NUMERIC NOT NULL,
    comment TEXT,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Create images table
CREATE TABLE public.images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "propertyId" UUID REFERENCES properties(id),
    fileName TEXT NOT NULL,
    url TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.images ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can manage all users" ON public.users;

DROP POLICY IF EXISTS "Anyone can view published properties" ON public.properties;
DROP POLICY IF EXISTS "Owners can view own properties" ON public.properties;
DROP POLICY IF EXISTS "Owners can create properties" ON public.properties;
DROP POLICY IF EXISTS "Owners can update own properties" ON public.properties;
DROP POLICY IF EXISTS "Owners can delete own properties" ON public.properties;

DROP POLICY IF EXISTS "Users can manage own favorites" ON public.favorites;

DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Guests can create bookings" ON public.bookings;
DROP POLICY IF EXISTS "Hosts can update bookings" ON public.bookings;

DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON public.reviews;

DROP POLICY IF EXISTS "Anyone can view images" ON public.images;
DROP POLICY IF EXISTS "Authenticated users can manage images" ON public.images;

-- Create policies for users
-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid()::text = uid);

-- Users can insert their own profile (during signup)
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid()::text = uid);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid()::text = uid);

-- Admins can do everything (assuming role check)
CREATE POLICY "Admins can manage all users" ON public.users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE uid = auth.uid()::text AND role = 'admin'
        )
    );

-- Create policies for properties
-- Anyone can read published and available properties
CREATE POLICY "Anyone can view published properties" ON public.properties
    FOR SELECT USING (status = 'published' AND "isAvailable" = true);

-- Owners can read their own properties (including drafts)
CREATE POLICY "Owners can view own properties" ON public.properties
    FOR SELECT USING (auth.uid()::text = "ownerId");

-- Owners and hosts can create properties
CREATE POLICY "Owners can create properties" ON public.properties
    FOR INSERT WITH CHECK (
        auth.uid()::text = "ownerId" AND
        EXISTS (
            SELECT 1 FROM public.users
            WHERE uid = auth.uid()::text AND (role = 'owner' OR role = 'admin')
        )
    );

-- Owners can update their own properties
CREATE POLICY "Owners can update own properties" ON public.properties
    FOR UPDATE USING (auth.uid()::text = "ownerId");

-- Owners and admins can delete properties
CREATE POLICY "Owners can delete own properties" ON public.properties
    FOR DELETE USING (
        auth.uid()::text = "ownerId" OR
        EXISTS (
            SELECT 1 FROM public.users
            WHERE uid = auth.uid()::text AND role = 'admin'
        )
    );

-- For favorites
CREATE POLICY "Users can manage own favorites" ON public.favorites
    FOR ALL USING (auth.uid()::text = "userId");

-- For bookings
CREATE POLICY "Users can view own bookings" ON public.bookings
    FOR SELECT USING (
        auth.uid()::text = guest_id OR
        auth.uid()::text = host_id OR
        EXISTS (
            SELECT 1 FROM public.users
            WHERE uid = auth.uid()::text AND role = 'admin'
        )
    );

CREATE POLICY "Guests can create bookings" ON public.bookings
    FOR INSERT WITH CHECK (
        auth.uid()::text = guest_id AND
        EXISTS (
            SELECT 1 FROM public.users
            WHERE uid = auth.uid()::text AND role = 'tenant'
        )
    );

CREATE POLICY "Hosts can update bookings" ON public.bookings
    FOR UPDATE USING (
        auth.uid()::text = host_id OR
        EXISTS (
            SELECT 1 FROM public.users
            WHERE uid = auth.uid()::text AND role = 'admin'
        )
    );

-- For reviews
CREATE POLICY "Anyone can view reviews" ON public.reviews
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create reviews" ON public.reviews
    FOR INSERT WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Users can update own reviews" ON public.reviews
    FOR UPDATE USING (auth.uid()::text = "userId");

-- For images
CREATE POLICY "Anyone can view images" ON public.images
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage images" ON public.images
    FOR ALL USING (auth.uid()::text = (SELECT "ownerId" FROM public.properties WHERE id = "propertyId"));

-- Create indexes for better performance
CREATE INDEX idx_properties_city ON public.properties(city);
CREATE INDEX idx_properties_price ON public.properties(price);
CREATE INDEX idx_properties_status ON public.properties(status);
CREATE INDEX idx_properties_owner ON public.properties("ownerId");
CREATE INDEX idx_favorites_user ON public.favorites("userId");
CREATE INDEX idx_favorites_property ON public.favorites("propertyId");
CREATE INDEX idx_bookings_guest ON public.bookings(guest_id);
CREATE INDEX idx_bookings_host ON public.bookings(host_id);
CREATE INDEX idx_bookings_property ON public.bookings(property_id);
CREATE INDEX idx_reviews_property ON public.reviews("propertyId");
CREATE INDEX idx_images_property ON public.images("propertyId");