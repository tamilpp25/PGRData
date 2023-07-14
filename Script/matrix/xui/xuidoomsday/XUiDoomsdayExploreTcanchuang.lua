local XUiGridDoomsdayResource = require("XUi/XUiDoomsday/XUiGridDoomsdayResource")
local XUiGridDoomsdayTeam = require("XUi/XUiDoomsday/XUiGridDoomsdayTeam")

local EXPLORE_TEAM_NUM = 2 --探索小队数量

local XUiDoomsdayExploreTcanchuang = XLuaUiManager.Register(XLuaUi, "UiDoomsdayExploreTcanchuang")

function XUiDoomsdayExploreTcanchuang:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayExploreTcanchuang:OnStart(stageId, placeId, closeCb)
    self.StageId = stageId
    self.PlaceId = placeId
    self.CloseCb = closeCb
    self.TeamIds = {1, 2}
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
end

function XUiDoomsdayExploreTcanchuang:OnEnable()
    self:UpdateView()
end

function XUiDoomsdayExploreTcanchuang:UpdateView()
    local stageId = self.StageId
    local stageData = self.StageData
    local placeId = self.PlaceId

    self.TxtTtile.text = XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "Name")
    self.TxtTtile01.text = XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "Desc")

    --资源栏
    self:RefreshTemplateGrids(
        self.PanelTool4,
        XDoomsdayConfigs.GetResourceIds(),
        self.PanelAsset,
        function()
            return XUiGridDoomsdayResource.New(stageId)
        end,
        "ResourceGrids"
    )

    --可获得资源
    self.GridInhabitant.gameObject:SetActiveEx(XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "CanGetPeople"))
    self:RefreshTemplateGrids(
        self.GridResource,
        XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "ResourceId"),
        self.PanelResource,
        nil,
        "RewardResourceGrids",
        function(grid, resourceId)
            grid.RImgIcon:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
        end
    )

    --探索小队状态
    self:RefreshTemplateGrids(
        {self.GridTeam1, self.GridTeam2},
        self.TeamIds,
        nil,
        function()
            return XUiGridDoomsdayTeam.New(stageId, handler(self, self.OnSelectTeam), handler(self, self.OnCreateTeam))
        end,
        "TeamGrids"
    )

    local placeTeamId = stageData:GetPlaceSelectTeamId(placeId)
    self:OnSelectTeam(placeTeamId)
end

function XUiDoomsdayExploreTcanchuang:UpdateBtnGo()
    --确认按钮
    local btnDisable = not self.SelectTeamId or self.StageData:CheckPlaceHasSelectTeamId(self.PlaceId)
    self.BtnGo:SetDisable(btnDisable, not btnDisable)
end

function XUiDoomsdayExploreTcanchuang:OnCreateTeam()
    self:OnClickBtnClose()
end

function XUiDoomsdayExploreTcanchuang:OnSelectTeam(teamId)
    if self.StageData:GetTeamEvent(teamId) ~= nil then
        XUiManager.TipText("DoomsdayTeamInEvent")
        return
    end
    self.SelectTeamId = XTool.IsNumberValid(teamId) and teamId or nil
    for index, inId in ipairs(self.TeamIds) do
        local grid = self:GetGrid(index, "TeamGrids")
        grid:SetSelect(teamId == inId)
        grid:SetBtnDisable(self.StageData:CheckPlaceHasSelectTeamId(self.PlaceId))
    end
    self:UpdateBtnGo()
end

function XUiDoomsdayExploreTcanchuang:AutoAddListener()
    self.BtnCloseDetail.CallBack = handler(self, self.OnClickBtnClose)
    self.BtnGo.CallBack = handler(self, self.OnClickBtnEnter)
end

function XUiDoomsdayExploreTcanchuang:OnClickBtnClose()
    if self.CloseCb then
        self.CloseCb()
    end
    self:Close()
end

function XUiDoomsdayExploreTcanchuang:OnClickBtnEnter()
    local teamId = self.SelectTeamId

    if not teamId then
        XUiManager.TipText("DoomsdayNotSelectTeam")
        return
    end

    if self.StageData:GetTeamEvent(teamId) ~= nil then
        XUiManager.TipText("DoomsdayTeamInEvent")
        return
    end

    self:OnClickBtnClose()
    XDataCenter.DoomsdayManager.DoomsdayTargetPlaceRequest(self.StageId, teamId, self.PlaceId)
end

return XUiDoomsdayExploreTcanchuang
