locals {
  product_information = {
    context : {
      project    = "cartographie-nationale"
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
  projectTitle = title(replace(local.product_information.context.project, "-", " "))
  layerTitle   = title(replace(local.product_information.context.layer, "-", " "))
  serviceTitle = title(replace(local.product_information.context.service, "-", " "))
}

locals {
  service = {
    cartographie-nationale = {
      name = "cartographie-nationale"
      client = {
        name  = "client"
        title = "client"
      }
    }
  }
}
