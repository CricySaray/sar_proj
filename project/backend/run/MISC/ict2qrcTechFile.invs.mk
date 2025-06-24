# *.ict file to qrcTechFile
# 华虹宏力40nm制程
.ONESHELL:
# 定义输入文件列表
INPUT_FILES := HHW_LO40NLPV4_7M_MTT30K_RDL28K_CBEST.ict \
								HHW_LO40NLPV4_7M_MTT30K_RDL28K_CWORST.ict \
								HHW_LO40NLPV4_7M_MTT30K_RDL28K_RCBEST.ict \
								HHW_LO40NLPV4_7M_MTT30K_RDL28K_RCWORST.ict \
								HHW_LO40NLPV4_7M_MTT30K_RDL28K_TYPICAL.ict

# 提取文件名中的关键字部分（如CBEST、CWORST等）并转换为小写
KEYWORDS := $(shell for f in $(INPUT_FILES); do echo $$f | sed 's/.*_(CWORST|CBEST|RCBEST|RCWORST|TYPICAL).*/\1/' | tr '[:upper:]' '[:lower:]'; done)

# 定义目标文件夹列表
TARGET_DIRS := $(KEYWORDS)

# 定义Techgen命令模板
TECHGEN_CMD = Techgen -simulation -multi_cpu 64 \
							$(CURDIR)/HHW_LO40NLPV4_7M_MTT30K_RDL28K_$(shell echo $(notdir $(1)) | tr '[:lower:]' '[:upper:]').ict \
							./HHW_LO40NLPV4_7M_MTT30K_RDL28K_$(shell echo $(notdir $(1)) | tr '[:lower:]' '[:upper:]').qrcTechFile

# 默认目标
all: $(TARGET_DIRS)

# 创建目标文件夹
$(TARGET_DIRS):
	mkdir -p $@ ; cd $@
	$(call TECHGEN_CMD,$@)

# 清理规则
clean:
	rm -rf $(TARGET_DIRS)
