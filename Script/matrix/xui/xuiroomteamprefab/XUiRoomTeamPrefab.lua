local XUiGridTeam = require("XUi/XUiRoomTeamPrefab/XUiGridTeam")
local MAX_PREFAB_NUM = CS.XGame.Config:GetInt("MaxTeamPrefab")

local XUiRoomTeamPrefab = XLuaUiManager.Register(XLuaUi, "UiRoomTeamPrefab")

function XUiRoomTeamPrefab:OnAwake()
    self:AddListener()
end

function XUiRoomTeamPrefab:OnStart(captainPos, firstFightPos, characterLimitType, limitBuffId, stageType, teamGridId, closeCb, stageId, team)
    self.CaptainPos = captainPos
    self.FirstFightPos = firstFightPos
    self.CharacterLimitType = characterLimitType
    self.LimitBuffId = limitBuffId
    self.StageType = stageType
    self.TeamGridId = teamGridId
    self.CloseCb = closeCb
    ---@type XUiGridTeam[]
    self.TeamPrefabs = {}
    self.StageId = stageId
    self.Team = team
end

function XUiRoomTeamPrefab:OnEnable()
    self:RefreshTeamList()
    self:OnAnimationSetChange()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.OnAnimationSetChange, self)
end

function XUiRoomTeamPrefab:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.OnTeamPrefabChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.OnAnimationSetChange, self)
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiRoomTeamPrefab:OnAnimationSetChange()
    for _, grid in pairs(self.TeamPrefabs) do
        grid:OnAnimationSetChange()
    end
end

function XUiRoomTeamPrefab:OnTeamPrefabChange(index, teamData)
    if self.TeamPrefabs[index] then
        self.TeamPrefabs[index]:Refresh(teamData, index)
    end
end

function XUiRoomTeamPrefab:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    XEventManager.AddEventListener(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.OnTeamPrefabChange, self)
end

function XUiRoomTeamPrefab:NewTeamGrid()
    local item = CS.UnityEngine.Object.Instantiate(self.GridTeam)
    local characterLimitType = self.CharacterLimitType
    local limitBuffId = self.LimitBuffId
    local stageType = self.StageType
    local teamGridId = self.TeamGridId
    local grid = XUiGridTeam.New(self, item, characterLimitType, limitBuffId, stageType, teamGridId, self.StageId)
    grid.Transform:SetParent(self.PanelTeamContent, false)
    grid.GameObject:SetActive(true)
    return grid
end

function XUiRoomTeamPrefab:GetSimpleTeamData(index)
    local maxPos = XDataCenter.TeamManager.GetMaxPos()
    local teamData = {}
    teamData.TeamId = index
    teamData.CaptainPos = XDataCenter.TeamManager.GetCaptainPos()
    teamData.FirstFightPos = XDataCenter.TeamManager.GetFirstFightPos()
    teamData.TeamName = CS.XTextManager.GetText("TeamPrefabDefaultName", index)
    teamData.TeamData = {}
    for idx = 1, maxPos do
        teamData.TeamData[idx] = 0
    end
    return teamData
end

function XUiRoomTeamPrefab:RefreshTeamList()
    self.GridTeam.gameObject:SetActive(false)
    local teamDataList = XDataCenter.TeamManager.GetTeamPrefabData()

    for i = 1, MAX_PREFAB_NUM do
        local grid = self.TeamPrefabs[i]
        if not grid then
            grid = self:NewTeamGrid(i)
            self.TeamPrefabs[i] = grid
        end
        local teamData = teamDataList[i] or self:GetSimpleTeamData(i)

        if not teamData.CaptainPos
                or teamData.CaptainPos < 1
                or teamData.CaptainPos > 3 then
            XLog.Error("XUiRoomTeamPrefab:RefreshTeamList函数错误，teamData的CaptainPos数据不正确")
            teamData.CaptainPos = 1
        end
        if not teamData.FirstFightPos
                or teamData.FirstFightPos < 1
                or teamData.FirstFightPos > 3 then
            XLog.Error("XUiRoomTeamPrefab:RefreshTeamList函数错误，teamData的FirstFightPos数据不正确")
            teamData.FirstFightPos = 1
        end

        grid:Refresh(teamData, i)
    end
end

function XUiRoomTeamPrefab:OnBtnBackClick()
    self:Close()
end