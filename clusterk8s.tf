terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "t1.9euelZqby87GypHIxsaVz8_KmZfJnu3rnpWaxsqUi5aKy5jNmpSJls7JkZ7l8_dbHwte-e9zG185_d3z9xtOCF7573MbXzn9.9-eOhx4EByeVet05zIqH9w9dWncfuKdpTTxUdURU8BLIAsZMFltTUpNNh3tArU9R4en_UcfcwZXOG9o4ejUYDQ"
  cloud_id  = "b1gitvdobutfgdjuj4sv"
  folder_id = "b1gt4i78feq1qvjpen4m"
  zone      = "ru-central1-a"
}

resource "yandex_kubernetes_cluster" "k8scluster" {
 name = "k8scluster"
 description = "Kubernetes cluster"
 network_id = yandex_vpc_network.k8snet.id
 master {
   zonal {
     zone      = yandex_vpc_subnet.k8ssubnet.zone
     subnet_id = yandex_vpc_subnet.k8ssubnet.id
     }
     public_ip = true
     security_group_ids = [yandex_vpc_security_group.k8s-public-services.id]
   }
   service_account_id      = yandex_iam_service_account.servacc.id
   node_service_account_id = yandex_iam_service_account.servacc.id
   depends_on = [
     yandex_resourcemanager_folder_iam_member.editor,
     yandex_resourcemanager_folder_iam_member.images-puller
   ]
 }

resource "yandex_vpc_network" "k8snet" { name = "k8snet" }

resource "yandex_vpc_subnet" "k8ssubnet" {
 v4_cidr_blocks = ["192.168.10.0/24"]
 zone           = "ru-central1-a"
 network_id     = yandex_vpc_network.k8snet.id
}

resource "yandex_iam_service_account" "servacc" {
 name        = "servacc"
 description = "<описание сервисного аккаунта>"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
 # Сервисному аккаунту назначается роль "editor".
 folder_id = "b1gt4i78feq1qvjpen4m"
 role      = "editor"
 member    = "serviceAccount:${yandex_iam_service_account.servacc.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
 # Сервисному аккаунту назначается роль "container-registry.images.puller".
 folder_id = "b1gt4i78feq1qvjpen4m"
 role      = "container-registry.images.puller"
 member    = "serviceAccount:${yandex_iam_service_account.servacc.id}"
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.k8snet.id
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера и сервисов."
    v4_cidr_blocks    = concat(yandex_vpc_subnet.k8ssubnet.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ICMP"
    description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 30000
    to_port           = 32767
  }
  egress {
    protocol          = "ANY"
    description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}