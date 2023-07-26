--=================
--选人界面主面板
--=================
local XUiSSBPickPanelPick = XClass(nil, "XUiSSBPickPanelPick")
local Panels = {
    PanelOwn = require("XUi/XUiSuperSmashBros/Pick/Panels/XUiSSBPickPanelPickOwn"),
    PanelEnemy = require("XUi/XUiSuperSmashBros/Pick/Panels/XUiSSBPickPanelPickEnemy"),
}

function XUiSSBPickPanelPick:Ctor(rootUi)
    ---@type XSmashBMode
    self.Mode = rootUi.Mode
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, self.RootUi.PanelPick)
    self:Init()
end

function XUiSSBPickPanelPick:Init()
    self:InitBtns()
    self:SetModeName()
    self:LoadModePrefab()
    self:InitPanelEnergy()
    self:InitPanels()
end

function XUiSSBPickPanelPick:InitBtns()
    self.BtnMonster.CallBack = function() self:OnClickBtnMonster() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
end

function XUiSSBPickPanelPick:SetModeName()
    self.TxtMode.text = self.Mode:GetName()
end

function XUiSSBPickPanelPick:LoadModePrefab()
    local prefabPath = self.Mode:GetPickUiPrefab()
    if prefabPath then
        self.CustomPanel = self.PanelPrefab:LoadPrefab(prefabPath)
    end
end

function XUiSSBPickPanelPick:InitCustomPanel()
    local isLine = self.Mode:GetIsLinearStage()
    local script
    if isLine then
        script = require("XUi/XUiSuperSmashBros/Pick/Panels/XUiSSBPickPanel1v1Stage")
    else
        script = require("XUi/XUiSuperSmashBros/Pick/Panels/XUiSSBPickPanelNormalStage")
    end
    self.Custom = script.New(self.CustomPanel, self.Mode, function() self:Refresh() end, function() return Panels.PanelOwn.GetTeam() end)
end

function XUiSSBPickPanelPick:InitPanelEnergy()
    local script = require("XUi/XUiSuperSmashBros/Common/XUiSSBPanelEnergy")
    self.EnergyPanel = script.New(self.PanelEnergy)

    self.RefreshEnergyCb = handler(self, self.TryRefreshEnergy)
end

function XUiSSBPickPanelPick:InitPanels()
    for _, panel in pairs(Panels) do
        panel.Init(self)
    end
    self:InitCustomPanel()
end

function XUiSSBPickPanelPick:ShowPanel(...)
    self.GameObject:SetActiveEx(true)
    self:OnEnable()
end

function XUiSSBPickPanelPick:HidePanel()
    self:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiSSBPickPanelPick:OnEnable()
    
    for _, panel in pairs(Panels) do
        panel.OnEnable()
    end
    self:TryRefreshEnergy()
    self:AddEventListeners()
end

function XUiSSBPickPanelPick:Refresh()
    for _, panel in pairs(Panels) do
        panel.Refresh()
    end
end

function XUiSSBPickPanelPick:OnDisable()
    for _, panel in pairs(Panels) do
        panel.OnDisable()
    end
    self:RemoveEventListeners()
end

function XUiSSBPickPanelPick:OnDestroy()
    for _, panel in pairs(Panels) do
        panel.OnDestroy()
    end
end

function XUiSSBPickPanelPick:TryRefreshEnergy()
    if self.EnergyPanel then
        self.EnergyPanel:Refresh()
    end
end

local EventAddFlag

function XUiSSBPickPanelPick:AddEventListeners()
    if EventAddFlag then return end
    XEventManager.AddEventListener(XEventId.EVENT_SSB_ENERGY_REFRESH, self.RefreshEnergyCb)
    EventAddFlag = true
end

function XUiSSBPickPanelPick:RemoveEventListeners()
    if not EventAddFlag then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_SSB_ENERGY_REFRESH, self.RefreshEnergyCb)
    EventAddFlag = nil
end

function XUiSSBPickPanelPick:SwitchToSelect(pos, roleType)
    local teamData
    if roleType == XSuperSmashBrosConfig.RoleType.Chara then

    elseif roleType == XSuperSmashBrosConfig.RoleType.Monster then
        teamData = Panels.PanelEnemy.GetTeam()
    end
    self.RootUi:SwitchPage(XSuperSmashBrosConfig.PickPage.Select, roleType, teamData, pos)
end

function XUiSSBPickPanelPick:OnClickBtnMonster()
    local team = Panels.PanelEnemy.GetTeam()
    local displayMonsterGroups = {}
    for _, id in pairs(team) do
        if id > 0 then
            table.insert(displayMonsterGroups, XDataCenter.SuperSmashBrosManager.GetMonsterGroupById(id))
        end
    end
    if not next(displayMonsterGroups) then
        if self.Mode:GetId() == XSuperSmashBrosConfig.ModeType.DeathRandom then
            return
        end
        XUiManager.TipText("SSBNeedSelectMonster")
        return
    end
    XLuaUiManager.Open("UiSuperSmashBrosMonster", displayMonsterGroups)
end

function XUiSSBPickPanelPick:OnClickBtnFight()
    local team = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId()).RoleIds
    --检查是否选了最低上场数量的角色
    local minNum = self.Mode:GetRoleMinPosition()
    local count = 0
    for _, id in pairs(team or {}) do
        if id ~= XSuperSmashBrosConfig.PosState.Empty and id ~= XSuperSmashBrosConfig.PosState.Ban then
            count = count + 1
            if count >= minNum then
                break
            end
        end
    end
    if count < minNum then
        XUiManager.TipText("SSBNeedRoleMinPosition", nil, nil, minNum)
        return
    end
    --构建队伍数据
    local ownTeam = {}
    local maxNum = self.Mode:GetRoleMaxPosition()
    local checkType
    local checkCharacterIdDic = {}
    local is1v1 = self.Mode:GetRoleBattleNum() == 1
    for i = 1, maxNum do
        ownTeam[i] = team[i] or 0
        if ownTeam[i] > 0 then
            local role = XDataCenter.SuperSmashBrosManager.GetRoleById(ownTeam[i])
            --检查是否能相同角色同队
            if checkCharacterIdDic[role:GetCharacterId()] then
                XUiManager.TipText("SSBRepeatCharacterInTeam")
                return
            else
                checkCharacterIdDic[role:GetCharacterId()] = true
            end
            -- if not is1v1 and ownTeam[i] > 0 then --cxldV2 不检查授格者混队
            --     --检查非1v1队伍对战时授格者和构造体是否同队，是的话弹出提示返回
            --     if not checkType then
            --         checkType = role:GetCharacterType()
            --     elseif checkType ~= role:GetCharacterType() then
            --         XUiManager.TipText("SSBMultyCharacterTypeInTeam")
            --         return
            --     end
            -- end
        end
    end

    local enemys = Panels.PanelEnemy.GetTeam()
    local enemyTeam = {}
    local bossLimit = self.Mode:GetBossLimit()
    maxNum = self.Mode:GetMonsterMaxPosition()
    local bossNum = 0
    for i = 1, maxNum do
        if enemys[i] > 0 then
            local monster = XDataCenter.SuperSmashBrosManager.GetMonsterGroupById(enemys[i])
            local isBoss = monster:GetMonsterType() == XSuperSmashBrosConfig.MonsterType.Boss
            if isBoss then
                bossNum = bossNum + 1
                if bossNum > bossLimit then
                    XUiManager.TipText("SSBBossNumOver", nil, nil, bossLimit)
                    return
                end
            end
        end
        enemyTeam[i] = enemys[i] or 0
    end
    local isLine = self.Mode:GetIsLinearStage()
    local sceneId = not isLine and self.RootUi.Scene.Id or 0
    local envId = not isLine and self.RootUi.Environment and self.RootUi.Environment.Id or 0
    XDataCenter.SuperSmashBrosManager.SetStage(self.Mode, envId, sceneId, ownTeam, enemyTeam,
        function()
            XLuaUiManager.Open("UiSuperSmashBrosReady", self.Mode)
            self.RootUi:RemovePickScenes()
        end)
end

return XUiSSBPickPanelPick