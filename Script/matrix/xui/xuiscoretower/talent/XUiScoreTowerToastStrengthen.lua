---@class XUiScoreTowerToastStrengthen : XLuaUi
---@field private _Control XScoreTowerControl
local XUiScoreTowerToastStrengthen = XLuaUiManager.Register(XLuaUi, "UiScoreTowerToastStrengthen")

function XUiScoreTowerToastStrengthen:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiScoreTowerToastStrengthen:OnStart(strengthenId, isSuccess)
    self.StrengthenId = strengthenId
    self.IsSuccess = isSuccess
end

function XUiScoreTowerToastStrengthen:OnEnable()
    self.TxtTips.gameObject:SetActiveEx(not self.IsSuccess)
    local curLevel = self._Control:GetStrengthenBuffCurLv(self.StrengthenId)
    if curLevel == 1 and self.IsSuccess then
        self.TxtTitle.text = self._Control:GetClientConfig("StrengthenRelatedTips", 8)
        return
    end
    -- 标题
    self.TxtTitle.text = self._Control:GetClientConfig("StrengthenRelatedTips", self.IsSuccess and 5 or 6)
    if not self.IsSuccess then
        -- 提示
        self.TxtTips.text = self._Control:GetClientConfig("StrengthenRelatedTips", 7)
        local rate = self._Control:GetStrengthenBuffNextLvRate(self.StrengthenId, curLevel)
        -- 概率
        self.TxtNum.text = string.format("%s%%", rate / 100)
    end
end

function XUiScoreTowerToastStrengthen:OnBtnCloseClick()
    self:Close()
end

return XUiScoreTowerToastStrengthen
