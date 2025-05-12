local XRestaurantChar = require("XModule/XRestaurant/XGameObject/XRestaurantChar")

---@class XRestaurantRole : XRestaurantChar 角色模型类
---@field _BubbleTexts string[]
---@field _FreeCount number 能随机次数
---@field _BubbleOffset UnityEngine.Vector3 气泡偏移
---@field _NextBubbleTime number 下次气泡弹出时间
---@field _HideEffectMap table<string, UnityEngine.GameObject> 是否销毁特效
local XRestaurantRole = XClass(XRestaurantChar, "XRestaurantRole")

function XRestaurantRole:InitData()
end

function XRestaurantRole:GetObjName()
    return string.format("@S-%s", tostring(self._Id))
end

function XRestaurantRole:CheckBeforeLoad()
    if not XTool.IsNumberValid(self._Id) then
        XLog.Error("load restaurant character error: character id is invalid")
        return false
    end
    return true
end

function XRestaurantRole:DelayRelease()
    if not self:Exist() then
        return
    end
    --还有引用，不销毁
    if self._ReferenceCount > 0 then
        return
    end
    self._OwnControl:GetRoom():ReleaseCharacter(self._Id)
end

function XRestaurantRole:GetAssetPath()
    local template = self._Model:GetCharacterModelTemplate(self._Id)
    if not template then
        return ""
    end
    return self._Model:GetNpcModelUrl(template.NpcId)
end

function XRestaurantRole:GetControllerPath()
    local template = self._Model:GetCharacterModelTemplate(self._Id)
    if not template then
        return ""
    end
    return self._Model:GetNpcControllerUrl(template.NpcId)
end

function XRestaurantRole:GetCharTypeDesc()
    return "员工NPC"
end

function XRestaurantRole:PlayBehaviour()
    XLuaBehaviorManager.PlayId("Loading", self._Agent)
end

function XRestaurantRole:ChangeState(state)
    if not self._IsDoLoadBehaviour then
        return
    end
    local isWork = self:DoIsWorking()
    local behaviorId = isWork and "Working" or "Pause"
    XLuaBehaviorManager.PlayId(behaviorId, self._Agent)
end

function XRestaurantRole:OnLoadBehaviourComplete()
    XRestaurantChar.OnLoadBehaviourComplete(self)
    self:ChangeState()
end

function XRestaurantRole:Show()
    XRestaurantChar.Show(self)
    self:PlayBehaviour()
end

--- 设置工作台
---@param target UnityEngine.Transform 目标工作台
---@return
--------------------------
function XRestaurantRole:SetWorkBench(target, pos, areaType)
    if not target then
        return
    end
    self._AreaType = areaType
    self._Transform.position = pos
    self._Transform:LookAt(target.transform)
    --直接获取的配置，需要Clone一份
    self._BubbleTexts = XTool.Clone(self._Model:GetCharacterTextList(self._Id, areaType))
    self._FreeCount = #self._BubbleTexts
end

--取消工作
function XRestaurantRole:UnAssignWork()
    XLuaBehaviorManager.PlayId("UnAssignWork", self._Agent)
end

function XRestaurantRole:DoIsWorking()
    local staff = self._OwnControl:GetCharacter(self._Id)
    if not staff then
        return false
    end
    return staff:IsWorking()
end

function XRestaurantRole:GetRandomBubbleText()
    local index = math.random(1, self._FreeCount)
    local text = self._BubbleTexts[index]
    self._BubbleTexts[index] = self._BubbleTexts[self._FreeCount]
    self._BubbleTexts[self._FreeCount] = text
    self._FreeCount = self._FreeCount - 1
    if self._FreeCount <= 0 then
        self._FreeCount = #self._BubbleTexts
    end
    return text
end

function XRestaurantRole:GetBubbleText(index)
    local text = self._BubbleTexts[index]
    return text or "? ? ?"
end

function XRestaurantRole:GetActionId(index)
    local template = self._Model:GetCharacterModelTemplate(self._Id)
    return template and template.Anim[index] or ""
end

function XRestaurantRole:DoCheckInt(intValue)
    return self._AreaType == intValue
end

function XRestaurantRole:GetRandomPoint()
    return self._OwnControl:GetRoom():GetRandomPoint(self._Id)
end

--工作是否有加成
function XRestaurantRole:IsWorkWithBuff()
    local staff = self._OwnControl:GetCharacter(self._Id)
    if not staff or staff:IsFree() then
        return false
    end
    local areaType, benchId = staff:GetAreaType(), staff:GetWorkBenchId()
    local bench = self._OwnControl:GetWorkbench(areaType, benchId)
    return bench:CheckHasBuff()
end

function XRestaurantRole:Release()
    self._BubbleTexts = nil
    XRestaurantChar.Release(self)
end

function XRestaurantRole:IsHideWhenStopBusiness()
    return true
end

return XRestaurantRole