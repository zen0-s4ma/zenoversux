#!/usr/bin/env bash
set -euo pipefail

# 1. root?
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# 2. Habilitar extra, community y multilib en /etc/pacman.conf
for repo in extra community multilib; do
  sed -i "/^\[$repo\]/,/^Include/ s/^#//" /etc/pacman.conf
done
pacman -Sy

# 3. actualizar
pacman -Syu --noconfirm

# 4. paquetes oficiales
# Definición de paquetes por categoría

if pacman -Qi iptables &>/dev/null; then
  pacman -Rs --noconfirm iptables
fi

PKGS_basics=(
  base-devel        # repo: core, descripción: Herramientas basicas de desarrollo 
  git               # repo: core, descripción: Herramienta git para gestion de repositorios de codigo
)

PKGS_kernel=(
  linux             # repo: core, descripción: Kernel de Linux
  linux-headers     # repo: core, descripción: Cabeceras del kernel de Linux
  linux-firmware    # repo: core, descripción: Firmware para dispositivos del kernel
  intel-ucode       # repo: core, descripción: Microcódigo actualizado para CPUs Intel
  kmod              # repo: core, descripción: Utilidades para gestión de módulos del kernel
  base-devel        # repo: core, descripción: Grupo de herramientas esenciales de desarrollo
)

PKGS_desktop=(
  xorg-xwayland              # repo: extra, descripción: Servidor X en Wayland
  plasma-meta                # repo: extra, descripción: Metapaquete de KDE Plasma
  kde-applications-meta      # repo: extra, descripción: Metapaquete de aplicaciones KDE
  sddm                       # repo: extra, descripción: Gestor de sesiones SDDM
)

PKGS_network=(
  networkmanager            # repo: extra, descripción: Gestión de conexiones de red
  plasma-nm                 # repo: extra, descripción: Applet de red para Plasma
  network-manager-applet    # repo: extra, descripción: Applet GTK para NetworkManager
  wpa_supplicant            # repo: extra, descripción: Cliente para WPA/WPA2 Wi-Fi
  wireless_tools            # repo: core, descripción: Herramientas para configuración inalámbrica
  bluez                     # repo: extra, descripción: Protocolo Bluetooth
  bluez-utils               # repo: extra, descripción: Utilidades Bluetooth
  bluedevil                 # repo: extra, descripción: Integración Bluetooth en KDE
  blueman                   # repo: extra, descripción: Applet Bluetooth GTK
  pipewire                  # repo: extra, descripción: Servidor multimedia
  pipewire-pulse            # repo: extra, descripción: Módulo de PulseAudio para PipeWire
  pipewire-alsa             # repo: extra, descripción: Módulo ALSA para PipeWire
  wireplumber               # repo: extra, descripción: Gestor de sesiones PipeWire
  alsa-utils                # repo: extra, descripción: Utilidades ALSA de audio
  pavucontrol               # repo: extra, descripción: Control de volumen de PulseAudio
  usbutils                  # repo: core, descripción: Herramientas para dispositivos USB
  udisks2                   # repo: extra, descripción: Servicio de gestión de discos
  udiskie                   # repo: extra, descripción: Applet de desmontaje automático
)

PKGS_virtualization=(
  libvirt           # repo: extra, descripción: API para gestión de máquinas virtuales
  dnsmasq           # repo: extra, descripción: Servidor DNS/DHCP liviano
  virt-manager      # repo: extra, descripción: GUI para gestionar virtualización
  virt-viewer       # repo: extra, descripción: Visor de consolas de VMs
  bridge-utils      # repo: extra, descripción: Herramientas para puentes de red
  ebtables          # repo: extra, descripción: Filtrado Ethernet bridging
  virt-install      # repo: extra, descripción: Script de instalación de VMs
  seabios           # repo: extra, descripción: BIOS de QEMU/SeaBIOS
  edk2-ovmf         # repo: extra, descripción: Firmware UEFI para QEMU
)

PKGS_containers=(
  lxc               # repo: extra, descripción: Contenedores Linux
  lxd               # repo: extra, descripción: Demonio LXD con REST API
  docker            # repo: extra, descripción: Plataforma de contenedores Docker
  docker-compose    # repo: extra, descripción: Orquestador de contenedores
  podman            # repo: extra, descripción: Contenedores sin demonio
  cockpit           # repo: extra, descripción: Interfaz web de gestión de servidores
  cockpit-podman    # repo: extra, descripción: Módulo Podman para Cockpit
)

PKGS_multimedia=(
  ffmpeg                 # repo: extra, descripción: Procesamiento de audio/video
  gst-plugins-base       # repo: extra, descripción: Plugins básicos GStreamer
  gst-plugins-good       # repo: extra, descripción: Plugins "buenos" GStreamer
  gst-plugins-bad        # repo: extra, descripción: Plugins "malos" GStreamer
  gst-plugins-ugly       # repo: extra, descripción: Plugins "feos" GStreamer
  gst-libav              # repo: extra, descripción: Plugins de Libav para GStreamer
  libdvdcss              # repo: extra, descripción: Biblioteca para descifrar DVDs
  libva-intel-driver     # repo: extra, descripción: Driver VA-API para Intel
)

PKGS_user=(
  flatpak       # repo: extra, descripción: Plataforma de despliegue de apps
)

PKGS_development=(
  python        # repo: core, descripción: Lenguaje de programación Python
  python-pip    # repo: extra, descripción: Gestor de paquetes Python
  rust          # repo: extra, descripción: Lenguaje de programación Rust
  go            # repo: extra, descripción: Lenguaje de programación Go
  jdk-openjdk   # repo: extra, descripción: Entorno Java OpenJDK
  nodejs        # repo: extra, descripción: Entorno JavaScript
  npm           # repo: extra, descripción: Gestor de paquetes JS
  cmake         # repo: extra, descripción: Herramienta de compilación
  meson         # repo: extra, descripción: Sistema de construcción moderno
  ninja         # repo: extra, descripción: Constructor rápido
  gdb           # repo: extra, descripción: Depurador GNU
  clang         # repo: extra, descripción: Compilador C/C++
)

PKGS_hardware=(
  inxi          # repo: extra, descripción: Información del sistema
  hwinfo        # repo: extra, descripción: Proveedor de info de hardware
  lshw          # repo: extra, descripción: Listado de hardware
  dmidecode     # repo: extra, descripción: Info de tablas DMI/SMBIOS
  pciutils      # repo: core, descripción: Herramientas para bus PCI
)

PKGS_cli=(
  htop         # repo: extra, descripción: Monitor de procesos interactivo
  fastfetch    # repo: extra, descripción: Info del sistema tipo Neofetch
  glances      # repo: extra, descripción: Monitor de sistema en consola
  iotop        # repo: extra, descripción: Monitor de I/O por procesos
  ncdu         # repo: extra, descripción: Analizador de disco en consola
  btop         # repo: extra, descripción: Monitor de recursos en C++
  tmux         # repo: extra, descripción: Multiplexor de terminales
  screen       # repo: extra, descripción: Multiplexor de terminales clásico
)

PKGS_modules=(
  dkms         # repo: extra, descripción: Gestión dinámica de módulos
  kexec-tools  # repo: extra, descripción: Herramientas para reinicio rápido
  acpi         # repo: extra, descripción: Información de ACPI
  acpid        # repo: extra, descripción: Demonio de eventos ACPI
  cpupower     # repo: extra, descripción: Gestión de frecuencia CPU
)

PKGS_utils=(
  wget              # repo: extra, descripción: Descarga de archivos web
  curl              # repo: extra, descripción: Transferencia de datos con URL
  tar               # repo: core, descripción: Archivador de archivos
  unzip             # repo: extra, descripción: Descompresión de ZIP
  zip               # repo: extra, descripción: Compresión ZIP
  rsync             # repo: extra, descripción: Sincronización de archivos
  git               # repo: extra, descripción: Control de versiones Git
  man-db            # repo: extra, descripción: Base de datos de man pages
  man-pages         # repo: extra, descripción: Páginas de manual del sistema
  which             # repo: core, descripción: Localizador de ejecutables
  sudo              # repo: extra, descripción: Ejecutar comandos como otro usuario
  chrony            # repo: extra, descripción: Cliente NTP
  gedit             # repo: extra, descripción: Editor de texto GTK
)

PKGS_gaming=(
  nvidia              # repo: extra, descripción: Drivers propietarios NVIDIA
  nvidia-utils        # repo: extra, descripción: Bibliotecas NVIDIA
  lib32-nvidia-utils  # repo: multilib, descripción: Bibliotecas NVIDIA 32-bit
  mangohud            # repo: extra, descripción: OSD para benchmarks de juegos
  lib32-mangohud      # repo: multilib, descripción: OSD 32-bit para juegos
  gamescope           # repo: extra, descripción: Compositor para juegos
  gamemode            # repo: extra, descripción: Optimización de rendimiento juegos
  steam               # repo: multilib, descripción: Plataforma de Valve
  lutris              # repo: extra, descripción: Gestión de juegos
  wine                # repo: multilib, descripción: Ejecutar apps Windows
)

PKGS_security=(
  nsjail   # repo: extra, descripción: Sandbox ligero
)

PKGS_snapshots=(
  snapper  # repo: extra, descripción: Gestor de snapshots Btrfs
)

PKGS_bootloader=(
  grub         # repo: core, descripción: Gestor de arranque GRUB
  efibootmgr   # repo: extra, descripción: Gestión de entradas EFI
  os-prober    # repo: extra, descripción: Detecta otros S.O.
)

# Instalación de paquetes oficiales
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

# 5. paru (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si --noconfirm
cd / && rm -rf /tmp/paru

# 6. AUR opcionales
paru -S --needed --noconfirm \
  xen \
  aqemu \
  snapper-gui \
  btrfs-assistant \
  grub-customizer \
  podman-desktop \
  heroic-games-launcher-bin \
  qemu-full \
  libva-vdpau-driver \
  vdpau-driver

# 7. Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y \
  org.libreoffice.LibreOffice org.videolan.VLC tv.kodi.Kodi \
  org.librewolf.Librewolf org.gimp.GIMP com.visualstudio.code

# 8. servicios
systemctl enable sddm NetworkManager bluetooth libvirtd lxd docker \
               snapper-timeline.timer snapper-cleanup.timer
systemctl start  sddm NetworkManager bluetooth libvirtd lxd docker \
               snapper-timeline.timer snapper-cleanup.timer

# 11. pausa y reboot
echo -e "\n¡Instalación completada!"
read -n1 -s -r -p "Presiona cualquier tecla para reiniciar..."
echo
reboot
