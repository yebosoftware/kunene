terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    supabase = {
      source  = "supabase/supabase"
      version = "1.5.1"
    }
  }

  # backend "s3" {
  #   bucket = "your-space-name"     # DigitalOcean Space name
  #   region = "nyc3"                # Space region (e.g., nyc3, sfo2)
  #   key    = "path/to/statefile.tfstate"  # Path within the Space (e.g., `myproject/terraform.tfstate`)
  #   access_key = "your-access-key"  # DigitalOcean access key
  #   secret_key = "your-secret-key"  # DigitalOcean secret key
  #   endpoint = "nyc3.digitaloceanspaces.com"  # Endpoint for DigitalOcean Spaces (nyc3, sfo2, etc.)
  #   acl = "private"               # Make the state file private
  # }
}

# Supabase
variable "supabase_access_token" {
  description = "Supabase API key"
  type        = string
  default     = ""
}

variable "supabase_organization_id" {
  description = "Supabase organization id"
  type        = string
  default     = ""
}

variable "supabase_project_region" {
  description = "Supabase project region"
  type        = string
  default     = ""
}

variable "supabase_project_name" {
  description = "Supabase project name"
  type        = string
  default     = ""
}

variable "supabase_database_password" {
  description = "Supabase database password"
  type        = string
  default     = ""
}

# Digital Ocean
variable "digital_ocean_access_token" {
  description = "Digital ocean access token"
  type        = string
  default     = ""
}

variable "digital_ocean_project_name" {
  description = "Digital ocean project name"
  type        = string
  default     = ""
}

variable "digital_ocean_project_description" {
  description = "Digital ocean project description"
  type        = string
  default     = ""
}

variable "supabase_build_dir" {
  description = "Digital ocean project description"
  type        = string
  default     = ""
}

# Providers

provider "digitalocean" {
  token = var.digital_ocean_access_token
}

provider "supabase" {
  access_token = var.supabase_access_token
}

provider "time" {}

# 1. Create a Supabase project
resource "supabase_project" "test" {
  organization_id   = var.supabase_organization_id
  name              = var.supabase_project_name
  database_password = var.supabase_database_password
  region            = var.supabase_project_region

  lifecycle {
    ignore_changes = [
      database_password,
      instance_size,
    ]
  }
}

# Need this to keep checking when the resource is ready
resource "null_resource" "supabase_polling" {
  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      MAX_RETRIES=10
      RETRY_DELAY=30 # Delay in seconds

      for i in $(seq 1 $MAX_RETRIES); do
        STATUS=$(curl -s -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" https://api.supabase.com/v1/projects/$SUPABASE_PROJECT_REF | jq -r '.status')

        if [[ "$STATUS" == "ACTIVE_HEALTHY" ]]; then
          echo "Supabase is ready!"
          exit 0
        else
          echo "Supabase not ready. Attempt $i/$MAX_RETRIES..."
          sleep $RETRY_DELAY
        fi
      done

      echo "Max retries reached. Supabase is not ready."
      exit 0
    EOT

    environment = {
      SUPABASE_ACCESS_TOKEN = var.supabase_access_token
      SUPABASE_PROJECT_REF = supabase_project.test.id
    }
  }
}

data "supabase_apikeys" "test_keys" {
  project_ref = supabase_project.test.id
  depends_on = [ null_resource.supabase_polling ]
}

# Sleep
resource "time_sleep" "wait_1_minute" {
  create_duration = "120s"
  depends_on = [ data.supabase_apikeys.test_keys ]
}

# Supabase cli link to project
resource "null_resource" "supabase_db_migrations" {
  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      cd $SUPABASE_BUILD_DIR
      SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN npx supabase link --project-ref $SUPABASE_PROJECT_REF --password $SUPABASE_DATABASE_PASSWORD
      # SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN npx supabase db push
      # SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN npx supabase functions deploy
      exit 0
    EOT

    environment = {
      SUPABASE_ACCESS_TOKEN = var.supabase_access_token
      SUPABASE_PROJECT_REF = supabase_project.test.id
      SUPABASE_DATABASE_PASSWORD = var.supabase_database_password
      SUPABASE_BUILD_DIR = var.supabase_build_dir
    }
  }
  depends_on = [ time_sleep.wait_1_minute ]
}

# Create a DigitalOcean project
resource "digitalocean_project" "playground" {
  name        = var.digital_ocean_project_name
  description = var.digital_ocean_project_description
  purpose     = "Web Application"
  environment = "Development"
  depends_on = [null_resource.supabase_db_migrations]
}

resource "digitalocean_app" "golang_sample_1" {
  project_id = digitalocean_project.playground.id  # Reference the project created earlier

  spec {
    name   = "golang-sample-1"
    region = "ams"

    service {
      name               = "go-service"
      instance_count     = 1
      instance_size_slug = "apps-s-1vcpu-1gb"

      git {
        repo_clone_url = "https://github.com/digitalocean/sample-golang.git"
        branch         = "main"
      }

      env {
        key   = "SUPABASE_ANON_KEY"
        value = data.supabase_apikeys.test_keys.anon_key
        scope = "RUN_TIME"
      }

      env {
        key   = "SUPABASE_SERVICE_ROLE_KEY"
        value = data.supabase_apikeys.test_keys.service_role_key
        scope = "RUN_TIME"
      }
    }
  }
}

output "digital_ocean_app_url" {
  value       = digitalocean_app.golang_sample_1.live_url
  description = "The URL of the DigitalOcean App Platform app"
}