---@class XDormQuestTerminal
local XDormQuestTerminal = XClass(nil, "XDormQuestTerminal")

function XDormQuestTerminal:Ctor(lv)
    self:UpdateData(lv)
end

function XDormQuestTerminal:UpdateData(lv)
    self.Lv = lv
    self.Config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestTerminal, lv)
    self.DetailConfig = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestTerminalDetail, lv)
end

-- 升级所需委托数
function XDormQuestTerminal:GetNeedFinishQuest()
    return self.Config.NeedFinishQuest or 0
end

-- 升级所需道具id
function XDormQuestTerminal:GetQuestTerminalNeedItem()
    return self.Config.NeedItem or {}
end

-- 升级所需道具数量
function XDormQuestTerminal:GetQuestTerminalItemCount()
    return self.Config.ItemCount or {}
end

-- 升级所需时间
function XDormQuestTerminal:GetQuestTerminalNeedTime()
    return self.Config.NeedTime or 0
end

-- 队伍栏位数量
function XDormQuestTerminal:GetQuestTerminalTeamCount()
    return self.Config.TeamCount or 0
end

-- 委托栏位数量
function XDormQuestTerminal:GetQuestTerminalQuestCount()
    return self.Config.QuestCount or 0
end

--region 详情配置

function XDormQuestTerminal:GetQuestTerminalDescription()
    return self.DetailConfig.Description or ""
end

--endregion

-- 获取终端等级描述
function XDormQuestTerminal:GetTerminalLvDesc()
    return XUiHelper.GetText("DormQuestTerminalLevelDesc", self.Lv)
end

-- 获取当前完成委托数、升级所需委托数
function XDormQuestTerminal:GetTerminalUpgradeQuest()
    local needFinishCount = self:GetNeedFinishQuest()
    local curUpgradeExp = XDataCenter.DormQuestManager.GetTerminalUpgradeExp()
    if curUpgradeExp > needFinishCount then
        curUpgradeExp = needFinishCount
    end
    return curUpgradeExp, needFinishCount
end

-- 获取当前等级、队伍数量、委托栏位数量
function XDormQuestTerminal:GetQuestTerminalPropertyData()
    local curLevel = self:GetTerminalLvDesc()
    local curTeamCount = self:GetQuestTerminalTeamCount()
    local curQuestCount = self:GetQuestTerminalQuestCount()
    return curLevel, curTeamCount, curQuestCount
end

-- 获取升级需要的物品数据
function XDormQuestTerminal:GetQuestTerminalItemData()
    local itemIds = self:GetQuestTerminalNeedItem()
    local itemCounts = self:GetQuestTerminalItemCount()
    local itemData = {}
    for index, itemId in pairs(itemIds) do
        local curCount = XDataCenter.ItemManager.GetCount(itemId)
        table.insert(itemData, {
            CostCount = itemCounts[index],
            Count = curCount,
            Id = itemId
        })
    end
    return itemData
end

-- 获取升级完成的时间
function XDormQuestTerminal:GetTerminalUpgradeFinishTime()
    local upgradeTime = XDataCenter.DormQuestManager.GetTerminalUpgradeTime()
    local needTime = self:GetQuestTerminalNeedTime()
    return upgradeTime + needTime
end

-- 检查当前是否是最大等级
function XDormQuestTerminal:CheckCurMaxLevel()
    local maxLevel = XDataCenter.DormQuestManager.GetTerminalMaxLevel()
    return self.Lv == maxLevel
end

-- 检查系统是否完成升级条件
function XDormQuestTerminal:CheckTerminalFinishUpgradeCondition()
    -- 升级条件
    local curUpgradeExp, needFinishCount = self:GetTerminalUpgradeQuest()
    if curUpgradeExp < needFinishCount then
        return false, XUiHelper.GetText("DormQuestTerminalNotUpgradeCondition")
    end
    -- 升级所需道具
    local itemData = self:GetQuestTerminalItemData()
    for _, data in pairs(itemData) do
        if data.Count < data.CostCount then
            return false, XUiHelper.GetText("DormQuestTerminalNotUpgradeItem")
        end
    end
    return true
end

-- 检查当前终端是否可升级
function XDormQuestTerminal:CheckTerminalCanUpgrade()
    -- 升级条件
    local isUpgrade = self:CheckTerminalFinishUpgradeCondition()
    -- 最大等级
    local isMaxLevel = self:CheckCurMaxLevel()
    -- 正在升级
    local isGoing = self:CheckTerminalOnGoing()
    return isUpgrade and not isMaxLevel and not isGoing
end

-- 检查终端是否正在升级 true为正在升级
function XDormQuestTerminal:CheckTerminalOnGoing()
    -- 终端状态
    local curState = XDataCenter.DormQuestManager.GetTerminalUpgradeStatus()
    return curState == XDormQuestConfigs.TerminalUpgradeState.OnGoing
end

return XDormQuestTerminal