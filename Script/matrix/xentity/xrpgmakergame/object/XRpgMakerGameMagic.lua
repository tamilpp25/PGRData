local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

---推箱子魔法阵
---@class XRpgMakerGameMagic:XRpgMakerGameObject
local XRpgMakerGameMagic = XClass(XRpgMakerGameObject, "XRpgMakerGameMagic")

function XRpgMakerGameMagic:Ctor(id)
    self:InitData()
end

function XRpgMakerGameMagic:InitData()
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
end

---@param mapObjData XMapObjectData
function XRpgMakerGameMagic:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
end

function XRpgMakerGameMagic:UpdateData(data)
    self:UpdatePosition(data)
end

function XRpgMakerGameMagic:UpdateObjPosAndDirection()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local x = self:GetPositionX()
    local y = self:GetPositionY()
    local cubePosition = self:GetCubeUpCenterPosition(y, x)
    cubePosition.y = transform.position.y
    self:SetGameObjectPosition(cubePosition)
end

function XRpgMakerGameMagic:OnLoadComplete()
    self:SetActive(false)
    self:SetActive(true)
    XRpgMakerGameMagic.Super.OnLoadComplete(self)
end

return XRpgMakerGameMagic