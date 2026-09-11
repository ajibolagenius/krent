-- ==============================================================================
-- FindRent (Nigeria) — Database Schema & Security Policies (Supabase / PostgreSQL)
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. Custom Types & Enums
CREATE TYPE user_role AS ENUM ('tenant', 'landlord', 'agent', 'admin');
CREATE TYPE verification_status AS ENUM ('unverified', 'pending', 'verified', 'rejected');
CREATE TYPE property_type AS ENUM ('self_contain', 'mini_flat', 'two_bedroom', 'three_bedroom', 'duplex', 'shared_apartment', 'terrace');
CREATE TYPE power_band AS ENUM ('Band A', 'Band B', 'Band C', 'Band D', 'Off-grid');
CREATE TYPE power_generator_type AS ENUM ('central_estate_247', 'central_estate_scheduled', 'private_generators_allowed', 'no_generators_allowed');
CREATE TYPE water_source_type AS ENUM ('industrial_treatment_plant', 'treated_borehole', 'raw_borehole', 'state_waterworks', 'well_water');
CREATE TYPE flood_risk_level AS ENUM ('low_dry', 'moderate_puddling', 'high_flood_risk');
CREATE TYPE property_status AS ENUM ('draft', 'pending_review', 'published', 'rented', 'archived');
CREATE TYPE inspection_status AS ENUM ('scheduled', 'completed', 'tenant_no_show', 'agent_no_show', 'cancelled');
CREATE TYPE escrow_status AS ENUM ('held', 'disbursed', 'refunded', 'disputed');
CREATE TYPE tenancy_status AS ENUM ('draft', 'active', 'renewed', 'terminated', 'defaulted');
CREATE TYPE payment_channel AS ENUM ('paystack_transfer', 'paystack_card', 'monnify_transfer', 'rnpl_financing');

-- 3. Profiles Table (Linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number VARCHAR(16) UNIQUE NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(255) UNIQUE,
  role user_role NOT NULL DEFAULT 'tenant',
  verification_status verification_status NOT NULL DEFAULT 'unverified',
  
  -- Identity & Verification (Nigeria KYC)
  nin_hash VARCHAR(64),
  bvn_hash VARCHAR(64),
  cac_number VARCHAR(32),
  agency_name VARCHAR(150),
  real_estate_license_id VARCHAR(50), -- ERCAAN, NIESV, or state agency
  kyc_verified_at TIMESTAMPTZ,
  
  -- Profile Details
  avatar_url TEXT,
  bio TEXT,
  rating NUMERIC(3, 2) DEFAULT 5.00,
  total_reviews INT DEFAULT 0,
  is_phone_verified BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Properties Table
CREATE TABLE IF NOT EXISTS public.properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- General Property Details
  title VARCHAR(220) NOT NULL,
  description TEXT NOT NULL,
  type property_type NOT NULL,
  bedrooms SMALLINT NOT NULL DEFAULT 1,
  bathrooms SMALLINT NOT NULL DEFAULT 1,
  toilets SMALLINT NOT NULL DEFAULT 1,
  is_serviced BOOLEAN DEFAULT false,
  is_furnished BOOLEAN DEFAULT false,

  -- Itemized Nigerian Financial Breakdown (All in NGN)
  annual_rent NUMERIC(14, 2) NOT NULL,
  service_charge NUMERIC(14, 2) DEFAULT 0.00,
  caution_deposit NUMERIC(14, 2) DEFAULT 0.00,
  legal_fee_percentage NUMERIC(4, 2) DEFAULT 5.00 CHECK (legal_fee_percentage <= 10.00),
  agency_fee_percentage NUMERIC(4, 2) DEFAULT 5.00 CHECK (agency_fee_percentage <= 10.00),
  
  -- Hyper-Local Nigerian Infrastructure Indicators
  power_band power_band NOT NULL DEFAULT 'Band B',
  power_generator_type power_generator_type NOT NULL DEFAULT 'private_generators_allowed',
  generator_schedule VARCHAR(120), -- e.g. "7:00 PM - 7:00 AM weekdays, 24hrs weekends"
  water_source water_source_type NOT NULL DEFAULT 'treated_borehole',
  flood_risk flood_risk_level NOT NULL DEFAULT 'low_dry',
  is_gated_estate BOOLEAN DEFAULT false,
  estate_name VARCHAR(150),
  estate_security_type VARCHAR(100) DEFAULT 'Manned Gate + Resident Access Code',
  annual_estate_dues NUMERIC(12, 2) DEFAULT 0.00,

  -- Location & PostGIS Spatial Geometry
  address TEXT NOT NULL,
  neighborhood VARCHAR(120) NOT NULL, -- e.g. Lekki Phase 1, Yaba, Ikeja GRA, Gwarinpa
  city VARCHAR(80) NOT NULL DEFAULT 'Lagos',
  state VARCHAR(80) NOT NULL DEFAULT 'Lagos',
  location GEOGRAPHY(Point, 4326),

  -- Media & Status
  images TEXT[] NOT NULL DEFAULT '{}',
  video_walkthrough_url TEXT,
  status property_status NOT NULL DEFAULT 'draft',
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES public.profiles(id),
  verified_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial and Filtering Indexes
CREATE INDEX IF NOT EXISTS idx_properties_location ON public.properties USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_properties_status ON public.properties (status);
CREATE INDEX IF NOT EXISTS idx_properties_price ON public.properties (annual_rent);
CREATE INDEX IF NOT EXISTS idx_properties_city_neighborhood ON public.properties (city, neighborhood);
CREATE INDEX IF NOT EXISTS idx_properties_owner ON public.properties (owner_id);

-- 5. Inspections Table (Booking + Anti-Extortion Escrow)
CREATE TABLE IF NOT EXISTS public.inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  scheduled_at TIMESTAMPTZ NOT NULL,
  status inspection_status NOT NULL DEFAULT 'scheduled',
  
  -- Commitment Fee Escrow
  escrow_fee NUMERIC(10, 2) NOT NULL DEFAULT 3000.00, -- e.g. ₦3,000 commitment
  escrow_status escrow_status NOT NULL DEFAULT 'held',
  payment_reference VARCHAR(100),
  
  tenant_check_in TIMESTAMPTZ,
  agent_check_in TIMESTAMPTZ,
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Tenancies & Agreements Table
CREATE TABLE IF NOT EXISTS public.tenancies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  landlord_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  agent_id UUID REFERENCES public.profiles(id),

  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  -- Financial Terms
  agreed_rent NUMERIC(14, 2) NOT NULL,
  service_charge NUMERIC(14, 2) DEFAULT 0.00,
  caution_deposit NUMERIC(14, 2) DEFAULT 0.00,
  legal_fee NUMERIC(14, 2) NOT NULL,
  agency_commission NUMERIC(14, 2) NOT NULL,
  total_initial_payment NUMERIC(14, 2) NOT NULL,
  
  payment_channel payment_channel NOT NULL DEFAULT 'paystack_transfer',
  is_rnpl_financed BOOLEAN DEFAULT false,
  rnpl_provider VARCHAR(50), -- Carbon, Credit Direct, etc.

  -- Digital Agreement Execution
  agreement_pdf_url TEXT,
  tenant_signed_at TIMESTAMPTZ,
  landlord_signed_at TIMESTAMPTZ,
  
  status tenancy_status NOT NULL DEFAULT 'draft',
  keys_handed_over_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Escrow Transactions Table
CREATE TABLE IF NOT EXISTS public.escrow_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenancy_id UUID REFERENCES public.tenancies(id) ON DELETE RESTRICT,
  inspection_id UUID REFERENCES public.inspections(id) ON DELETE RESTRICT,
  payer_id UUID NOT NULL REFERENCES public.profiles(id),
  
  total_amount NUMERIC(14, 2) NOT NULL,
  landlord_payout NUMERIC(14, 2) DEFAULT 0.00,
  agent_payout NUMERIC(14, 2) DEFAULT 0.00,
  platform_fee NUMERIC(14, 2) DEFAULT 0.00,
  
  paystack_reference VARCHAR(100) UNIQUE,
  paystack_subaccount_code VARCHAR(100),
  status escrow_status NOT NULL DEFAULT 'held',
  disbursed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Spatial Search Function (Find Properties within Radius)
CREATE OR REPLACE FUNCTION search_properties_nearby(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_meters DOUBLE PRECISION DEFAULT 10000,
  max_rent NUMERIC DEFAULT 100000000,
  req_bedrooms INT DEFAULT NULL
)
RETURNS SETOF public.properties AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.properties
  WHERE status = 'published'
    AND annual_rent <= max_rent
    AND (req_bedrooms IS NULL OR bedrooms = req_bedrooms)
    AND ST_DWithin(
      location,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_meters
    )
  ORDER BY location <-> ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography;
END;
$$ LANGUAGE plpgsql STABLE;

-- 9. Row Level Security (RLS) Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenancies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_transactions ENABLE ROW LEVEL SECURITY;

-- Profiles: Public can view verified agents/landlords; Users edit own profile
CREATE POLICY "Public profiles are viewable by everyone" 
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Properties: Published properties are viewable by everyone; Owners manage their listings
CREATE POLICY "Anyone can view published properties" 
  ON public.properties FOR SELECT USING (status = 'published' OR auth.uid() = owner_id);

CREATE POLICY "Verified owners and agents can create listings" 
  ON public.properties FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their own listings" 
  ON public.properties FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their own listings" 
  ON public.properties FOR DELETE USING (auth.uid() = owner_id);
