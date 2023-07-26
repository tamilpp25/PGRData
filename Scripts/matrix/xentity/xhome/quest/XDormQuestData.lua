local XDormQuestInfo = require("XEntity/XHome/Quest/XDormQuestInfo")
local XDormQuestAcceptInfo = require("XEntity/XHome/Quest/XDormQuestAcceptInfo")
local XDormQuestFileInfo = require("XEntity/XHome/Quest/XDormQuestFileInfo")

local type = type
local pairs = pairs
local tableInsert = table.insert

--[[public sealed class XDormQuestDataDb
{ 
    // 重置次数
    public int ResetCount;
    // 委托终端等级
    public int TerminalLv;
    // 升级完成委托数
    public int TerminalUpgradeExp;
    // 累计完成委托数
    public int FinishQuestCount;
    // 升级开始时间
    public long TerminalUpgradeTime;
    // 升级状态
    public int TerminalUpgradeStatus;
    // 已完成委托
    public List<List<int>> FinishQuests = new List<List<int>>();
    // 已触发单次限定委托
    public HashSet<int> TriggerLimitedQuest = new HashSet<int>();
    // 特殊委托Id
    public int SpecialQuestId;
    // 全部委托
    public List<XQuestInfo> TotalQuest = new List<XQuestInfo>();
    // 已接取委托
    public List<XQuestAccept> QuestAccept = new List<XQuestAccept>();
    // 已获得文件
    public List<XQuestFile> CollectFiles = new List<XQuestFile>();
}]]

local Default = {
    _TerminalLv = 0, -- 委托终端等级
    _TerminalUpgradeExp = 0, -- 升级完成委托数
    _TerminalUpgradeTime = 0, -- 升级开始时间
    _TerminalUpgradeStatus = 0, -- 升级状态
    _TotalQuest = {}, -- 全部委托
    _QuestAccept = {}, -- 已接取委托
    _CollectFiles = {}, -- 已获得文件
}

---@class XDormQuestData
local XDormQuestData = XClass(nil, "XDormQuestData")

function XDormQuestData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XDormQuestData:UpdateData(data)
    self._TerminalLv = data.TerminalLv
    self._TerminalUpgradeExp = data.TerminalUpgradeExp
    self._TerminalUpgradeTime = data.TerminalUpgradeTime
    self._TerminalUpgradeStatus = data.TerminalUpgradeStatus
    self:UpdateTotalQuest(data.TotalQuest)
    self:UpdateQuestAccept(data.QuestAccept)
    self:UpdateCollectFile(data.CollectFiles)
end

-- 记录已查阅文件
function XDormQuestData:RecordReadFile(fileId)
    local questFileInfo = self:GetQuestFileInfo(fileId)
    if not questFileInfo then
        return
    end
    questFileInfo:RecordReadFile()
end

-- 刷新全部委托数据
function XDormQuestData:UpdateTotalQuest(data)
    self._TotalQuest = {}
    for _, v in pairs(data) do
        local totalQuest = XDormQuestInfo.New(v)
        tableInsert(self._TotalQuest, totalQuest)
    end
end

-- 刷新已接取委托数据
function XDormQuestData:UpdateQuestAccept(data)
    ---@type XDormTerminalTeam
    local dormTerminalTeamEntity = XDataCenter.DormQuestManager.GetDormTerminalTeamEntity()
    self._QuestAccept = {}
    dormTerminalTeamEntity:ClearTeamData()
    for _, v in pairs(data) do
        local questAccept = XDormQuestAcceptInfo.New(v)
        tableInsert(self._QuestAccept, questAccept)
    end
    dormTerminalTeamEntity:UpdateTeamData(self._QuestAccept)
end

-- 刷新已获得文件数据
function XDormQuestData:UpdateCollectFile(data, isUpdate)
    for _, v in pairs(data) do
        local fileId = v.FileId
        local questFileInfo = self:GetQuestFileInfo(fileId)
        if not questFileInfo then
            local collectFile = XDormQuestFileInfo.New(v)
            self._CollectFiles[fileId] = collectFile
            -- 获得新文件
            if isUpdate then
                XDataCenter.DormQuestManager.SetIsHaveNewQuestFile(true)
            end
        else
            questFileInfo:UpdateData(v)
        end
    end
end

-- 刷新终端等级
function XDormQuestData:UpdateTerminalLv(lv)
    self._TerminalLv = lv
end

-- 刷新完成委托数
function XDormQuestData:UpdateTerminalUpgradeExp(count)
    self._TerminalUpgradeExp = count
end

-- 刷新升级开始时间
function XDormQuestData:UpdateTerminalUpgradeTime(time)
    self._TerminalUpgradeTime = time
end

-- 刷新升级状态
function XDormQuestData:UpdateTerminalUpgradeStatus(state)
    self._TerminalUpgradeStatus = state
end

-- 升级成功后刷新信息
function XDormQuestData:UpdateUpgradeSuccessData()
    self._TerminalLv = self._TerminalLv + 1
    self._TerminalUpgradeExp = 0
    self._TerminalUpgradeStatus = XDormQuestConfigs.TerminalUpgradeState.Finish
end

-- 获取全部委托
function XDormQuestData:GetTotalQuest()
    return self._TotalQuest
end

-- 获取已接取委托
function XDormQuestData:GetQuestAccept()
    return self._QuestAccept
end

-- 获取终端等级
function XDormQuestData:GetTerminalLv()
    return self._TerminalLv
end

-- 获取完成委托数
function XDormQuestData:GetTerminalUpgradeExp()
    return self._TerminalUpgradeExp
end

-- 获取升级开始时间
function XDormQuestData:GetTerminalUpgradeTime()
    return self._TerminalUpgradeTime
end

-- 获取升级状态
function XDormQuestData:GetTerminalUpgradeStatus()
    return self._TerminalUpgradeStatus
end

-- 获取已获得的文件
function XDormQuestData:GetCollectFiles()
    return self._CollectFiles
end

---@return XDormQuestFileInfo
function XDormQuestData:GetQuestFileInfo(fileId)
    return self._CollectFiles[fileId]
end

-- 检测文件是否已查阅
function XDormQuestData:CheckReadFile(fileId)
    local questFileInfo = self:GetQuestFileInfo(fileId)
    if not questFileInfo then
        return false
    end
    return questFileInfo:GetIsRead()
end

return XDormQuestData