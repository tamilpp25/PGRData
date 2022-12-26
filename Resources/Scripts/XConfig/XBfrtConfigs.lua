local TABLE_BFRT_CHAPTER_PATH = "Share/Fuben/Bfrt/BfrtChapter.tab"
local TABLE_BFRT_GROUP_PATH = "Share/Fuben/Bfrt/BfrtGroup.tab"
local TABLE_ECHELON_INFO_PATH = "Share/Fuben/Bfrt/EchelonInfo.tab"

local BfrtChapterTemplates = {}
local BfrtGroupTemplates = {}
local EchelonInfoTemplates = {}

XBfrtConfigs = XBfrtConfigs or {}

XBfrtConfigs.CAPTIAN_MEMBER_INDEX = 1
XBfrtConfigs.FIRST_FIGHT_MEMBER_INDEX = 1

XBfrtConfigs.MEMBER_POS_COLOR = {
    "FF1111FF", -- red
    "4F99FFFF", -- blue
    "F9CB35FF", -- yellow
}

function XBfrtConfigs.Init()
    BfrtChapterTemplates = XTableManager.ReadByIntKey(TABLE_BFRT_CHAPTER_PATH, XTable.XTableBfrtChapter, "ChapterId")
    BfrtGroupTemplates = XTableManager.ReadByIntKey(TABLE_BFRT_GROUP_PATH, XTable.XTableBfrtGroup, "GroupId")
    EchelonInfoTemplates = XTableManager.ReadByIntKey(TABLE_ECHELON_INFO_PATH, XTable.XTableEchelonInfo, "Id")
end

function XBfrtConfigs.GetBfrtChapterTemplates()
    return BfrtChapterTemplates
end

function XBfrtConfigs.GetBfrtGroupTemplates()
    return BfrtGroupTemplates
end

function XBfrtConfigs.GetEchelonInfoTemplates()
    return EchelonInfoTemplates
end