local XUiButton = require("XUi/XUiCommon/XUiButton")

---@class XUiTransfiniteMainGridIsland
local XUiTransfiniteMainGridIsland = XClass(nil, "XUiTransfiniteMainGridIsland")

function XUiTransfiniteMainGridIsland:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnLostNote, self.OnClickRecord)
    XUiHelper.RegisterClickEvent(self, self.BtnLostPassage, self.OnClick)
    ---@type XUiButtonLua
    self._ButtonAchievement = XUiButton.New(self.BtnLostSuccess)
    self._StageGroup = false
end

---@param data XViewModelTransfiniteDataIsland
function XUiTransfiniteMainGridIsland:Update(data)
    self._StageGroup = data.StageGroup
    self.BtnLostPassage:SetNameByGroup(0, data.Name)
    self.BtnLostPassage:SetNameByGroup(1, data.TextProgress)
    self.BtnLostSuccess:SetNameByGroup(0, data.AchievementAmount)
    self.BtnLostSuccess:ShowReddot(data.IsEnableReward)
    self._ButtonAchievement:SetFillAmount("ImgProgressBarBg/ImgProgressBar", data.Progress)
end

function XUiTransfiniteMainGridIsland:OnClickRecord()
    local stageGroup = self._ViewModel:GetStageGroup()
    
    XLuaUiManager.Open("UiTransfiniteSuccess", stageGroup)
end

function XUiTransfiniteMainGridIsland:OnClick()
    XLuaUiManager.Open("UiTransfiniteBattlePrepare", self._StageGroup)
end

return XUiTransfiniteMainGridIsland