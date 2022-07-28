locals {
  product_information = {
    context : {
      project    = "cartographie_nationale"
      layer      = "infrastructure"
      service    = "network"
      start_date = "2022-04-01"
      end_date   = "unknown"
    }
    purpose : {
      disaster_recovery = "medium"
      service_class     = "bronze"
    }
    organization : {
      client = "anct"
    }
    stakeholders : {
      business_owner  = "celestin.leroux@beta.gouv.fr"
      technical_owner = "marc.gavanier@beta.gouv.fr"
      approver        = "marc.gavanier@beta.gouv.fr"
      creator         = "terraform"
      team            = "cartographie-nationale"
    }
  }
}

locals {
  projectTitle = title(replace(local.product_information.context.project, "_", " "))
  layerTitle   = title(replace(local.product_information.context.layer, "_", " "))
  serviceTitle = title(replace(local.product_information.context.service, "_", " "))
  domainNames  = ["cartographie.societenumerique.gouv.fr", "tribe-taxi.com"]
}

locals {
  service = {
    cartographie_nationale = {
      name = "cartographie_nationale"
      api = {
        name  = "api"
        title = "api"
      }
      client = {
        name  = "client"
        title = "client"
      }
    }
  }
}
