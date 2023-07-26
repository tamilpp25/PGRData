local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

---推箱子掉落物
---@class XRpgMakerGameDrop:XRpgMakerGameObject
local XRpgMakerGameDrop = XClass(XRpgMakerGameObject, "XRpgMakerGameDrop")

function XRpgMakerGameDrop:Ctor(id)
    self:InitData()
end

function XRpgMakerGameDrop:InitData()
    self.IsPickUp = false   -- 是否被拾取
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
end

---@param mapObjData XMapObjectData
function XRpgMakerGameDrop:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
end

function XRpgMakerGameDrop:UpdateData(data)
    self:UpdatePosition(data)
end

function XRpgMakerGameDrop:UpdateObjPosAndDirection()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local x = self:GetPositionX()
    local y = self:GetPositionY()
    local cubePosition = self:GetCubeUpCenterPosition(y, x)
    cubePosition.y = transform.position.y
    self:SetGameObjectPosition(cubePosition)
    self:SetActive(not self.IsPickUp)
end

function XRpgMakerGameDrop:GetDropType()
    return self.MapObjData and self.MapObjData:GetParams()[2]
end

function XRpgMakerGameDrop:SetPickUp(isPickUp)
    self.IsPickUp = isPickUp
    self:SetActive(not self.IsPickUp)
end

function XRpgMakerGameDrop:CheckIsPickUp()
    return self.IsPickUp
end

return XRpgMakerGameDrop