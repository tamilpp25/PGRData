local XUiGridStrongHoldTeamMember = require("XUi/XUiStronghold/XUiGridStrongHoldTeamMember")
local XUiGridStrongholdPlugin = require("XUi/XUiStronghold/XUiGridStrongholdPlugin")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridStrongholdTeam = XClass(nil, "XUiGridStrongholdTeam")

function XUiGridStrongholdTeam:Ctor(ui, fightCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGrids = {}
    self.PluginGrids = {}
    self.FightCb = fightCb

    XTool.InitUiObject(self)

    self.BtnLeader.CallBack = function()
        self:OnBtnLeaderClick()
    end
    self.BtnRune.CallBack = function()
        self:OnBtnRuneClick()
    end
    self.BtnFight.CallBack = function()
        self:OnBtnFightClick()
    end
    self.BtnReset.CallBack = function()
        self:OnBtnResetClick()
    end

    self.GridDeployMember.gameObject:SetActiveEx(false)
    self.GridPlugin.gameObject:SetActiveEx(false)

    XEventManager.AddEventListener(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK, self.UpdateView, self)
end

function XUiGridStrongholdTeam:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK, self.UpdateView, self)
end

function XUiGridStrongholdTeam:Refresh(teamList, teamId, groupId, isPrefab)
    self.TeamList = teamList
    --队伍数据更改赋值
    self.TeamListClip = XDataCenter.StrongholdManager.GetTeamListClipTemp(groupId, teamList)
    --仅显示用
    self.TeamId = teamId
    self.GroupId = groupId
    local team = self:GetTeam()

    if isPrefab then
        --队伍预设
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdTeamTitle", teamId)

        local runeDesc = team:GetRuneDesc()
        self.TxtBuff.text = runeDesc
        self.TxtBuff.gameObject:SetActiveEx(true)

        self.PanelRequire.gameObject:SetActiveEx(false)
        self.PanelVictory.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
    else
        --战斗编队
        local stageIndex = teamId

        self.TxtTitle.text = XDataCenter.StrongholdManager.GetGroupStageName(groupId, stageIndex)

        local requireAbility = XDataCenter.StrongholdManager.GetGroupRequireAbility(groupId)
        self.TxtRequireAbility.text = requireAbility
        self.PanelRequire.gameObject:SetActiveEx(true)

        local buffDes = XDataCenter.StrongholdManager.GetGroupStageBuffDesc(groupId, stageIndex)
        local runeDesc = team:GetRuneDesc()
        self.TxtBuff.text = buffDes .. runeDesc
        self.TxtBuff.gameObject:SetActiveEx(true)

        local isFinished = XDataCenter.StrongholdManager.IsGroupStageFinished(groupId, stageIndex)
        self.PanelVictory.gameObject:SetActiveEx(isFinished)

        self.BtnFight.gameObject:SetActiveEx(true)
    end

    local hasRune = team:HasRune()
    self.PanelNor.gameObject:SetActiveEx(hasRune)
    self.PanelEmpty.gameObject:SetActiveEx(not hasRune)
    if hasRune then
        local runeId, subRuneId = team:GetRune()
        self.ImgRune:SetSprite(XStrongholdConfigs.GetRuneIcon(runeId))
        self.ImgSubRune:SetSprite(XStrongholdConfigs.GetSubRuneIcon(subRuneId))
        self.ImgColor.color = team:GetRuneColor()
    end

    local doNotShowEffect = true
    self:UpdateView(doNotShowEffect)
end

function XUiGridStrongholdTeam:UpdateView(doNotShowEffect)
    self:UpdateTeam()
    self:UpdatePlugins(doNotShowEffect)
end

function XUiGridStrongholdTeam:UpdateTeam()
    local groupId = self.GroupId
    local teamId = self.TeamId
    local teamList = self.TeamList

    local team = self:GetTeam(true)
    self.TxtLeaderSkill.text = team:GetCaptainSkillDesc()

    local requireMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
    if not XTool.IsNumberValid(requireMemberNum) then
        XLog.Error(
            string.format(
                "关卡要求上阵人数为0空，请检查配置，groupId:%d，teamId:%d，配置路径：%s",
                groupId,
                teamId,
                XStrongholdConfigs.GetGroupConfigPath()
            )
        )
        return
    end

    for index = 1, requireMemberNum do
        local grid = self.MemberGrids[index]
        if not grid then
            local go =
                index == 1 and self.GridDeployMember or
                CSUnityEngineObjectInstantiate(self.GridDeployMember, self.PanelDeployMembers)
            grid = XUiGridStrongHoldTeamMember.New(go)
            self.MemberGrids[index] = grid
        end

        grid:Refresh(teamList, teamId, index, groupId)

        --蓝色放到第一位
        if index == 2 then
            grid.Transform:SetAsFirstSibling()
        end

        grid.GameObject:SetActiveEx(true)
    end

    for index = requireMemberNum + 1, #self.MemberGrids do
        self.MemberGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiGridStrongholdTeam:UpdatePlugins(doNotShowEffect)
    local team = self:GetTeam()
    local plugins = team:GetAllPlugins()

    for index = 1, #plugins do
        local grid = self.PluginGrids[index]
        if not grid then
            local go =
                index == 1 and self.GridPlugin or CSUnityEngineObjectInstantiate(self.GridPlugin, self.PanelCoreContent)
            local clickCb = handler(self, self.OnClickPlugin)
            grid = XUiGridStrongholdPlugin.New(go, clickCb)
            self.PluginGrids[index] = grid
        end

        local plugin = plugins[index]
        local isAllPluginEmpty = team:IsAllPluginEmpty()
        grid:Refresh(plugin, isAllPluginEmpty, doNotShowEffect)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #plugins + 1, #self.PluginGrids do
        self.PluginGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiGridStrongholdTeam:OnBtnLeaderClick()
    local groupId = self.GroupId
    local teamId = self.TeamId
    local requireMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
    local team = self:GetTeam()
    local teamClip = self:GetTeam(true)
    local characterIdList, characterIdToIsIsAssitantDic = team:GenarateTeamCharacterList(requireMemberNum)
    local captainPos = team:GetCaptainPos()
    XLuaUiManager.Open(
        "UiNewRoomSingleTip",
        self,
        characterIdList,
        captainPos,
        function(index)
            team:SetCaptainPos(index)
            teamClip:SetCaptainPos(index)
            self:UpdateTeam()
        end,
        characterIdToIsIsAssitantDic
    )
end

function XUiGridStrongholdTeam:OnClickPlugin()
    XLuaUiManager.Open("UiStrongholdCoreTips", self.TeamList, self.TeamId, self.GroupId)
end

function XUiGridStrongholdTeam:GetTeam(isUseClip)
    -- isUseClip时仅显示队伍数据用
    return isUseClip and self.TeamListClip[self.TeamId] or self.TeamList[self.TeamId]
end

function XUiGridStrongholdTeam:OnBtnRuneClick()
    local runeIdList = XDataCenter.StrongholdManager.GetAllRuneIds()
    if XTool.IsTableEmpty(runeIdList) then
        XLog.Error("XUiStrongholdRune:InitTabBtnGroup error, 服务器下发可用符文列表为空")
        return
    end
    local team = self:GetTeam()
    local runeId, subRuneId = team:GetRune()
    XLuaUiManager.Open("UiStrongholdRune", self.TeamList, self.TeamId, self.GroupId, runeId)
end

function XUiGridStrongholdTeam:OnBtnFightClick()
    if self.FightCb then
        self.FightCb()
    end
    XDataCenter.StrongholdManager.TryEnterFight(self.GroupId, self.TeamId, self.TeamList)
end

function XUiGridStrongholdTeam:OnBtnResetClick()
    local callFunc = function()
        local groupId = self.GroupId
        local stageId = XDataCenter.StrongholdManager.GetGroupStageId(groupId, self.TeamId)
        XDataCenter.StrongholdManager.ResetStrongholdStageRequest(groupId, stageId)
    end
    local title = CSXTextManagerGetText("StrongholdTeamResetStageConfirmTitle")
    local content = CSXTextManagerGetText("StrongholdTeamResetStageConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

return XUiGridStrongholdTeam
