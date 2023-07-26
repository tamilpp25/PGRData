local XUiMaverick2TalentGrid = XClass(nil, "UiMaverick2TalentGrid")

function XUiMaverick2TalentGrid:Ctor(ui)
    self.TreeCfg = nil -- 天赋树配置表
    self.GroupCfgs = nil -- 天赋组列表
    self.IsGroupLock = false -- 天赋组是否锁住

    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiMaverick2TalentGrid:Refresh(root, treeCfg)
    self.Root = root
    self.TreeCfg = treeCfg

    -- 天赋组解锁提示
    local assignUnit = XDataCenter.Maverick2Manager.GetAssignActiveUnitCnt(treeCfg.RobotId)
    local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
    self.IsGroupLock = false
    local desc = nil
    if assignUnit < treeCfg.NeedUnit then
        self.IsGroupLock = true
        desc = "" -- todo
    end
    if mentalLv < treeCfg.NeedMentalLv then
        self.IsGroupLock = true
        desc = "" -- todo
    end
    -- todo 根据isLock和desc显示锁和描述

    -- 获取天赋
    self.GroupCfgs = {}
    local configs = XMaverick2Configs.GetMaverick2TalentGroup()
    for _, config in ipairs(configs) do
        if config.TalentGroupId == treeCfg.TalentGroupId then
            table.insert(self.GroupCfgs, config)
        end
    end

    -- 刷新item列表
    local go
    for i = 1, self.ItemList.childCount do
        go = self.ItemList:GetChild(i-1)
        go.gameObject:SetActiveEx(false)
    end
    for i, groupCfg in ipairs(self.GroupCfgs) do
        local go = nil
        if i > self.ItemList.childCount then
            go = CS.UnityEngine.Object.Instantiate(self.XinZhiItem.gameObject, self.ItemList)
        else
            go = self.ItemList:GetChild(i-1)
        end
        go.gameObject:SetActiveEx(true)
        self:RefreshTalent(go, i)
    end
end

function XUiMaverick2TalentGrid:RefreshTalent(go, index)
    local groupCfg = self.GroupCfgs[index]
    local lvConfigs = XMaverick2Configs.GetTalentLvConfigs(groupCfg.TalentId)
    local lv = XDataCenter.Maverick2Manager.GetTalentLv(self.TreeCfg.RobotId, groupCfg.TalentGroupId, groupCfg.TalentId)
    local isMax = lv == #lvConfigs
    local icon = lv == 0 and lvConfigs[1].Icon or lvConfigs[lv].Icon -- 无0级配置表，使用一级的图标配置

    local needUnit = 0
    local isTalentLock = false
    local desc = nil
    if not isMax then
        local nextLvCfg = lvConfigs[lv+1]
        needUnit = nextLvCfg.NeedUnit
        if nextLvCfg.Condition then
            isTalentLock = XConditionManager.CheckCondition(nextLvCfg.Condition)
            desc = nextLvCfg.UnlockTips
        end
    end

    -- todo 刷新icon、等级、锁、升级消耗

    -- 点击事件
    XUiHelper.RegisterClickEvent(self, go, function()
        self:OnClickTalent(index)
    end)
end

function XUiMaverick2TalentGrid:OnClickTalent(index)
    local groupCfg = self.GroupCfgs[index]
    self.Root:OpenTalentDetail(groupCfg)
end

return XUiMaverick2TalentGrid