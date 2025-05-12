local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelBossInshotCharacterDetail
local XUiPanelBossInshotCharacterDetail = XClass(nil, "XUiPanelBossInshotCharacterDetail")

function XUiPanelBossInshotCharacterDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    
    self.PANEL_TYPE = {
        MAIN = 1,
        SELECT_TALENT = 2,
    }
end

-- team : XTeam
function XUiPanelBossInshotCharacterDetail:SetData(team, stageId, rootUi)
    self.Team = team
    self.StageId = stageId
    self.RootUi = rootUi
end

function XUiPanelBossInshotCharacterDetail:HideRootUiGo()
    self.RootUi.BtnJoinTeam.gameObject:SetActiveEx(false)
    self.RootUi.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.RootUi.BtnFashion.gameObject:SetActiveEx(false)
    self.RootUi.BtnPartner.gameObject:SetActiveEx(false)
    self.RootUi.BtnConsciousness.gameObject:SetActiveEx(false)
    self.RootUi.BtnWeapon.gameObject:SetActiveEx(false)
end

function XUiPanelBossInshotCharacterDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClick)
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    XUiHelper.RegisterClickEvent(self, self.GridTalent2:GetObject("BtnClick"), self.OnBtnTalentClick2)
    XUiHelper.RegisterClickEvent(self, self.GridTalent3:GetObject("BtnClick"), self.OnBtnTalentClick3)
    XUiHelper.RegisterClickEvent(self, self.BtnEquip, self.OnBtnEquipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnEquip, self.OnBtnUnEquipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiPanelBossInshotCharacterDetail:OnBtnBackClick()
    self:SwitchPanel(self.PANEL_TYPE.MAIN)
end

function XUiPanelBossInshotCharacterDetail:OnBtnJoinTeamClick()
    self.RootUi:OnBtnJoinTeamClicked()
end

function XUiPanelBossInshotCharacterDetail:OnBtnQuitTeamClick()
    self.RootUi:OnBtnQuitTeamClicked()
end

function XUiPanelBossInshotCharacterDetail:OnBtnTalentClick2()
    self.TalentPos = 1
    self:SwitchPanel(self.PANEL_TYPE.SELECT_TALENT)
end

function XUiPanelBossInshotCharacterDetail:OnBtnTalentClick3()
    self.TalentPos = 2
    self:SwitchPanel(self.PANEL_TYPE.SELECT_TALENT)
end

function XUiPanelBossInshotCharacterDetail:OnBtnEquipClick()
    local talentCfg = self.SelectTalentCfgs[self.SelectTalentIndex]
    local isUnlock, tips = XMVCA.XBossInshot:IsCharacterTalentUnlock(self.CharacterId, talentCfg.Id)
    if not isUnlock then
        XUiManager.TipError(tips)
        return
    end
    
    XMVCA.XBossInshot:BossInshotSelectTalentRequest(self.CharacterId, self.TalentPos, talentCfg.Id, function()
        self:SwitchPanel(self.PANEL_TYPE.MAIN)
    end)
end

function XUiPanelBossInshotCharacterDetail:OnBtnUnEquipClick()
    local talentCfg = self.SelectTalentCfgs[self.SelectTalentIndex]
    local isEquip, pos = XMVCA.XBossInshot:IsCharacterTalentSelect(self.CharacterId, talentCfg.Id)
    XMVCA.XBossInshot:BossInshotSelectTalentRequest(self.CharacterId, pos, 0, function()
        self:SwitchPanel(self.PANEL_TYPE.MAIN)
    end)
end

function XUiPanelBossInshotCharacterDetail:OnBtnBackClick()
    self:SwitchPanel(self.PANEL_TYPE.MAIN)
end

function XUiPanelBossInshotCharacterDetail:Refresh(currentEntityId)
    self.CurrentEntityId = currentEntityId
    self.CharacterId = XEntityHelper.GetCharacterIdByEntityId(currentEntityId)
    
    self:HideRootUiGo()

    local talentPos = XMVCA.XBossInshot:GetCharacterDetailTalentPos()
    if talentPos then
        XMVCA.XBossInshot:SetCharacterDetailTalentPos(nil)
        self.TalentPos = talentPos
        self:SwitchPanel(self.PANEL_TYPE.SELECT_TALENT)
    else
        self:SwitchPanel(self.PANEL_TYPE.MAIN)
    end
end

--- 切换面板
function XUiPanelBossInshotCharacterDetail:SwitchPanel(panelType)
    self.CurPanelType = panelType
    self.PanelMain.gameObject:SetActiveEx(self.CurPanelType == self.PANEL_TYPE.MAIN)
    self.PanelSelectTalent.gameObject:SetActiveEx(self.CurPanelType == self.PANEL_TYPE.SELECT_TALENT)

    if self.CurPanelType == self.PANEL_TYPE.MAIN then
        self.PanelMainEnable = self.PanelMainEnable or self.Transform:Find("PanelMain/Animation/PanelMainEnable"):GetComponent("PlayableDirector")
        self.PanelMainEnable.gameObject:PlayTimelineAnimation()
        self:RefreshPanelMain()
    elseif self.CurPanelType == self.PANEL_TYPE.SELECT_TALENT then
        self:RefreshPanelSelectTalent()
    end
end

--- 刷新主面板
function XUiPanelBossInshotCharacterDetail:RefreshPanelMain()
    local isInTeam = self.Team:GetEntityIdIsInTeam(self.CurrentEntityId)
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)

    -- 默认穿戴的天赋
    local talentCfg = XMVCA.XBossInshot:GetCharacterDefaultWearTalentCfg(self.CharacterId)
    local isUnlock = XMVCA.XBossInshot:IsCharacterTalentUnlock(self.CharacterId, talentCfg.Id)
    self.GridTalent1:GetObject("PanelTalent").gameObject:SetActiveEx(true)
    self.GridTalent1:GetObject("PanelAdd").gameObject:SetActiveEx(false)
    self.GridTalent1:GetObject("RImgIcon"):SetRawImage(talentCfg.Icon)
    self.GridTalent1:GetObject("TxtName").text = isUnlock and talentCfg.Name or ""
    self.GridTalent1:GetObject("TxtDesc").text = talentCfg.Desc
    local unlockTips = ""
    if not isUnlock and talentCfg.UnlockConditionId ~= 0 then
        unlockTips = XConditionManager.GetConditionDescById(talentCfg.UnlockConditionId)
    end
    self.GridTalent1:GetObject("TxtUnlockTips").text = unlockTips

    -- 手动穿戴的天赋    
    local selTalentIds = XMVCA.XBossInshot:GetCharacterSelectTalentIds(self.CharacterId)
    for i = 1, XEnumConst.BOSSINSHOT.WEAR_TALENT_MAX_CNT do
        local talentId = selTalentIds[i]
        local uiObj = self["GridTalent"..(i+1)]
        local isEquipTalent = talentId ~= nil and talentId ~= 0
        uiObj:GetObject("PanelTalent").gameObject:SetActiveEx(isEquipTalent)
        uiObj:GetObject("PanelAdd").gameObject:SetActiveEx(not isEquipTalent)
        if isEquipTalent then
            local config = XMVCA.XBossInshot:GetConfigBossInshotTalent(talentId)
            uiObj:GetObject("RImgIcon"):SetRawImage(config.Icon)
            uiObj:GetObject("TxtName").text = config.Name
            uiObj:GetObject("TxtDesc").text = config.Desc
            uiObj:GetObject("TxtUnlockTips").text = ""
        end
    end
end

--- 刷新选择天赋面板
function XUiPanelBossInshotCharacterDetail:RefreshPanelSelectTalent()
    if not self.DynamicTable then
        self:InitDynamicTable()
    end
    self:UpdateTalentList()
end

function XUiPanelBossInshotCharacterDetail:InitDynamicTable()
    self.GridTalent.gameObject:SetActiveEx(false)
    local XUiGridTalent = require("XUi/XUiBossInshot/XUiGridTalent")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTalentScroll)
    self.DynamicTable:SetProxy(XUiGridTalent)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelBossInshotCharacterDetail:UpdateTalentList()
    self.SelectTalentCfgs = XMVCA.XBossInshot:GetCharacterHandWearTalentCfgs(self.CharacterId)
    self.SelectTalentIndex = 1
    self.DynamicTable:SetDataSource(self.SelectTalentCfgs)
    self.DynamicTable:ReloadDataASync(1)
    self:RefreshEquipBtn()
end

function XUiPanelBossInshotCharacterDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local talentCfg = self.SelectTalentCfgs[index]
        grid:Refresh(self.CharacterId, talentCfg)
        grid:SetSelected(index == self.SelectTalentIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local grids = self.DynamicTable:GetGrids()
        for i, grid in ipairs(grids) do
            grid:SetSelected(i == index)
        end
        self.SelectTalentIndex = index
        self:RefreshEquipBtn()
    end
end

function XUiPanelBossInshotCharacterDetail:RefreshEquipBtn()
    local talentCfg = self.SelectTalentCfgs[self.SelectTalentIndex]
    local isEquip = XMVCA.XBossInshot:IsCharacterTalentSelect(self.CharacterId, talentCfg.Id)
    self.BtnEquip.gameObject:SetActiveEx(not isEquip)
    self.BtnUnEquip.gameObject:SetActiveEx(isEquip)
end

return XUiPanelBossInshotCharacterDetail