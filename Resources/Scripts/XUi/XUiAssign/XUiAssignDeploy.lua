local XUiAssignDeploy = XLuaUiManager.Register(XLuaUi, "UiAssignDeploy")

local table = table
local ipairs = ipairs

local XUiGridAssignDeployTeam = require("XUi/XUiAssign/XUiGridAssignDeployTeam")
local XUiPanelAssignFormation = require("XUi/XUiAssign/XUiPanelAssignFormation")

function XUiAssignDeploy:OnAwake()
    self:InitComponent()
end

function XUiAssignDeploy:OnStart()
    self.GroupId = XDataCenter.FubenAssignManager.SelectGroupId
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self:InitGroupInfo()
end

function XUiAssignDeploy:OnEnable()
    self.GroupId = XDataCenter.FubenAssignManager.SelectGroupId
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self:Refresh()
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
        self:Refresh()
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


function XUiAssignDeploy:Refresh()
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
        self:Close()
        -- 打开战斗前loading界面
        XLuaUiManager.Open("UiAssignInfo", self.ChapterId, self.GroupId, teamCharList, captainPosList, firstFightPosList)
    end)
end

function XUiAssignDeploy:OnBtnFormationClick()
    self.FormationPanel:Show(self.GroupId)
end

function XUiAssignDeploy:OnBtnAutoTeamClick()
    XDataCenter.FubenAssignManager.AutoTeam(self.GroupId)
    self:Refresh()
end

function XUiAssignDeploy:OnBtnBackClick()
    self:Close()
end

function XUiAssignDeploy:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAssignDeploy:OnFormationConfirm()
    self:Refresh()
end