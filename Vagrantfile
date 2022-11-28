Vagrant.configure("2") do |config|
      config.vm.box = "debian/buster64"
      config.vm.define "vagrant-kubeflow"
      config.vm.provider :virtualbox do |vb|
          vb.name = "vbox-vagrant-kubeflow"
          vb.memory = 6144
          vb.cpus = 2
      end
      config.vm.provision :shell, path: "./scripts/bootstrap.sh"
      config.vm.network :forwarded_port, guest: 8887, host: 8887, host_ip:"127.0.0.1"
      config.vm.network :forwarded_port, guest: 8888, host: 8888, host_ip:"127.0.0.1"
end