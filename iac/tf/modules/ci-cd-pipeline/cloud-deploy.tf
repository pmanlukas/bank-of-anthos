resource "google_clouddeploy_target" "targets" {
  for_each = toset(var.targets)

  project  = var.project_id
  name     = "${each.value}-${var.team}"
  location = var.region

  gke {
    cluster = var.clusters[each.key].cluster.id
  }

  execution_configs{
      artifact_storage = "gs://${google_storage_bucket.delivery_artifacts.name}"
      service_account = google_service_account.cloud_deploy.email
      usages = [
          "RENDER",
          "DEPLOY"
      ]
  }
}

resource "google_clouddeploy_delivery_pipeline" "delivery-pipeline" {
  location = var.region
  name     = var.team
  serial_pipeline {
    dynamic "stages" {
      for_each = { for idx, target in var.targets : idx => target }
      content {
        profiles  = [stages.value]
        target_id = google_clouddeploy_target.targets[stages.value].name
      }
    }
  }
}