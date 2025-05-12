
---@class XRestaurantSignNpc : XRestaurantChar
---@field _Controller UnityEngine.Animator
---@field _ClickArea UnityEngine.GameObject 点击区域
local XRestaurantSignNpc = XClass(require("XModule/XRestaurant/XGameObject/XRestaurantChar"), "XRestaurantSignNpc")

function XRestaurantSignNpc:Init()
    local strPos = self._Model:GetClientConfigValue("SignNpcProperty", 1)
    self._Position = XMVCA.XRestaurant:StrPos2Vector3(strPos)
end

function XRestaurantSignNpc:InitData()
    local template = self._Model:GetSignModelTemplate(self._Id)
    self._AnimationList = template and template.Anim or {}
end

function XRestaurantSignNpc:GetAssetPath()
    local template = self._Model:GetSignModelTemplate(self._Id)
    if not template then
        return ""
    end
    return self._Model:GetNpcModelUrl(template.NpcId)
end

function XRestaurantSignNpc:GetObjName()
    return string.format("@S-%s", self._Id)
end

function XRestaurantSignNpc:CheckBeforeLoad()
    local path = self:GetAssetPath()
    return not string.IsNilOrEmpty(path)
end

function XRestaurantSignNpc:GetControllerPath()
    local template = self._Model:GetSignModelTemplate(self._Id)
    if not template then
        return ""
    end
    return self._Model:GetNpcControllerUrl(template.NpcId)
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
    XLuaBehaviorManager.PlayId(self._Model:GetSignNpcBehaviourId(XMVCA.XRestaurant.SignState.Incomplete), self._Agent)
end

function XRestaurantSignNpc:ChangeState(state)
    XLuaBehaviorManager.PlayId(self._Model:GetSignNpcBehaviourId(state), self._Agent)
end

function XRestaurantSignNpc:GetActionId(index)
    return self._AnimationList[index]
end

function XRestaurantSignNpc:IsToday(day)
    return self._Id == day
end

function XRestaurantSignNpc:OnClick(eventData)
    self._OwnControl:OpenSign()
end

function XRestaurantSignNpc:Dispose()
    self._OwnControl:GetRoom():ReleaseSignNpc()
end

return XRestaurantSignNpc