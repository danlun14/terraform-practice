resource "yandex_kubernetes_node_group" "k8snodes" {
  cluster_id = "${yandex_kubernetes_cluster.k8scluster.id}"
  name = "k8s-nodes"
  instance_template {
    platform_id = "standard-v2"
    resources {
      cores = 2
      memory = 2
    }
    boot_disk {
      type = "network-hdd"
      size = 64
    }
    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.k8ssubnet.id}"]
    }
    container_runtime {
     type = "docker"
    }
    metadata = {
      "ssh-keys" = "admin:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYHYUWdRvW7c9oQTKiXP4pz6Qguajq/mn82AkMTBYAT"
    }
  }
  scale_policy {
    fixed_scale {
      size = 2
    }
  }
}