local XUiBabelTowerMainNewTips = XLuaUiManager.Register(XLuaUi, "UiBabelTowerMainNewTips")
local XUiGridBabelTowerMainNewRole = require("XUi/XUiFubenBabelTower/XUiGridBabelTowerMainNewRole")

function XUiBabelTowerMainNewTips:OnStart(unlockInfo, warnInfo, cancelCallBack, confirmCallBack)
    self.PermissionNnlocking.gameObject:SetActiveEx(unlockInfo ~= nil)
    self.PanelWarning.gameObject:SetActiveEx(warnInfo ~= nil)
    self.BtnNoWarning.gameObject:SetActiveEx(false)
    self.BtnNoWarning2.gameObject:SetActiveEx(false)
    
    if unlockInfo then
        XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
        self.TxtTitleUnlock.text = unlockInfo.Title
        self.TxtDescUnlock.text = unlockInfo.Content
        if unlockInfo.ScoreTitle then
            local grid = XUiGridBabelTowerMainNewRole.New(self.GridRole)
            grid:Refresh(unlockInfo.ScoreTitle)
        end
    end

    if warnInfo then
        -- 注册ui事件
        self:RegisterUiEvents()
        
        self.TxtTitle.text = warnInfo.Title
        self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(warnInfo.Content)
        
        self.BtnReselect.gameObject:SetActiveEx(not warnInfo.IsWarning)
        self.BtnChangeRole.gameObject:SetActiveEx(warnInfo.IsWarning)
        if warnInfo.HintInfo then
            self.HintCb = warnInfo.HintInfo.HintCb
            local isSelect = warnInfo.HintInfo.Status == true
            self[warnInfo.HintInfo.HintClickName]:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
            self[warnInfo.HintInfo.HintClickName].gameObject:SetActiveEx(true)
        end
    end
    
    self.OkCallBack = confirmCallBack
    self.CancelCallBack = cancelCallBack
end

function XUiBabelTowerMainNewTips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnChallenge, self.OnBtnChallengeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReselect, self.OnBtnReselectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChangeRole, self.OnBtnChangeRoleClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNoWarning, self.OnBtnNoWarningClick)
    XUiHelper.RegisterClickEvent(self, self.BtnNoWarning2, self.OnBtnNoWarningClick)
end

--region PermissionUnlocking

function XUiBabelTowerMainNewTips:OnBtnCloseClick()
    self:Close()
end

--endregion

--region PanelWarning or InsufficientLevel
-- 继续挑战
function XUiBabelTowerMainNewTips:OnBtnChallengeClick()
    self:Close()
    if self.OkCallBack then
        self.OkCallBack()
    end
end

-- 重新选择
function XUiBabelTowerMainNewTips:OnBtnReselectClick()
    self:Close()
end

-- 变更角色
function XUiBabelTowerMainNewTips:OnBtnChangeRoleClick()
    self:Close()
    if self.CancelCallBack then
        self.CancelCallBack()
    end
end

--不在显示警告
function XUiBabelTowerMainNewTips:OnBtnNoWarningClick()
    local isSelect = self.BtnNoWarning.ButtonState == CS.UiButtonState.Select
    if self.HintCb then
        self.HintCb(isSelect)
    end
end

--endregion

return XUiBabelTowerMainNewTips