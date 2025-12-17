-- ============================================
-- TRAVEL GOALS MIGRATION
-- ============================================
-- Create travel_goals table for setting and tracking travel goals

CREATE TABLE IF NOT EXISTS travel_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL, -- 'countries', 'continents', 'visited_count', 'distance'
  target_value INTEGER NOT NULL,
  current_value INTEGER DEFAULT 0,
  deadline DATE,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE travel_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for travel_goals
CREATE POLICY "Users can view their own travel goals"
  ON travel_goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own travel goals"
  ON travel_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own travel goals"
  ON travel_goals FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own travel goals"
  ON travel_goals FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_travel_goals_user_id ON travel_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_travel_goals_completed ON travel_goals(is_completed);

