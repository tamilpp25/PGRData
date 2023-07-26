
---@class XRestaurantSignNpc : XRestaurantChar
---@field _Controller UnityEngine.Animator
---@field _ClickArea UnityEngine.GameObject 点击区域
local XRestaurantSignNpc = XClass(require("XModule/XRestaurant/XGameObject/XRestaurantChar"), "XRestaurantSignNpc")

function XRestaurantSignNpc:Init()
    local strPos = XRestaurantConfigs.GetClientConfig("SignNpcProperty", 1)
    self._Position = XRestaurantConfigs.StrPos2Vector3(strPos)
end

function XRestaurantSignNpc:InitData()
    self._AnimationList = XRestaurantConfigs.GetSignActivityNpcAnimations(self._Id)
end

function XRestaurantSignNpc:GetAssetPath()
    return XRestaurantConfigs.GetSignActivityNpcModelPath(self._Id)
end

function XRestaurantSignNpc:GetObjName()
    return string.format("@SignNpc:Day%s", self._Id)
end

function XRestaurantSignNpc:CheckBeforeLoad()
    local path = XRestaurantConfigs.GetSignActivityNpcModelPath(self._Id)
    return not string.IsNilOrEmpty(path)
end

function XRestaurantSignNpc:GetControllerPath()
    return XRestaurantConfigs.GetSignActivityNpcControllerPath(self._Id)
end

function XRestaurantSignNpc:GetCharTypeDesc()
    return "签到NPC"
end

function XRestaurantSignNpc:InitCharTransform()
    self._ClickArea = CS.UnityEngine.GameObject("Effect")
    self._ClickArea.transform:SetParent(self._Transform)
    self:TryResetTransform(self._ClickArea.transform)
    --增加点击范围
    ---@type UnityEngine.BoxCollider
    local collider = self._ClickArea.gameObject:AddComponent(typeof(CS.UnityEngine.BoxCollider))
    collider.center = CS.UnityEngine.Vector3.up
    collider.size = CS.UnityEngine.Vector3(1, 2, 1)
    
    --改变朝向
    local target = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3.back)
    self._Transform.rotation = target
    --设置位置
    self._Transform.position = self._Position
end

function XRestaurantSignNpc:IsNeedClick()
    return true
end

function XRestaurantSignNpc:PlayBehaviour()
    XLuaBehaviorManager.PlayId(XRestaurantConfigs.GetSignNpcBehaviourId(XRestaurantConfigs.SignState.Incomplete), self._Agent)
end

function XRestaurantSignNpc:ChangeState(state)
    XLuaBehaviorManager.PlayId(XRestaurantConfigs.GetSignNpcBehaviourId(state), self._Agent)
end

function XRestaurantSignNpc:GetActionId(index)
    return self._AnimationList[index]
end

function XRestaurantSignNpc:IsToday(day)
    return self._Id == day
end

function XRestaurantSignNpc:OnClick(eventData)
    XDataCenter.RestaurantManager.OpenSignin()
end

function XRestaurantSignNpc:Dispose()
    self:Release()
end

return XRestaurantSignNpc