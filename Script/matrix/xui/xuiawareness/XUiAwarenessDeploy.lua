local XUiAwarenessDeploy = XLuaUiManager.Register(XLuaUi, "UiAwarenessDeploy")
local AutoCheckTeamTrigger = nil

local table = table
local ipairs = ipairs

local XUiGridAwarenessDeployTeam = require("XUi/XUiAwareness/Grid/XUiGridAwarenessDeployTeam")
local XUiPanelAwarenessFormation = require("XUi/XUiAwareness/Grid/XUiPanelAwarenessFormation")

function XUiAwarenessDeploy:OnAwake()
    self:InitComponent()
end

function XUiAwarenessDeploy:OnStart(chapterId)
    AutoCheckTeamTrigger = true
    self.ChapterId = chapterId
    self:InitGroupInfo()
end

function XUiAwarenessDeploy:OnEnable()
    if AutoCheckTeamTrigger then
        AutoCheckTeamTrigger = nil
        self:AutoCheckTeamToRefresh()
    end
    self:RefreshTeamGrid()

    self.TextDesc.text = CS.XTextManager.GetText("AwarenessHintText")
end

function XUiAwarenessDeploy:InitComponent()
    self.FormationPanel = XUiPanelAwarenessFormation.New(self, self.PanelFormation)
    self.FormationPanel:Close()
    self.GridDeployTeam.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.BtnAutoTeam.CallBack = function() self:OnBtnAutoTeamClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.BtnFormation.CallBack = function() self:OnBtnFormationClick() end
    self.BtnFormation:SetButtonState(XUiButtonState.Disable)
end

function XUiAwarenessDeploy:OnGetEvents()
    return { XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM, XEventId.EVENT_ON_ASSIGN_TEAM_CHANGED, XEventId.EVENT_ASSIGN_REFRESH_FORMATION }
end

--事件监听
function XUiAwarenessDeploy:OnNotify(evt)
    if evt == XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM then
        self:OnFormationConfirm()
    elseif evt == XEventId.EVENT_ON_ASSIGN_TEAM_CHANGED then
        self:RefreshTeamGrid()
    elseif evt == XEventId.EVENT_ASSIGN_REFRESH_FORMATION then
        self.FormationPanel:RefreshForAnim()
    end
end

function XUiAwarenessDeploy:InitGroupInfo()
    local data = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
    self.TeamGridList = {}
    self.ListData = data:GetTeamInfoId()
    self.StageListData = data:GetStageId()
    for _, _ in ipairs(self.ListData) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridDeployTeam)
        ui.transform:SetParent(self.PanelTeamContent, false)
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridAwarenessDeployTeam.New(self, ui)
        table.insert(self.TeamGridList, grid)
    end
end

function XUiAwarenessDeploy:AutoCheckTeamToRefresh()
    -- 先检查队伍是否为空
    -- 若为空则往前查找有队伍信息的group 
    if not XDataCenter.FubenAwarenessManager.CheckChapterHadRecordTeam(self.ChapterId) then
        local targetPreGroupTeamData = nil
        local teamRecords = XDataCenter.FubenAwarenessManager.GetChapterTeamRecords()
        for i = 1, #teamRecords do
            local chapterTeamRecordData = teamRecords[i]
            if not XTool.IsTableEmpty(chapterTeamRecordData) then
                targetPreGroupTeamData = XTool.Clone(chapterTeamRecordData)
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
                local teamData = teamId and XDataCenter.FubenAwarenessManager.GetTeamDataById(teamId) or nil
                -- 处理成员
                local teamList = targetPreGroupTeamData.TeamInfoList[i]
                if teamData then
                    for index, charId in pairs(teamList) do
                        if index > teamData:GetNeedCharacter() then
                            table.remove(teamList, index)
                        end
                    end
                end
                
                -- 处理首发位
                local firstFightPosListNum = targetPreGroupTeamData.FirstFightPosList[i]
                if teamData and firstFightPosListNum > teamData:GetNeedCharacter() then
                    targetPreGroupTeamData.FirstFightPosList[i] = 1
                end

                -- 处理队长位
                local captainPosListNum = targetPreGroupTeamData.CaptainPosList[i]
                if teamData and captainPosListNum > teamData:GetNeedCharacter() then
                    targetPreGroupTeamData.CaptainPosList[i] = 1
                end

                -- 清除多余队伍
                if i > #self.ListData then
                    table.remove(targetPreGroupTeamData.TeamInfoList, i)
                    table.remove(targetPreGroupTeamData.FirstFightPosList, i)
                    table.remove(targetPreGroupTeamData.CaptainPosList, i)
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

function XUiAwarenessDeploy:RefreshTeamGrid()
    local memberCount = XDataCenter.FubenAwarenessManager.GetChapterMemberCount(self.ChapterId)
    self.BtnFormation.gameObject:SetActiveEx(memberCount > 0)
    self.BtnFormation:SetButtonState(XUiButtonState.Normal)

    for i, grid in ipairs(self.TeamGridList) do
        if self.ListData[i] then
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(self.ChapterId, i, self.ListData[i])
        else
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiAwarenessDeploy:OnBtnFightClick()
    -- 检查队伍
    local allTeamHasMember, teamCharList, captainPosList, firstFightPosList = XDataCenter.FubenAwarenessManager.TryGetFightTeamCharList(self.ChapterId)
    if not allTeamHasMember then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignFightNoMember"))
        return
    end

    -- 设置队伍
    XDataCenter.FubenAwarenessManager.AwarenessSetTeamRequest(self.ChapterId, teamCharList, captainPosList, firstFightPosList, function()
        local targetIndex = 1
        local targetStageId = nil
        local groupData = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
        local stageIdList = groupData:GetStageId()
        for i = 1, #stageIdList, 1 do
            local stageId = stageIdList[i]
            if not XDataCenter.FubenAwarenessManager.CheckStageFinish(stageId) then
                targetIndex = i
                targetStageId = stageId
                break
            end
        end

        -- 进入战斗
        local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
        XDataCenter.FubenAwarenessManager.SetEnterLoadingData(targetIndex, teamCharList[targetIndex], groupData, chapterData, true)
        XDataCenter.FubenManager.EnterAwarenessFight(targetStageId, teamCharList[targetIndex], captainPosList[targetStageId], nil, nil, firstFightPosList[targetIndex])
    end)
end

function XUiAwarenessDeploy:OnBtnFormationClick()
    self.FormationPanel:Show(self.ChapterId)
end

function XUiAwarenessDeploy:OnBtnAutoTeamClick()
    XDataCenter.FubenAwarenessManager.AutoTeam(self.ChapterId)
    self:RefreshTeamGrid()
end

function XUiAwarenessDeploy:OnBtnBackClick()
    self:Close()
end

function XUiAwarenessDeploy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAwarenessDeploy:OnFormationConfirm()
    self:RefreshTeamGrid()
end