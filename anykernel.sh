### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=AIO Kernel Pack by superuseryu
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=sapphire
device.name2=sapphiren
supported.versions=13-16
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;


## boot install

# -- Flush stale key events from buffer --
flush_keys() {
  sleep 0.3;
}

# -- Step 1: Choose kernel source (GKI vs CLO) --
choose_source() {
  ui_print " ";
  ui_print "  Step 1: Select Kernel Source";
  ui_print "  VOL + = GKI (AOSP)";
  ui_print "  VOL - = CLO (CodeLinaro)";
  ui_print " ";

  flush_keys;
  while true; do
    input=$(getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN)");
    case "$input" in
      *KEY_VOLUMEUP*)
        return 1;
        ;;
      *KEY_VOLUMEDOWN*)
        return 2;
        ;;
    esac
    sleep 0.1;
  done
}

# -- Step 2: Choose KSU variant --
choose_ksu() {
  ui_print " ";
  ui_print "  Step 2: Select KSU Variant";
  ui_print "  VOL + = NoKSU (Vanilla)";
  ui_print "  VOL - = KSU (Wild-KSU + SUSFS)";
  ui_print " ";

  flush_keys;
  while true; do
    input=$(getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN)");
    case "$input" in
      *KEY_VOLUMEUP*)
        return 1;
        ;;
      *KEY_VOLUMEDOWN*)
        return 2;
        ;;
    esac
    sleep 0.1;
  done
}

# -- Detect available images --
HAS_GKI_KSU=0;
HAS_GKI_NOKSU=0;
HAS_CLO_KSU=0;
HAS_CLO_NOKSU=0;

[ -f "$AKHOME/Image.gki.ksu" ]   && HAS_GKI_KSU=1;
[ -f "$AKHOME/Image.gki.noksu" ] && HAS_GKI_NOKSU=1;
[ -f "$AKHOME/Image.clo.ksu" ]   && HAS_CLO_KSU=1;
[ -f "$AKHOME/Image.clo.noksu" ] && HAS_CLO_NOKSU=1;

SELECTED_IMAGE="";

# -- Check if AIO (all 4 images available) --
if [ "$HAS_GKI_KSU" = "1" ] && [ "$HAS_GKI_NOKSU" = "1" ] && \
   [ "$HAS_CLO_KSU" = "1" ] && [ "$HAS_CLO_NOKSU" = "1" ]; then

  # Step 1: GKI or CLO?
  choose_source;
  SOURCE=$?;

  # Step 2: KSU or NoKSU?
  choose_ksu;
  VARIANT=$?;

  if [ "$SOURCE" = "1" ] && [ "$VARIANT" = "2" ]; then
    SELECTED_IMAGE="Image.gki.ksu";
    ui_print "  >> GKI + Wild-KSU + SUSFS";
  elif [ "$SOURCE" = "1" ] && [ "$VARIANT" = "1" ]; then
    SELECTED_IMAGE="Image.gki.noksu";
    ui_print "  >> GKI Vanilla (NoKSU)";
  elif [ "$SOURCE" = "2" ] && [ "$VARIANT" = "2" ]; then
    SELECTED_IMAGE="Image.clo.ksu";
    ui_print "  >> CLO + Wild-KSU + SUSFS";
  elif [ "$SOURCE" = "2" ] && [ "$VARIANT" = "1" ]; then
    SELECTED_IMAGE="Image.clo.noksu";
    ui_print "  >> CLO Vanilla (NoKSU)";
  fi

# -- Fallback: partial combinations --
elif [ "$HAS_GKI_KSU" = "1" ] && [ "$HAS_GKI_NOKSU" = "1" ]; then
  choose_ksu;
  if [ $? = "2" ]; then
    SELECTED_IMAGE="Image.gki.ksu";
    ui_print "  >> GKI + Wild-KSU + SUSFS";
  else
    SELECTED_IMAGE="Image.gki.noksu";
    ui_print "  >> GKI Vanilla (NoKSU)";
  fi

elif [ "$HAS_CLO_KSU" = "1" ] && [ "$HAS_CLO_NOKSU" = "1" ]; then
  choose_ksu;
  if [ $? = "2" ]; then
    SELECTED_IMAGE="Image.clo.ksu";
    ui_print "  >> CLO + Wild-KSU + SUSFS";
  else
    SELECTED_IMAGE="Image.clo.noksu";
    ui_print "  >> CLO Vanilla (NoKSU)";
  fi

# -- Single image fallbacks --
elif [ "$HAS_GKI_KSU" = "1" ]; then
  SELECTED_IMAGE="Image.gki.ksu";
  ui_print "  >> GKI + Wild-KSU (auto)";
elif [ "$HAS_GKI_NOKSU" = "1" ]; then
  SELECTED_IMAGE="Image.gki.noksu";
  ui_print "  >> GKI Vanilla (auto)";
elif [ "$HAS_CLO_KSU" = "1" ]; then
  SELECTED_IMAGE="Image.clo.ksu";
  ui_print "  >> CLO + Wild-KSU (auto)";
elif [ "$HAS_CLO_NOKSU" = "1" ]; then
  SELECTED_IMAGE="Image.clo.noksu";
  ui_print "  >> CLO Vanilla (auto)";

# -- Legacy fallback: old naming (Image.ksu / Image.noksu) --
elif [ -f "$AKHOME/Image.ksu" ] && [ -f "$AKHOME/Image.noksu" ]; then
  ui_print "  Legacy package detected (Image.ksu + Image.noksu).";
  choose_ksu;
  if [ $? = "2" ]; then
    SELECTED_IMAGE="Image.ksu";
    ui_print "  >> KSU";
  else
    SELECTED_IMAGE="Image.noksu";
    ui_print "  >> NoKSU";
  fi
elif [ -f "$AKHOME/Image.ksu" ]; then
  SELECTED_IMAGE="Image.ksu";
  ui_print "  >> KSU (auto)";
elif [ -f "$AKHOME/Image.noksu" ]; then
  SELECTED_IMAGE="Image.noksu";
  ui_print "  >> NoKSU (auto)";
elif [ -f "$AKHOME/Image" ]; then
  ui_print "  Single kernel image found, flashing...";
else
  ui_print " ";
  ui_print "ERROR: No kernel image found!";
  ui_print "  Expected one of:";
  ui_print "  Image.gki.ksu / Image.gki.noksu";
  ui_print "  Image.clo.ksu / Image.clo.noksu";
  ui_print " ";
  exit 1;
fi

# -- Move selected image to Image --
if [ -n "$SELECTED_IMAGE" ]; then
  mv -f "$AKHOME/$SELECTED_IMAGE" "$AKHOME/Image";
  rm -f "$AKHOME/Image.gki.ksu" \
        "$AKHOME/Image.gki.noksu" \
        "$AKHOME/Image.clo.ksu" \
        "$AKHOME/Image.clo.noksu" \
        "$AKHOME/Image.ksu" \
        "$AKHOME/Image.noksu";
fi

# -- Verify Image exists before flashing --
if [ ! -f "$AKHOME/Image" ]; then
  ui_print " ";
  ui_print "ERROR: Kernel image preparation failed!";
  ui_print " ";
  exit 1;
fi

# -- Flash --
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" ] || \
   [ -L "/dev/block/by-name/init_boot_a" ]; then
  ui_print "  Detected init_boot partition";
  split_boot;
  flash_boot;
else
  ui_print "  Using boot partition";
  dump_boot;
  write_boot;
fi
## end boot install


## init_boot files attributes
#init_boot_attributes() {
#set_perm_recursive 0 0 755 644 $RAMDISK/*;
#set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
#} # end attributes

# init_boot shell variables
#BLOCK=init_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for init_boot patching
#reset_ak;

# init_boot install
#dump_boot;

#write_boot;
## end init_boot install


## vendor_kernel_boot shell variables
#BLOCK=vendor_kernel_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_kernel_boot patching
#reset_ak;

# vendor_kernel_boot install
#dump_boot;

#write_boot;
## end vendor_kernel_boot install
