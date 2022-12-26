local XUiHackDevelop = XLuaUiManager.Register(XLuaUi, "UiHackDevelop")

local XUiPanelLevelInfo = require("XUi/XUiFubenHack/ChildView/XUiPanelLevelInfo")
local XUiPanelBuffDetail = require("XUi/XUiFubenHack/ChildView/XUiPanelBuffDetail")
local XUiGridLevelBuff = require("XUi/XUiFubenHack/ChildItem/XUiGridLevelBuff")

function XUiHackDevelop:OnAwake()
    self:AutoAddListener()
end

function XUiHackDevelop:OnStart()
    self.ActTemplate = XDataCenter.FubenHackManager.GetCurrentActTemplate()
    self:InitUi()
    self:Refresh()
    XScheduleManager.ScheduleOnce(function()
        self:MoveIntoBuff(XDataCenter.FubenHackManager.GetBuffListShowIndex())
    end, 0)
    self.IsPlayingAnim = false
    self.IsPlayedAnim = false
end

function XUiHackDevelop:OnGetEvents()
    return { XEventId.EVENT_FUBEN_HACK_UPDATE,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiHackDevelop:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_HACK_UPDATE then
        self:Refresh(args)
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Hack then return end
        XDataCenter.FubenHackManager.OnActivityEnd()
    end
end

function XUiHackDevelop:OnDestroy()
    for i, v in pairs(self.LvBuffList)do
        v:OnDestroy()
        self.LvBuffList[i] = nil
    end
end

function XUiHackDevelop:OnBtnExpandClick()
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_HACK_CLICK)
    if self.IsPlayingAnim then return end
    self.BtnExpand.gameObject:SetActiveEx(false)
    self.IsPlayingAnim = true
    self:PlayAnimation("PanelQuanRotate", function()
        self.IsPlayedAnim = true
        self.IsPlayingAnim = false
        self:PlayAnimation("PanelQuanLoop")
    end)
end

function XUiHackDevelop:InitUi()
    self.TxtTitle.text = CSXTextManagerGetText("FubenHackDevelop")
    self.TxtTitleEn.text = CSXTextManagerGetText("FubenHackDevelopEn")

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, true)
    self.PanelLevelInfo = XUiPanelLevelInfo.New(self, self.PanelLvInfo)
    self.BtnBuffBarList = {}
    for i = 1, XFubenHackConfig.BuffBarCapacity do
        self.BtnBuffBarList[i] = self["BtnBuffBar"..i]
        self.BtnBuffBarList[i].CallBack = function() self:OnBtnBuffBarClick(i) end
    end
    self.LvBuffList = {}
    for i = 1, XDataCenter.FubenHackManager.GetMaxLevel() do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.BuffListContent)
        ui.name = i
        self.LvBuffList[i] = XUiGridLevelBuff.New(self, ui)
    end
    self.GridBuff.gameObject:SetActiveEx(false)
    self.PanelBuffDetail = {}
    self.PanelBuffDetail[XFubenHackConfig.PopUpPos.Left] = XUiPanelBuffDetail.New(self, self.PanelSelectLeft)
    self.PanelBuffDetail[XFubenHackConfig.PopUpPos.Right] = XUiPanelBuffDetail.New(self, self.PanelSelectRight)
end

function XUiHackDevelop:MoveIntoBuff(level, isPlayAnim)
    if level <= 0 or level > XDataCenter.FubenHackManager.GetMaxLevel() then return end
    local height = CS.XResolutionManager.OriginHeight
    local gridRect = self.LvBuffList[level].Transform
    local tarPosY = (height / 4) - gridRect.localPosition.y
    local tarPos = self.BuffListContent.localPosition
    --XLog.Warning(tarPosY, self.BuffListContent.localPosition.y)
    tarPos.y = tarPosY
    self.SRBuffList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    if isPlayAnim then
        if tarPosY - self.BuffListContent.localPosition.y < height / 2 and
                tarPosY - self.BuffListContent.localPosition.y > -40 then
            self.SRBuffList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
            return
        end
        XUiHelper.DoMove(self.BuffListContent, tarPos, 0.5, XUiHelper.EaseType.Sin, function()
            self.SRBuffList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        end)
    else
        self.BuffListContent.localPosition = tarPos
        self.SRBuffList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    end
end

function XUiHackDevelop:Refresh()
    self.BuffBarList = XDataCenter.FubenHackManager.GetBuffBarList()

    self.AssetActivityPanel:Refresh({self.ActTemplate.TicketId})

    for i = 1, XFubenHackConfig.BuffBarCapacity do
        self.BtnBuffBarList[i]:SetButtonState(XDataCenter.FubenHackManager.IsBuffPosUnlock(i) and XUiButtonState.Normal or XUiButtonState.Disable)
        local item = self.BtnBuffBarList[i].transform
        local imgPlus = item:Find("ImgPlus")
        local rimgBuff = item:Find("RImgBuff"):GetComponent("RawImage")
        if self.BuffBarList[i] == 0 then
            imgPlus.gameObject:SetActiveEx(XDataCenter.FubenHackManager.IsBuffPosUnlock(i))
            rimgBuff.gameObject:SetActiveEx(false)
        else
            imgPlus.gameObject:SetActiveEx(false)
            rimgBuff.gameObject:SetActiveEx(true)
            rimgBuff:SetRawImage(XFubenHackConfig.GetBuffById(self.BuffBarList[i]).Icon)
            if self.BuffBarLastState and self.BuffBarLastState[i] == 0 then
                self.BtnBuffBarList[i]:ShowTag(false)
                self.BtnBuffBarList[i]:ShowTag(true)
            end
        end
    end
    self.BuffBarLastState = XTool.Clone(self.BuffBarList)

    for i = 1, XDataCenter.FubenHackManager.GetMaxLevel() do
        self.LvBuffList[i]:Refresh(i)
    end

    self.PanelLevelInfo:Refresh()
end

function XUiHackDevelop:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self:BindHelpBtn(self.BtnHelp, "FubenHack")

    self:RegisterClickEvent(self.BtnExpand, self.OnBtnExpandClick)
end

function XUiHackDevelop:OpenPanelBuffDetail(buffId, pos)
    self.PanelBuffDetail[pos]:Show(buffId)
end

function XUiHackDevelop:OnBtnBuffBarClick(index)
    --for i = 1, XDataCenter.FubenHackManager.GetMaxLevel() do
    --    local buffId = XDataCenter.FubenHackManager.GetLevelCfg(i).Id
    --    if self.BuffBarList[index] == buffId then
    --        self:MoveIntoBuff(i, true)
    --        break
    --    end
    --end

    local res, level = XDataCenter.FubenHackManager.IsBuffPosUnlock(index)
    if res then
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_HACK_CLICK, self.BuffBarList[index], true)
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("FubenHackBuffPosLockTip", level))
    end

    if not self.IsPlayedAnim or self.IsPlayingAnim or self.BuffBarList[index] == 0 then return end
    self:OpenPanelBuffDetail(self.BuffBarList[index], XFubenHackConfig.PopUpPos.Left)
end

function XUiHackDevelop:OnBtnBackClick()
    self:Close()
end

function XUiHackDevelop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
