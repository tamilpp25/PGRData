-- 预热小彩蛋特效
---@class XUiMainBoardEffect
local XUiMainBoardEffect = XClass(nil, "XUiMainBoardEffect")

---@param parent XUiMain
function XUiMainBoardEffect:Ctor(parent)
    self.Parent = parent
    ---@type table<number, { EffectGo: UnityEngine.GameObject, Time: number }>
    self.EffectDataList = {}
    -- 是否在UI动画中
    self.IsInUIAnim = false
end

function XUiMainBoardEffect:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.TriggerBoardEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_START, self.UIAnimStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, self.UIAnimEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK, self.UIAnimBreak, self)
end

function XUiMainBoardEffect:OnDisable()
    self:HideEffect()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_END, self.TriggerBoardEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_START, self.UIAnimStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_END, self.UIAnimEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROLE_ACTION_UIANIM_BREAK, self.UIAnimBreak, self)
end

-- 触发特效
function XUiMainBoardEffect:TriggerBoardEffect()
    XMVCA.XUiMain:TriggerBoardEffect(function()
        self:ShowEffect()
    end)
end

-- UI动画开始
function XUiMainBoardEffect:UIAnimStart()
    self:HideEffect()
    self.IsInUIAnim = true
end

-- UI动画结束
function XUiMainBoardEffect:UIAnimEnd()
    self.IsInUIAnim = false
end

-- UI动画中断
function XUiMainBoardEffect:UIAnimBreak()
    self.IsInUIAnim = false
end

-- 显示特效
function XUiMainBoardEffect:ShowEffect()
    -- UI动画中不显示特效
    if self.IsInUIAnim then
        return
    end
    ---@type UnityEngine.Transform
    local transform = self.Parent:GetRoleModelTransform()
    if XTool.UObjIsNil(transform) then
        return
    end
    local effectPaths = XMVCA.XUiMain:GetBoardEffectPaths()
    if XTool.IsTableEmpty(effectPaths) then
        return
    end
    for index, data in ipairs(effectPaths) do
        local rootName = data.RootName
        local path = data.Path
        ---@type UnityEngine.Transform
        local rootTransform
        if string.IsNilOrEmpty(rootName) then
            rootTransform = self.Parent.UiModel.UiModelParent.transform
        else
            rootTransform = transform:FindTransform(rootName)
        end
        if not XTool.UObjIsNil(rootTransform) then
            local effectGo = rootTransform:LoadPrefab(path, false)
            effectGo:SetActiveEx(true)
            self.EffectDataList[index] = { EffectGo = effectGo, Time = data.Time }
        end
    end
    self:StartTimer()
end

-- 隐藏特效
function XUiMainBoardEffect:HideEffect()
    self:StopTimer()
    if XTool.IsTableEmpty(self.EffectDataList) then
        return
    end
    for _, data in pairs(self.EffectDataList) do
        if not XTool.UObjIsNil(data.EffectGo) then
            data.EffectGo:SetActiveEx(false)
        end
    end
    self.EffectDataList = {}
end

-- 定时器
function XUiMainBoardEffect:StartTimer()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.Parent.GameObject) then
            self:StopTimer()
            return
        end
        if XTool.IsTableEmpty(self.EffectDataList) then
            self:StopTimer()
            return
        end
        -- 时间结束后自动移除
        for index = #self.EffectDataList, 1, -1 do
            local data = self.EffectDataList[index]
            if data.Time <= 0 then
                if not XTool.UObjIsNil(data.EffectGo) then
                    data.EffectGo:SetActiveEx(false)
                end
                table.remove(self.EffectDataList, index)
            else
                data.Time = data.Time - 1
            end
        end
    end, 1000)
end

-- 停止定时器
function XUiMainBoardEffect:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiMainBoardEffect
