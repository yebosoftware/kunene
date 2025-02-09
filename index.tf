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

# Providers

provider "digitalocean" {
  token = var.digital_ocean_access_token
}

provider "supabase" {
  access_token = var.supabase_access_token
}

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

# 2. Create a DigitalOcean project
resource "digitalocean_project" "playground" {
  name        = var.digital_ocean_project_name
  description = var.digital_ocean_project_description
  purpose     = "Web Application"
  environment = "Development"
}

resource "digitalocean_app" "golang-sample-1" {
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
    }
  }

  project_id = digitalocean_project.playground.id  # Reference the project created earlier
}

output "digital_ocean_app_url" {
  value       = digitalocean_app.golang-sample-1.url
  description = "The URL of the DigitalOcean App Platform app"
}