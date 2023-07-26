local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiGuildWarDeployPanelFormation = require("XUi/XUiGuildWar/TeamAreaStageDeploy/ChildPanel/XUiGuildWarDeployPanelFormation")
local XUiGuildWarTeamGrid = require("XUi/XUiGuildWar/TeamAreaStageDeploy/Grid/XUiGuildWarTeamGrid")

local XUiGuildWarDeploy = XLuaUiManager.Register(XLuaUi, "UiGuildWarDeploy")

function XUiGuildWarDeploy:OnAwake()
    --快速编队面板
    self.PanelDeployFormation = XUiGuildWarDeployPanelFormation.New(self.PanelFormation, function() self:UpdateView()  end)
    self.PanelDeployFormation:Hide()
    --队伍Grid预制体和内存池
    self.TeamGridContent = self.PanelTeamContent.transform
    self.TeamGridPool = XStack.New() --插件解锁预览 UI内存池
    self.TeamGridList = XStack.New() --正在使用的插件解锁预览UI
    self.GridDeployTeam.gameObject:SetActiveEx(false)
    --返回和主菜单
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    --快速编队按钮
    self.BtnFormation.CallBack = function()
        self:OnClickBtnFormation()
    end
    --上传分数
    self.BtnUpLoadRecord.CallBack = function()
        self:OnClickUploadRecord()
    end
end

function XUiGuildWarDeploy:OnStart(node)
    self.Node = node
    XDataCenter.GuildWarManager.RequestAssistCharacterList()
end

function XUiGuildWarDeploy:OnEnable()
    self:UpdateView()
    self:AddEventLisnter()
end

function XUiGuildWarDeploy:OnDestroy()
    self:RemoveEventLisnter()
end

function XUiGuildWarDeploy:AddEventLisnter()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST, self.UpdateView, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_SECRETNODE_RESET, self.UpdateView, self)
end

function XUiGuildWarDeploy:RemoveEventLisnter()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST, self.UpdateView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_SECRETNODE_RESET, self.UpdateView, self)
end

--更新视图
function XUiGuildWarDeploy:UpdateView()
    --刷新队伍显示
    self:TeamGridReturnPool()
    local children = self.Node:GetChildrenNodes()
    --检查 更新队伍数据
    local teamBuild = self.Node:GetTeamBuild(true)
    for i=1, #children do
        self:GetTeamGrid():Refresh(children[i])
    end

    --记录总分
    local record = self.Node:GetAreaRecord()
    self.TxtRecord.gameObject:SetActiveEx(record > 0)
    self.TxtRecord.text = self.Node:GetAreaRecord()
    --当前总分
    self.TxtCurrent.text = self.Node:GetAreaScore()
end
--从内存池提取TeamGrid
---@return XUiGuildWarTeamGrid
function XUiGuildWarDeploy:GetTeamGrid()
    local grid
    if self.TeamGridPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridDeployTeam)
        object.transform:SetParent(self.TeamGridContent, false)
        grid = XUiGuildWarTeamGrid.New(object,self)
    else
        grid = self.TeamGridPool:Pop()
    end
    grid.GameObject:SetActiveEx(true)
    self.TeamGridList:Push(grid)
    return grid
end
--所有使用中的TeamGrid回归内存池
function XUiGuildWarDeploy:TeamGridReturnPool()
    while (not self.TeamGridList:IsEmpty()) do
        local object = self.TeamGridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.TeamGridPool:Push(object)
    end
end
--更换队员按钮
function XUiGuildWarDeploy:OnMemberClick(childNode,memberIndex)
    if not self.Node:CheckChildExist(childNode) then
        XLog.Error("Child Error Node:" .. self.Node:GetId() .. " Dosent Had Child:" .. childNode:GetId())
        return
    end 
    RunAsyn(function()
        XLuaUiManager.Open("UiGuildWarDeployCharacterSelect",{
            RootNode = self.Node,
            ChildNode = childNode,
            MemberPos = memberIndex,
        })
        local signalCode, newMemberData = XLuaUiManager.AwaitSignal("UiGuildWarDeployCharacterSelect ", "UpdateEntityId", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        self:UpdateView()
        ---- 播放音效
        local soundType = XFavorabilityConfigs.SoundEventType.MemberJoinTeam
        if rootUi.Team:GetCaptainPos() == memberIndex then
            soundType = XFavorabilityConfigs.SoundEventType.CaptainJoinTeam
        end
        rootUi.FavorabilityManager.PlayCvByType(newMemberData.EntityId, soundType)
    end)
    return true
end
--编队调整按钮
function XUiGuildWarDeploy:OnClickBtnFormation()
    self.PanelDeployFormation:Show(self.Node)
end
--上传记录按钮
function XUiGuildWarDeploy:OnClickUploadRecord()
    --当前总分
    local score = self.Node:GetAreaScore()
    --记录总分
    local record = self.Node:GetAreaRecord()
    if score > record then
        XDataCenter.GuildWarManager.RequestUploadAreaScore(self.Node)
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaUploadError"))
    end
end