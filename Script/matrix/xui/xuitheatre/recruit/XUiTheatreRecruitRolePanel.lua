local XUiTheatreRecruitRoleGrid = require("XUi/XUiTheatre/Recruit/XUiTheatreRecruitRoleGrid")

local GRID_NUM = 3

--招募界面：招募角色列表控件
local XUiTheatreRecruitRolePanel = XClass(nil, "XUiTheatreRecruitRolePanel")

function XUiTheatreRecruitRolePanel:Ctor(ui, rootUi, models)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSample = rootUi.GridMulitiplayerRoomChar
    self.GridSample.gameObject:SetActiveEx(false)
    self.Model3D = models
    self:InitPanel()
end

function XUiTheatreRecruitRolePanel:Destroy()
    for _, grid in ipairs(self.CharaGrids) do
        grid:Destroy()
    end
end

function XUiTheatreRecruitRolePanel:InitPanel()
    self.CharaGrids = {}
    for i = 1, GRID_NUM do
        local roomCharCase = self.Transform:FindTransform("RoomCharCase" .. i)
        if roomCharCase then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridSample.gameObject)
            prefab.transform:SetParent(roomCharCase, false)
            prefab.gameObject:SetActiveEx(true)
            self.CharaGrids[i] = XUiTheatreRecruitRoleGrid.New(prefab, self.Model3D[i], self.RootUi, i, function()
                self:UpdateData()
            end)
        end
    end
end

function XUiTheatreRecruitRolePanel:UpdateData(playEffect)
    local hasRoleIndexDic = {}  --缓存有角色的格子的Index

    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    local adventureChapter = adventureManager:GetCurrentChapter()
    local recruitRoleDic = adventureChapter:GetRecruitRoleDic()
    local poolId
    local theatreRoleId
    for _, adventureRole in pairs(recruitRoleDic or {}) do
        theatreRoleId = adventureRole:GetId()
        poolId = XTool.IsNumberValid(theatreRoleId) and XTheatreConfigs.GetRolePoolId(theatreRoleId)
        if poolId and self.CharaGrids[poolId] then
            self.CharaGrids[poolId]:RefreshDatas(adventureRole, playEffect)
            hasRoleIndexDic[poolId] = true
        end
    end

    for i = 1, GRID_NUM do
        if not hasRoleIndexDic[i] then
            self.CharaGrids[i]:RefreshDatas(nil)
        end
    end
end

return XUiTheatreRecruitRolePanel