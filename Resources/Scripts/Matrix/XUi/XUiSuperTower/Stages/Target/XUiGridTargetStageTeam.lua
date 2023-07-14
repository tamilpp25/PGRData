local XUiGridTargetStageTeamMember = require("XUi/XUiSuperTower/Stages/Target/XUiGridTargetStageTeamMember")
local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
local DefaultElement = 0
local IsomerElement = 6
local XUiGridTargetStageTeam = XClass(nil, "XUiGridTargetStageTeam")

function XUiGridTargetStageTeam:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGrids = {}
    self.PluginGrids = {}

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    
    self.GridDeployMember.gameObject:SetActiveEx(false)
    self.GridSuperTowerCore.gameObject:SetActiveEx(false)
end

function XUiGridTargetStageTeam:OnDestroy()

end

function XUiGridTargetStageTeam:SetButtonCallBack()
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClick() end
    self.BtnCore.CallBack = function() self:OnSelectPulginClick() end
    self.BtnConsume.CallBack = function() self:OnSelectPulginClick() end
end

function XUiGridTargetStageTeam:UpdataGrid(stageIndex, stStage)
    local stageId = stStage:GetStageId()[stageIndex]
    self.Team = stageId and XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
    self.STStage = stStage
    self.StageIndex = stageIndex
    
    self:UpdateTeam()
    self:UpdatePlugins()
    self:UpdateInfo()
end

function XUiGridTargetStageTeam:UpdateInfo()
    self.TxtTitle.text = CSTextManagerGetText("STFightLoadingTeamText", self.StageIndex)
    local requireAbility = self.STStage:GetStageAbilityByIndex(self.StageIndex)
    self.TxtRequireAbility.text = requireAbility
    if self.ImgTitleBgFight then--倾向
        local stageId = self.STStage:GetStageIdByIndex(self.StageIndex)
        local element = DefaultElement
        local recommendType = XFubenConfigs.GetStageRecommendCharacterType(stageId)
        
        if recommendType == XCharacterConfigs.CharacterType.Isomer then
            element = IsomerElement
        elseif recommendType == XCharacterConfigs.CharacterType.Normal then
            element = XFubenConfigs.GetStageRecommendCharacterElement(stageId) or DefaultElement
        end
        
        local icon = XSuperTowerConfigs.GetElementIconByKey(element)
        self.ImgTitleBgFight:SetSprite(icon)
    end
end

function XUiGridTargetStageTeam:UpdateTeam()
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local memberEntityIdList = self.Team:GetEntityIds()
    local memberNum = self.STStage:GetMemberCountByIndex(self.StageIndex)
    
    for index = 1, memberNum do
        local grid = self.MemberGrids[index]
        if not grid then
            local go = CSObjectInstantiate(self.GridDeployMember, self.PanelDeployMembers)
            grid = XUiGridTargetStageTeamMember.New(go)
            self.MemberGrids[index] = grid
        end
        
        local memberEntityId = memberEntityIdList[index] or 0
        local memberRole = roleManager:GetRole(memberEntityId)
        grid:Refresh(self.StageIndex, memberRole, index, self.STStage)

        --蓝色放到第一位
        if index == 2 then
            grid.Transform:SetAsFirstSibling()
        end

        grid.GameObject:SetActiveEx(true)
    end

    for index = memberNum + 1, #self.MemberGrids do
        self.MemberGrids[index].GameObject:SetActiveEx(false)
    end
    
    local captainId = self.Team:GetCaptainPosEntityId() or 0
    local captainRole = roleManager:GetRole(captainId)
    self.TxtLeaderSkill.text = captainRole and captainRole:GetCaptainSkillDesc() or ""
end

function XUiGridTargetStageTeam:UpdatePlugins()
    local extraData = self.Team:GetExtraData()
    local pluginList = extraData and extraData:GetPlugins() or {}
    local IsPluginEmpty = extraData:GetIsEmpty()
    self.PanelCoreContent.gameObject:SetActiveEx(not IsPluginEmpty)
    self.BtnCore.gameObject:SetActiveEx(IsPluginEmpty)
    
    for index, plugin in pairs(pluginList) do
        if plugin ~= 0 then
            local grid = self.PluginGrids[index]
            if not grid then
                local go = CSObjectInstantiate(self.GridSuperTowerCore, self.PanelCoreContent)
                grid = XUiSuperTowerPluginGrid.New(go)
                self.PluginGrids[index] = grid
            end
            grid:RefreshData(plugin)
            grid.GameObject:SetActiveEx(true)
        end
    end
    for index = extraData:GetCurrentCapacity() + 1, #self.PluginGrids do
        self.PluginGrids[index].GameObject:SetActiveEx(false)
    end
    
end

function XUiGridTargetStageTeam:OnBtnLeaderClick()
    local characterViewModelDic = {}
    for pos, entityId in ipairs(self.Team:GetEntityIds()) do
        characterViewModelDic[pos] = self:GetCharacterViewModelByEntityId(entityId)
    end
    XLuaUiManager.Open("UiBattleRoleRoomCaptain", characterViewModelDic, self.Team:GetCaptainPos(), function(newCaptainPos)
            self.Team:UpdateCaptianPos(newCaptainPos)
            self:UpdateTeam()
        end)
end

function XUiGridTargetStageTeam:GetCharacterViewModelByEntityId(id)
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    local role = roleManager:GetRole(id)
    if not role then return nil end
    return role:GetCharacterViewModel()
end

function XUiGridTargetStageTeam:OnSelectPulginClick()
    XLuaUiManager.Open("UiSuperTowerChooseCore", self.STStage:GetStageIdByIndex(self.StageIndex))
end

return XUiGridTargetStageTeam