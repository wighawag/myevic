> **This fork's `pufflimit-gcc6` branch is the puff limiter built with the toolchain of upstream's era, for hardware testing. It has NOT been confirmed to boot on any device.**
>
> - ⚠️ The [`pufflimit`](../../tree/pufflimit) branch, built with a current GCC, did not boot on an eVic VTwo Mini (E115, HW 1.00). This branch exists to tell whether the modern toolchain was the cause: it keeps upstream's `Makefile`, `linker.ld` and `src/myevic.s`, and adds only the limiter source.
> - Build with `./build-gcc6.sh`, which fetches ARM GNU Embedded 6-2017-q2 (GCC 6.3.1), checks its SHA-256, builds into `build/`, and refuses to produce an image too big for the chip. `./build-gcc6.sh --upstream` builds upstream's own source with the same toolchain, for comparison.
> - Back up your DataFlash and check your box code before flashing anything. Stock firmware can be restored by holding `+` while connecting USB.
> - The limiter can only refuse to fire. Power regulation (`src/atomizer.c`) is unchanged. The Flappy Bird game is left out, because with it the image does not fit in ROM.
> - `bin/myevic.bin` is upstream's stock build, not the limiter.

## **myevic**
This is myevic Custom Firmware.

#### Based on:
*Original VTC Mini 3.03 firmware*

#### Main Features:
The look-and-feel of the myevic firmware is more-or-less identical to the original firmware, so you shouldn't be lost.  
Many new features and options are made available through the menu system; I strongly encourage you to fully read the present documentation.


## Documentation Index 
   __1.__ [Usage and compatibility](git_doc_en/usageandcompatibility_en.md)
   
   __2.__ [Behaviour Changes](git_doc_en/behaviourchanges_en.md)
   
   __3.__ [How to build](git_doc_en/howtobuild_en.md)

   __4.__ [Profiles](git_doc_en/profiles_en.md)

   __5.__ [Menus](git_doc_en/menus_en.md)

   5a. [Main Screen](git_doc_en/mainscr_en.md)
     
   5b. [Screen Menu](git_doc_en/screen_en.md)

   5c. [Coil Menu](git_doc_en/coils_en.md)

   5d. [Vaping Menu](git_doc_en/vaping_en.md)

   5e. [Clock Menu](git_doc_en/clock_en.md)

   5f. [Interface Menu](git_doc_en/interface_en.md)
  
   5d. [Expert Menu](git_doc_en/expert_en.md)

-----
### Thanks to:

    * ReservedField
    * Bane
    * TBXin
    * maelstrom2001
    * Daveee10
    * Eugene San
    * MarkyAD
    * bluenazgul
    * Sharky1980
    * gdb
    
    And many others, supporting this project and taking the time to open or help solving issues.
