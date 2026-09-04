# DevJournal — Complete Supabase & GitHub Authentication Setup Guide

This guide details all necessary steps to connect your **Supabase Cloud Database**, **Supabase Auth**, and **GitHub OAuth 2.0** to DevJournal.

---

## 1. Supabase Setup & Database Schema

### Step 1: Create a Supabase Project
1. Go to [Supabase.com](https://supabase.com) and create a free project named **DevJournal**.
2. Go to **Project Settings → API** and copy:
   - **Project URL** (e.g., `https://xyzcompany.supabase.co`)
   - **anon / public key**

### Step 2: Create Database Tables (SQL Schema)
Open the **SQL Editor** in your Supabase Dashboard and run the following query:

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Journal Entries Table
create table public.journal_entries (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    title text not null,
    content text,
    date timestamp with time zone default timezone('utc'::text, now()),
    mood text default '😄',
    focus_level text default 'High',
    hours_spent numeric(4,2) default 2.5,
    tags text[],
    git_hub_repo_name text,
    is_synced_with_supabase boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. Projects Table
create table public.projects (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    name text not null,
    project_description text,
    category text default 'Personal Project',
    progress numeric(3,2) default 0.0,
    status text default 'Active',
    git_hub_repo_name text,
    commits_count integer default 0,
    prs_count integer default 0,
    issues_count integer default 0,
    stars_count integer default 0,
    updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Enable Row Level Security (RLS)
alter table public.journal_entries enable row level security;
alter table public.projects enable row level security;

-- Create RLS Policies so users only read/write their own data
create policy "Users can perform all actions on their journal entries"
    on public.journal_entries for all
    using (auth.uid() = user_id);

create policy "Users can perform all actions on their projects"
    on public.projects for all
    using (auth.uid() = user_id);
```

---

## 2. GitHub OAuth 2.0 Integration

### Step 1: Create a GitHub Developer OAuth App
1. Go to [GitHub Developer Settings → OAuth Apps](https://github.com/settings/developers).
2. Click **New OAuth App**:
   - **Application Name**: `DevJournal iOS`
   - **Homepage URL**: `https://github.com/daddychill1414/SWIFT_DEVJOURNAL`
   - **Authorization callback URL**: `devjournal://oauth-callback` (or your Supabase auth callback URL: `https://<YOUR_SUPABASE_ID>.supabase.co/auth/v1/callback`)
3. Copy your **Client ID** and generate a **Client Secret**.

---

## 3. Configuring Xcode & Environment Credentials

Add your secrets into Xcode Scheme Environment Variables:

1. Open Xcode -> **Product → Scheme → Edit Scheme...** (`Cmd + <`).
2. Select **Run** on the left menu, then click **Arguments**.
3. Under **Environment Variables**, add:

| Variable Name | Example Value | Description |
|---|---|---|
| `SUPABASE_URL` | `https://your-project.supabase.co` | Supabase API endpoint |
| `SUPABASE_ANON_KEY` | `eyJhbGciOi...` | Supabase Anonymous Key |
| `GITHUB_CLIENT_ID` | `Ov23...` | GitHub OAuth Client ID |

---

## 4. Swift Code Integration Reference

In [SupabaseService.swift](file:///z:/CODES%21%21%21%21%20SSD/DEVJOURNAL/DevJournal/Services/SupabaseService.swift), replace the fallback execution with the official `supabase-swift` package call:

```swift
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()
    
    let client = SupabaseClient(
        supabaseURL: URL(string: AppConfiguration.supabaseURL)!,
        supabaseKey: AppConfiguration.supabaseAnonKey
    )
    
    func syncJournalEntry(_ entry: JournalEntry) async throws {
        try await client.from("journal_entries").insert(entry).execute()
        entry.isSyncedWithSupabase = true
    }
}
```
