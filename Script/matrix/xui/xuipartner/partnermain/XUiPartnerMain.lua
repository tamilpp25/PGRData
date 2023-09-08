local XUiPartnerMain = XLuaUiManager.Register(XLuaUi, "UiPartnerMain")
local XUiGridPartner = require("XUi/XUiPartner/PartnerMain/XUiGridPartner")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPartnerRecommendCharacter = require("XUi/XUiPartner/PartnerCompose/XUiPartnerRecommendCharacter")

local CSTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineGameObject = CS.UnityEngine.GameObject
local DefaultIndex = 1

function XUiPartnerMain:OnStart(state, partner, IsNotBackChange, IsNotSelectPartner)
    self.LastPartner = {}
    self.ModelEffect = {}
    self.IsChangeUiState = true
    self.IsUpdateByEvent = false
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.CurUiState = self.FightBackUiState or (state or XPartnerConfigs.MainUiState.Overview)
    ---@type XUiPartnerRecommendCharacter
    self.PanelRecommendCharacter = XUiPartnerRecommendCharacter.New(self.PanelRole, self)

    self:SetLastPartner(self.CurUiState, self.FightBackPartner or partner)

    self.CurPartnerState = XPartnerConfigs.PartnerState.Combat
    self.IsNotBackChange = self.FightBackIsNotBackChange or IsNotBackChange
    self.IsNotSelectPartner = self.FightBackIsNotSelectPartner or IsNotSelectPartner

    self.isComposePanelOpenByStar = false

    self:SetButtonCallBack()
    self:InitSceneRoot()
    self:InitDynamicTable()

    self:AddRedPointEvent(self.BtnCompose, self.OnCheckComposeNews, self, { XRedPointConditions.Types.CONDITION_PARTNER_COMPOSE_RED })
end

function XUiPartnerMain:OnDestroy()

end

function XUiPartnerMain:OnEnable()
    self:ChangeUiState(self.CurUiState)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_DATAUPDATE, self.UpdatePanelByEvent, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED, self.UpdatePanelByEvent, self)
end

function XUiPartnerMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_DATAUPDATE, self.UpdatePanelByEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED, self.UpdatePanelByEvent, self)
    self.RoleModelPanel:HideAllEffects()
end

function XUiPartnerMain:UpdatePanelByEvent()
    self.IsUpdateByEvent = true
    self:ShowPanel()
    self.IsUpdateByEvent = false
end

function XUiPartnerMain:IsUiOverview()
    return self.CurUiState == XPartnerConfigs.MainUiState.Overview
end

function XUiPartnerMain:IsUiCompose()
    return self.CurUiState == XPartnerConfigs.MainUiState.Compose
end

function XUiPartnerMain:IsUiProperty()
    return self.CurUiState == XPartnerConfigs.MainUiState.Property
end

function XUiPartnerMain:IsPartnerStandby()
    return self.CurPartnerState == XPartnerConfigs.PartnerState.Standby
end

function XUiPartnerMain:IsPartnerCombat()
    return self.CurPartnerState == XPartnerConfigs.PartnerState.Combat
end

---@return XPartner
function XUiPartnerMain:GetLastPartner(state)
    if state == XPartnerConfigs.MainUiState.Property then
        return self.LastPartner[XPartnerConfigs.MainUiState.Overview]
    else
        return self.LastPartner[state]
    end
end

function XUiPartnerMain:SetLastPartner(state, partner)
    if state == XPartnerConfigs.MainUiState.Property then
        self.LastPartner[XPartnerConfigs.MainUiState.Overview] = partner
    else
        self.LastPartner[state] = partner
    end
end

function XUiPartnerMain:SetButtonCallBack()
    self.BtnCompose.CallBack = function()
        self:OpenComposePanel()
    end
    self.BtnChange.CallBack = function()
        self:ChangePartnerState()
    end
    self.BtnTrial.CallBack = function()
        self:OnBtnTrialClick()
    end
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.PaneComposeView:GetObject("BtnComposeAll").CallBack = function()
        self:OnBtnComposeAllClick()
    end

    self:BindHelpBtn(self.BtnHelp, "PartnerHelp")
end

function XUiPartnerMain:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")

    self.CameraFar = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamFarStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamFarCombat"),
        [XPartnerConfigs.CameraType.Compose] = root:FindTransform("UiCamFarCompose"),
        [XPartnerConfigs.CameraType.Level] = root:FindTransform("UiCamFarLv"),
        [XPartnerConfigs.CameraType.Quality] = root:FindTransform("UiCamFarQuality"),
        [XPartnerConfigs.CameraType.Skill] = root:FindTransform("UiCamFarSkill"),
        [XPartnerConfigs.CameraType.Story] = root:FindTransform("UiCamFarrStory"),
        [XPartnerConfigs.CameraType.StandbyNoSelect] = root:FindTransform("UiCamFarStandbyNoSelect"),
        [XPartnerConfigs.CameraType.CombatNoSelect] = root:FindTransform("UiCamFarCombatNoSelect"),
    }
    self.CameraNear = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamNearStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamNearCombat"),
        [XPartnerConfigs.CameraType.Compose] = root:FindTransform("UiCamNearCompose"),
        [XPartnerConfigs.CameraType.Level] = root:FindTransform("UiCamNearLv"),
        [XPartnerConfigs.CameraType.Quality] = root:FindTransform("UiCamNearQuality"),
        [XPartnerConfigs.CameraType.Skill] = root:FindTransform("UiCamNearSkill"),
        [XPartnerConfigs.CameraType.Story] = root:FindTransform("UiCamNearrStory"),
        [XPartnerConfigs.CameraType.StandbyNoSelect] = root:FindTransform("UiCamNearStandbyNoSelect"),
        [XPartnerConfigs.CameraType.CombatNoSelect] = root:FindTransform("UiCamNearCombatNoSelect"),
    }

    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiPartnerMain:InitDynamicTable()
    self.PaneMainView:GetObject("GridCharacterNew").gameObject:SetActiveEx(false)
    self.PaneComposeView:GetObject("GridCharacterNew").gameObject:SetActiveEx(false)

    self.MainDynamicTable = XDynamicTableNormal.New(self.PaneMainView:GetObject("SViewCharacterList"))
    self.MainDynamicTable:SetProxy(XUiGridPartner)
    self.MainDynamicTable:SetDelegate(self)

    self.ComposeDynamicTable = XDynamicTableNormal.New(self.PaneComposeView:GetObject("SViewCharacterList"))
    self.ComposeDynamicTable:SetProxy(XUiGridPartner)
    self.ComposeDynamicTable:SetDelegate(self)

end

function XUiPartnerMain:SetupDynamicTable()
    local selectIndex = 1
    self.DefaultSelectPartnerId = self.PageDatas[DefaultIndex] and self.PageDatas[DefaultIndex]:GetId()

    local lastPartner = self:GetLastPartner(self.CurUiState)
    if lastPartner then
        for index, data in pairs(self.PageDatas) do
            if data:GetId() == lastPartner:GetId() then
                selectIndex = index
                self.DefaultSelectPartnerId = lastPartner:GetId()
                break
            end
        end
    end

    if self:IsUiCompose() then
        self.CurDynamicTable = self.ComposeDynamicTable
    else
        self.CurDynamicTable = self.MainDynamicTable
    end

    self.CurDynamicTable:SetDataSource(self.PageDatas)
    self.CurDynamicTable:ReloadDataSync(selectIndex)

end

function XUiPartnerMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self.CurUiState, self)
    end
end

function XUiPartnerMain:SelectPartner(partner)
    local lastPartner = self:GetLastPartner(self.CurUiState)
    local lastPartnerId = lastPartner and lastPartner:GetId()
    if lastPartnerId ~= partner:GetId() or self.IsChangeUiState then
        self.CurPartnerState = XPartnerConfigs.PartnerState.Combat
        self.IsChangeUiState = false
        self:UpdateRoleModel(partner:GetCombatModel(), partner, true)
        self:UpdateCamera()
        self:UpdateRecommendCharacter4Compose(partner)
    end
    self:UpdatePanel(partner)
    self:SetLastPartner(self.CurUiState, partner)
    self.BtnTrial.gameObject:SetActiveEx(self:IsTrialShow(partner))
end

function XUiPartnerMain:IsTrialShow(partner)
    if not partner then
        return false
    end

    if not self:IsUiOverview() then
        return false
    end

    return partner:GetStageSkipId() > 0
end

function XUiPartnerMain:UpdatePanel(Data)
    if self:IsUiOverview() then
        self:UpdateChildUi("UiPartnerOwnedInfo", Data)
    elseif self:IsUiCompose() then
        self:UpdateChildUi("UiPartnerCompose", Data)
        self:UpdateRecommendCharacter4Compose()
    end
end

function XUiPartnerMain:UpdateChildUi(uiName, Data)
    local childUi = self:FindChildUiObj(uiName)
    childUi:UpdatePanel(Data)
end

function XUiPartnerMain:ChangePartnerState()
    if self:IsPartnerStandby() then
        self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Combat)
    elseif self:IsPartnerCombat() then
        self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Standby)
    end
end

function XUiPartnerMain:DoPartnerStateChange(state)
    if state == self.CurPartnerState then
        return
    end

    local partner = self:GetLastPartner(self.CurUiState)
    if not partner then
        return
    end

    XLuaUiManager.SetMask(true)
    local closeMask = function()
        XLuaUiManager.SetMask(false)
    end

    if self:IsPartnerStandby() then

        local voiceId = partner:GetSToCVoice()
        if voiceId and voiceId > 0 then
            XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
        end

        self.CurPartnerState = state
        self:UpdateCamera()
        --self.RoleModelPanel:LoadEffect(partner:GetSToCEffect(), "ModelOffEffect", true, true)
        self.RoleModelPanel:LoadPartnerUiEffect(partner:GetStandbyModel(), XPartnerConfigs.EffectParentName.ModelOffEffect, true, true)
        self:PlayPartnerAnima(partner:GetSToCAnime(), true, function()
            self:UpdateRoleModel(partner:GetCombatModel(), partner, false)
            self.RoleModelPanel:LoadPartnerUiEffect(partner:GetCombatModel(), XPartnerConfigs.EffectParentName.ModelOnEffect, true, true)
            --self.RoleModelPanel:LoadEffect(partner:GetCombatBornEffect(), "ModelOnEffect", true, true)
            self:PlayPartnerAnima(partner:GetCombatBornAnime(), true, closeMask)
        end)

    elseif self:IsPartnerCombat() then

        local voiceId = partner:GetCToSVoice()
        if voiceId and voiceId > 0 then
            XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
        end
        --self.RoleModelPanel:LoadEffect(partner:GetCToSEffect(), "ModelOnEffect", true, true)
        self.RoleModelPanel:LoadPartnerUiEffect(partner:GetCombatModel(), XPartnerConfigs.EffectParentName.ModelOffEffect, true, true)
        self:PlayPartnerAnima(partner:GetCToSAnime(), true, function()
            self.CurPartnerState = state
            self:UpdateCamera()
            self:UpdateRoleModel(partner:GetStandbyModel(), partner, false)
            --self.RoleModelPanel:LoadEffect(partner:GetStandbyBornEffect(), "ModelOffEffect", true, true)
            self.RoleModelPanel:LoadPartnerUiEffect(partner:GetStandbyModel(), XPartnerConfigs.EffectParentName.ModelOnEffect, true, true)
            self:PlayPartnerAnima(partner:GetStandbyBornAnime(), true, closeMask)
        end)
    else
        closeMask()
    end
end

function XUiPartnerMain:PlayPartnerAnima(animaName, fromBegin, callBack)
    local IsCanPlay = self.RoleModelPanel:PlayAnima(animaName, fromBegin, callBack)
    if not IsCanPlay then
        if callBack then
            callBack()
        end
    end
end

--更新模型
function XUiPartnerMain:UpdateRoleModel(modelId, partner, IsShowEffect)
    self.RoleModelPanel:UpdatePartnerModel(modelId, XModelManager.MODEL_UINAME.XUiPartnerMain, nil, function(model)
        self.PanelDrag.Target = model.transform
        if IsShowEffect then
            self.ImgEffectHuanren.gameObject:SetActiveEx(false)
            self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        end
    end, false, true, true)
end

function XUiPartnerMain:ChangeUiState(state)
    local isOverviewToProperty = (self.CurUiState == XPartnerConfigs.MainUiState.Overview and state == XPartnerConfigs.MainUiState.Property) or
            (self.CurUiState == XPartnerConfigs.MainUiState.Property and state == XPartnerConfigs.MainUiState.Overview)

    if not isOverviewToProperty then
        self:PlayAnimation("DarkEnable")
        self.IsChangeUiState = true
    end

    self.CurUiState = state
    self:ShowPanel()
end

function XUiPartnerMain:ShowPanel()
    self.PageDatas = {}
    local IsPartnerListEmpty = XDataCenter.PartnerManager.IsPartnerListEmpty()

    if self:IsUiOverview() then
        if IsPartnerListEmpty then
            self.CurUiState = XPartnerConfigs.MainUiState.Compose
        end
    end

    self.RoleModelPanel:ShowRoleModel()

    local lastPartner = self:GetLastPartner(self.CurUiState)
    if self:IsUiOverview() then
        local lastPartnerId = lastPartner and lastPartner:GetId()

        self.PageDatas = XDataCenter.PartnerManager.GetPartnerOverviewDataList(lastPartnerId, nil, true)
        XPartnerSort.OverviewSortFunction(self.PageDatas)

        self:OpenChildUi("UiPartnerOwnedInfo", self)
        self:PlayAnimation("ListEnable")
        self:SetupDynamicTable()

    elseif self:IsUiCompose() then
        self.PageDatas, self.CanComposeIdList, self.CanComposeCount = XDataCenter.PartnerManager.GetPartnerComposeDataList()
        self.PaneComposeView:GetObject("BtnComposeAll").gameObject:SetActiveEx(self.CanComposeCount > 1)

        XPartnerSort.ComposeSortFunction(self.PageDatas)

        self:OpenChildUi("UiPartnerCompose", self)
        self:PlayAnimation("ListEnable")
        self:SetupDynamicTable()

    elseif self:IsUiProperty() then
        local tabIndex = self.isComposePanelOpenByStar and XPartnerConfigs.PriorityTabType.Quality or XPartnerConfigs.PriorityTabType.Level
        self:DoPartnerStateChange(XPartnerConfigs.PartnerState.Combat)
        self:OpenChildUi("UiPartnerProperty", self, tabIndex)
        self:UpdateChildUi("UiPartnerProperty", lastPartner)
    end

    self:UpdateCamera()

    self.BtnCompose.gameObject:SetActiveEx(self:IsUiOverview() and not self.IsNotSelectPartner)
    self.BtnChange.gameObject:SetActiveEx(self:IsUiOverview())

    self.BtnTrial.gameObject:SetActiveEx(self:IsTrialShow(self:GetLastPartner(self.CurUiState)))

    self.PaneMainView.gameObject:SetActiveEx(self:IsUiOverview() and not self.IsNotSelectPartner)
    self.PaneComposeView.gameObject:SetActiveEx(self:IsUiCompose())

    if self.IsNotSelectPartner or (self.IsFightBack and self:IsUiProperty()) then
        local partner = self:GetLastPartner(self.CurUiState)
        if partner then
            self:SelectPartner(partner)
        end
    end

    self.IsFightBack = false
end

function XUiPartnerMain:OpenChildUi(uiName, ...)
    if not XLuaUiManager.IsUiShow(uiName) then
        self:OpenOneChildUi(uiName, ...)
    end
end

function XUiPartnerMain:SetCameraType(type)
    for k, _ in pairs(self.CameraFar) do
        self.CameraFar[k].gameObject:SetActiveEx(k == type)
    end

    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == type)
    end
end

function XUiPartnerMain:UpdateCamera()
    if self:IsPartnerStandby() then
        local cameraType = self.IsNotSelectPartner and XPartnerConfigs.CameraType.StandbyNoSelect or XPartnerConfigs.CameraType.Standby
        self:SetCameraType(cameraType)
    elseif self:IsPartnerCombat() then
        if self:IsUiOverview() then
            local cameraType = self.IsNotSelectPartner and XPartnerConfigs.CameraType.CombatNoSelect or XPartnerConfigs.CameraType.Combat
            self:SetCameraType(cameraType)
        elseif self:IsUiCompose() then
            self:SetCameraType(XPartnerConfigs.CameraType.Compose)
        elseif self:IsUiProperty() then
            --在property界面选中页签时切换镜头
        end
    end
end

function XUiPartnerMain:Close()
    if not self:IsUiOverview() then
        --界面不是在辅助机总览界面
        if XDataCenter.PartnerManager.IsPartnerListEmpty() or self.IsNotBackChange then
            self.Super.Close(self)
        else
            --判断是否是在合成界面
            if self:IsUiCompose() then
                self:BackFromComposePanel()
                --判断是否是在培养界面
            elseif self:IsUiProperty() then
                self:BackFromPropertyPanel()
            end
        end
    else
        --当前在总览界面（即该类所控制的主界面），那么关闭自己即可
        self.Super.Close(self)
    end
end

function XUiPartnerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPartnerMain:OnBtnTrialClick()
    local partner = self:GetLastPartner(self.CurUiState)
    local skipId = partner:GetStageSkipId()
    if skipId > 0 then
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiPartnerMain:ShowRoleModel()
    self.RoleModelPanel:ShowRoleModel()
end

function XUiPartnerMain:HideRoleModel()
    self.RoleModelPanel:HideRoleModel()
    self.RoleModelPanel:HideAllEffects()
end

function XUiPartnerMain:OnCheckComposeNews(count)
    self.BtnCompose:ShowReddot(count >= 0)
end

function XUiPartnerMain:OnReleaseInst()
    return {
        UiState = self.CurUiState,
        Partner = self:GetLastPartner(self.CurUiState),
        IsNotBackChange = self.IsNotBackChange,
        IsNotSelectPartner = self.IsNotSelectPartner,
    }
end

function XUiPartnerMain:OnResume(data)
    self.IsFightBack = true
    self.FightBackUiState = data.UiState
    self.FightBackPartner = data.Partner
    self.FightBackIsNotBackChange = data.IsNotBackChange
    self.FightBackIsNotSelectPartner = data.IsNotSelectPartner
end

function XUiPartnerMain:OnBtnComposeAllClick()
    XDataCenter.PartnerManager.TipDialog(nil, function()
        XPartnerSort.CanComposeIdSort(self.CanComposeIdList)
        XDataCenter.PartnerManager.PartnerComposeRequest(self.CanComposeIdList, true)
    end, "PartnerAllComposeHint")
end

function XUiPartnerMain:OpenComposePanel(isOpenByStar)
    self.isComposePanelOpenByStar = isOpenByStar
    self:ChangeUiState(XPartnerConfigs.MainUiState.Compose)
end

--养成系统返回按钮
function XUiPartnerMain:BackFromPropertyPanel()
    local propertyPanel = self:FindChildUiObj("UiPartnerProperty")
    if propertyPanel then
        --从 进化页签-激活界面 返回
        local qualityPanel = propertyPanel:GetPartnerQualityPanel()
        if qualityPanel then
            if qualityPanel.IsShowStarPanel then
                qualityPanel:CloseStarPanel()
                return
            end
        end

        --从 技能页签-技能详情界面 返回
        local skillPanel = propertyPanel:GetPartnerSkillPanel()
        if skillPanel then
            if skillPanel:IsInfoSkillState() then
                --如果它是在技能详细状态，那么返回技能概述状态，并显示那个面板
                skillPanel:SetSkillMainState()
                skillPanel:ShowPanel()
                return
            end
        end
    end

    self:ChangeUiState(XPartnerConfigs.MainUiState.Overview)
end

--从 合成系统界面 返回
function XUiPartnerMain:BackFromComposePanel()
    if self.isComposePanelOpenByStar then
        local propertyPanel = self:FindChildUiObj("UiPartnerProperty")
        if propertyPanel then
            local qualityPanel = propertyPanel:GetPartnerQualityPanel()
            if qualityPanel then
                self:ChangeUiState(XPartnerConfigs.MainUiState.Property)
                local lastPartner = self:GetLastPartner(self.CurUiState)
                self:UpdateRoleModel(lastPartner:GetCombatModel(), lastPartner, true)
            end
        end

        self.isComposePanelOpenByStar = false
    else
        self:ChangeUiState(XPartnerConfigs.MainUiState.Overview)
    end
end

function XUiPartnerMain:UpdateRecommendCharacter4Compose(partner)
    if not partner then
        return
    end
    local characterId = XPartnerConfigs.GetPartnerRecommendCharacterId(partner:GetTemplateId())
    if characterId and characterId > 0 then
        self.PanelRecommendCharacter:Update(characterId)
        self.PanelRecommendCharacter.GameObject:SetActiveEx(true)
    else
        self.PanelRecommendCharacter.GameObject:SetActiveEx(false)
    end
end
