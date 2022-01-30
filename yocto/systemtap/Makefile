all :
	LDFLAGS="" stap \
        -v \
        -a arm64 \
        -B CROSS_COMPILE=$(CROSS_COMPILE) \
        -r /opt/poky/2.4.4/sysroots/aarch64-poky-linux/usr/src/kernel \
        -e 'probe begin { log ("hello " . k) exit () } global k="world" ' \
        -m stap_hello

clean :
	rm -f stap_hello.ko


