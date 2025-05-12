local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@field _Control XPassportControl
---@class XUiPassportUpLevelGrid:XUiNode
local XUiPassportUpLevelGrid = XClass(XUiNode, "XUiPassportUpLevelGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText
local MaxGridCount = 3

function XUiPassportUpLevelGrid:Ctor(ui)
    self.RewardPanelList = {}
    self:SetImgEffectActive(false)
end

function XUiPassportUpLevelGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPassportUpLevelGrid:Refresh(levelId)
    self:SetImgEffectActive(false)

    local level = self._Control:GetPassportLevel(levelId)
    self.Text.text = CSXTextManagerGetText("PassportLevelUnLockSupplyDesc", level)

    local unLockPassportRewardIdList = self._Control:GetUnLockPassportRewardIdListByLevel(level)
    local gridCostItem
    local panel
    local rewardData
    for i, passportRewardId in ipairs(unLockPassportRewardIdList) do
        rewardData = self._Control:GetPassportRewardData(passportRewardId)
        gridCostItem = self["GridCostItem" .. i]
        panel = self.RewardPanelList[i]
        if gridCostItem and not panel then
            panel = XUiGridCommon.New(self.RootUi, gridCostItem)
            table.insert(self.RewardPanelList, panel)
        end

        if gridCostItem and panel and rewardData then
            panel:Refresh(rewardData)
            gridCostItem.gameObject:SetActiveEx(true)
        else
            gridCostItem.gameObject:SetActiveEx(false)
        end
    end

    for i = #unLockPassportRewardIdList + 1, MaxGridCount do
        gridCostItem = self["GridCostItem" .. i]
        if gridCostItem then
            gridCostItem.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPassportUpLevelGrid:ShowEffect()
    self:SetImgEffectActive(true)
    XScheduleManager.ScheduleOnce(function()
        self:SetImgEffectActive(false)
    end, XScheduleManager.SECOND)
end

function XUiPassportUpLevelGrid:SetImgEffectActive(isActive)
    if XTool.UObjIsNil(self.ImgEffect) then
        return
    end
    self.ImgEffect.gameObject:SetActiveEx(isActive)
end

return XUiPassportUpLevelGrid