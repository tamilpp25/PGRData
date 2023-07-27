local XUiAssignDeploy = XLuaUiManager.Register(XLuaUi, "UiAssignDeploy")
local AutoCheckTeamTrigger = nil

local table = table
local ipairs = ipairs

local XUiGridAssignDeployTeam = require("XUi/XUiAssign/XUiGridAssignDeployTeam")
local XUiPanelAssignFormation = require("XUi/XUiAssign/XUiPanelAssignFormation")

function XUiAssignDeploy:OnAwake()
    self:InitComponent()
end

function XUiAssignDeploy:OnStart()
    AutoCheckTeamTrigger = true
    self.GroupId = XDataCenter.FubenAssignManager.SelectGroupId
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self:InitGroupInfo()
end

function XUiAssignDeploy:OnEnable()
    self.GroupId = XDataCenter.FubenAssignManager.SelectGroupId
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    if AutoCheckTeamTrigger then
        AutoCheckTeamTrigger = nil
        self:AutoCheckTeamToRefresh()
    end
    self:RefreshTeamGrid()

    self.TextDesc.text = CS.XTextManager.GetText("AwarenessHintText")
end

function XUiAssignDeploy:InitComponent()
    self.FormationPanel = XUiPanelAssignFormation.New(self, self.PanelFormation)
    self.FormationPanel:Close()
    self.GridDeployTeam.gameObject:SetActiveEx(false)
    -- self.PanelDanger
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.BtnAutoTeam.CallBack = function() self:OnBtnAutoTeamClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.BtnFormation.CallBack = function() self:OnBtnFormationClick() end
    self.BtnFormation:SetButtonState(XUiButtonState.Disable)
end

function XUiAssignDeploy:OnGetEvents()
    return { XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM, XEventId.EVENT_ON_ASSIGN_TEAM_CHANGED, XEventId.EVENT_ASSIGN_REFRESH_FORMATION }
end

--事件监听
function XUiAssignDeploy:OnNotify(evt)
    if evt == XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM then
        self:OnFormationConfirm()
    elseif evt == XEventId.EVENT_ON_ASSIGN_TEAM_CHANGED then
        self:RefreshTeamGrid()
    elseif evt == XEventId.EVENT_ASSIGN_REFRESH_FORMATION then
        self.FormationPanel:RefreshForAnim()
    end
end

function XUiAssignDeploy:InitGroupInfo()
    local data = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    self.TeamGridList = {}
    self.ListData = data:GetTeamInfoId()
    self.StageListData = data:GetStageId()
    for _, _ in ipairs(self.ListData) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridDeployTeam)
        ui.transform:SetParent(self.PanelTeamContent, false)
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridAssignDeployTeam.New(self, ui)
        table.insert(self.TeamGridList, grid)
    end
end

function XUiAssignDeploy:AutoCheckTeamToRefresh()
    -- 先检查队伍是否为空
    -- 若为空则往前查找有队伍信息的group 
    if not XDataCenter.FubenAssignManager.CheckGroupHadRecordTeam(self.GroupId) then
        local targetPreGroupTeamData = nil
        local teamRecords = XDataCenter.FubenAssignManager.GetGroupTeamRecords()
        for i = #teamRecords, 1, -1 do
            local groupTeamRecordData = teamRecords[i]
            local groupId = groupTeamRecordData.GroupId
            if groupId < self.GroupId then
                targetPreGroupTeamData = XTool.Clone(groupTeamRecordData)
                break
            end
        end
        -- 如果找到了，copy到这一group，并同步服务器
        if targetPreGroupTeamData then
            -- copy前要检查队伍兼容性
            -- 如果被copy的队伍比该group需要的队伍多,剔除掉多的
            -- 如果相同位置的队伍 人数也比当前的多， 剔除掉多的
            for i = 1, #targetPreGroupTeamData.TeamInfoList, 1 do
                local teamId = self.ListData[i]
                local teamData = teamId and XDataCenter.FubenAssignManager.GetTeamDataById(teamId) or nil
                -- 处理成员
                local teamList = targetPreGroupTeamData.TeamInfoList[i]
                if teamData then
                    for index, charId in pairs(teamList) do
                        if index > teamData:GetNeedCharacter() then
                            -- table.remove(teamList, index)
                            teamList[index] = nil
                        end
                    end
                end
                
                -- 处理首发位(有部分老玩家在首发位概念出来前就玩过该活动导致服务端没存，所以要额外判空1次firstFightPosListNum)
                local firstFightPosListNum = targetPreGroupTeamData.FirstFightPosList[i]
                if teamData and firstFightPosListNum and firstFightPosListNum > teamData:GetNeedCharacter() then
                    targetPreGroupTeamData.FirstFightPosList[i] = 1
                end

                -- 处理队长位
                local captainPosListNum = targetPreGroupTeamData.CaptainPosList[i]
                if teamData and captainPosListNum and captainPosListNum > teamData:GetNeedCharacter() then
                    targetPreGroupTeamData.CaptainPosList[i] = 1
                end

                -- 清除多余队伍
                if i > #self.ListData then
                    -- table.remove(targetPreGroupTeamData.TeamInfoList, i)
                    -- table.remove(targetPreGroupTeamData.FirstFightPosList, i)
                    -- table.remove(targetPreGroupTeamData.CaptainPosList, i)
                    targetPreGroupTeamData.TeamInfoList[i] = nil
                    targetPreGroupTeamData.FirstFightPosList[i] = nil
                    targetPreGroupTeamData.CaptainPosList[i] = nil
                end

                -- 设置修改后的数据
                if teamData then
                    teamData:SetMemberList(targetPreGroupTeamData.TeamInfoList[i])
                    teamData:SetFirstFightIndex(targetPreGroupTeamData.FirstFightPosList[i])
                    teamData:SetLeaderIndex(targetPreGroupTeamData.CaptainPosList[i])
                end
            end
        end
    end
    
end

function XUiAssignDeploy:RefreshTeamGrid()
    local memberCount = XDataCenter.FubenAssignManager.GetGroupMemberCount(self.GroupId)
    self.BtnFormation.gameObject:SetActiveEx(memberCount > 0)
    self.BtnFormation:SetButtonState(XUiButtonState.Normal)

    for i, grid in ipairs(self.TeamGridList) do
        if self.ListData[i] then
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(self.GroupId, i, self.ListData[i])
        else
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiAssignDeploy:OnBtnFightClick()
    -- --检查挑战次数
    -- local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    -- if groupData:GetFightCount() >= groupData:GetMaxFightCount() then
    --     XUiManager.TipMsg(CS.XTextManager.GetText("FubenChallengeCountNotEnough"))
    --     return
    -- end
    -- 检查队伍
    local allTeamHasMember, teamCharList, captainPosList, firstFightPosList = XDataCenter.FubenAssignManager.TryGetFightTeamCharList(self.GroupId)
    if not allTeamHasMember then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignFightNoMember"))
        return
    end

    -- 设置队伍
    XDataCenter.FubenAssignManager.AssignSetTeamRequest(self.GroupId, teamCharList, captainPosList, firstFightPosList, function()
        local targetIndex = 1
        local targetStageId = nil
        local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
        local stageIdList = groupData:GetStageId()
        for i = 1, #stageIdList, 1 do
            local stageId = stageIdList[i]
            if not XDataCenter.FubenAssignManager.CheckStageFinish(stageId) then
                targetIndex = i
                targetStageId = stageId
                break
            end
        end

        -- 进入战斗
        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
        XDataCenter.FubenAssignManager.SetEnterLoadingData(targetIndex, teamCharList[targetIndex], groupData, chapterData, true)
        XDataCenter.FubenManager.EnterAssignFight(targetStageId, teamCharList[targetIndex], captainPosList[targetStageId], nil, nil, firstFightPosList[targetIndex])

        -- 打开战斗前loading界面
        -- XLuaUiManager.Open("UiAssignInfo", self.ChapterId, self.GroupId, teamCharList, captainPosList, firstFightPosList)
    end)
end

function XUiAssignDeploy:OnBtnFormationClick()
    self.FormationPanel:Show(self.GroupId)
end

function XUiAssignDeploy:OnBtnAutoTeamClick()
    XDataCenter.FubenAssignManager.AutoTeam(self.GroupId)
    self:RefreshTeamGrid()
end

function XUiAssignDeploy:OnBtnBackClick()
    self:Close()
end

function XUiAssignDeploy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAssignDeploy:OnFormationConfirm()
    self:RefreshTeamGrid()
end