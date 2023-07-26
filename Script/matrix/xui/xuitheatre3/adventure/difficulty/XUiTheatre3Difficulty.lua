local XGridTheatre3Difficulty = require("XUi/XUiTheatre3/Adventure/Difficulty/XGridTheatre3Difficulty")

---@class XUiTheatre3Difficulty : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Difficulty = XLuaUiManager.Register(XLuaUi, "UiTheatre3Difficulty")

function XUiTheatre3Difficulty:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3Difficulty:OnStart()
    self:InitDifficultyPanelList()
    self:Refresh()
end

--region Ui - Refresh
function XUiTheatre3Difficulty:Refresh()
    for i, grid in ipairs(self._DifficultyPanelList) do
        grid:Refresh(self._DifficultyIdList[i])
    end
end
--endregion

--region Ui - Difficulty
function XUiTheatre3Difficulty:InitDifficultyPanelList()
    self._DifficultyIdList = self._Control:GetDifficultyIdList()
    ---@type XGridTheatre3Difficulty[]
    self._DifficultyPanelList = {
        XGridTheatre3Difficulty.New(self.PanelDifficulty1.transform, self),
        XGridTheatre3Difficulty.New(self.PanelDifficulty2.transform, self),
        XGridTheatre3Difficulty.New(self.PanelDifficulty3.transform, self),
    }
    self._BtnList = {
        self.PanelDifficulty1,
        self.PanelDifficulty2,
        self.PanelDifficulty3,
    }
    self.BtnGroup:Init(self._BtnList, handler(self, self.SelectDifficulty))
    self.BtnGroup:SelectIndex(1)
end

function XUiTheatre3Difficulty:SelectDifficulty(index)
    self._SelectDifficultyId = self._DifficultyIdList[index]
    self:Refresh()
end
--endregion

--region Ui - BtnListener
function XUiTheatre3Difficulty:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeamInstall, self.OnBtnTeamInstallClick)
end

function XUiTheatre3Difficulty:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Difficulty:OnBtnTeamInstallClick()
    if not XTool.IsNumberValid(self._SelectDifficultyId) then
        return
    end
    local cfg = self._Control:GetDifficultyById(self._SelectDifficultyId)
    local conditionId = cfg.ConditionId
    local isUnLock, lockDesc
    if XTool.IsNumberValid(conditionId) then
        isUnLock = self._Control:IsDifficultyUnlock(self._SelectDifficultyId)
        lockDesc = XConditionManager.GetConditionDescById(conditionId)
    else
        isUnLock = true
    end
    if isUnLock then
        self._Control:RequestAdventureSelectDifficulty(self._SelectDifficultyId, function()
            self._Control:CheckAndOpenAdventureNextStep(true)
        end)
    else
        XUiManager.TipError(lockDesc)
    end
end
--endregion

return XUiTheatre3Difficulty