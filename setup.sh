#!/usr/bin/env bash
set -euo pipefail

# 1. ¿root?
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# 2. Habilitar extra y multilib en /etc/pacman.conf
for repo in extra multilib; do
  sed -i "/^\[$repo\]/,/^Include/ s/^#//" /etc/pacman.conf
done
pacman -Sy

# 3. Actualizar sistema
pacman -Syu --noconfirm

# 4. Paquetes oficiales por categoría

PKGS_basics=(
  base-devel        # repo: core, descripción: Herramientas básicas de desarrollo
  git               # repo: core, descripción: Control de versiones Git
)

PKGS_kernel=(
  linux             # repo: core, descripción: Kernel de Linux
  linux-headers     # repo: core, descripción: Cabeceras del kernel de Linux
  linux-firmware    # repo: core, descripción: Firmware del kernel
  intel-ucode       # repo: core, descripción: Microcódigo CPUs Intel
  kmod              # repo: core, descripción: Gestión de módulos
)

PKGS_desktop=(
  xorg-xwayland              # repo: extra, descripción: Servidor X en Wayland
  plasma-meta                # repo: extra, descripción: Metapaquete KDE Plasma
  kde-applications-meta      # repo: extra, descripción: Metapaquete apps KDE
  sddm                       # repo: extra, descripción: Gestor de sesiones SDDM
)

PKGS_network=(
  networkmanager            # repo: extra, descripción: Gestor de red
  plasma-nm                 # repo: extra, descripción: Applet red Plasma
  network-manager-applet    # repo: extra, descripción: Applet GTK NM
  wpa_supplicant            # repo: extra, descripción: Cliente WPA/WPA2 Wi-Fi
  wireless_tools            # repo: core, descripción: Herramientas Wi-Fi
  bluez                     # repo: extra, descripción: Bluetooth
  bluez-utils               # repo: extra, descripción: Utilidades Bluetooth
  bluedevil                 # repo: extra, descripción: Integración BT en KDE
  blueman                   # repo: extra, descripción: Applet Bluetooth GTK
  pipewire                  # repo: extra, descripción: Servidor multimedia
  pipewire-pulse            # repo: extra, descripción: PulseAudio en PipeWire
  pipewire-alsa             # repo: extra, descripción: ALSA en PipeWire
  wireplumber               # repo: extra, descripción: Gestor PipeWire
  alsa-utils                # repo: extra, descripción: Utilidades ALSA
  pavucontrol               # repo: extra, descripción: Control de volumen
  usbutils                  # repo: core, descripción: Herramientas USB
  udisks2                   # repo: extra, descripción: Servicio discos
  udiskie                   # repo: extra, descripción: Auto-desmonte discos
)

PKGS_virtualization=(
  libvirt           # repo: extra, descripción: API VMs
  dnsmasq           # repo: extra, descripción: DNS/DHCP liviano
  virt-manager      # repo: extra, descripción: GUI VMs
  virt-viewer       # repo: extra, descripción: Visor consolas VMs
  bridge-utils      # repo: extra, descripción: Puentes de red
  ebtables          # repo: extra, descripción: Filtrado bridging
  virt-install      # repo: extra, descripción: Script instalación VMs
  seabios           # repo: extra, descripción: BIOS QEMU/SeaBIOS
  edk2-ovmf         # repo: extra, descripción: UEFI para QEMU
)

PKGS_containers=(
  lxc               # repo: extra, descripción: Contenedores Linux
  lxd               # repo: extra, descripción: Demonio LXD
  docker            # repo: extra, descripción: Plataforma Docker
  docker-compose    # repo: extra, descripción: Orquestador Docker
  podman            # repo: extra, descripción: Contenedores sin demonio
  cockpit           # repo: extra, descripción: GUI web servidores
  cockpit-podman    # repo: extra, descripción: Módulo Podman en Cockpit
)

PKGS_multimedia=(
  ffmpeg                 # repo: extra, descripción: Audio/video
  gst-plugins-base       # repo: extra, descripción: GStreamer básico
  gst-plugins-good       # repo: extra, descripción: GStreamer “good”
  gst-plugins-bad        # repo: extra, descripción: GStreamer “bad”
  gst-plugins-ugly       # repo: extra, descripción: GStreamer “ugly”
  gst-libav              # repo: extra, descripción: Libav en GStreamer
  libdvdcss              # repo: extra, descripción: Desencriptar DVDs
  libva-intel-driver     # repo: extra, descripción: VA-API Intel
)

PKGS_user=(
  flatpak       # repo: extra, descripción: Plataforma de apps
)

PKGS_development=(
  python        # repo: core, descripción: Python
  python-pip    # repo: extra, descripción: Pip para Python
  rust          # repo: extra, descripción: Rust
  go            # repo: extra, descripción: Go
  jdk-openjdk   # repo: extra, descripción: Java OpenJDK
  nodejs        # repo: extra, descripción: Node.js
  npm           # repo: extra, descripción: NPM
  cmake         # repo: extra, descripción: CMake
  meson         # repo: extra, descripción: Meson
  ninja         # repo: extra, descripción: Ninja
  gdb           # repo: extra, descripción: Depurador GDB
  clang         # repo: extra, descripción: Compilador Clang
)

PKGS_hardware=(
  inxi          # repo: extra, descripción: Info sistema
  hwinfo        # repo: extra, descripción: Info hardware
  lshw          # repo: extra, descripción: Listado hardware
  dmidecode     # repo: extra, descripción: DMI/SMBIOS
  pciutils      # repo: core, descripción: Bus PCI
)

PKGS_cli=(
  htop         # repo: extra, descripción: Monitor procesos
  fastfetch    # repo: extra, descripción: Info sistema ASCII
  glances      # repo: extra, descripción: Monitor consola
  iotop        # repo: extra, descripción: I/O procesos
  ncdu         # repo: extra, descripción: Análisis disco
  btop         # repo: extra, descripción: Monitor C++
  tmux         # repo: extra, descripción: Multiplexor terminal
  screen       # repo: extra, descripción: Multiplexor clásico
)

PKGS_modules=(
  dkms         # repo: extra, descripción: DKMS
  kexec-tools  # repo: extra, descripción: kexec
  acpi         # repo: extra, descripción: Info ACPI
  acpid        # repo: extra, descripción: Demonio ACPI
  cpupower     # repo: extra, descripción: Gestión CPU
)

PKGS_utils=(
  wget                 # repo: extra, descripción: Descargas web
  curl                 # repo: extra, descripción: Transferencia URL
  tar                  # repo: core, descripción: Archivador
  unzip                # repo: extra, descripción: Descompresión ZIP
  zip                  # repo: extra, descripción: Compresión ZIP
  rsync                # repo: extra, descripción: Sincronización
  man-db               # repo: extra, descripción: DB páginas man
  man-pages            # repo: extra, descripción: Páginas de man
  which                # repo: core, descripción: Localizar ejecutables
  sudo                 # repo: extra, descripción: Ejecutar como otro
  chrony               # repo: extra, descripción: Cliente NTP
  gedit                # repo: extra, descripción: Editor GTK
)

PKGS_gaming=(
  nvidia              # repo: extra, descripción: Drivers NVIDIA
  nvidia-utils        # repo: extra, descripción: Libs NVIDIA
  lib32-nvidia-utils  # repo: multilib, descripción: Libs 32-bit
  mangohud            # repo: extra, descripción: OSD benchmarks
  lib32-mangohud      # repo: multilib, descripción: OSD 32-bit
  gamescope           # repo: extra, descripción: Compositor juegos
  gamemode            # repo: extra, descripción: Optimización juegos
  steam               # repo: multilib, descripción: Steam
  lutris              # repo: extra, descripción: Gestor de juegos
  wine                # repo: multilib, descripción: Windows apps
)

PKGS_security=(
  nsjail   # repo: extra, descripción: Sandbox ligero
)

PKGS_snapshots=(
  snapper  # repo: extra, descripción: Snapshots Btrfs
)

PKGS_bootloader=(
  grub         # repo: core, descripción: GRUB
  efibootmgr   # repo: extra, descripción: EFI entries
  os-prober    # repo: extra, descripción: Detecta otros S.O.
)

# 5. Instalar paquetes oficiales
pacman -S --needed --noconfirm \
  "${PKGS_basics[@]}" \
  "${PKGS_kernel[@]}" \
  "${PKGS_desktop[@]}" \
  "${PKGS_network[@]}" \
  "${PKGS_virtualization[@]}" \
  "${PKGS_containers[@]}" \
  "${PKGS_multimedia[@]}" \
  "${PKGS_user[@]}" \
  "${PKGS_development[@]}" \
  "${PKGS_hardware[@]}" \
  "${PKGS_cli[@]}" \
  "${PKGS_modules[@]}" \
  "${PKGS_utils[@]}" \
  "${PKGS_gaming[@]}" \
  "${PKGS_security[@]}" \
  "${PKGS_snapshots[@]}" \
  "${PKGS_bootloader[@]}"

# 6. Compilar e instalar paru (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si --noconfirm
cd / && rm -rf /tmp/paru

# 7. Instalación de AUR
paru -S --needed --noconfirm \
  aqemu \
  snapper-gui \
  btrfs-assistant \
  grub-customizer \
  podman-desktop \
  heroic-games-launcher-bin \
  qemu-full \
  libva-vdpau-driver \
  vdpau-driver

# 8. Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y \
  org.libreoffice.LibreOffice \
  org.videolan.VLC \
  tv.kodi.Kodi \
  org.librewolf.Librewolf \
  org.gimp.GIMP \
  com.visualstudio.code

# 9. Habilitar y arrancar servicios
systemctl enable \
  sddm NetworkManager bluetooth libvirtd lxd docker \
  snapper-timeline.timer snapper-cleanup.timer

systemctl start \
  sddm NetworkManager bluetooth libvirtd lxd docker \
  snapper-timeline.timer snapper-cleanup.timer

# 10. Pausa y reboot
echo -e "\n¡Instalación completada!"
read -n1 -s -r -p "Presiona cualquier tecla para reiniciar..."
echo
reboot
