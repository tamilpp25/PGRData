
local XUiPanelSGWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWall")

---@class XUiPanelSGPhotoWall : XUiPanelSGWall
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _PanelOp XUiPanelSGPhotoWallOp
local XUiPanelSGPhotoWall = XClass(XUiPanelSGWall, "XUiPanelSGPhotoWall")

local SgFurnitureType = XMVCA.XSkyGardenDorm.XSgFurnitureType
---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XUiPanelSGPhotoWall:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGPhotoWall:Refresh()
    XUiPanelSGWall.Refresh(self)
end

function XUiPanelSGPhotoWall:InitUi()
    XUiPanelSGWall.InitUi(self)
    self._PanelTab = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallTab").New(self.ScrollTitleTab, self, self._AreaType, 1)
    self._PanelOp = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGPhotoWallOp").New(self.PanelWall, self, self._AreaType)
end

function XUiPanelSGPhotoWall:InitCb()
    self._CreateFunc = {
        [SgFurnitureType.Photo] = function(id, cfgId) self:OnCreatePhoto(id, cfgId) end,
        [SgFurnitureType.Decoration] = function(id, cfgId) self:OnCreateDecoration(id, cfgId) end,
        [SgFurnitureType.DecorationBoard] = function(id, cfgId) self:OnCreateDecorationBoard(id, cfgId) end,
    }
end

function XUiPanelSGPhotoWall:InitFurniture()
    local data = self.Parent:GetContainerData()
    local dict = data:GetFurnitureDict()
    ---@type XSgFurnitureData[]
    local list = {}
    local maxLayer = 0
    for _, f in pairs(dict) do
        list[#list + 1] = f
        maxLayer = math.max(maxLayer, f:GetLayer())
    end
    self._Control:SetMaxLayer(maxLayer)
    
    table.sort(list, function(a, b)
        local layerA = a:GetLayer()
        local layerB = b:GetLayer()
        if layerA ~= layerB then
            return layerA > layerB
        end
        return a:GetId() < a:GetId()
    end)
    
    for i, f in pairs(list) do
        self._PanelOp:CreateFurniture(i, f:GetId(), false, false)
    end
end

function XUiPanelSGPhotoWall:OnCreatePhoto(id, cfgId)
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CREATE_PHOTO, {
        Id = id,
        SoId = self._Control:GetFurnitureSceneObjId(cfgId),
    })
    self._Control:AddFightFurnitureData(id, data)
    self._PanelOp:CreateFurniture(0, id, true, false)
end

function XUiPanelSGPhotoWall:OnCreateDecoration(id, cfgId)
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CREATE_PHOTO_ADORN, {
        Id = id,
        SoId = self._Control:GetFurnitureSceneObjId(cfgId),
    })
    self._Control:AddFightFurnitureData(id, data)
    self._PanelOp:CreateFurniture(0, id, true, false)
end

function XUiPanelSGPhotoWall:OnCreateDecorationBoard(id, cfgId)
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CHANGE_OR_CREATE_PHOTO_WALL, {
        Id = self._Control:GetFurnitureSceneObjId(cfgId),
    })
    self._Control:UpdateWallFightData(data)
    --更换容器
    self._Control:CloneContainerFurnitureData(self._AreaType):ChangeContainer(id, cfgId)
    --通知战斗更换
    self._PanelOp:SwitchContainer()
    self.Parent:UpdateView()
end

return XUiPanelSGPhotoWall