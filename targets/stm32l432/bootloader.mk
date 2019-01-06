CC=arm-none-eabi-gcc
CP=arm-none-eabi-objcopy
SZ=arm-none-eabi-size
AR=arm-none-eabi-ar

# ST related
SRC = bootloader/main.c bootloader/bootloader.c
SRC += src/init.c src/redirect.c src/flash.c src/rng.c src/led.c src/device.c
SRC += src/fifo.c src/crypto.c src/attestation.c
SRC += src/startup_stm32l432xx.s src/system_stm32l4xx.c
SRC += $(wildcard lib/*.c) $(wildcard lib/usbd/*.c)

# FIDO2 lib
SRC += ../../fido2/util.c ../../fido2/u2f.c ../../fido2/extensions/extensions.c
SRC += ../../fido2/stubs.c ../../fido2/log.c  ../../fido2/ctaphid.c  ../../fido2/ctap.c

# Crypto libs
SRC += ../../crypto/sha256/sha256.c ../../crypto/micro-ecc/uECC.c

OBJ1=$(SRC:.c=.o)
OBJ=$(OBJ1:.s=.o)


INC = -Ibootloader/ -Isrc/ -Isrc/cmsis/ -Ilib/ -Ilib/usbd/ -I../../fido2/ -I../../fido2/extensions
INC += -I../../tinycbor/src -I../../crypto/sha256 -I../../crypto/micro-ecc
INC += -I../../crypto/tiny-AES-c

ifndef LDSCRIPT
LDSCRIPT=linker/bootloader_stm32l4xx.ld
endif

CFLAGS= $(INC)

TARGET=bootloader
HW=-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb

# Solo or Nucleo board
CHIP=STM32L432xx

ifndef DEBUG
DEBUG=0
endif

DEFINES = -DDEBUG_LEVEL=$(DEBUG) -D$(CHIP) -DAES256=1  -DUSE_FULL_LL_DRIVER -DAPP_CONFIG=\"bootloader.h\" $(EXTRA_DEFINES)
# DEFINES += -DTEST_SOLO_STM32 -DTEST -DTEST_FIFO=1

CFLAGS=$(INC) -c $(DEFINES)   -Wall -fdata-sections -ffunction-sections $(HW) -g
LDFLAGS_LIB=$(HW) $(SEARCH) -specs=nano.specs  -specs=nosys.specs  -Wl,--gc-sections  -lnosys
LDFLAGS=$(HW) $(LDFLAGS_LIB) -T$(LDSCRIPT) -Wl,-Map=$(TARGET).map, -Wl,-Bstatic --cref


.PRECIOUS: %.o

all: $(TARGET).elf
	$(SZ) $^


%.o: %.c
	$(CC) $^ $(HW)  -Os $(CFLAGS) -o $@

../../crypto/micro-ecc/uECC.o: ../../crypto/micro-ecc/uECC.c
	$(CC) $^ $(HW)  -Os $(CFLAGS) -o $@

%.o: %.s
	$(CC) $^ $(HW)  -Os $(CFLAGS) -o $@

%.elf: $(OBJ)
	$(CC) $^ $(HW) $(LDFLAGS) -o $@

%.hex: %.elf
	$(CP) -O ihex $^ $(TARGET).hex

clean:
	rm -f *.o src/*.o bootloader/*.o src/*.elf  $(OBJ)