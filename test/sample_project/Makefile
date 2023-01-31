INSTALL_ROOT := install_root

all:
	gcc -o sample_project main.c

install:
	mkdir -p $(INSTALL_ROOT)/usr/bin/
	cp -p sample_project $(INSTALL_ROOT)/usr/bin/

clean:
	rm -f sample_project
