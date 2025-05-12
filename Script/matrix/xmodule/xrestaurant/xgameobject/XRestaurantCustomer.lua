

local XRestaurantChar = require("XModule/XRestaurant/XGameObject/XRestaurantChar")

---@class XRestaurantCustomer : XRestaurantChar
---@field
local XRestaurantCustomer = XClass(XRestaurantChar, "XRestaurantCustomer")

function XRestaurantCustomer:GetAssetPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    return self._Model:GetNpcModelUrl(npcId)
end

function XRestaurantCustomer:GetControllerPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end 
    return self._Model:GetNpcControllerUrl(npcId)
end

function XRestaurantCustomer:GetNpcId()
    return self._Model:GetCustomerNpcId(self._Id)
end

function XRestaurantCustomer:GetObjName()
    return string.format("@C-%s", tostring(self._Id))
end

function XRestaurantCustomer:GetCharTypeDesc()
    return "顾客NPC"
end

function XRestaurantCustomer:GetBehaviourId()
    local template = self._Model:GetCustomerTemplate(self._Id)
    return template and template.BehaviourId or ""
end

function XRestaurantCustomer:SetBornPoint(point, redPoint, greenPoint)
    self._BornPoint = point
    self._RedPoint = redPoint
    self._GreedPoint = greenPoint
end

--立即释放
function XRestaurantCustomer:Dispose()
    self._OwnControl:GetRoom():RemoveCustomer(self:GetNpcId())
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
    return self._OwnControl:GetRoom():GetCustomerRandomPoint()
end

function XRestaurantCustomer:GetRandomBubbleText()
    local text = self._Model:GetCustomerTextList(self._Id)
    local index = math.random(1, #text)
    return text[index]
end

function XRestaurantCustomer:GetBubbleText(index)
    local text = self._Model:GetCustomerTextList(self._Id)
    return text[index] or "? ? ?"
end

return XRestaurantCustomer