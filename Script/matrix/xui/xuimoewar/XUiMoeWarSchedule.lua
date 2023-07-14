local XUiMoeWarSchedule = XLuaUiManager.Register(XLuaUi, "UiMoeWarSchedule")
local XUiPanelMatchCommon = require("XUi/XUiMoeWar/SubPage/XUiPanelMatchCommon")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_MODEL_COUNT = 3
local recordUpdate = {}
function XUiMoeWarSchedule:OnStart(defaultSelectIndex)
    self.LeftTabIndex = 1
    self.GroupIndex = defaultSelectIndex or 1
    self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    self:Init()
end

function XUiMoeWarSchedule:OnEnable()
    if not self:CheckIsNeedPop() then
        self:AddTimer()
        self:Refresh()
    end
end

function XUiMoeWarSchedule:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_UPDATE,
    }
end

function XUiMoeWarSchedule:OnNotify(event)
    if event == XEventId.EVENT_MOE_WAR_UPDATE then
        self:Refresh()
    end
end

function XUiMoeWarSchedule:OnDisable()
    self:RemoveTimer()
end

function XUiMoeWarSchedule:Init()
    self:InitSceneRoot()
    self:InitTopTab()
    self:InitSessionPanel()
    self:InitLeftTab()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "MoeWar")
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[1], function()
        self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    recordUpdate = {}
end

function XUiMoeWarSchedule:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.SmallMatchPanelModel = {}
    self.SmallMatchImgEffect = {}
    self.SmallMatchPanelModel[1] = root:FindTransform("PanelModelCase1")
    self.SmallMatchPanelModel[2] = root:FindTransform("PanelModelCase2")
    self.SmallMatchPanelModel[3] = root:FindTransform("PanelModelCase3")
    self.FinalMatchPanelModel = root:FindTransform("PanelModelCase4")
    self.SmallMatchRolePanel = {}
    for i = 1, MAX_MODEL_COUNT do
        self.SmallMatchRolePanel[i] = XUiPanelRoleModel.New(self.SmallMatchPanelModel[i], self.Name, nil, true, nil, true)
    end
    self.FinalMatchRolePanel = XUiPanelRoleModel.New(self.FinalMatchPanelModel, self.Name, nil, true, nil, true)
end

function XUiMoeWarSchedule:InitSessionPanel()
    self.PanelSession = {}
    for _, sId in pairs(XMoeWarConfig.SessionType) do
        self.PanelSession[sId] = XUiPanelMatchCommon.New(self["PanelSession" .. sId], function(index, player)
            self:UpdateModel(index, player)
        end)
    end
end

function XUiMoeWarSchedule:InitLeftTab()
    self.TabCfg = XMoeWarConfig.GetScheduleTabGroup()
    self.LeftTabList = {}
    self.TxtBtnGrpMatchEnd = {}
    self.TxtBtnGrpMatchLock = {}
    self.TxtBtnGrpMatchNow = {}
    for i, cfg in ipairs(self.TabCfg) do
        ---@type XUiComponent.XUiButton
        local obj = self.LeftTabList[i]
        if not obj then
            obj = CS.UnityEngine.GameObject.Instantiate(self["BtnType" .. cfg.BtnType], self.BtnGrpMatch.transform)
            obj.gameObject:SetActiveEx(true)
            table.insert(self.LeftTabList, obj)
        end
        if cfg.ParentIndex > 0 then
            obj.SubGroupIndex = cfg.ParentIndex
        end
        local lockTransform = obj.transform:Find("TagLock/Text")
        if lockTransform then
            self.TxtBtnGrpMatchLock[i] = lockTransform:GetComponent("Text")
        end
        local nowTransform = obj.transform:Find("TagNow/Text")
        if nowTransform then
            self.TxtBtnGrpMatchNow[i] = nowTransform:GetComponent("Text")
        end
        local endTransform = obj.transform:Find("TagEnd/Text")
        if endTransform then
            self.TxtBtnGrpMatchEnd[i] = endTransform:GetComponent("Text")
        end
        obj:SetNameByGroup(0, cfg.Name)
        obj:SetNameByGroup(1, cfg.SecondName)
        if cfg.SessionId > 0 then
            local match = XDataCenter.MoeWarManager.GetVoteMatch(cfg.SessionId)
            if not match:GetNotOpen() then
                self.LeftTabIndex = i
            end
        end
    end
    self:UpdateChildBtnLine()
    self.BtnGrpMatch:Init(self.LeftTabList, function(index)
        self:OnSelectLeftTab(index)
    end)
    self.BtnGrpMatch:SelectIndex(self.LeftTabIndex)
end

function XUiMoeWarSchedule:OnSelectLeftTab(index)
    local cfg = self.TabCfg[index]
    ---@type XMoeWarMatch
    local match = XDataCenter.MoeWarManager.GetVoteMatch(cfg.SessionId)
    if not match then
        for j, btn in ipairs(self.LeftTabList) do
            if btn.SubGroupIndex == index then
                local childMatch = XDataCenter.MoeWarManager.GetVoteMatch(self.TabCfg[j].SessionId)
                if childMatch and childMatch:GetNotOpen() or childMatch:GetInTime() then
                    match = childMatch
                    break
                end
            end
        end
        if not match then
            return
        end
    end
    if match and match:GetNotOpen() then
        local startTime = match:GetStartTime()
        XUiManager.TipMsg(XUiHelper.GetInTimeDesc(startTime))
        return
    end
    if self.LeftTabIndex ~= index then
        self:PlayAnimation("QieHuan")
    end
    self.LeftTabIndex = index
    self.GroupIndex = self.GroupIndex or 1
    self.BtnGrpGroup.gameObject:SetActiveEx(cfg.IsShowGroupTab == 1)
    if cfg.IsShowGroupTab == 1 then
        self.BtnGrpGroup:SelectIndex(self.GroupIndex)
    else
        self:Refresh()
    end
end

function XUiMoeWarSchedule:InitTopTab()
    local groups = XDataCenter.MoeWarManager.GetActivityInfo()
    self.GroupTabList = {}
    for i = 1, #(groups.GroupName) do
        ---@type XUiComponent.XUiButton
        local btn = self.GroupTabList[i]
        if not btn then
            btn = CS.UnityEngine.GameObject.Instantiate(self.BtnGroup, self.BtnGrpGroup.transform)
            btn.gameObject:SetActiveEx(true)
            table.insert(self.GroupTabList, btn)
        end
        btn:SetNameByGroup(1, groups.GroupSecondName[i])
        btn:SetNameByGroup(0, groups.GroupName[i])
    end
    self.BtnGrpGroup:Init(self.GroupTabList, function(index)
        self:OnSelectGroup(index)
    end)
end

function XUiMoeWarSchedule:OnSelectGroup(index)
    if self.GroupIndex ~= index then
        self:PlayAnimation("QieHuan")
    end
    self.GroupIndex = index
    self:Refresh()
end

function XUiMoeWarSchedule:Refresh()
    local cfg = self.TabCfg[self.LeftTabIndex]
    for _, session in pairs(self.PanelSession) do
        session:Hide()
    end
    local session = self.PanelSession[cfg.SessionId]
    if cfg.SessionId == XMoeWarConfig.SessionType.Game3In1 then
        self.FinalMatchRolePanel:ShowRoleModel()
        for _, panel in pairs(self.SmallMatchRolePanel) do
            panel:HideRoleModel()
        end
    elseif cfg.SessionId == XMoeWarConfig.SessionType.Game6In3 then
        self.FinalMatchRolePanel:HideRoleModel()
        for _, panel in pairs(self.SmallMatchRolePanel) do
            panel:ShowRoleModel()
        end
    else
        self.FinalMatchRolePanel:HideRoleModel()
        for _, panel in pairs(self.SmallMatchRolePanel) do
            panel:HideRoleModel()
        end
    end
    session:Show()
    session:Refresh(self.GroupIndex, cfg.SessionId, cfg.IsShowModel == 1, cfg.IsShowGroupTab == 1)
end

function XUiMoeWarSchedule:OnGetEvents()
    return { XEventId.EVENT_MOE_WAR_UPDATE,
        XEventId.EVENT_MOE_WAR_ACTIVITY_END }
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

function XUiMoeWarSchedule:UpdateModel(pos, player)
    local modelPanel --, effect
    if pos then
        --effect =self.SmallMatchPanelModel[pos]
        modelPanel = self.SmallMatchRolePanel[pos]
    else
        --effect = self.FinalMatchImgEffect
        pos = MAX_MODEL_COUNT + 1
        modelPanel = self.FinalMatchRolePanel
    end

    --effect.gameObject:SetActiveEx(false)
    if not player then
        return
    end
    --#102859 角色模型一直刷新导致动画异常问题
    if not recordUpdate[pos] then
        recordUpdate[pos] = true
        modelPanel:UpdateRoleModel(player:GetModel(), nil, XModelManager.MODEL_UINAME.XUiMoeWarSchedule, function(model)
            --effect.gameObject:SetActiveEx(true)
        end, nil, true, true)
    end

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
        XLuaUiManager.RunMain()
        return true
    else
        self.LastMatchType = match:GetType()
    end
end

function XUiMoeWarSchedule:AddTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateBtnGrpMatch()
        self:Refresh()
    end, XScheduleManager.SECOND)
    self:UpdateBtnGrpMatch()
end

function XUiMoeWarSchedule:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 刷新左侧时间
function XUiMoeWarSchedule:UpdateBtnGrpMatch()
    for i = 1, #self.LeftTabList do
        local v = self.LeftTabList[i]
        local txtLock = self.TxtBtnGrpMatchLock[i]
        local txtNow = self.TxtBtnGrpMatchNow[i]
        local txtEnd = self.TxtBtnGrpMatchEnd[i]
        local match = XDataCenter.MoeWarManager.GetVoteMatch(self.TabCfg[i].SessionId)
        if v.SubGroupIndex > 0 then
            goto CONTINUE
        end
        if not match then
            for j, btn in ipairs(self.LeftTabList) do
                if btn.SubGroupIndex == i then
                    local childMatch = XDataCenter.MoeWarManager.GetVoteMatch(self.TabCfg[j].SessionId)
                    match = childMatch
                    if childMatch and (childMatch:GetNotOpen() or childMatch:GetInTime()) then
                        break
                    end
                end
            end
        end
        local now = XTime.GetServerNowTimestamp()
        local curBtnState = v.ButtonState:GetHashCode() ~= XUiButtonState.Disable
        local nextBtnState = curBtnState
        if match:GetNotOpen() then
            nextBtnState = false
            local openTimeStr = XUiHelper.GetTime(match:GetStartTime() - now, XUiHelper.TimeFormatType.MOE_WAR)
            if txtLock then
                txtLock.text = CSXTextManagerGetText("MoeWarScheOpenCountdown", openTimeStr)
            end
        elseif match:GetInTime() then
            nextBtnState = true
            local remainTimeStr = XUiHelper.GetTime(match:GetEndTime() - now, XUiHelper.TimeFormatType.MOE_WAR)
            if txtNow then
                txtNow.text = CSXTextManagerGetText("MoeWarScheCloseCountdown", remainTimeStr)
            end
        else
            nextBtnState = true
            if txtEnd then
                txtEnd.text = CSXTextManagerGetText("MoeWarScheIsEnd")
            end
        end
        if curBtnState ~= nextBtnState then
            v:SetButtonState(nextBtnState and XUiButtonState.Normal or XUiButtonState.Disable)
        end
        v:ShowTag(match:GetInTime())
        if txtLock then
            txtLock.transform.parent.gameObject:SetActiveEx(match:GetNotOpen())
        end
        if txtEnd then
            txtEnd.transform.parent.gameObject:SetActiveEx(match:GetIsEnd())
        end
        ::CONTINUE::
    end

end

function XUiMoeWarSchedule:UpdateChildBtnLine()
    local group = -1
    for i = 1, #self.LeftTabList do
        if group ~= -1 and self.LeftTabList[i].SubGroupIndex ~= group then
            local upLine = self.LeftTabList[i - 1].transform:Find("UpLine")
            local downLine = self.LeftTabList[i - 1].transform:Find("DownLine")
            upLine.gameObject:SetActiveEx(false)
            downLine.gameObject:SetActiveEx(true)
            group = -1
        elseif self.LeftTabList[i].SubGroupIndex ~= group and group == -1 then
            group = self.LeftTabList[i].SubGroupIndex
            local downLine = self.LeftTabList[i].transform:Find("DownLine")
            downLine.gameObject:SetActiveEx(false)
        elseif self.LeftTabList[i].SubGroupIndex == group and group ~= -1 then
            local downLine = self.LeftTabList[i].transform:Find("DownLine")
            local upLine = self.LeftTabList[i].transform:Find("UpLine")
            downLine.gameObject:SetActiveEx(false)
            upLine.gameObject:SetActiveEx(false)
        end
    end
end

return XUiMoeWarSchedule
