local XUiRoleGrid = require("XUi/XUiBiancaTheatre/Recruit/XUiRoleGrid")

local GRID_NUM = 3
local CenterIndex = 2 --中间位模型索引

--招募界面：招募角色列表控件
local XUiRolePanel = XClass(nil, "XUiRolePanel")

function XUiRolePanel:Ctor(ui, rootUi, models)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Model3D = models
    XTool.InitUiObject(self)
    self:InitPanel()
    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(false)
end

function XUiRolePanel:Destroy()
    for _, grid in ipairs(self.CharaGrids) do
        grid:Destroy()
    end
end

function XUiRolePanel:InitPanel()
    self.CharaGrids = {}
    for i = 1, GRID_NUM do
        local roomCharCase = self.Transform:FindTransform("RoomCharCase" .. i)
        if roomCharCase then
            local prefab = XUiHelper.Instantiate(self.GridMulitiplayerRoomChar, roomCharCase)
            prefab.gameObject:SetActiveEx(true)
            self.CharaGrids[i] = XUiRoleGrid.New(prefab, self.Model3D[i], self.RootUi, i)
        end
    end
end

function XUiRolePanel:UpdateData(playEffect)
    local hasRoleIndexDic = {}  --缓存有角色的格子的Index

    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local adventureChapter = adventureManager:GetCurrentChapter()
    local recruitRoleDic = adventureChapter:GetRecruitRoleDic()
    local theatreRoleId
    for i, adventureRole in pairs(recruitRoleDic or {}) do
        theatreRoleId = adventureRole:GetId()
        self.CharaGrids[i]:RefreshDatas(adventureRole, playEffect)
        hasRoleIndexDic[i] = true
    end

    for i = 1, GRID_NUM do
        if not hasRoleIndexDic[i] then
            self.CharaGrids[i]:RefreshDatas(nil)
        end
    end
end

function XUiRolePanel:HideModel(gridIndex)
    self:ChangeModelInDecay(gridIndex)
    for index, grid in ipairs(self.CharaGrids) do
        grid:SetModelActive(gridIndex == index)
        if gridIndex == index then
            grid:ShowDecayEffect()
        end
    end
end

function XUiRolePanel:ShowModel()
    for _, grid in ipairs(self.CharaGrids) do
        grid:SetModelActive(true)
    end
end

function XUiRolePanel:ChangeModelInDecay(gridIndex)
    local modelPosition, modelRotation = self.CharaGrids[CenterIndex]:GetModelTransformParams()
    local uiPosition = self.CharaGrids[CenterIndex]:GetUiPosition()
    if gridIndex ~= CenterIndex then
        self.CharaGrids[CenterIndex]:ChangeModelPosition(self.CharaGrids[gridIndex]:GetModelTransformParams())
        self.CharaGrids[gridIndex]:ChangeModelPosition(modelPosition, modelRotation)
        self.CharaGrids[CenterIndex]:ChangeUiPosition(self.CharaGrids[gridIndex]:GetUiPosition())
        self.CharaGrids[gridIndex]:ChangeUiPosition(uiPosition)
    end
end

return XUiRolePanel