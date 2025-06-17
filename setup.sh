#!/usr/bin/env bash
set -euo pipefail

# 1. Comprobar que somos root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# 2. Habilitar repositorios extra y multilib en /etc/pacman.conf
sed -i '/^\[extra\]/,/Include/ s/^#//' /etc/pacman.conf
sed -i '/^\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Sy  # refrescar base de datos

# 3. Actualizar todo el sistema
pacman -Syu --noconfirm

# 4. Instalar herramientas de desarrollo básicas y Git
pacman -S --needed --noconfirm base-devel git

# 5. Instalar paquetes de repositorio oficial
pacman -S --needed --noconfirm \
  # Kernel y firmware
  linux linux-headers linux-firmware intel-ucode kmod \
  # Wayland + KDE Plasma 6
  xorg-xwayland plasma-meta kde-applications-meta plasma-wayland-session sddm \
  # Red y conectividad
  networkmanager plasma-nm network-manager-applet wpa_supplicant wireless_tools \
  bluez bluez-utils bluedevil blueman \
  pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils pavucontrol \
  usbutils udisks2 udiskie \
  # Virtualización
  qemu qemu-full libvirt dnsmasq virt-manager virt-viewer bridge-utils ebtables virt-install \
  seabios edk2-ovmf \
  # Contenedores
  lxc lxd docker docker-compose \
  podman podman-docker cockpit cockpit-podman \
  # Multimedia
  ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
  libdvdcss libva-intel-driver libva-vdpau-driver vdpau-driver \
  # Software usuario
  flatpak \
  # Desarrollo
  python python-pip rust go jdk-openjdk nodejs npm \
  cmake meson ninja gdb clang \
  # Hardware / diagnóstico
  inxi hwinfo lshw dmidecode pciutils \
  # CLI de sistema
  htop fastfetch neofetch glances iotop ncdu btop tmux screen \
  # Bajo nivel y módulos
  dkms kexec-tools acpi acpid cpupower \
  # Utilidades comunes
  wget curl tar unzip zip rsync git man-db man-pages which sudo chrony systemd-timesyncd gedit \
  # NVIDIA + optimización gaming
  nvidia nvidia-utils lib32-nvidia-utils mangohud lib32-mangohud gamescope gamemode \
  steam lutris wine \
  # Seguridad / sandbox
  nsjail \
  # Snapshots
  snapper \
  # GRUB y herramientas
  grub efibootmgr os-prober

# 6. Instalar xen desde AUR (no está en repos oficiales)
cd /tmp
git clone https://aur.archlinux.org/xen.git
cd xen
makepkg -si --noconfirm
cd /
rm -rf /tmp/xen

# 7. Instalar AUR helper (paru)
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd /
rm -rf /tmp/paru

# 8. Instalar paquetes AUR opcionales
paru -S --noconfirm --needed \
  aqemu snapper-gui btrfs-assistant grub-customizer podman-desktop heroic-games-launcher-bin

# 9. Configurar Flatpak y aplicaciones de Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y \
  flathub org.libreoffice.LibreOffice \
  flathub org.videolan.VLC \
  flathub tv.kodi.Kodi \
  flathub org.librewolf.Librewolf \
  flathub com.visualstudio.code

# 10. Habilitar y arrancar servicios systemd
systemctl enable \
  sddm NetworkManager bluetooth libvirtd lxd docker \
  snapper-timeline.timer snapper-cleanup.timer

systemctl start \
  sddm NetworkManager bluetooth libvirtd lxd docker \
  snapper-timeline.timer snapper-cleanup.timer

echo -e "\n¡Instalación completada! Reinicia el sistema para cargar todo correctamente."

# Esperar que el usuario presione una tecla
read -n 1 -s -r -p "Presiona cualquier tecla para reiniciar..."

# Reiniciar el sistema
reboot
