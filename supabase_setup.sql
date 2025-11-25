-- SQL script to create the required tables in Supabase
-- Run this in your Supabase SQL editor

-- IMPORTANT: After running this script, you MUST also:
-- 1. Create a storage bucket named 'images' in Supabase Dashboard > Storage
-- 2. Make it public
-- 3. Run the following SQL to set storage policies:

-- Storage policies for 'images' bucket (run after creating the bucket)
INSERT INTO storage.buckets (id, name, public) VALUES ('images', 'images', true) ON CONFLICT DO NOTHING;
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

-- Create policies for users
CREATE POLICY "Allow all operations on users" ON public.users FOR ALL USING (true);

-- Create policies for properties
CREATE POLICY "Allow all operations on properties" ON public.properties
    FOR ALL USING (true);

-- Update existing properties to published status (for development)
UPDATE public.properties SET status = 'published' WHERE status = 'draft';

-- Update existing properties to published status (for development)
UPDATE public.properties SET status = 'published' WHERE status = 'draft';

-- For favorites, allow all operations
CREATE POLICY "Allow all operations on favorites" ON public.favorites
    FOR ALL USING (true);

-- For bookings
CREATE POLICY "Allow all operations on bookings" ON public.bookings
    FOR ALL USING (true);

-- For reviews
CREATE POLICY "Allow all operations on reviews" ON public.reviews FOR ALL USING (true);

-- For images
CREATE POLICY "Allow all operations on images" ON public.images FOR ALL USING (true);

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