---@class XUiPanelRogueSimMainLevelUp : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimMainLevelUp = XClass(XUiNode, "XUiPanelRogueSimMainLevelUp")

function XUiPanelRogueSimMainLevelUp:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridReward.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridRewardList = {}
end

function XUiPanelRogueSimMainLevelUp:Refresh(data)
    self.Data = data
    -- 等级
    self.TxtLv.text = self._Control:GetCurMainLevel()
    -- 奖励
    self:RefreshReward()
    -- 解锁科技等级和探索区域
    local isUnlockTech, isUnlockArea = self:CheckUnlockTechAndArea()
    self.PanelUnlock.gameObject:SetActiveEx(isUnlockTech or isUnlockArea)
    self.Txt01.gameObject:SetActiveEx(isUnlockTech)
    self.Txt02.gameObject:SetActiveEx(isUnlockArea)
end

function XUiPanelRogueSimMainLevelUp:RefreshReward()
    local rewardList = self:GetMainLevelRewardList()
    local index = 0
    for id, count in pairs(rewardList) do
        index = index + 1
        local grid = self.GridRewardList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridReward, self.PanelRewardList)
            self.GridRewardList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("RImgIcon"):SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(id))
        grid:GetObject("TxtCount").text = string.format("x%s", count)
    end
    for i = index + 1, #self.GridRewardList do
        self.GridRewardList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimMainLevelUp:GetMainLevelRewardList()
    local rewardList = {}
    for _, v in pairs(self.Data) do
        local level = v.Level
        local configId = self._Control:GetMainLevelConfigId(level)
        -- 资源
        local rewardResourceIds = self._Control:GetMainLevelRewardResourceIds(configId)
        local rewardResourceCounts = self._Control:GetMainLevelRewardResourceCounts(configId)
        for index, id in pairs(rewardResourceIds) do
            local curCount = rewardList[id] or 0
            rewardList[id] = curCount + rewardResourceCounts[index]
        end
    end
    return rewardList
end

-- 检测是否解锁科技和探索区域
function XUiPanelRogueSimMainLevelUp:CheckUnlockTechAndArea()
    local isUnlockTech = false
    local isUnlockArea = false
    for _, v in pairs(self.Data) do
        local level = v.Level
        local configId = self._Control:GetMainLevelConfigId(level)
        -- 解锁科技等级
        local unlockTechLevel = self._Control:GetMainLevelUnlockTechLevel(configId)
        if XTool.IsNumberValid(unlockTechLevel) then
            isUnlockTech = true
        end
        -- 解锁区域索引
        local unlockAreaIdx = self._Control:GetMainLevelUnlockAreaIdx(configId)
        if XTool.IsNumberValid(unlockAreaIdx) then
            isUnlockArea = true
        end
    end
    return isUnlockTech, isUnlockArea
end

function XUiPanelRogueSimMainLevelUp:OnBtnCloseClick()
    self:Close()
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        return
    end
    -- 弹出下一个弹框
    self._Control:ShowPopup(type)
end

return XUiPanelRogueSimMainLevelUp
