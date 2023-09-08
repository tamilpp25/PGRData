local XUiButton = require("XUi/XUiCommon/XUiButton")

---@class XUiTransfiniteMainGridIsland
local XUiTransfiniteMainGridIsland = XClass(nil, "XUiTransfiniteMainGridIsland")

function XUiTransfiniteMainGridIsland:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XViewModelTransfinite
    self._ViewModel = false
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnLostNote, self.OnClickRecord)
    XUiHelper.RegisterClickEvent(self, self.BtnLostPassage, self.OnClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLostSuccess, self.OnClickSuccess)
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
    self.BtnLostPassage:SetRawImage(data.IslandImage)
    self._ButtonAchievement:SetFillAmount("ImgProgressBarBg/ImgProgressBar", data.Progress)
end

function XUiTransfiniteMainGridIsland:OnClickRecord()
    self._ViewModel:OnClickRecord(self._StageGroup)
end

function XUiTransfiniteMainGridIsland:OnClick()
    XLuaUiManager.Open("UiTransfiniteBattlePrepare", self._StageGroup)
end

function XUiTransfiniteMainGridIsland:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiTransfiniteMainGridIsland:OnClickSuccess()
    XLuaUiManager.Open("UiTransfiniteSuccess", self._StageGroup)
end

return XUiTransfiniteMainGridIsland