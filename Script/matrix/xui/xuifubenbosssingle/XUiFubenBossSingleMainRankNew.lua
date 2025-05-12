local XUiFubenBossSingleMainRank = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMainRank")

---@class XUiFubenBossSingleMainRankNew : XUiFubenBossSingleMainRank
---@field BtnRank XUiComponent.XUiButton
---@field PanelRankEmpty UnityEngine.RectTransform
---@field TxtRankEmpty UnityEngine.UI.Text
---@field TxtNoneRank UnityEngine.UI.Text
---@field TxtRank UnityEngine.UI.Text
---@field PanelRankInfo UnityEngine.RectTransform
local XUiFubenBossSingleMainRankNew = XClass(XUiFubenBossSingleMainRank, "XUiFubenBossSingleMainRankNew")

function XUiFubenBossSingleMainRankNew:OnStart(rootUi)
    self._RootUi = rootUi
    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleMainRankNew:Init()
    local bossSingleData = self._Control:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()

    self.Super.Init(self)
    if self._Control:CheckHasRankData(levelType) then
        self.BtnRank:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnRank:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiFubenBossSingleMainRankNew:RefreshRankReward()
end

function XUiFubenBossSingleMainRankNew:OnBtnRankClick()
    local levelType = self._Control:GetBossSingleData():GetBossSingleLevelType()

    self._Control:OpenRankUi(levelType)
end

function XUiFubenBossSingleMainRankNew:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick, true)
end

return XUiFubenBossSingleMainRankNew
