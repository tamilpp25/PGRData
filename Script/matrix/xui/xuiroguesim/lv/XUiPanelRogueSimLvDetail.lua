---@class XUiPanelRogueSimLvDetail : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimLvDetail = XClass(XUiNode, "XUiPanelRogueSimLvDetail")

function XUiPanelRogueSimLvDetail:OnStart()
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridBuffList = {}
end

function XUiPanelRogueSimLvDetail:Refresh(id)
    self.Id = id
    self.ConfigLevel = self._Control:GetMainLevelConfigLevel(id)
    -- 图片
    self.RImgBuild:SetRawImage(self._Control:GetMainLevelIcon(id))
    -- 等级
    self.TxtLv.text = self.ConfigLevel
    -- 当前等级
    local curLevel = self._Control:GetCurMainLevel()
    self.PanelNow.gameObject:SetActiveEx(curLevel == self.ConfigLevel)
    -- 未解锁
    self.PanelLock.gameObject:SetActiveEx(curLevel < self.ConfigLevel)
    -- 加成
    self:RefreshBuff()
end

function XUiPanelRogueSimLvDetail:RefreshBuff()
    local additionDesc = self:GetAdditionDesc()
    for index, desc in pairs(additionDesc) do
        local grid = self.GridBuffList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuff, self.PanelBuffBubble)
            self.GridBuffList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtName").text = desc
    end
    for i = #additionDesc + 1, #self.GridBuffList do
        self.GridBuffList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimLvDetail:GetAdditionDesc()
    local additionDesc = {}
    -- 资源
    local rewardResourceIds = self._Control:GetMainLevelRewardResourceIds(self.Id)
    local rewardResourceCounts = self._Control:GetMainLevelRewardResourceCounts(self.Id)
    local resourceDesc = self._Control:GetClientConfig("MainLevelUpAdditionDesc", 1)
    for index, id in pairs(rewardResourceIds) do
        additionDesc[index] = string.format(resourceDesc, self._Control.ResourceSubControl:GetResourceName(id), rewardResourceCounts[index])
    end
    -- 解锁科技等级
    local unlockTechLevel = self._Control:GetMainLevelUnlockTechLevel(self.Id)
    if XTool.IsNumberValid(unlockTechLevel) then
        local techDesc = self._Control:GetClientConfig("MainLevelUpAdditionDesc", 2)
        additionDesc[#additionDesc + 1] = string.format(techDesc, unlockTechLevel)
    end
    -- 解锁区域索引
    local unlockAreaIdx = self._Control:GetMainLevelUnlockAreaIdx(self.Id)
    if XTool.IsNumberValid(unlockAreaIdx) then
        local areaDesc = self._Control:GetClientConfig("MainLevelUpAdditionDesc", 3)
        additionDesc[#additionDesc + 1] = string.format(areaDesc, unlockAreaIdx)
    end
    return additionDesc
end

return XUiPanelRogueSimLvDetail
