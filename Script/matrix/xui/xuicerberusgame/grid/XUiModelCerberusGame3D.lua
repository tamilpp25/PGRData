---@class XUiModelCerberusGame3D
local XUiModelCerberusGame3D = XClass(nil, "XUiModelCerberusGame3D")

local ModelDic = 
{
    [1] = "R3TwentyoneMd010031",
    [2] = "R2NuoketiMd010031",
    [3] = "R3WeilaMd010031",
}

local CameraPos = 
{
    [1] = 6,
    [2] = 22.6,
    [3] = 40.8,
}

function XUiModelCerberusGame3D:Ctor(ui, rootui)
    self.RootUi2D = rootui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CurSelectIndex = nil
    XTool.InitUiObject(self)

    self:InitInfo()
end

function XUiModelCerberusGame3D:InitInfo()
    -- 阴影要放在武器模型加载完之后
    for k, key in pairs(ModelDic) do
        CS.XShadowHelper.AddShadow(self[key].gameObject, true)
    end
end

function XUiModelCerberusGame3D:SetChangeByRoleBtn(index, doModelSeleCb)
    if self.CurSelectIndex == index then
        return
    end
    self:SetAllModelCamFalse()
    -- 轨道转完才能转角色
    self:SetTrackSelect(index, function ()
        if doModelSeleCb then
            self:SetModelSelect(index)
        end
    end)
    self.CurSelectIndex = index
end

function XUiModelCerberusGame3D:SetModelSelect(index)
    if self.ChangeTimer then
        return
    end

    for modelIndex, modelKey in pairs(ModelDic) do
        self["UiCamFar0"..modelIndex].gameObject:SetActiveEx(modelIndex == index)
        self["UiCamNear0"..modelIndex].gameObject:SetActiveEx(modelIndex == index)
        if modelIndex ~= index then
            self:SetTargetModelUnSelect(modelIndex)
        end
    end
    -- 播放目标角色的Select状态
    self:SetTargerModelSelect(index)
end
        
function XUiModelCerberusGame3D:SetTrackSelect(index, cb)
    self:SetTrackPathPosition(CameraPos[index], cb)
end

function XUiModelCerberusGame3D:CheckLeftOrRight(currentValue, targetValue)
    local inc = (targetValue - currentValue + 53) % 53 -- 虚拟相机一圈的值是53
    local dec = (currentValue - targetValue + 53) % 53
    if inc <= dec then
        return true
    else
        return false
    end
end

function XUiModelCerberusGame3D:SetTrackPathPosition(value, cb)
    if self.ChangeTimer then
        self:StopTimer()
    end

    local trackDollyNear = self.CamNearMain:GetCinemachineComponent(CS.Cinemachine.CinemachineCore.Stage.Body, typeof(CS.Cinemachine.CinemachineTrackedDolly))
    local trackDollyFar = self.CamFarMain:GetCinemachineComponent(CS.Cinemachine.CinemachineCore.Stage.Body, typeof(CS.Cinemachine.CinemachineTrackedDolly))
        
    local duration = 3
    local moveSpeed = 0.6
    local targetValue = tonumber(string.format("%.f", value))
    local orgPath = tonumber(string.format("%.f", trackDollyNear.m_PathPosition))

    self.ChangeTimer = XUiHelper.Tween(duration, function ()
        local currPath = tonumber(string.format("%.f", trackDollyNear.m_PathPosition))
        if currPath == targetValue then
            self:StopTimer()
            if cb then
                cb()
            end
            return
        end

        local addNum = 0
        if self:CheckLeftOrRight(orgPath, targetValue) then
            addNum = moveSpeed
        else
            addNum = -1 * moveSpeed
        end
        -- 由于虚拟相机绕一圈值会叠加，所以需要减一圈的值
        local res = (trackDollyNear.m_PathPosition + addNum)%53
  
        trackDollyNear.m_PathPosition = res
        trackDollyFar.m_PathPosition = res
    end)
end

function XUiModelCerberusGame3D:StopTimer()
    if self.ChangeTimer then
        XScheduleManager.UnSchedule(self.ChangeTimer)
        self.ChangeTimer = nil
    end
end

function XUiModelCerberusGame3D:SetTargetModelUnSelect(index)
    local modelKey = ModelDic[index]
    local animator = self[modelKey]
    if not animator then
        return
    end

    local stateInfo = animator:GetCurrentAnimatorStateInfo(0)
    if stateInfo:IsName("Attack85") or stateInfo:IsName("Attack84") then
        animator:SetTrigger("DoPlayBack")
    end
end

function XUiModelCerberusGame3D:SetTargerModelSelect(index)
    local modelKey = ModelDic[index]
    local animator = self[modelKey]
    if not animator then
        return
    end

    local stateInfo = animator:GetCurrentAnimatorStateInfo(0)
    if stateInfo:IsName("Attack85") or stateInfo:IsName("Attack84") then
        return
    end
    animator:SetTrigger("DoPlaySelect")
end

function XUiModelCerberusGame3D:SetAllModelUnSelect()
    for modelIndex, modelKey in pairs(ModelDic) do
        self:SetTargetModelUnSelect(modelIndex)
    end
end

function XUiModelCerberusGame3D:SetAllModelCamFalse()
    for modelIndex, modelKey in pairs(ModelDic) do
        self["UiCamFar0"..modelIndex].gameObject:SetActiveEx(false)
        self["UiCamNear0"..modelIndex].gameObject:SetActiveEx(false)
    end
end

return XUiModelCerberusGame3D