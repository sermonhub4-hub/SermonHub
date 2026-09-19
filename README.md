# SermonHub

A clean black-and-white sermon streaming PWA built with Next.js 16, React 19 and Supabase.

## Run locally

1. Copy `.env.example` to `.env.local`.
2. Add your Supabase URL and publishable key.
3. Run `npm install`.
4. Run `npm run dev`.

## Deploy to Vercel

Import this repository/project into Vercel and add the same environment variables under Project Settings → Environment Variables.

## Supabase

The SQL in `supabase/schema.sql` creates the core tables, indexes, RLS policies, profile trigger, and secure admin authorization structure. Create your first user in Supabase Auth, then add their UUID to `public.admin_users` as shown in the SQL comments.

Never put a Supabase service-role key in client-side code.
