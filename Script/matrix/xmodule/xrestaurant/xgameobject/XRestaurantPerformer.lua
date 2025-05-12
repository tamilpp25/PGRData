
local XRestaurantChar = require("XModule/XRestaurant/XGameObject/XRestaurantChar")

---@class XRestaurantPerformer : XRestaurantChar 演员
---@field _Model XRestaurantModel
---@field _OwnControl XRestaurantControl
local XRestaurantPerformer = XClass(XRestaurantChar, "XRestaurantPerformer")

function XRestaurantPerformer:GetAssetPath()
    return self._Model:GetNpcModelUrl(self:GetNpcId())
end

function XRestaurantPerformer:GetControllerPath()
    return self._Model:GetNpcControllerUrl(self:GetNpcId())
end

function XRestaurantPerformer:GetNpcId()
    return self._Model:GetPerformerNpcId(self._Id)
end

function XRestaurantPerformer:GetObjName()
    return string.format("@P-%s", tostring(self._Id))
end

function XRestaurantPerformer:GetCharTypeDesc()
    return "演员NPC"
end

function XRestaurantPerformer:GetBehaviourId(state)
    local template = self._Model:GetPerformerTemplate(self._Id)
    return template and template.PerformBehaviorIds[state] or ""
end

function XRestaurantPerformer:ChangeState(state)
    if self._State == state then
        return
    end
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    self._State = state
    XLuaBehaviorManager.PlayId(self:GetBehaviourId(state), self._Agent)
end

function XRestaurantPerformer:SetTransform(x, y, z, rX, rY, rZ)
    self._Position = Vector3(x, y, z)
    self._Rotation = CS.UnityEngine.Quaternion.Euler(rX, rY, rZ)
end

function XRestaurantPerformer:InitCharTransform()
    self._Transform.position = self._Position
    self._Transform.rotation = self._Rotation
end

function XRestaurantPerformer:PlayBehaviour()
    self:ChangeState(1)
end

function XRestaurantPerformer:Born(bornCb)
    XRestaurantChar.Born(self, bornCb)

    self._OwnControl:GetRoom():TryRemoveCustomer(self:GetNpcId())
end

function XRestaurantPerformer:Dispose()
    if not self._OwnControl then
        return
    end
    local perform = self._OwnControl:GetRoom():GetPerform()
    if not perform then
        return
    end
    perform:RemoveActor(self:GetId())
end

function XRestaurantPerformer:SetBubbleTextList(dialogId)
    self._DialogTxtList = self._Model:GetDialogTextList(dialogId)
end

function XRestaurantPerformer:GetBubbleText(index)
    if index and index <= 0 then
        index = 1
    end
    return self._DialogTxtList and self._DialogTxtList[index] or ""
end

return XRestaurantPerformer