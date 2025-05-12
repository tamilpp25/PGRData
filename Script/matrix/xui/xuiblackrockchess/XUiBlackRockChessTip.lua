---@class XUiBlackRockChessTip : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessTip = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessTip")

function XUiBlackRockChessTip:OnAwake()
    self.BtnYes.CallBack = handler(self, self.OnBtnYes)
    self.BtnNo.CallBack = handler(self, self.OnBtnNo)
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnHint.CallBack = handler(self, self.OnBtnHintClick)
end

function XUiBlackRockChessTip:OnStart(title, yesTxt, yesCb, noTxt, noCb, hintInfo)
    self._YesCb = yesCb
    self._NoCb = noCb

    self.TxtDetails.text = title

    if yesTxt then
        self.BtnYes:SetNameByGroup(0, yesTxt)
    end

    if noTxt then
        self.BtnNo:SetNameByGroup(0, noTxt)
    end

    if hintInfo then
        self.SetHintCb = hintInfo.SetHintCb

        local isSelect = hintInfo.Status == true
        self.BtnHint:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self.BtnHint.gameObject:SetActiveEx(true)
        self.IsNeedClose = hintInfo.IsNeedClose

        if hintInfo.HintText and hintInfo.HintText ~= "" then
            self.TxtHint.text = hintInfo.HintText
        end
    else
        self.BtnHint.gameObject:SetActiveEx(false)
    end

    self:SetAutoCloseInfo(self._Control:GetActivityStopTime(), function(isClose)
        if isClose then
            self._Control:OnActivityEnd()
            return
        end
    end, nil, 0)
end

function XUiBlackRockChessTip:OnBtnYes()
    self:Close()
    if self._YesCb then
        self._YesCb()
    end
end

function XUiBlackRockChessTip:OnBtnNo()
    self:Close()
    if self._NoCb then
        self._NoCb()
    end
end

function XUiBlackRockChessTip:OnBtnHintClick()
    local isSelect = self.BtnHint.ButtonState == CS.UiButtonState.Select
    if self.SetHintCb then
        self.SetHintCb(isSelect)
    end
    -- 点击今日不再提示，同时关闭提示界面
    if self.IsNeedClose and isSelect then
        self:OnBtnNo()
    end
end

return XUiBlackRockChessTip