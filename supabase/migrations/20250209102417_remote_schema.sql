
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$DECLARE
  organization_id bigint;
BEGIN
  -- Insert a new organization using the raw_meta_data field
  INSERT INTO public.organizations (name)
  VALUES (new.raw_user_meta_data->>'organization_name')
  RETURNING id INTO organization_id;

  -- Insert the profile with the organization_id
  INSERT INTO public.profiles (id, full_name, avatar_url, organization_id)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url', organization_id);

  RETURN new;
END;$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."flow_templates" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_disabled" boolean DEFAULT false
);

ALTER TABLE "public"."flow_templates" OWNER TO "postgres";

ALTER TABLE "public"."flow_templates" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."flow_templates_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."flows" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "flow_template_id" bigint,
    "organization_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "data" "jsonb"
);

ALTER TABLE "public"."flows" OWNER TO "postgres";

ALTER TABLE "public"."flows" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."flows_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."node_templates" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "flow_template_id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "node_type_id" bigint NOT NULL
);

ALTER TABLE "public"."node_templates" OWNER TO "postgres";

ALTER TABLE "public"."node_templates" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."node_templates_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."node_types" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."node_types" OWNER TO "postgres";

ALTER TABLE "public"."node_types" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."node_types_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."nodes" (
    "id" bigint NOT NULL,
    "flow_id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "node_type_id" bigint NOT NULL,
    "latest_upload_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."nodes" OWNER TO "postgres";

ALTER TABLE "public"."nodes" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."nodes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."organizations" OWNER TO "postgres";

ALTER TABLE "public"."organizations" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."organizations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "username" "text",
    "full_name" "text",
    "avatar_url" "text",
    "website" "text",
    "organization_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "username_length" CHECK (("char_length"("username") >= 3))
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."uploads" (
    "id" bigint NOT NULL,
    "node_id" bigint NOT NULL,
    "filename" "text" NOT NULL,
    "upload_date" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."uploads" OWNER TO "postgres";

ALTER TABLE "public"."uploads" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."uploads_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."user_types" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."user_types" OWNER TO "postgres";

ALTER TABLE "public"."user_types" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."user_types_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY "public"."flow_templates"
    ADD CONSTRAINT "flow_templates_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."flows"
    ADD CONSTRAINT "flows_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."node_templates"
    ADD CONSTRAINT "node_templates_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."node_types"
    ADD CONSTRAINT "node_types_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");

ALTER TABLE ONLY "public"."uploads"
    ADD CONSTRAINT "uploads_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."user_types"
    ADD CONSTRAINT "user_types_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."flows"
    ADD CONSTRAINT "flows_flow_template_id_fkey" FOREIGN KEY ("flow_template_id") REFERENCES "public"."flow_templates"("id");

ALTER TABLE ONLY "public"."flows"
    ADD CONSTRAINT "flows_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id");

ALTER TABLE ONLY "public"."node_templates"
    ADD CONSTRAINT "node_templates_flow_template_id_fkey" FOREIGN KEY ("flow_template_id") REFERENCES "public"."flow_templates"("id");

ALTER TABLE ONLY "public"."node_templates"
    ADD CONSTRAINT "node_templates_node_type_id_fkey" FOREIGN KEY ("node_type_id") REFERENCES "public"."node_types"("id");

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_flow_id_fkey" FOREIGN KEY ("flow_id") REFERENCES "public"."flows"("id");

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_latest_upload_id_fkey" FOREIGN KEY ("latest_upload_id") REFERENCES "public"."uploads"("id");

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_node_type_id_fkey" FOREIGN KEY ("node_type_id") REFERENCES "public"."node_types"("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id");

ALTER TABLE ONLY "public"."uploads"
    ADD CONSTRAINT "uploads_node_id_fkey" FOREIGN KEY ("node_id") REFERENCES "public"."nodes"("id");

CREATE POLICY "Allow a user to only select their own uploads " ON "public"."uploads" FOR SELECT TO "authenticated" USING (("node_id" IN ( SELECT "nodes"."id"
   FROM "public"."nodes"
  WHERE ("nodes"."flow_id" IN ( SELECT "flows"."id"
           FROM "public"."flows"
          WHERE ("flows"."organization_id" = ( SELECT "profiles"."organization_id"
                   FROM "public"."profiles"
                  WHERE ("profiles"."id" = "auth"."uid"()))))))));

CREATE POLICY "Allow all authenticated to select" ON "public"."node_templates" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Allow all authenticated to select" ON "public"."node_types" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Allow all authenticated to select " ON "public"."flow_templates" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Allow users from Jump organization to select nodes" ON "public"."flows" FOR SELECT TO "authenticated" USING ((( SELECT "organizations"."name"
   FROM "public"."organizations"
  WHERE ("organizations"."id" = "flows"."organization_id")) = 'Jump'::"text"));

CREATE POLICY "Allow users to insert flows belonging to their organization" ON "public"."flows" FOR INSERT TO "authenticated" WITH CHECK (("organization_id" = ( SELECT "profiles"."organization_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));

CREATE POLICY "Allow users to insert nodes belonging to their organization's f" ON "public"."nodes" FOR INSERT TO "authenticated" WITH CHECK (("flow_id" IN ( SELECT "flows"."id"
   FROM "public"."flows"
  WHERE ("flows"."organization_id" = ( SELECT "profiles"."organization_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))));

CREATE POLICY "Allow users to insert uploads belonging to their organization's" ON "public"."uploads" FOR INSERT TO "authenticated" WITH CHECK (("node_id" IN ( SELECT "nodes"."id"
   FROM "public"."nodes"
  WHERE ("nodes"."flow_id" IN ( SELECT "flows"."id"
           FROM "public"."flows"
          WHERE ("flows"."organization_id" = ( SELECT "profiles"."organization_id"
                   FROM "public"."profiles"
                  WHERE ("profiles"."id" = "auth"."uid"()))))))));

CREATE POLICY "Allow users to only select flows of their own org" ON "public"."nodes" FOR SELECT TO "authenticated" USING (("flow_id" IN ( SELECT "flows"."id"
   FROM "public"."flows"
  WHERE ("flows"."organization_id" = ( SELECT "profiles"."organization_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))));

CREATE POLICY "Allow users to select flows belonging to their organization" ON "public"."flows" FOR SELECT TO "authenticated" USING (("organization_id" IN ( SELECT "profiles"."organization_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));

CREATE POLICY "Allow users to update nodes of their own org" ON "public"."nodes" FOR UPDATE TO "authenticated" USING (("flow_id" IN ( SELECT "flows"."id"
   FROM "public"."flows"
  WHERE ("flows"."organization_id" = ( SELECT "profiles"."organization_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))));

CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));

CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "id"));

ALTER TABLE "public"."flow_templates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."flows" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."node_templates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."node_types" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."nodes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."uploads" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."user_types" ENABLE ROW LEVEL SECURITY;

ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON TABLE "public"."flow_templates" TO "anon";
GRANT ALL ON TABLE "public"."flow_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."flow_templates" TO "service_role";

GRANT ALL ON SEQUENCE "public"."flow_templates_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."flow_templates_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."flow_templates_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."flows" TO "anon";
GRANT ALL ON TABLE "public"."flows" TO "authenticated";
GRANT ALL ON TABLE "public"."flows" TO "service_role";

GRANT ALL ON SEQUENCE "public"."flows_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."flows_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."flows_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."node_templates" TO "anon";
GRANT ALL ON TABLE "public"."node_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."node_templates" TO "service_role";

GRANT ALL ON SEQUENCE "public"."node_templates_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."node_templates_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."node_templates_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."node_types" TO "anon";
GRANT ALL ON TABLE "public"."node_types" TO "authenticated";
GRANT ALL ON TABLE "public"."node_types" TO "service_role";

GRANT ALL ON SEQUENCE "public"."node_types_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."node_types_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."node_types_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."nodes" TO "anon";
GRANT ALL ON TABLE "public"."nodes" TO "authenticated";
GRANT ALL ON TABLE "public"."nodes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."nodes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."nodes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."nodes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."organizations" TO "anon";
GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";

GRANT ALL ON SEQUENCE "public"."organizations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."organizations_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."organizations_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."uploads" TO "anon";
GRANT ALL ON TABLE "public"."uploads" TO "authenticated";
GRANT ALL ON TABLE "public"."uploads" TO "service_role";

GRANT ALL ON SEQUENCE "public"."uploads_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."uploads_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."uploads_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."user_types" TO "anon";
GRANT ALL ON TABLE "public"."user_types" TO "authenticated";
GRANT ALL ON TABLE "public"."user_types" TO "service_role";

GRANT ALL ON SEQUENCE "public"."user_types_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_types_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_types_id_seq" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
