#!/usr/bin/env bash
set -euo pipefail

# 1. root?
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# 2. habilitar extra y multilib
sed -i '/^\[extra\]/,/^Include/ s/^#//' /etc/pacman.conf
sed -i '/^\[multilib\]/,/^Include/ s/^#//' /etc/pacman.conf
pacman -Sy

# 3. actualizar
pacman -Syu --noconfirm

# 4. base-devel + git
pacman -S --needed --noconfirm base-devel git

# 5. paquetes oficiales
PKGS=(
  # Kernel y firmware
  linux linux-headers linux-firmware intel-ucode kmod
  # Wayland + KDE Plasma 6
  xorg-xwayland plasma-meta kde-applications-meta plasma-wayland-session sddm
  # Red y conectividad
  networkmanager plasma-nm network-manager-applet wpa_supplicant wireless_tools
  bluez bluez-utils bluedevil blueman
  pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils pavucontrol
  usbutils udisks2 udiskie
  # Virtualización
  qemu qemu-full libvirt dnsmasq virt-manager virt-viewer bridge-utils ebtables virt-install
  seabios edk2-ovmf
  # Contenedores
  lxc lxd docker docker-compose
  podman podman-docker cockpit cockpit-podman
  # Multimedia
  ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
  libdvdcss libva-intel-driver libva-vdpau-driver vdpau-driver
  # Usuario
  flatpak
  # Desarrollo
  python python-pip rust go jdk-openjdk nodejs npm
  cmake meson ninja gdb clang
  # Hardware / diagnóstico
  inxi hwinfo lshw dmidecode pciutils
  # CLI
  htop fastfetch neofetch glances iotop ncdu btop tmux screen
  # Módulos y bajo nivel
  dkms kexec-tools acpi acpid cpupower
  # Utilidades
  wget curl tar unzip zip rsync git man-db man-pages which sudo chrony systemd-timesyncd gedit
  # Gaming / NVIDIA
  nvidia nvidia-utils lib32-nvidia-utils mangohud lib32-mangohud gamescope gamemode
  steam lutris wine
  # Seguridad / sandbox
  nsjail
  # Snapshots
  snapper
  # GRUB y herramientas
  grub efibootmgr os-prober
)

pacman -S --needed --noconfirm "${PKGS[@]}"


# 6. xen (AUR)
cd /tmp
git clone https://aur.archlinux.org/xen.git
cd xen && makepkg -si --noconfirm
cd / && rm -rf /tmp/xen

# 7. paru (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si --noconfirm
cd / && rm -rf /tmp/paru

# 8. AUR opcionales
paru -S --needed --noconfirm \
  aqemu snapper-gui btrfs-assistant grub-customizer podman-desktop heroic-games-launcher-bin

# 9. Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y \
  org.libreoffice.LibreOffice org.videolan.VLC tv.kodi.Kodi \
  org.librewolf.Librewolf org.gimp.GIMP com.visualstudio.code

# 10. servicios
systemctl enable sddm NetworkManager bluetooth libvirtd lxd docker \
               snapper-timeline.timer snapper-cleanup.timer
systemctl start  sddm NetworkManager bluetooth libvirtd lxd docker \
               snapper-timeline.timer snapper-cleanup.timer

# 11. pausa y reboot
echo -e "\n¡Instalación completada!"
read -n1 -s -r -p "Presiona cualquier tecla para reiniciar..."
echo
reboot
