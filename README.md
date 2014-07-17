lz4-delphi
==========

Delphi bindings for [lz4](https://code.google.com/p/lz4/).

Includes easy-to-use wrapper class and an default mode implementation of the new [lz4s streaming format](http://fastcompression.blogspot.fr/2013/04/lz4-streaming-format-final.html).

A Binding for xxHash is also present, since it is necessary for lz4s;

Lz4 Version [r119](https://code.google.com/p/lz4/source/detail?r=119);

Object Files
==========

Contributed binaries are build using MinGW 4.8.1. and the original sourcecode by Yann Collet: [lz4](https://code.google.com/p/lz4/) and [xxHash](https://code.google.com/p/xxhash/).

Compability
===========

Tested with RadStudio XE3.

Currently Win32 lib files only.

Licence
==========

See Licence files:

[lz4-delphi](https://github.com/Hugie/lz4-delphi/blob/master/LICENSE)

[lz4](https://github.com/Hugie/lz4-delphi/blob/master/LICENSE.lz4)

[xxHash](https://github.com/Hugie/lz4-delphi/blob/master/LICENSE.xxHash)

Speed and Validation Test
==========

    System: Intel Core i7 M640 Dual Core, 2.80GHz, 8GB RAM
    Input: 270MB Dicom Medical Image File

    LZ4 ( pure lz4 )
    LZ4SS  ( lz4s via TMemoryStream )
    LZ4SSN ( lz4s via TMemoryStream - no Hash Stream Checks )
    LZ4SM  ( lz4s via Memory Pointer )
    LZ4SMN ( lz4s via Memory Pointer - no Hash Stream Checks )

    LZ4 Delphi Binding Library Test
       LZ4:    276676254 ->    168943648 ( 61,06%),       436,13 MB/s
       LZ4:    276676254 <-    168943648 ( 61,06%),      1589,51 MB/s

     LZ4SS:    276676254 ->    168944258 ( 61,06%),       136,36 MB/s
     LZ4SS:    276676254 <-    168944258 ( 61,06%),       203,44 MB/s

    LZ4SSN:    276676254 ->    168944254 ( 61,06%),       190,10 MB/s
    LZ4SSN:    276676254 <-    168944254 ( 61,06%),       293,83 MB/s

     LZ4SM:    276676254 ->    168944239 ( 61,06%),       211,43 MB/s
     LZ4SM:    276676254 <-    168944239 ( 61,06%),       451,04 MB/s

    LZ4SMN:    276676254 ->    168944235 ( 61,06%),       313,37 MB/s
    LZ4SMN:    276676254 <-    168944235 ( 61,06%),      1474,07 MB/s

     SynLZ:    276676254 ->    155036174 ( 56,04%),       362,44 MB/s
     SynLZ:    277761274 <-    155036174 ( 55,82%),       330,29 MB/s

Implementation is compared to [SynLZ](http://synopse.info/forum/viewtopic.php?id=32)

Comparism using Yann Collets with lz4 delivered fullbench32.exe.

Only necessary results are shown:

    *** LZ4 speed analyzer r118 32-bits, by Yann Collet (Jul  3 2014) ***
    LZ4_compress                 : 276676254 -> 168969345 (61.07%),  463.1 MB/s
    LZ4_compress_continue        : 276676254 -> 168943960 (61.06%),  330.7 MB/s
    LZ4_decompress_safe          : 276676254 ->                     1645.6 MB/s

Support
==========

Please open a ticket or contribute a bugifx / improvement.

No commercial support, at the moment.
