local XUiMoeWarSchedule = XLuaUiManager.Register(XLuaUi, "UiMoeWarSchedule")

local XUiPanelMatchLarge = require("XUi/XUiMoeWar/SubPage/XUiPanelMatchLarge")
local XUiPanelMatchSmall = require("XUi/XUiMoeWar/SubPage/XUiPanelMatchSmall")
local XUiPanelMatchFinal = require("XUi/XUiMoeWar/SubPage/XUiPanelMatchFinal")

local CSXTextManagerGetText = CS.XTextManager.GetText

local MAX_MODEL_COUNT = 3

function XUiMoeWarSchedule:OnAwake()
    self.BtnList = {self.BtnGame24In12, self.BtnGame12In6, self.BtnGame6In3, self.BtnGame3In1}
    self.PanelList = {self.PanelGame24In12, self.PanelGame12In6, self.PanelGame6In3, self.PanelGame3In1}
    self.ObjList = {}
    self.SessionList = XDataCenter.MoeWarManager.GetSessionList()
    self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    self.IsPlayAnim = false

    self:InitUiView()
    self:InitSceneRoot()

    for i, match in ipairs(self.SessionList) do
        if not match:GetNotOpen() then
            self.CurrentView = i
        end
    end
    self.CurrentView = self.CurrentView or 1
    self.BtnGrpMatch:Init(self.BtnList ,function(index) self:SwitchTab(index) end)
    self:UpdateBtnGrpMatch()
    self.BtnGrpMatch:SelectIndex(self.CurrentView, false)
end

function XUiMoeWarSchedule:OnEnable()
    if not self:CheckIsNeedPop() then
        self:AddTimer()
        self:Refresh()
    end
end

function XUiMoeWarSchedule:OnStart(selectGroup)
    self.LastMatchType = XDataCenter.MoeWarManager.GetCurMatch():GetType()
    self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    self:Refresh(true, selectGroup)
end

function XUiMoeWarSchedule:OnGetEvents()
    return { XEventId.EVENT_MOE_WAR_UPDATE,
             XEventId.EVENT_MOE_WAR_ACTIVITY_END}
end

function XUiMoeWarSchedule:OnNotify(evt, ...)
    if evt == XEventId.EVENT_MOE_WAR_UPDATE then
        if not self:CheckIsNeedPop() then
            self:Refresh(true)
        end
    elseif evt == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
        XDataCenter.MoeWarManager.OnActivityEnd()
    end
end

function XUiMoeWarSchedule:OnDisable()
    self:RemoveTimer()
end

function XUiMoeWarSchedule:InitUiView()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)

    XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[1], function()
        self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    end, self.AssetActivityPanel)

    self.TxtBtnGrpMatchLock = {}
    self.TxtBtnGrpMatchNow = {}
    self.TxtBtnGrpMatchEnd = {}

    for i, v in ipairs(self.BtnList) do
        local match = XDataCenter.MoeWarManager.GetMatch(i)
        v:SetNameByGroup(0, match:GetName())
        v:SetNameByGroup(1, match:GetSubName())
        self.TxtBtnGrpMatchLock[i] = v.transform:Find("TagLock/Text"):GetComponent("Text")
        self.TxtBtnGrpMatchNow[i] = v.transform:Find("TagNow/Text"):GetComponent("Text")
        self.TxtBtnGrpMatchEnd[i] = v.transform:Find("TagEnd/Text"):GetComponent("Text")
    end

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "MoeWar")
end

function XUiMoeWarSchedule:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.SmallMatchPanelModel = {}
    self.SmallMatchImgEffect = {}
    self.SmallMatchPanelModel[1] = root:FindTransform("PanelModelCase1")
    --self.SmallMatchImgEffect[1] = root:FindTransform("ImgEffectHuanren1")
    self.SmallMatchPanelModel[2]  = root:FindTransform("PanelModelCase2")
    --self.SmallMatchImgEffect[2] = root:FindTransform("ImgEffectHuanren2")
    self.SmallMatchPanelModel[3]  = root:FindTransform("PanelModelCase3")
    --self.SmallMatchImgEffect[3] = root:FindTransform("ImgEffectHuanren3")
    self.FinalMatchPanelModel = root:FindTransform("PanelModelCase4")
    --self.FinalMatchImgEffect = root:FindTransform("ImgEffectHuanren4")
end

function XUiMoeWarSchedule:SwitchTab(index, isFromOtherUi)
    if self.CurrentView == index then
        return
    elseif XDataCenter.MoeWarManager.GetMatch(index):GetNotOpen() then
        local startTime = XDataCenter.MoeWarManager.GetVoteMatch(index):GetStartTime()
        XUiManager.TipMsg(XUiHelper.GetInTimeDesc(startTime))
        return
    else
        if not isFromOtherUi then
            self:PlayAnimation("QieHuan1")
        end
        self.CurrentView = index
        self:Refresh()
    end
end

function XUiMoeWarSchedule:Refresh(isForce, selectGroup)
    -- 刷新右侧内容
    if not self.ObjList[self.CurrentView] then
        local curPanel = self.PanelList[self.CurrentView]
        if self.CurrentView == XMoeWarConfig.SessionType.Game24In12
                or self.CurrentView == XMoeWarConfig.SessionType.Game12In6 then
            self.ObjList[self.CurrentView] = XUiPanelMatchLarge.New(self, curPanel, self.CurrentView)
        elseif self.CurrentView == XMoeWarConfig.SessionType.Game6In3 then
            self.SmallMatchRolePanel = {}
            for i = 1, MAX_MODEL_COUNT do
                self.SmallMatchRolePanel[i] = XUiPanelRoleModel.New(self.SmallMatchPanelModel[i], self.Name, nil, true, nil, true)
            end
            self.ObjList[self.CurrentView] = XUiPanelMatchSmall.New(self, curPanel, self.CurrentView, function(pos, player)
                self:UpdateModel(pos, player)
            end)
        elseif self.CurrentView == XMoeWarConfig.SessionType.Game3In1 then
            self.FinalMatchRolePanel = XUiPanelRoleModel.New(self.FinalMatchPanelModel, self.Name, nil, true, nil, true)
            self.ObjList[self.CurrentView] = XUiPanelMatchFinal.New(self, curPanel, self.CurrentView, function(pos, player)
                self:UpdateModel(pos, player)
            end)
        end
    end

    for i, panel in ipairs(self.PanelList) do
        panel.gameObject:SetActiveEx(i == self.CurrentView)
    end

    if self.CurrentView == XMoeWarConfig.SessionType.Game6In3 then
        for i = 1, MAX_MODEL_COUNT do
            self.SmallMatchRolePanel[i]:ShowRoleModel()
        end
        CS.XShadowHelper.SetGlobalShadowMeshHeight(0.52)
    elseif self.ObjList[XMoeWarConfig.SessionType.Game6In3] then
        for i = 1, MAX_MODEL_COUNT do
            self.SmallMatchRolePanel[i]:HideRoleModel()
        end
    end

    if self.ObjList[XMoeWarConfig.SessionType.Game3In1] then
        if self.CurrentView == XMoeWarConfig.SessionType.Game3In1 then
            self.FinalMatchRolePanel:ShowRoleModel()
            CS.XShadowHelper.SetGlobalShadowMeshHeight(0.63)
        else
            self.FinalMatchRolePanel:HideRoleModel()
        end
    end

    self.ObjList[self.CurrentView]:Refresh(isForce, selectGroup)
end

function XUiMoeWarSchedule:AddTimer()
    self.Timer = XScheduleManager.ScheduleForever(function() self:UpdateBtnGrpMatch() end, XScheduleManager.SECOND)
end

function XUiMoeWarSchedule:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 刷新左侧时间
function XUiMoeWarSchedule:UpdateBtnGrpMatch()
    for i, v in ipairs(self.BtnList) do
        local txtLock = self.TxtBtnGrpMatchLock[i]
        local txtNow = self.TxtBtnGrpMatchNow[i]
        local txtEnd = self.TxtBtnGrpMatchEnd[i]
        local match = XDataCenter.MoeWarManager.GetVoteMatch(i)
        local now = XTime.GetServerNowTimestamp()
        local curBtnState = v.ButtonState:GetHashCode() ~= XUiButtonState.Disable
        local nextBtnState = curBtnState
        if match:GetNotOpen() then
            nextBtnState = false
            local openTimeStr = XUiHelper.GetTime(match:GetStartTime() - now, XUiHelper.TimeFormatType.MOE_WAR)
            txtLock.text = CSXTextManagerGetText("MoeWarScheOpenCountdown", openTimeStr)
        elseif match:GetInTime() then
            nextBtnState = true
            local remainTimeStr = XUiHelper.GetTime(match:GetEndTime() - now, XUiHelper.TimeFormatType.MOE_WAR)
            txtNow.text = CSXTextManagerGetText("MoeWarScheCloseCountdown", remainTimeStr)
        else
            nextBtnState = true
            txtEnd.text = CSXTextManagerGetText("MoeWarScheIsEnd")
        end
        if curBtnState ~= nextBtnState then
            v:SetButtonState(nextBtnState and XUiButtonState.Normal or XUiButtonState.Disable)
        end
        v:ShowTag(match:GetInTime())
        txtLock.gameObject:SetActiveEx(match:GetNotOpen())
        txtEnd.transform.parent.gameObject:SetActiveEx(match:GetIsEnd())
    end

end


function XUiMoeWarSchedule:UpdateModel(pos, player)
    local modelPanel--, effect
    if pos then
        --effect =self.SmallMatchPanelModel[pos]
        modelPanel = self.SmallMatchRolePanel[pos]
    else
        --effect = self.FinalMatchImgEffect
        modelPanel = self.FinalMatchRolePanel
    end

    --effect.gameObject:SetActiveEx(false)
    if not player then
        return
    end

    modelPanel:UpdateRoleModel(player:GetModel(), nil, XModelManager.MODEL_UINAME.XUiMoeWarSchedule, function(model)
        --effect.gameObject:SetActiveEx(true)
    end, nil, true, true)

    if not self.IsPlayAnim then
        XScheduleManager.ScheduleOnce(function()
            modelPanel:PlayAnima(player:GetAnim(XMoeWarConfig.ActionType.Thank), true)
            self.IsPlayAnim = true
        end, 500)
    end
end

function XUiMoeWarSchedule:OnBtnBackClick()
    self:Close()
end

function XUiMoeWarSchedule:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMoeWarSchedule:CheckIsNeedPop()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if match:GetType() == XMoeWarConfig.MatchType.Voting and self.LastMatchType == XMoeWarConfig.MatchType.Publicity then
        XUiManager.TipText("MoeWarMatchEnd")
        XLuaUiManager.Remove("XUiMoeWarVote")
        self:Close()
        return true
    else
        self.LastMatchType = match:GetType()
    end
end