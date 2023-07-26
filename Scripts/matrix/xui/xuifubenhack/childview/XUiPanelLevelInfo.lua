local XUiPanelLevelInfo = XClass(nil, "XUiPanelLevelInfo")

local Lerp = CS.UnityEngine.Mathf.Lerp

function XUiPanelLevelInfo:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitUi()
    self:Refresh()
end

function XUiPanelLevelInfo:InitUi()
    self.ActTemplate = XDataCenter.FubenHackManager.GetCurrentActTemplate()
    self.TxtName.text = CS.XTextManager.GetText("FubenHackLevelName")
    --self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ActTemplate.ExpId))
end

function XUiPanelLevelInfo:Refresh(isPlayAnim)
    self.IsPlayAnim = isPlayAnim
    self.TxtMaxLevel.text = string.format("/%d", XDataCenter.FubenHackManager.GetMaxLevel())

    if self.IsPlayAnim then
        self:NextStep()
    else
        self:ShowInfo()
    end
end

function XUiPanelLevelInfo:ShowInfo()
    local curLv = XDataCenter.FubenHackManager.GetLevel()
    local isMaxLv = curLv >= XDataCenter.FubenHackManager.GetMaxLevel()
    self.TxtLevel.text = string.format("%02d", curLv)
    if isMaxLv then
        self.TxtExp.text = CS.XTextManager.GetText("RpgTowerMaxLevel")
        self.ImgProgress.fillAmount = 1
        --self.RImgIcon.gameObject:SetActiveEx(false)
    else
        local curExp = XDataCenter.FubenHackManager.GetCurExp()
        local upExp = XDataCenter.FubenHackManager.GetNextUpExp()
        self.TxtExp.text = string.format("%d/%d", curExp, upExp)
        self.ImgProgress.fillAmount = curExp / upExp
    end
end

function XUiPanelLevelInfo:NextStep()
    if not self.IsPlayAnim then return end
    local isExpAdd, isLvUp, showLv, curExp, nextExp, fullExp = XDataCenter.FubenHackManager.CheckExpAdd()
    if isExpAdd then
        self.TxtLevel.text = string.format("%02d", showLv)
        self.AnimTimer = XUiHelper.Tween(0.7, function(f)
            local tempExp
            if isLvUp then
                tempExp = Lerp(curExp, 2 * fullExp - nextExp, f)
            else
                tempExp = Lerp(curExp, nextExp, f)
            end
            if tempExp <= fullExp then
                self.ImgProgress.fillAmount = tempExp / fullExp
                self.TxtExp.text = string.format("%.f/%d", tempExp, fullExp)
            else
                self.ImgProgress.fillAmount = (2 * fullExp - tempExp) / fullExp
            end
            --XLog.Warning(showLv, curExp, nextExp, fullExp)
        end, function()
            self:NextStep()
        end, function(t)
            return XUiHelper.Evaluate(XUiHelper.EaseType.Sin, t)
        end)
        return true
    else
        self:ShowInfo()
        XDataCenter.FubenHackManager.CheckLevelUp()
    end
end

function XUiPanelLevelInfo:OnDisable()
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
    end
    self.IsPlayAnim = false
end

return XUiPanelLevelInfo