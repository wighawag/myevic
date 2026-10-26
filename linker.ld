/* Memory regions */
MEMORY {
	ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 100K
	RAM (rwx) : ORIGIN = 0x20000000, LENGTH =  32K
}

/* Library configurations */
/* No multilib subdirectory prefix here. It was "armv7e-m/", then "v7e-m/",
   and on a current toolchain it is "thumb/v7e-m/nofp/": hardcoding it means
   re-patching this file for every toolchain. Name the libraries bare and let
   the Makefile put the right multilib directory on the -L search path, which
   it derives from `arm-none-eabi-gcc -print-multi-directory`. */
GROUP(
	libnosys.a
	libgcc.a
	libc.a
	libm.a
)

ENTRY(Reset_Handler)

SECTIONS {
	.text : {
		KEEP(*(.isr_vectors))

		LONG(0x5746594D)
		LONG(images1_start)
		LONG(images1_end)
		LONG(images2_start)
		LONG(images2_end)
		LONG(Strings_Start)
		LONG(Strings_End)

		. = ALIGN(4);
		*(.text*)

		. = ALIGN(4);
		KEEP(*(.myevic*))

		. = ALIGN(4);
		KEEP(*(.productid*))

		. = ALIGN(4);
		*(.rodata*)

		. = ALIGN(4);
		Strings_Start = .;
		*(.strings*)
		Strings_End = .;

		. = ALIGN(4);
		images1_start = .;
		*(.imgblock1)
		images1_end = .;

		images2_start = .;
		*(.imgblock2)
		images2_end = .;

	} > ROM

	/* The RAM-init table goes IMMEDIATELY after .text and BEFORE the .data
	   load image, which is upstream's order: in the upstream-shipped
	   bin/myevic.bin the table sits at img1_end and .data follows it.

	   The order is not cosmetic. GetFirmwareSize() (myevic.s) computes the
	   image size as Data_Start_ROM + Data_Size, i.e. it assumes .data is the
	   LAST thing in the image. With the table after .data the image is 24 bytes
	   longer than that, and myevic's virtual USB disk (storage.c) serves a
	   truncated firmware file.

	   Placing it here also avoids the problem the previous layout had to work
	   around: .data is assigned "> RAM" with an AT() load address, and current
	   ld does not advance the ROM region pointer past an AT() image, so anything
	   placed in ROM AFTER .data needed a hand-computed address to avoid landing
	   on top of it. Nothing is placed after .data any more, so no hand-computed
	   address is needed.

	   The symbols referenced here (Data_Start_ROM, Data_Size, SRAMZ_*) are
	   defined further down; ld resolves forward references at the end. */
	.raminit : {
		. = ALIGN(4);
		RAMInitTable = .;

		LONG(Data_Start_ROM)
		LONG(Data_Start_RAM)
		LONG(Data_Size)

		LONG(SRAMZ_Start)
		LONG(SRAMZ_Start)
		LONG(SRAMZ_Size)

		RAMInitEnd = .;
	} > ROM

	. = ALIGN(8);
	Data_Start_ROM = .;

	.data : AT (Data_Start_ROM) {
		Data_Start_RAM = .;
		*(vtable)
		*(.data*)

		. = ALIGN(4);
		Data_End_RAM = .;
	} > RAM

	/* The .data load image must still fit in ROM. ld checks the regions of
	   output sections, but nothing checks an AT() image hanging off the end of
	   ROM, so assert it explicitly: an image that overran ROM would be cut off
	   by the flasher and boot with half-initialised RAM. */
	ASSERT(Data_Start_ROM + SIZEOF(.data) <= ORIGIN(ROM) + LENGTH(ROM),
	       "the .data load image does not fit in ROM")

	Data_Size = Data_End_RAM - Data_Start_RAM;

	.sram : {
		SRAMZ_Start = .;

		. = ALIGN(4);
		*(COMMON)
		*(.bss*)

		end = .;

		. = ALIGN(8);
		*(.stack)

		SRAMZ_End = .;
	} > RAM

	SRAMZ_Size = SRAMZ_End - SRAMZ_Start;
}

/* Named ".raminit", not ".text": upstream had TWO output sections both named
   .text, which is legal but makes every diagnostic about the table read as if
   it were about the code. Nothing references the section by name; the startup
   code and GetFirmwareSize() use the RAMInitTable/RAMInitEnd symbols, and the
   Makefile's objcopy must list it with -j or the table is dropped from the
   image. */
