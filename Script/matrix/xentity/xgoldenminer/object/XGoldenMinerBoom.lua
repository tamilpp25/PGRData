local XGoldenMinerBaseObj = require("XEntity/XGoldenMiner/Object/XGoldenMinerBaseObj")

--黄金矿工炸弹
local XGoldenMinerBoom = XClass(XGoldenMinerBaseObj, "XGoldenMinerBoom")

function XGoldenMinerBoom:Ctor()
    self.IsNotHideInputHandle = false
    self.BoomCollider = self.Transform:GetComponent("CircleCollider2D")
    if not self:IsBoomCollider() then
        return
    end
    self.BoomCollider.enabled = false
end

function XGoldenMinerBoom:InitTriggerBoomFunc(triggerBoomFunc)
    self.TriggerBoomFunc = triggerBoomFunc
end

function XGoldenMinerBoom:OnTriggerEnter(collider)
    --触发对象不是钩爪
    local goldenMinerStoneId = tonumber(collider.gameObject.name)
    if XTool.IsNumberValid(goldenMinerStoneId) then
        local stoneType = XGoldenMinerConfigs.GetStoneType(goldenMinerStoneId)
        if stoneType == XGoldenMinerConfigs.StoneType.Boom and not XTool.UObjIsNil(self.GameObject) then
            self.IsNotHideInputHandle = true
            self:SetObjToTriggerParent(true)
        end
        return
    end

    if not self:IsBoomCollider() or XTool.UObjIsNil(collider.transform:GetComponent("Rigidbody2D")) or not self:IsActiveGoInputHandler() then
        return
    end

    self.IsNotHideInputHandle = true

    if self.TrigerCallback then
        self.TrigerCallback(self)
    end
end

function XGoldenMinerBoom:SetObjToTriggerParent(isLoadEffect)
    self.IsNotHideInputHandle = true
    self.BoomCollider.enabled = true
    self.BoomCollider.isTrigger = true

    local destroyTime = isLoadEffect and 0.5 or 0.05   --需要加载爆炸特效时延迟销毁时间加长
    if isLoadEffect then
        local effect = XGoldenMinerConfigs.GetStoneCatchEffect(self:GetId())
        self:LoadResource(self.Transform, effect)
    end
    
    self:StopDestroyTimer()
    self.DestroyTime = XScheduleManager.ScheduleForeverEx(function()
        destroyTime = destroyTime - CS.UnityEngine.Time.deltaTime
        if not XTool.UObjIsNil(self.GameObject) and destroyTime <= 0 then
            XUiHelper.Destroy(self.GameObject)
            self:StopDestroyTimer()
        end
    end, 0)
end

function XGoldenMinerBoom:SetGoInputHandlerActive(isActive)
    XGoldenMinerBoom.Super.SetGoInputHandlerActive(self, self.IsNotHideInputHandle or isActive)
end

function XGoldenMinerBoom:IsBoomCollider()
    if XTool.UObjIsNil(self.BoomCollider) then
        XLog.Error("炸弹未找到CircleCollider2D组件")
        return false
    end
    return true
end

function XGoldenMinerBoom:StopDestroyTimer()
    if self.DestroyTime then
        XScheduleManager.UnSchedule(self.DestroyTime)
        self.DestroyTime = nil
    end
end

return XGoldenMinerBoom