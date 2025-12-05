-- SQL script to create or update the required tables in Supabase
-- Run this in your Supabase SQL editor

-- IMPORTANT: After running this script, ensure you have:
-- 1. Created a storage bucket named 'images' in Supabase Dashboard > Storage
-- 2. Made it public
-- 3. Storage policies are set below

-- Storage policies for 'images' bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('images', 'images', true) ON CONFLICT (id) DO NOTHING;

-- Drop existing policies to avoid conflicts when recreating them
DROP POLICY IF EXISTS "Allow public read access on images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own images" ON storage.objects;

CREATE POLICY "Allow public read access on images" ON storage.objects FOR SELECT USING (bucket_id = 'images');
CREATE POLICY "Allow authenticated users to upload images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'images' AND auth.role() = 'authenticated');
CREATE POLICY "Allow users to update their own images" ON storage.objects FOR UPDATE USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Allow users to delete their own images" ON storage.objects FOR DELETE USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    uid TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    "firstName" TEXT, -- Made nullable
    "lastName" TEXT, -- Made nullable
    role TEXT DEFAULT 'tenant',
    "profileImageUrl" TEXT,
    "isHost" BOOLEAN DEFAULT false,
    city TEXT,
    country TEXT,
    bio TEXT,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ,
    "fcmToken" TEXT, -- Added for Push Notifications
    "kycStatus" TEXT DEFAULT 'unverified' -- can be: unverified, pending, verified, rejected
);

-- Ensure new columns exist for users (safe update)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'fcmToken') THEN
        ALTER TABLE public.users ADD COLUMN "fcmToken" TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'kycStatus') THEN
        ALTER TABLE public.users ADD COLUMN "kycStatus" TEXT DEFAULT 'unverified';
    END IF;
END $$;

-- Create properties table
CREATE TABLE IF NOT EXISTS public.properties (
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

-- Ensure new columns exist for properties
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'latitude') THEN
        ALTER TABLE public.properties ADD COLUMN latitude NUMERIC;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'longitude') THEN
        ALTER TABLE public.properties ADD COLUMN longitude NUMERIC;
    END IF;
END $$;

-- Create favorites table
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES users(uid),
    "propertyId" UUID NOT NULL REFERENCES properties(id),
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE("userId", "propertyId")
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guest_id TEXT NOT NULL REFERENCES users(uid),
    property_id UUID NOT NULL REFERENCES properties(id),
    host_id TEXT NOT NULL REFERENCES users(uid),
    check_in_date TIMESTAMPTZ NOT NULL,
    check_out_date TIMESTAMPTZ,
    total_price NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "propertyId" UUID NOT NULL REFERENCES properties(id),
    "userId" TEXT NOT NULL REFERENCES users(uid),
    rating NUMERIC NOT NULL,
    comment TEXT,
    "createdAt" TIMESTAMpTZ DEFAULT NOW()
);

-- Create images table
CREATE TABLE IF NOT EXISTS public.images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "propertyId" UUID REFERENCES properties(id),
    fileName TEXT NOT NULL,
    url TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES users(uid),
    "planId" TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    "startDate" TIMESTAMPTZ NOT NULL,
    "endDate" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- NEW: CHAT SYSTEM TABLES
-- Create conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "propertyId" UUID REFERENCES properties(id),
    participants TEXT[] NOT NULL, -- Array of user UIDs
    "lastMessage" TEXT,
    "lastMessageTime" TIMESTAMPTZ DEFAULT NOW(),
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "conversationId" UUID REFERENCES conversations(id) ON DELETE CASCADE,
    "senderId" TEXT NOT NULL REFERENCES users(uid),
    content TEXT,
    "mediaUrl" TEXT,
    "mediaType" TEXT DEFAULT 'text', -- text, image, video
    "isRead" BOOLEAN DEFAULT false,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- NEW: TICKET SYSTEM TABLES
-- Create tickets table
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" TEXT NOT NULL REFERENCES users(uid),
    "propertyId" UUID NOT NULL REFERENCES properties(id),
    "hostId" TEXT NOT NULL REFERENCES users(uid),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open', -- e.g., open, in_progress, resolved, closed
    priority TEXT DEFAULT 'medium', -- e.g., low, medium, high
    images TEXT[],
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Create ticket_comments table
CREATE TABLE IF NOT EXISTS public.ticket_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    "ticketId" UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    "userId" TEXT NOT NULL REFERENCES users(uid),
    content TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- NEW: Function and Trigger to create user profile on sign up
-- This function will be called by the trigger below
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (uid, email)
  VALUES (new.id::text, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- This trigger will call the function when a new user is created in auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users; -- Drop if it exists to avoid errors
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Helper function to check user's host status
CREATE OR REPLACE FUNCTION is_host(user_uid TEXT)
RETURNS BOOLEAN AS $$
  SELECT "isHost" FROM public.users WHERE uid = user_uid;
$$ LANGUAGE sql SECURITY DEFINER;

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to recreate them
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;

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

DROP POLICY IF EXISTS "Users can manage own subscriptions" ON public.subscriptions;

-- Drop Chat Policies
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can insert conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can view messages" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages" ON public.messages;

-- Drop Ticket Policies
DROP POLICY IF EXISTS "Users can manage their own tickets" ON public.tickets;
DROP POLICY IF EXISTS "Hosts can view tickets for their properties" ON public.tickets;
DROP POLICY IF EXISTS "Users can manage comments on their tickets" ON public.ticket_comments;

-- Create policies for users
CREATE POLICY "Users can view their own data" ON public.users
    FOR SELECT USING (uid = auth.uid()::text);
CREATE POLICY "Users can update their own data" ON public.users
    FOR UPDATE USING (uid = auth.uid()::text);

-- Create policies for properties
CREATE POLICY "Anyone can view published properties" ON public.properties
    FOR SELECT USING (status != 'rented' AND "isAvailable" = true);

CREATE POLICY "Owners can view own properties" ON public.properties
    FOR SELECT USING ("ownerId" = auth.uid()::text); 
    
CREATE POLICY "Owners can create properties" ON public.properties
    FOR INSERT WITH CHECK (
      "ownerId" = auth.uid()::text AND
      is_host(auth.uid()::text)
      -- AND (SELECT "kycStatus" FROM public.users WHERE uid = auth.uid()::text) = 'verified' -- Add this line back when KYC is ready
    );

CREATE POLICY "Owners can update own properties" ON public.properties
    FOR UPDATE USING (
      "ownerId" = auth.uid()::text AND
      is_host(auth.uid()::text)
    );

CREATE POLICY "Owners can delete own properties" ON public.properties
    FOR DELETE USING (
      "ownerId" = auth.uid()::text AND
      is_host(auth.uid()::text)
    );

-- For favorites
CREATE POLICY "Users can manage own favorites" ON public.favorites
    FOR ALL USING ("userId" = auth.uid()::text);

-- For bookings
CREATE POLICY "Users can view own bookings" ON public.bookings
    FOR SELECT USING (guest_id = auth.uid()::text OR host_id = auth.uid()::text);

CREATE POLICY "Guests can create bookings" ON public.bookings
    FOR INSERT WITH CHECK (guest_id = auth.uid()::text);

CREATE POLICY "Hosts can update bookings" ON public.bookings
    FOR UPDATE USING (host_id = auth.uid()::text);

-- For reviews
CREATE POLICY "Anyone can view reviews" ON public.reviews
    FOR SELECT USING (true);
    
CREATE POLICY "Authenticated users can create reviews" ON public.reviews
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    
CREATE POLICY "Users can update own reviews" ON public.reviews
    FOR UPDATE USING ("userId" = auth.uid()::text);

-- For images
CREATE POLICY "Anyone can view images" ON public.images
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage images" ON public.images
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- For subscriptions
CREATE POLICY "Users can manage own subscriptions" ON public.subscriptions
    FOR ALL USING ("userId" = auth.uid()::text);

-- Policies for Chat
CREATE POLICY "Users can view their conversations" ON public.conversations
    FOR SELECT USING (auth.uid()::text = ANY(participants));

CREATE POLICY "Users can insert conversations" ON public.conversations
    FOR INSERT WITH CHECK (auth.uid()::text = ANY(participants));

CREATE POLICY "Users can update their conversations" ON public.conversations
    FOR UPDATE USING (auth.uid()::text = ANY(participants));

CREATE POLICY "Users can view messages" ON public.messages
    FOR SELECT USING (
        "conversationId" IN (
            SELECT id FROM public.conversations WHERE auth.uid()::text = ANY(participants)
        )
    );

CREATE POLICY "Users can insert messages" ON public.messages
    FOR INSERT WITH CHECK ("senderId" = auth.uid()::text);


-- Policies for Tickets
CREATE POLICY "Users can manage their own tickets" ON public.tickets
    FOR ALL USING ("userId" = auth.uid()::text);

CREATE POLICY "Hosts can view tickets for their properties" ON public.tickets
    FOR SELECT USING ("hostId" = auth.uid()::text);

CREATE POLICY "Users can manage comments on their tickets" ON public.ticket_comments
    FOR ALL USING ("userId" = auth.uid()::text);
