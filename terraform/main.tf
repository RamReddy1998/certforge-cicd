provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = "certforge-app"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifact_registry]
}

resource "google_cloud_run_service" "app" {
  name     = "certforge-app"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/certforge-app/app:latest"
        ports {
          container_port = 3000
        }
        env {
          name  = "PORT"
          value = "3000"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run_api]
}

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.app.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
