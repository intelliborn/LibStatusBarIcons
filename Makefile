PATH=/cygdrive/c/appledev/build2/dat/pre/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/opt/local/bin

CC = arm-apple-darwin9-gcc 
LD = arm-apple-darwin9-ld

CFLAGS = -s -fno-common -Wno-unused -O3  -std=c99   -I/cygdrive/c/appledev/build2/dat/sys/usr/lib/gcc/arm-apple-darwin9/4.2.1/include  -I.
LDFLAGS =  -F/cygdrive/c/appledev/build2/dat/sys/System/Library/PrivateFrameworks -framework UIKit -framework CoreFoundation  -framework SystemConfiguration -multiply_defined suppress  -lobjc -framework Foundation  
 
all: LibStatusBarIcons.dylib statusIconsCLI 
 
IP=192.168.4.152
 
LibStatusBarIcons.dylib: LibStatusIconsView.o Hooker.o
	@echo -n "Linking $@... "
	@$(CC) $(LDFLAGS) -init _StatusInit -dynamiclib   -o $@ $^
	@echo "done."
	@scp LibStatusBarIcons.dylib root@$(IP):/Library/MobileSubstrate/DynamicLibraries/LibStatusBarIcons.dylib
	@ssh root@$(IP) "sysctl -w security.mac.proc_enforce=0 security.mac.vnode_enforce=0; ldid -S /Library/MobileSubstrate/DynamicLibraries/LibStatusBarIcons.dylib ; sysctl -w security.mac.proc_enforce=1  " 
	
statusIconsCLI: LibStatusIconsMain.o
	@echo -n "Linking $@... "
	@$(CC) $(LDFLAGS) -o $@ $^
	@echo "done."
	@scp statusIconsCLI root@$(IP):/usr/bin
	@ssh root@$(IP) "sysctl -w security.mac.proc_enforce=0 security.mac.vnode_enforce=0; ldid -S /usr/bin/statusIconsCLI ; sysctl -w security.mac.proc_enforce=1  " 


%.o: %.m
	@echo -n "Compiling $<... "
	@$(CC) -c $(CFLAGS) $< -o $@
	@echo "done."

