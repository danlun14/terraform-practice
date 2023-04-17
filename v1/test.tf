terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.89.0"
    }
  }
}

provider "yandex" {
  token     = "t1.9euelZqby87GypHIxsaVz8_KmZfJnu3rnpWaxsqUi5aKy5jNmpSJls7JkZ7l8_dbHwte-e9zG185_d3z9xtOCF7573MbXzn9.9-eOhx4EByeVet05zIqH9w9dWncfuKdpTTxUdURU8BLIAsZMFltTUpNNh3tArU9R4en_UcfcwZXOG9o4ejUYDQ"
  cloud_id  = "b1gitvdobutfgdjuj4sv"
  folder_id = "b1gt4i78feq1qvjpen4m"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "my-first-vm" {
  name        = "test-instance"
  platform_id = "standard-v1" # тип процессора (Intel Broadwell)

  resources {
    cores  = 2 # vCPU
    memory = 2 # RAM
  }

  boot_disk {
    initialize_params {
      image_id = "fd8haecqq3rn9ch89eua" # ОС (Ubuntu, 22.04 LTS)
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id # одна из дефолтных подсетей
    nat       = true                   # автоматически установить динамический ip
  }
  metadata = {
    user-data = "${file("./users.txt")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_my-first-vm" {
  value = yandex_compute_instance.my-first-vm.network_interface.0.ip_address
}

output "external_ip_address_my-first-vm" {
  value = yandex_compute_instance.my-first-vm.network_interface.0.nat_ip_address
}
