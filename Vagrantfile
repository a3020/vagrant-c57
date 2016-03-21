# This is ruby syntax. 2 is the Vagrant version
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  
  # This stuff is executed as root
  config.vm.provision "shell", path: "bootstrap.sh"
  #config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
  
  # http://127.0.0.1:8080
  config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true
  
  config.vm.network "private_network", type: "dhcp"
end
