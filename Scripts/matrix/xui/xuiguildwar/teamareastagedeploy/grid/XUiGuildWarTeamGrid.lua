--================成员方格代码 begin =============
--region 成员方格代码
---@class XUiGuildWarTeamGrid
local XUiGuildWarTeamMember = XClass(nil, "XUiGuildWarTeamMember")
local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}
function XUiGuildWarTeamMember:Ctor(ui,rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnClick,function() self:OnMemberClick() end,true)
    --位置对应的颜色框
    self.Member_pos_color = {
        [1] = self.ImgRed,
        [2] = self.ImgBlue,
        [3] = self.ImgYellow,
    }
end

-- xTeam : XGuildWarAreaTeam
function XUiGuildWarTeamMember:Refresh(xTeam, index)
    self.XTeam = xTeam
    self.MemberIndex = index
    self.Pos = index
    local team = xTeam
    --角色的位置颜色
    for i, colorObject in pairs(self.Member_pos_color) do
        colorObject.gameObject:SetActiveEx(index == i)
    end
    local member = team:GetMember(index)
    --是否闲置位置
    local isEmpty = member:IsEmpty()
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.PanelMember.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        self.ImgLeaderTag.gameObject:SetActiveEx(false)
        self.ImgFirstRole.gameObject:SetActiveEx(false)
    else
        local headIcon = member:GetSmallHeadIcon()
        --设置角色头像
        self.RImgRoleHead:SetRawImage(headIcon)
        --队长标志
        local leaderIndex = team:GetCaptainPos()
        self.ImgLeaderTag.gameObject:SetActiveEx(index == leaderIndex)
        --首发标志
        local firstFightIndex = team:GetFirstFightPos()
        self.ImgFirstRole.gameObject:SetActiveEx(index == firstFightIndex)
    end
    self.RImgRoleHead.gameObject:SetActiveEx(not isEmpty)
    
    --是否助战角色
    local isAssitant = member:IsAssitant()
    self.ImgSupport.gameObject:SetActiveEx(isAssitant)

    --是否机器人
    --local isRobot = member:IsRobot()
    --self.PanelTrial.gameObject:SetActiveEx(isRobot)

    --角色战斗里
    local ability = member:GetAbility()
    self.TxtNowAbility.text = ability
end

function XUiGuildWarTeamMember:OnMemberClick()
    self.RootUi:OnMemberClick(self.MemberIndex)
end

--endregion
--================成员方格代码 end =============
local XUiGuildWarTeamGrid = XClass(nil, "XUiGuildWarTeamGrid")

function XUiGuildWarTeamGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Node = nil
    XTool.InitUiObject(self)
    --角色Grid预制体和内存池
    self.MembersContent = self.PanelDeployMembers.transform
    self.MembersPool = XStack.New() --插件解锁预览 UI内存池
    self.MembersList = XStack.New() --正在使用的插件解锁预览UI
    self.GridDeployMember.gameObject:SetActiveEx(false)
    
    --通关分数面板
    local panelVictory = self.PanelVictory.transform:GetComponent("UiObject")
    self.TxtVictoryRecord = panelVictory:GetObject("TxtRecord")
    self.TxtVictoryScore = panelVictory:GetObject("TxtScore")
    self.BtnReset = panelVictory:GetObject("BtnReset")
    self.TxtDesc.supportRichText = true
    --挑战按钮
    self. BtnFight.CallBack = function()
        self:OnClickBtnFight()
    end
    --重置区域成绩按钮
    self.BtnReset.CallBack = function()
        self:OnClickBtnReset()
    end
    --设置队长技按钮
    self.BtnLeader.CallBack = function()
        self:OnClickBtnLeader()
    end
    
end
function XUiGuildWarTeamGrid:OnDestroy()
end

--teamBuild @XGuildWarAreaBuild
function XUiGuildWarTeamGrid:Refresh(node)
    self.Node = node
    local nodeId =  self.Node:GetId()
    --关卡头像
    self.RImgMonsterIcon:SetRawImage(XGuildWarConfig.GetNodeIcon(nodeId))
    --关卡名字
    self.TxtTitleName.text = XGuildWarConfig.GetNodeName(nodeId)
    --关卡描述
    self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(XGuildWarConfig.GetNodeDesc(nodeId))
    --推荐战力
    local ability = self.Node:GetAbility()
    if ability == 0 then ability = "-" end
    self.TxtRequireAbility.text  = ability
    --上次记录
    local record = self.Node:GetRecord()
    if record == 0 then record = "-" end
    self.TxtRecord.text = record
    --战力参数过低图片
    self.ImgNotPassCondition.gameObject:SetActiveEx(false)
    --当前成绩面板
    self.PanelVictory.gameObject:SetActiveEx(self.Node:GetScoreLock())
    self.TxtVictoryScore.text = self.Node:GetScore()
    local record = self.Node:GetRecord()
    self.TxtVictoryRecord.gameObject:SetActiveEx(record > 0)
    self.TxtVictoryRecord.text = self.Node:GetRecord()
    self:UpdateTeamView()
end

function XUiGuildWarTeamGrid:UpdateTeamView()
    --刷新队员显示
    self:MemberGridReturnPool()
    local xTeam = self.Node:GetXTeam()
    self:GetMemberGrid():Refresh(xTeam,2)
    self:GetMemberGrid():Refresh(xTeam,1)
    self:GetMemberGrid():Refresh(xTeam,3)
    --队长技能描述
    self.TxtLeaderSkill.text = xTeam:GetCaptainSkillDesc()
end

--从内存池提取TeamGrid
function XUiGuildWarTeamGrid:GetMemberGrid()
    local grid
    if self.MembersPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridDeployMember)
        object.transform:SetParent(self.MembersContent, false)
        grid = XUiGuildWarTeamMember.New(object,self)
    else
        grid = self.MembersPool:Pop()
    end
    grid.GameObject:SetActiveEx(true)
    self.MembersList:Push(grid)
    return grid
end
--所有使用中的TeamGrid回归内存池
function XUiGuildWarTeamGrid:MemberGridReturnPool()
    while (not self.MembersList:IsEmpty()) do
        local object = self.MembersList:Pop()
        object.GameObject:SetActiveEx(false)
        self.MembersPool:Push(object)
    end
end

--点击更换队员
function XUiGuildWarTeamGrid:OnMemberClick(memberIndex)
    self.RootUi:OnMemberClick(self.Node,memberIndex)
end
--点击挑战按钮
function XUiGuildWarTeamGrid:OnClickBtnFight()
    local teamInfo = self.Node:GetXGuildWarTeamInfo()
    if teamInfo.CharacterInfos[teamInfo.CaptainPos].Id == 0 then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end
    if teamInfo.CharacterInfos[teamInfo.FirstFightPos].Id == 0 then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
        return
    end
    XDataCenter.GuildWarManager.RequestEnterAreaTeamStage(self.Node)
end
--点击设置队长
function XUiGuildWarTeamGrid:OnClickBtnLeader()
    local xTeam = self.Node:GetXTeam()
    local characterIdList = xTeam:GetEntityIds()
    local captainPos = xTeam:GetCaptainPos()
    XLuaUiManager.Open(
        "UiNewRoomSingleTip",
        self,
        characterIdList,
        captainPos,
        function(index)
            xTeam:UpdateCaptainPos(index)
            self:UpdateTeamView()
        end
    )
end
--点击重置关卡
function XUiGuildWarTeamGrid:OnClickBtnReset()
    local score = self.Node:GetScore()
    local record = self.Node:GetRecord()
    if score > record then
        local content = CS.XTextManager.GetText("GuildWarTeamAreaResetDialogTitle")
        XUiManager.DialogTip("", content, nil, nil, function()
            XDataCenter.GuildWarManager.RequestResetAreaTeamScore(self.Node)
        end)
    else
        XDataCenter.GuildWarManager.RequestResetAreaTeamScore(self.Node)
    end
end

return XUiGuildWarTeamGrid
