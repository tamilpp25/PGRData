
local XRestaurantChar = require("XModule/XRestaurant/XGameObject/XRestaurantChar")

---@class XRestaurantOrderNpc : XRestaurantChar
local XRestaurantOrderNpc = XClass(XRestaurantChar, "XRestaurantOrderNpc")

--跟角色Id不绑定属性初始化
function XRestaurantOrderNpc:Init()
    local key = "OrderNpcBornPoint"
    local template = self._Model:GetClientConfig(key)
    local point, rotate = template.Values[1], template.Values[2]
    
    self._Position = XMVCA.XRestaurant:StrPos2Vector3(point)
    self._Rotate = XMVCA.XRestaurant:StrPos2Vector3(rotate)
end

function XRestaurantOrderNpc:Born(bornCb)
    XRestaurantChar.Born(self, bornCb)
    
    self._OwnControl:GetRoom():TryRemoveCustomer(self:GetNpcId())
end

function XRestaurantOrderNpc:Show()
    XRestaurantChar.Show(self)
    --处理旋转/位移/缩放
    self:InitCharTransform()
end

--跟角色Id绑定属性初始化
function XRestaurantOrderNpc:InitData()
    local template = self._Model:GetOrderModelTemplate(self._Id)
    self._AnimationList = template.Anim
end

function XRestaurantOrderNpc:GetAssetPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    return self._Model:GetNpcModelUrl(npcId)
end

function XRestaurantOrderNpc:GetNpcId()
    local template = self._Model:GetOrderModelTemplate(self._Id)
    return template and template.NpcId or 0
end

function XRestaurantOrderNpc:GetControllerPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    return self._Model:GetNpcControllerUrl(npcId)
end

function XRestaurantOrderNpc:GetObjName()
    return string.format("@O-%s", self._Id)
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
    local behaviorId = self:GetOrderNpcBehaviourId(XMVCA.XRestaurant.PerformState.NotStart)
    XLuaBehaviorManager.PlayId(behaviorId, self._Agent)
end

function XRestaurantOrderNpc:GetOrderNpcBehaviourId(state)
    -- state 下标从0开始
    state = state + 1
    return self._Model:GetClientConfigValue("OrderNpcBehaviourId", state)
end

function XRestaurantOrderNpc:GetActionId(index)
    return self._AnimationList[index]
end

function XRestaurantOrderNpc:ChangeState(state)
    if state == XMVCA.XRestaurant.PerformState.Finish then
        XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_INDENT_NPC_STATE_CHANGED, false, self._Id)
    end
    XLuaBehaviorManager.PlayId(self:GetOrderNpcBehaviourId(state), self._Agent)
end

function XRestaurantOrderNpc:IsNeedClick()
    return true
end

function XRestaurantOrderNpc:Dispose()
    self._OwnControl:GetRoom():ReleaseOrderNpc()
end

function XRestaurantOrderNpc:GetRandomBubbleText()
    local template = self._Model:GetOrderModelTemplate(self._Id)
    return template and XUiHelper.ReplaceTextNewLine(template.RePlay) or ""
end

function XRestaurantOrderNpc:IsHideWhenStopBusiness()
    return true
end

return XRestaurantOrderNpc