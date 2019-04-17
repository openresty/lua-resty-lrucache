.PHONY: all clean
default : all

TARGZ_INPUTS := http://nginx.org/download/nginx-1.7.9.tar.gz \
                https://github.com/cloudflare/lua-aho-corasick/archive/46f1a4146b8b9021b8df25a39572d1242ece899d.tar.gz

LOCALFILES := $(foreach f, $(TARGZ_INPUTS), $(call notdir, $f))
KEYFILES := $(patsubst %.tar.gz, %.key, $(LOCALFILES))
TMP_FILE := a.tmp
TMP_DIR := tmp

ITERATOR := 4
LUAJIT := luajit

######################################################################
#
#   Download *.tar.gz files from Internet
#
######################################################################
#
define DOWNLOAD
$$(notdir $(1)) :
	wget $(1) -O $$@
endef
$(foreach k,$(TARGZ_INPUTS),$(eval $(call DOWNLOAD,$(k))))

######################################################################
#
#   generate files of keys from ther *.tar.gz downloaded from Internet
#
######################################################################
#
define GEN_KEY
$$(patsubst %.tar.gz, %.key, $(1)): $(1)
	rm -rf $(TMP_DIR); \
	mkdir $(TMP_DIR); \
	tar -C $(TMP_DIR) -zxvf $(1); \
	find $(TMP_DIR) -type f -exec cat {} \; > $(TMP_FILE); \
	./key.py $(TMP_FILE) > $$@
	rm -rf $(TMP_DIR) $(TMP_FILE)
endef
$(foreach k,$(LOCALFILES),$(eval $(call GEN_KEY,$(k))))

all:
	@for f in $(KEYFILES); do \
		echo "Testing with $${f}..."; \
		for i in `seq $(ITERATOR)`; do \
			echo "Iteration $${i}"; \
			rm -f $${f}; \
            $(MAKE) $${f} > /dev/null; \
            $(LUAJIT) ./test.lua $${f}; \
		done; \
	done

clean:
	rm -rf $(LOCALFILES) $(KEYFILES) $(TMP_FILE) $(TMP_DIR)
