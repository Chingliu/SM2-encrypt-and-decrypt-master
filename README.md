# SM2-encrypt-and-decrypt
&ensp;&ensp;&ensp;&ensp;An implementation of computing SM2 encryption and decryption is provided. Header files and library files of OpenSSL 1.1.1 are needed while compiling and linking. OpenSSL website is: https://www.openssl.org
  
&ensp;&ensp;&ensp;&ensp;SM2 is a cryptographic algorithm based on elliptic curves. It is defined in the following standards of China:
- GB/T32918.1-2016,
- GB/T32918.2-2016,
- GB/T32918.3-2016,
- GB/T32918.4-2016,
- GM/T 0003-2012.  
  
&ensp;&ensp;&ensp;&ensp;Computing SM2 encryption and decryption are supported in OpenSSL 1.1.1. In the source package, "/crypto/sm2/sm2_crypt.c" is a good example. SM2 Encryption and decryption are encapsulated in an abstract level called EVP. In some cases using EVP interfaces to compute SM2 encryption and decryption is a little inconvenient. An implementation bypassing invoking OpenSSL EVP interfaces directly is given here.


Work with OpenSSL 3.0.0 ?  
&ensp;&ensp;&ensp;&ensp;The codes here is designed to be run with OpenSSL 1.1.1. If the codes are compiled with OpenSSL 3.0.0 on Linux platform, many warnings are shown. But it can be run with OpenSSL 3.0.0. Test with CentOS Linux 7.9 + gcc 4.8.5 + OpenSSL 3.0.0 has passed. The codes cannot be compiled on Windows platform with OpenSSL 3.0.0.


今天遇到一个需要隐藏动态库符号的需求，记录一下。

因为某些原因需要将定制的OPENSSL库进行封装成一个新的动态库，提供给其他用户使用。并且我们用到的这个OpenSSL库是经过改造的，与系统库里自带的OpenSSL是不相同的。
先贴出Makefile

all:libsgcccrypto.a libsgcccrypto.so test
crypto.o:crypto.h crypto.h
        gcc -g -o crypto.o -fPIC -I../openssl-1-0-x/include -c crypto.c
libsgcccrypto.a:crypto.o ../openssl-1-0-x/libcrypto.a
        echo CREATE libsgcccrypto.a > ar.mac
        echo ADDLIB ../openssl-1-0-x/libcrypto.a >> ar.mac
        echo ADDMOD crypto.o >> ar.mac
        echo SAVE >> ar.mac
        echo END >> ar.mac
        ar -M < ar.mac
        rm -rf *.mac
libsgcccrypto.so:crypto.o ../openssl-1-0-x/libcrypto.a
        gcc -g -shared -fPIC -o libsgcccrypto.so crypto.o -L../openssl-1-0-x -lcrypto
test: test.c libsgcccrypto.so
        gcc -g -o test test.c -Wl,-rpath=./ -L. -lsgcccrypto -ldl
clean:
        rm -rf libsgcccrypto.a *.so *.o *.mac test


从Makefile可以看出我们的目标很简单，就是自己编写了一个crypto.c，实现了一些接口，这些接口会使用到OpenSSL里的一些功能，我们希望将新编写的crypto.c与所使用的OpenSSL库（静态库）合并编译为一个新的动态库libsgcccrypto.so。上面的Makefile可以完成这个功能。

我们来检查一下编译好的so库

[root@localhost crypto]# readelf -s libsgcccrypto.so |grep EVP| more
    91: 00000000000768cf   197 FUNC    GLOBAL DEFAULT   11 EVP_PKEY_free
   100: 00000000000e2037    13 FUNC    GLOBAL DEFAULT   11 EVP_des_ede3
   107: 00000000000e0e8c    13 FUNC    GLOBAL DEFAULT   11 EVP_des_cfb1
   108: 00000000000e397d    13 FUNC    GLOBAL DEFAULT   11 EVP_rc2_ecb
   123: 00000000000e0e99    13 FUNC    GLOBAL DEFAULT   11 EVP_des_cfb8
   430: 0000000000075faf    13 FUNC    GLOBAL DEFAULT   11 EVP_sm3
--More--

好么，OpenSSL库里的符号都导出了，可想而知，如果用户使用了我们封装的动态库，同时又使用了系统的OpenSSL库，这样一定会出问题。
首先想到的是-fvisibility=hidden选项。可惜这个选项只是在编译期间起作用，而我们的OpenSSL库是已经编译好的静态库，这个选项对已经编译好了的静态库起不了作用，但还是可以将我们crypto.c中被默认导出的一些不必要的接口隐藏掉，修改Makefile，给要导出的接口添加attribute，再看看效果。

all:libsgcccrypto.a libsgcccrypto.so test
crypto.o:crypto.h crypto.h
        gcc -g -o crypto.o -fPIC -fvisibility=hidden -I../openssl-1-0-x/include -c crypto.c
libsgcccrypto.a:crypto.o ../openssl-1-0-x/libcrypto.a
        echo CREATE libsgcccrypto.a > ar.mac
        echo ADDLIB ../openssl-1-0-x/libcrypto.a >> ar.mac
        echo ADDMOD crypto.o >> ar.mac
        echo SAVE >> ar.mac
        echo END >> ar.mac
        ar -M < ar.mac
        rm -rf *.mac
libsgcccrypto.so:crypto.o ../openssl-1-0-x/libcrypto.a
        gcc -g -shared -fPIC -o libsgcccrypto.so crypto.o -L../openssl-1-0-x -lcrypto
test: test.c libsgcccrypto.so
        gcc -g -o test test.c -Wl,-rpath=./ -L. -lsgcccrypto -ldl
clean:
        rm -rf libsgcccrypto.a *.so *.o *.mac test


/* crypto.h */
#define EXPORT_API __attribute((visibility("default")))
EXPORT_API SGCC_ENCRYPT_API sgcc_crypto_load_api();

[root@localhost crypto]# readelf -s crypto.o| grep GLOBAL |grep FUNC|more
    42: 0000000000000000    65 FUNC    GLOBAL HIDDEN    1 check_support_algs
    43: 0000000000000041    31 FUNC    GLOBAL HIDDEN    1 check_has_init
    90: 0000000000001397   167 FUNC    GLOBAL HIDDEN    1 sgcc_save_pubkey
    92: 000000000000143e   167 FUNC    GLOBAL HIDDEN    1 sgcc_save_prikey
    94: 00000000000014fa   334 FUNC    GLOBAL DEFAULT    1 sgcc_crypto_load_api

可以看到crypto.o中只有sgcc_crypto_load_api接口被导出，其他接口都是隐藏状态。这样用户连接我们的动态库就只能访问这一个接口了。

继续尝试，在链接阶段加入参数 -Wl,–exclude-libs,ALL

all:libsgcccrypto.a libsgcccrypto.so test
crypto.o:crypto.h crypto.h
        gcc -g -o crypto.o -fPIC -fvisibility=hidden -I../openssl-1-0-x/include -c crypto.c
libsgcccrypto.a:crypto.o ../openssl-1-0-x/libcrypto.a
        echo CREATE libsgcccrypto.a > ar.mac
        echo ADDLIB ../openssl-1-0-x/libcrypto.a >> ar.mac
        echo ADDMOD crypto.o >> ar.mac
        echo SAVE >> ar.mac
        echo END >> ar.mac
        ar -M < ar.mac
        rm -rf *.mac
libsgcccrypto.so:crypto.o ../openssl-1-0-x/libcrypto.a
        gcc -g -shared -fPIC -Wl,--exclude-libs,ALL -o libsgcccrypto.so crypto.o -L../openssl-1-0-x -lcrypto
test: test.c libsgcccrypto.so
        gcc -g -o test test.c -Wl,-rpath=./ -L. -lsgcccrypto -ldl
clean:
        rm -rf libsgcccrypto.a *.so *.o *.mac test

[root@localhost crypto]# readelf -s libsgcccrypto.so |grep GLOBAL|grep EVP
[root@localhost crypto]#
[root@localhost crypto]# readelf -s libsgcccrypto.so |grep GLOBAL|more
     2: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND fileno@GLIBC_2.2.5 (2)
     3: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND mktime@GLIBC_2.2.5 (2)
     4: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND memset@GLIBC_2.2.5 (2)
     5: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND ftell@GLIBC_2.2.5 (2)
     6: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND close@GLIBC_2.2.5 (2)
     7: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND ioctl@GLIBC_2.2.5 (2)
     8: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND abort@GLIBC_2.2.5 (2)
    11: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND fseek@GLIBC_2.2.5 (2)
    12: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND __isoc99_sscanf@GLIBC_2.7 (3)
    13: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND __assert_fail@GLIBC_2.2.5 (2)
    14: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND strcasecmp@GLIBC_2.2.5 (2)
[root@localhost crypto]# readelf -s libsgcccrypto.so |grep GLOBAL|grep sgcc
    80: 0000000000025dc6   334 FUNC    GLOBAL DEFAULT   11 sgcc_crypto_load_api
  5669: 0000000000025dc6   334 FUNC    GLOBAL DEFAULT   11 sgcc_crypto_load_api


OK，静态库里的符号统统不见，只剩下我们需要的sgcc_crypto_load_api，这样就不怕咱们的动态库污染用户的符号空间了，目标达成！
————————————————
版权声明：本文为CSDN博主「myctime_43939128」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/weixin_43939128/article/details/104603614