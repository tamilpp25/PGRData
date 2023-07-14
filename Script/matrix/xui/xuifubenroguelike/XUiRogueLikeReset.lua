local XUiRogueLikeReset = XLuaUiManager.Register(XLuaUi, "UiRogueLikeReset")

function XUiRogueLikeReset:OnAwake()
    self.BtnClose.CallBack = function () self:Close() end
    self.BtnTanchuangClose.CallBack = function () self:Close() end
    self.BtnResetAll.CallBack = function () self:OnBtnResetAllClick() end
    self.BtnSingleReset.CallBack = function () self:OnBtnSingleResetClick() end
end

function XUiRogueLikeReset:OnStart(title, content)
    if title ~= nil and title ~= "" then
        self.TitleLabel.text = title
    else
        self.TitleLabel.text = CS.XTextManager.GetText("RogueLikePurgatoryResetTitle")
    end

    self.ContentText.text = string.gsub(content, "\\n", "\n")
end

function XUiRogueLikeReset:OnBtnResetAllClick()
    self:RealReset(1)
end

function XUiRogueLikeReset:OnBtnSingleResetClick()
    self:RealReset(2)
end

function XUiRogueLikeReset:RealReset(resetType)
    XDataCenter.FubenRogueLikeManager.ResetHardNode(resetType, function()
        self:Close()
    end)
end

