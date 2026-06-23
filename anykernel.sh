### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=AIO Kernel Pack by superuseryu
do.devicecheck=0
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

# -- Wait for key release --
flush_keys() {
  sleep 0.15;
}

# -- Read one keypress: return 1=VOL+ 2=VOL- --
read_key() {
  while true; do
    input=$(getevent -qlc 1 2>/dev/null);
    case "$input" in
      *KEY_VOLUMEUP*DOWN*)   flush_keys; return 1 ;;
      *KEY_VOLUMEDOWN*DOWN*) flush_keys; return 2 ;;
    esac
  done
}

# -- Step 1: Select kernel source --
choose_source() {
  ui_print " ";
  ui_print "  Step 1: Select Kernel Source";
  ui_print "  VOL+ = Select GKI (AOSP)";
  ui_print "  VOL- = Select CLO (CodeLinaro)";
  ui_print " ";
  flush_keys;
  read_key;
}

# -- Step 2: Select KSU variant (3 options) --
# VOL+ = next option, VOL- = confirm
choose_ksu() {
  ui_print " ";
  ui_print "  Step 2: Select Variant";
  ui_print "  VOL+ = Next option";
  ui_print "  VOL- = Confirm selection";

  KSU_OPTION=1;

  print_menu() {
    ui_print " ";
    [ "$KSU_OPTION" = "1" ] && ui_print "  > NoKSU (Vanilla)"      || ui_print "      NoKSU (Vanilla)";
    [ "$KSU_OPTION" = "2" ] && ui_print "  > Wild+KSUN"        || ui_print "      Wild-KSUN";
    [ "$KSU_OPTION" = "3" ] && ui_print "  > SukiSU Ultra"    || ui_print "      SukiSU Ultra";
  }
  print_menu;

  flush_keys;
  while true; do
    input=$(getevent -qlc 1 2>/dev/null);
    case "$input" in
      *KEY_VOLUMEUP*DOWN*)
        KSU_OPTION=$(( KSU_OPTION % 3 + 1 ));
        print_menu;
        flush_keys;
        ;;
      *KEY_VOLUMEDOWN*DOWN*)
        flush_keys;
        return $KSU_OPTION;
        ;;
    esac
  done
}

# -- Step 2 simple: 2 options --
choose_ksu_simple() {
  ui_print " ";
  ui_print "  Step 2: Select Variant";
  ui_print "  VOL+ = Select $1";
  ui_print "  VOL- = Select $2";
  ui_print " ";
  flush_keys;
  read_key;
}

# -- Detect available images --
HAS_GKI_KSU=0; HAS_GKI_NOKSU=0; HAS_GKI_SUKI=0;
HAS_CLO_KSU=0; HAS_CLO_NOKSU=0; HAS_CLO_SUKI=0;

[ -f "$AKHOME/Image.gki.ksu" ]   && HAS_GKI_KSU=1;
[ -f "$AKHOME/Image.gki.noksu" ] && HAS_GKI_NOKSU=1;
[ -f "$AKHOME/Image.gki.suki" ]  && HAS_GKI_SUKI=1;
[ -f "$AKHOME/Image.clo.ksu" ]   && HAS_CLO_KSU=1;
[ -f "$AKHOME/Image.clo.noksu" ] && HAS_CLO_NOKSU=1;
[ -f "$AKHOME/Image.clo.suki" ]  && HAS_CLO_SUKI=1;

SELECTED_IMAGE="";

# -- Full AIO: all 6 images --
if [ "$HAS_GKI_KSU" = "1" ] && [ "$HAS_GKI_NOKSU" = "1" ] && [ "$HAS_GKI_SUKI" = "1" ] && \
   [ "$HAS_CLO_KSU" = "1" ] && [ "$HAS_CLO_NOKSU" = "1" ] && [ "$HAS_CLO_SUKI" = "1" ]; then

  choose_source;  SOURCE=$?;
  choose_ksu; VARIANT=$?;

  if   [ "$SOURCE" = "1" ] && [ "$VARIANT" = "1" ]; then SELECTED_IMAGE="Image.gki.noksu"; ui_print "  >> GKI - Vanilla";
  elif [ "$SOURCE" = "1" ] && [ "$VARIANT" = "2" ]; then SELECTED_IMAGE="Image.gki.ksu";   ui_print "  >> GKI + Wild-KSUN";
  elif [ "$SOURCE" = "1" ] && [ "$VARIANT" = "3" ]; then SELECTED_IMAGE="Image.gki.suki";  ui_print "  >> GKI + SukiSU Ultra";
  elif [ "$SOURCE" = "2" ] && [ "$VARIANT" = "1" ]; then SELECTED_IMAGE="Image.clo.noksu"; ui_print "  >> CLO - Vanilla";
  elif [ "$SOURCE" = "2" ] && [ "$VARIANT" = "2" ]; then SELECTED_IMAGE="Image.clo.ksu";   ui_print "  >> CLO + Wild-KSUN";
  elif [ "$SOURCE" = "2" ] && [ "$VARIANT" = "3" ]; then SELECTED_IMAGE="Image.clo.suki";  ui_print "  >> CLO + SukiSU Ultra";
  fi

# -- 4 images (old AIO without SukiSU) --
elif [ "$HAS_GKI_KSU" = "1" ] && [ "$HAS_GKI_NOKSU" = "1" ] && \
     [ "$HAS_CLO_KSU" = "1" ] && [ "$HAS_CLO_NOKSU" = "1" ]; then

  choose_source; SOURCE=$?;
  choose_ksu_simple "No Root" "Wild-KSU + SUSFS"; KEY=$?;

  if   [ "$SOURCE" = "1" ] && [ "$KEY" = "1" ]; then SELECTED_IMAGE="Image.gki.noksu"; ui_print "  >> GKI - Vanilla";
  elif [ "$SOURCE" = "1" ] && [ "$KEY" = "2" ]; then SELECTED_IMAGE="Image.gki.ksu";   ui_print "  >> GKI + Wild-KSUN";
  elif [ "$SOURCE" = "2" ] && [ "$KEY" = "1" ]; then SELECTED_IMAGE="Image.clo.noksu"; ui_print "  >> CLO - Vanilla";
  elif [ "$SOURCE" = "2" ] && [ "$KEY" = "2" ]; then SELECTED_IMAGE="Image.clo.ksu";   ui_print "  >> CLO + Wild-KSUN";
  fi

# -- GKI only 3 variants --
elif [ "$HAS_GKI_KSU" = "1" ] && [ "$HAS_GKI_NOKSU" = "1" ] && [ "$HAS_GKI_SUKI" = "1" ]; then
  choose_ksu; VARIANT=$?;
  [ "$VARIANT" = "1" ] && SELECTED_IMAGE="Image.gki.noksu" && ui_print "  >> GKI - Vanilla";
  [ "$VARIANT" = "2" ] && SELECTED_IMAGE="Image.gki.ksu"   && ui_print "  >> GKI + Wild-KSUN";
  [ "$VARIANT" = "3" ] && SELECTED_IMAGE="Image.gki.suki"  && ui_print "  >> GKI + SukiSU Ultra";

# -- CLO only 3 variants --
elif [ "$HAS_CLO_KSU" = "1" ] && [ "$HAS_CLO_NOKSU" = "1" ] && [ "$HAS_CLO_SUKI" = "1" ]; then
  choose_ksu; VARIANT=$?;
  [ "$VARIANT" = "1" ] && SELECTED_IMAGE="Image.clo.noksu" && ui_print "  >> CLO - Vanilla";
  [ "$VARIANT" = "2" ] && SELECTED_IMAGE="Image.clo.ksu"   && ui_print "  >> CLO + Wild-KSUN";
  [ "$VARIANT" = "3" ] && SELECTED_IMAGE="Image.clo.suki"  && ui_print "  >> CLO + SukiSU Ultra";

# -- GKI only 2 variants --
elif [ "$HAS_GKI_KSU" = "1" ] && [ "$HAS_GKI_NOKSU" = "1" ]; then
  choose_ksu_simple "No Root" "Wild-KSU + SUSFS"; KEY=$?;
  [ "$KEY" = "1" ] && SELECTED_IMAGE="Image.gki.noksu" && ui_print "  >> GKI - Vanilla";
  [ "$KEY" = "2" ] && SELECTED_IMAGE="Image.gki.ksu"   && ui_print "  >> GKI + Wild-KSUN";

# -- CLO only 2 variants --
elif [ "$HAS_CLO_KSU" = "1" ] && [ "$HAS_CLO_NOKSU" = "1" ]; then
  choose_ksu_simple "No Root" "Wild-KSU + SUSFS"; KEY=$?;
  [ "$KEY" = "1" ] && SELECTED_IMAGE="Image.clo.noksu" && ui_print "  >> CLO - Vanilla";
  [ "$KEY" = "2" ] && SELECTED_IMAGE="Image.clo.ksu"   && ui_print "  >> CLO + Wild-KSUN";

# -- Single image fallbacks --
elif [ "$HAS_GKI_KSU" = "1" ];   then SELECTED_IMAGE="Image.gki.ksu";   ui_print "  >> GKI + Wild-KSUN (auto)";
elif [ "$HAS_GKI_SUKI" = "1" ];  then SELECTED_IMAGE="Image.gki.suki";  ui_print "  >> GKI + SukiSU (auto)";
elif [ "$HAS_GKI_NOKSU" = "1" ]; then SELECTED_IMAGE="Image.gki.noksu"; ui_print "  >> GKI Vanilla (auto)";
elif [ "$HAS_CLO_KSU" = "1" ];   then SELECTED_IMAGE="Image.clo.ksu";   ui_print "  >> CLO + Wild-KSUN (auto)";
elif [ "$HAS_CLO_SUKI" = "1" ];  then SELECTED_IMAGE="Image.clo.suki";  ui_print "  >> CLO + SukiSU (auto)";
elif [ "$HAS_CLO_NOKSU" = "1" ]; then SELECTED_IMAGE="Image.clo.noksu"; ui_print "  >> CLO Vanilla (auto)";

# -- Legacy fallback --
elif [ -f "$AKHOME/Image.ksu" ] && [ -f "$AKHOME/Image.noksu" ]; then
  ui_print "  Legacy package detected.";
  choose_ksu_simple "No Root" "KSU"; KEY=$?;
  [ "$KEY" = "1" ] && SELECTED_IMAGE="Image.noksu" && ui_print "  >> Vanilla";
  [ "$KEY" = "2" ] && SELECTED_IMAGE="Image.ksu"   && ui_print "  >> KSU";
elif [ -f "$AKHOME/Image.ksu" ];   then SELECTED_IMAGE="Image.ksu";   ui_print "  >> KSU (auto)";
elif [ -f "$AKHOME/Image.noksu" ]; then SELECTED_IMAGE="Image.noksu"; ui_print "  >> Vanilla (auto)";
elif [ -f "$AKHOME/Image" ]; then
  ui_print "  Single image found, flashing...";
else
  ui_print " ";
  ui_print "ERROR: No kernel image found!";
  ui_print "  Expected one of:";
  ui_print "  Image.gki.ksu / Image.gki.noksu / Image.gki.suki";
  ui_print "  Image.clo.ksu / Image.clo.noksu / Image.clo.suki";
  ui_print " ";
  exit 1;
fi

# -- Move selected image to Image --
if [ -n "$SELECTED_IMAGE" ]; then
  mv -f "$AKHOME/$SELECTED_IMAGE" "$AKHOME/Image";
  rm -f "$AKHOME/Image.gki.ksu"   \
        "$AKHOME/Image.gki.noksu" \
        "$AKHOME/Image.gki.suki"  \
        "$AKHOME/Image.clo.ksu"   \
        "$AKHOME/Image.clo.noksu" \
        "$AKHOME/Image.clo.suki"  \
        "$AKHOME/Image.ksu"       \
        "$AKHOME/Image.noksu";
fi

# -- Verify Image exists --
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

#BLOCK=init_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;
#reset_ak;
#dump_boot;
#write_boot;
## end init_boot install


## vendor_kernel_boot shell variables
#BLOCK=vendor_kernel_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;
#reset_ak;
#dump_boot;
#write_boot;
## end vendor_kernel_boot install
