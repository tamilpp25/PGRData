

local XRestaurantChar = require("XModule/XRestaurant/XGameObject/XRestaurantChar")

---@class XRestaurantCustomer : XRestaurantChar
---@field
local XRestaurantCustomer = XClass(XRestaurantChar, "XRestaurantCustomer")

function XRestaurantCustomer:GetAssetPath()
    return XRestaurantConfigs.GetCustomerModelPath(self._Id)
end

function XRestaurantCustomer:GetControllerPath()
    return XRestaurantConfigs.GetCustomerModelController(self._Id)
end

function XRestaurantCustomer:GetObjName()
    return string.format("@Customer:%s", tostring(self._Id))
end

function XRestaurantCustomer:GetCharTypeDesc()
    return "顾客NPC"
end

function XRestaurantCustomer:GetBehaviourId()
    return XRestaurantConfigs.GetCustomerBehaviourId(self._Id)
end

function XRestaurantCustomer:SetBornPoint(point, redPoint, greenPoint)
    self._BornPoint = point
    self._RedPoint = redPoint
    self._GreedPoint = greenPoint
end

--立即释放
function XRestaurantCustomer:Dispose()
    self:Release()
    local room = XDataCenter.RestaurantManager.GetRoom()
    room:RemoveCustomer(self._Id)
end

function XRestaurantCustomer:InitCharTransform()
    if self._BornPoint then
        self._Transform.position = self._BornPoint
    end

    --改变朝向
    local target = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3.back)
    self._Transform.rotation = target
    self:TryAddNavMeshAgent()
    --self._MoveAgent.IsIgnoreCollide = true
end

function XRestaurantCustomer:PlayBehaviour()
    XLuaBehaviorManager.PlayId(self:GetBehaviourId(), self._Agent)
end

function XRestaurantCustomer:DoSetGreenPoint()
    self._Agent:SetVarDicByKey("TargetPosition", self._GreedPoint)
end

function XRestaurantCustomer:DoSetRedPoint()
    self._Agent:SetVarDicByKey("TargetPosition", self._RedPoint)
end

function XRestaurantCustomer:DoSetStartPoint()
    self._Agent:SetVarDicByKey("TargetPosition", self._BornPoint)
end

function XRestaurantCustomer:GetRandomPoint()
    local room = XDataCenter.RestaurantManager.GetRoom()
    return room:GetCustomerRandomPoint()
end

--function XRestaurantCustomer:GetBubbleKey()
--    return string.format("Customer_%s", self._Id)
--end

function XRestaurantCustomer:GetRandomBubbleText()
    local text = XRestaurantConfigs.GetCustomerTextList(self._Id)
    local index = math.random(1, #text)
    return text[index]
end

function XRestaurantCustomer:GetBubbleText(index)
    local text = XRestaurantConfigs.GetCustomerTextList(self._Id)
    return text[index] or "? ? ?"
end

return XRestaurantCustomer