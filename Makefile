CC = gcc
# Either this one
#CFLAGS = -DREGEX_STANDALONE -fPIC -DREG_DEBUG -g
# Or this one
CFLAGS = -DREGEX_STANDALONE -fPIC -D_NDEBUG -O3
LDFLAGS = -shared
SRCS = regcomp.c regexec.c regerror.c regfree.c regalone.c
OBJS = $(SRCS:.c=.o)
BINS = libhsrex.so libhswrex.so
all:
	make libhsrex.so
	rm -f $(OBJS)
	make "CFLAGS=$(CFLAGS) -DREGEX_WCHAR" libhswrex.so
$(BINS): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)
clean:
	rm -f $(OBJS) $(BINS)
