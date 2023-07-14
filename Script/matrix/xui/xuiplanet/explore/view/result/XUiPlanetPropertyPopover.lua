---@class XUiPlanetPropertyPopover:XLuaUi
local XUiPlanetPropertyPopover = XLuaUiManager.Register(XLuaUi, "UiPlanetPropertyPopover")

function XUiPlanetPropertyPopover:Ctor()
end

function XUiPlanetPropertyPopover:OnAwake()
    self:BindExitBtns(self.BtnClose)
    self:BindExitBtns(self.BtnTanchuangClose)
    self:RegisterClickEvent(self.BtnConfirm, self._OnClickClose)
    self:RegisterClickEvent(self.BtnCancel, self._OnClickLeaveExplore)
end

function XUiPlanetPropertyPopover:OnStart(isTip, txtTitle, contentTxt, sureCb, closeCb)
    if txtTitle then
        self.TxtName.text = txtTitle
    end
    if contentTxt then
        self.TxtTitle02.text = contentTxt
    end
    if sureCb or closeCb then
        self.BtnConfirm:SetNameByGroup(0, XUiHelper.GetText("PlanetRunningTipSure"))
        self.BtnCancel:SetNameByGroup(0, XUiHelper.GetText("PlanetRunningTipCancel"))
    end
    self.IsTip = isTip or false
    self.SureCb = sureCb or false
    self.CloseCb = closeCb or false
end

function XUiPlanetPropertyPopover:_OnClickClose()
    if self.IsTip then
        self:Close()
        if self.SureCb then
            self.SureCb()
        end
        return
    end
    --保存关卡进度时退出其他无关界面
    local uiList = {
        "UiPlanetChapter",
        "UiPlanetChapterChoice",
        "UiPlanetExplore",
    }
    for _, uiName in ipairs(uiList) do
        if XLuaUiManager.IsUiLoad(uiName) then
            XLuaUiManager.Remove(uiName)
        end
    end
    XLuaUiManager.Close("UiPlanetPropertyPopover")
    XLuaUiManager.Close("UiPlanetBattleMain")
end

function XUiPlanetPropertyPopover:_OnClickLeaveExplore()
    if self.IsTip then
        self:Close()
        if self.CloseCb then
            self.CloseCb()
        end
        return
    end
    XDataCenter.PlanetManager.SettleStage()
    self:Close()
end

return XUiPlanetPropertyPopover
