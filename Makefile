# GNU Makefile

BUILD_TYPE     ?= Release
# --- Configuration ---
include Makerules


ROOT_DIR = ./
OPENSSL_DIR = $(ROOT_DIR)/openssl111s
OPENSSL_HDR = $(OPENSSL_DIR)/include
OPENSSL_LIB = $(OPENSSL_DIR)/lib

default: all

BUILD_INFO = $(OS)/$(PLATFORM)

OUT = $(ROOT_DIR)
OUT = $(ROOT_DIR)/output/$(BUILD_TYPE)/$(BUILD_INFO)
BIN = $(ROOT_DIR)/bin/$(BUILD_TYPE)/$(BUILD_INFO)


ifeq "$(OS)" "MACOS"
TARGET1 = liboed.dylib
else
TARGET1 = liboed.so
endif
TARGET2 = liboed.a


CFLAGS += -I$(ROOT_DIR) -I$(OPENSSL_HDR)
LDFLAGS += -L$(OPENSSL_LIB) 
LIBS += -lcrypto
LIBS += -lssl


ALL_DIR := $(OUT)
ALL_DIR += $(BIN)

# --- Commands ---

CC_CMD = $(CC) $(CFLAGS) -o $@ -c $<
CXX_CMD = $(CXX) $(CFLAGS) $(CXXFLAGS) -o $@ -c $<
AR_CMD = $(AR) cr $@ $^
LINK_CMD = $(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)
MKDIR_CMD = $(QUIET_MKDIR) mkdir -p $@
RM_CMD = rm -f $@

# --- Rules ---

$(ALL_DIR) :
	$(MKDIR_CMD)

$(BIN)/$(TARGET1):
	$(RM_CMD)
	$(LINK_CMD)
	
$(BIN)/$(TARGET2):
	$(RM_CMD)
	$(AR_CMD)

$(OUT)/%.o : %.c | $(ALL_DIR)
	$(CC_CMD)

$(OUT)/%.o : %.cpp | $(ALL_DIR)
	$(CXX_CMD)
	
# --- File lists ---
SRC_HDR := $(wildcard $(ROOT_DIR)/*.h)

SRC := $(wildcard $(ROOT_DIR)/*.c)
SRCPP := $(wildcard $(ROOT_DIR)/*.cpp)


#OBJS := $(SRC:%.c=$(OUT)/%.o)
OBJS := $(patsubst $(ROOT_DIR)/%.c,$(OUT)/%.o,$(SRC))
OBJS += $(patsubst $(ROOT_DIR)/%.cpp,$(OUT)/%.o,$(SRCPP))

$(OBJS) : $(SRC) $(SRCPP) $(SRC_HDR)

DLL := $(BIN)/$(TARGET1)
LIB := $(BIN)/$(TARGET2)
$(DLL) $(LIB) : $(OBJS)

all : $(DLL) $(LIB)
	
clean:
	rm -rf $(OUT)
	rm -rf $(BIN)
	
.PHONY: krc clean
	


	
