local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XGridTheatre3Difficulty : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3Difficulty = XClass(XUiNode, "XGridTheatre3Difficulty")

function XGridTheatre3Difficulty:OnStart()
    self.Grid128.gameObject:SetActiveEx(true)
    self.Grid128Select.gameObject:SetActiveEx(true)
    ---@type XUiGridCommon
    self._RewardCommon = XUiGridCommon.New(self.Parent, self.Grid128)
    ---@type XUiGridCommon
    self._RewardCommonSelect = XUiGridCommon.New(self.Parent, self.Grid128Select)
    if self._RewardCommon then
        self._RewardCommon:Refresh(XEnumConst.THEATRE3.Theatre3OutCoin)
        self._RewardCommon:SetProxyClickFunc(function()
            self:OnRewardGridClick()
        end)
    end
    if self._RewardCommonSelect then
        self._RewardCommonSelect:Refresh(XEnumConst.THEATRE3.Theatre3OutCoin)
        self._RewardCommonSelect:SetProxyClickFunc(function()
            self:OnRewardGridClick()
        end)
    end
end

--region Ui - Refresh
function XGridTheatre3Difficulty:Refresh(difficultyId)
    self._DifficultyCfg = self._Control:GetDifficultyById(difficultyId)
    local conditionId = self._DifficultyCfg.ConditionId
    if XTool.IsNumberValid(conditionId) then
        self.IsUnlock = self._Control:IsDifficultyUnlock(difficultyId)
        self.LockDesc = XConditionManager.GetConditionDescById(conditionId)
    else
        self.IsUnlock = true
    end

    self.PanelLock.gameObject:SetActiveEx(not self.IsUnlock)
    self.PanelLockSelect.gameObject:SetActiveEx(not self.IsUnlock)

    if self.PanelDifficulty then
        self.PanelDifficulty:SetNameByGroup(0, self._DifficultyCfg.Name)
        for i = 0, self.PanelDifficulty.TxtGroupList[1].TxtList.Count - 1 do
            self.PanelDifficulty.TxtGroupList[1].TxtList[i].gameObject:SetActiveEx(false)
        end
        self.PanelDifficulty:SetNameByGroup(2, XUiHelper.ConvertLineBreakSymbol(self._DifficultyCfg.Desc))
        self.PanelDifficulty:SetNameByGroup(3, XUiHelper.ConvertLineBreakSymbol(self._DifficultyCfg.StoryDesc))
        self.PanelDifficulty:SetNameByGroup(5, self._DifficultyCfg.BPExpRate)
        self.PanelDifficulty:SetNameByGroup(6, self.LockDesc)
        if not string.IsNilOrEmpty(self._DifficultyCfg.BgIcon) then
            self.PanelDifficulty:SetRawImage(self._DifficultyCfg.BgIcon)
        end
    end
end
--endregion

--region Ui - BtnListener
function XGridTheatre3Difficulty:OnRewardGridClick()
    XLuaUiManager.Open("UiTheatre3Tips", XEnumConst.THEATRE3.Theatre3OutCoin)
end
--endregion

return XGridTheatre3Difficulty