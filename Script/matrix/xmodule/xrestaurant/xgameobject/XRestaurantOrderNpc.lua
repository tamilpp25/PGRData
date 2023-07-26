

---@class XRestaurantOrderNpc : XRestaurantChar
local XRestaurantOrderNpc = XClass(require("XModule/XRestaurant/XGameObject/XRestaurantChar"), "XRestaurantOrderNpc")

--跟角色Id不绑定属性初始化
function XRestaurantOrderNpc:Init()
    local point = XRestaurantConfigs.GetClientConfig("OrderNpcBornPoint", 1)
    local rotate = XRestaurantConfigs.GetClientConfig("OrderNpcBornPoint", 2)
    
    self._Position = XRestaurantConfigs.StrPos2Vector3(point)
    self._Rotate = XRestaurantConfigs.StrPos2Vector3(rotate)
    
end

--跟角色Id绑定属性初始化
function XRestaurantOrderNpc:InitData()
    self._AnimationList = XRestaurantConfigs.GetOrderNpcAnimationList(self._Id)
end

function XRestaurantOrderNpc:GetAssetPath()
    return XRestaurantConfigs.GetOrderModel(self._Id)
end

function XRestaurantOrderNpc:GetControllerPath()
    return XRestaurantConfigs.GetOrderModelController(self._Id)
end

function XRestaurantOrderNpc:GetObjName()
    return string.format("@OrderNpc:%s", self._Id)
end

function XRestaurantOrderNpc:GetCharTypeDesc()
    return "订单NPC"
end

function XRestaurantOrderNpc:OnClick()
end

function XRestaurantOrderNpc:InitCharTransform()
    self._Transform.position = self._Position
    self._Transform.rotation = CS.UnityEngine.Quaternion.Euler(self._Rotate)
end

--加载进入时播放
function XRestaurantOrderNpc:PlayBehaviour()
    XLuaBehaviorManager.PlayId(XRestaurantConfigs.GetOrderNpcBehaviourId(XRestaurantConfigs.OrderState.NotStart), self._Agent)
end

function XRestaurantOrderNpc:GetActionId(index)
    return self._AnimationList[index]
end

function XRestaurantOrderNpc:ChangeState(state)
    XLuaBehaviorManager.PlayId(XRestaurantConfigs.GetOrderNpcBehaviourId(state), self._Agent)
end

function XRestaurantOrderNpc:IsNeedClick()
    return true
end

function XRestaurantOrderNpc:Dispose()
    self:Release()
end

function XRestaurantOrderNpc:GetRandomBubbleText()
    return XRestaurantConfigs.GetOrderNpcReplay(self._Id)
end

return XRestaurantOrderNpc