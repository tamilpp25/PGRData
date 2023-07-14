local XEquipModel = XClass(nil, "XEquipModel")

-- go 为绑定生命周期的对象
-- luaBehaviour （XLuaBehaviour组件）提供生命周期回调
function XEquipModel:Ctor(go, luaBehaviour)
    self.GameObject = go
    self.LuaBehaviour = luaBehaviour
    luaBehaviour.LuaOnDisable = function() self:OnDisable() end
    luaBehaviour.LuaOnDestroy = function() self:OnDestroy() end

    self.AudioInfoDict = {}
end

function XEquipModel:OnDisable()
    -- 清除音效
    self:ClearAudioInfo()
end

function XEquipModel:OnDestroy()
    self:UnScheduleRotate()
    XModelManager.RemoveLuaBehaviour(self.GameObject)
end

-- 记录模型音效
function XEquipModel:AddAudioInfo(audioInfo)
    self.AudioInfoDict[audioInfo] = true
end

-- 停止模型音效
function XEquipModel:ClearAudioInfo()
    if next(self.AudioInfoDict) then
        for audioInfo, _ in pairs(self.AudioInfoDict) do
            audioInfo:Stop()
        end
        self.AudioInfoDict = {}
    end
end


--==============================--
--desc: 自转
--@rootGo: 根结点 提供XAutoRotation组件
--@model: 武器模型
--@modelId: 武器模型id
--==============================--
function XEquipModel:AutoRotateWeapon(rootGo, model, modelId)
    self:UnScheduleRotate()

    local delay = XEquipConfig.GetEquipUiAutoRotateDelay(modelId)
    if delay and delay > 0 then
        self.RotateScheduleId = XScheduleManager.ScheduleOnce(function()
            self:DoAutoRotateWeapon(rootGo, model)
        end, delay)
    else
        self:DoAutoRotateWeapon(rootGo, model)
    end
end

function XEquipModel:DoAutoRotateWeapon(rootGo, model)
    if XTool.UObjIsNil(rootGo) or XTool.UObjIsNil(model) then
        return
    end

    local rotate = rootGo:GetComponent("XAutoRotation")
    if rotate then
        rotate.RotateSelf = false
        rotate.Inited = false
        rotate.Target = model.transform
    end
end

function XEquipModel:UnScheduleRotate()
    if self.RotateScheduleId then
        XScheduleManager.UnSchedule(self.RotateScheduleId)
        self.RotateScheduleId = nil
    end
end

return XEquipModel