
---@class XUiGridAreaWarBlockCommon 节点通用类
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
local XUiGridAreaWarBlockCommon = XClass(nil, "XUiGridAreaWarBlockCommon")

function XUiGridAreaWarBlockCommon:Ctor(ui, ...)
    XTool.InitUiObjectByUi(self, ui)
    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClick)
    end
    if self.EffectAttack then
        self.EffectAttack.gameObject:SetActiveEx(false)
    end

    self:SetFighting(false)
    
    self.HideMaskCb = handler(self, self._HideMask)

    self.PanelJdEnable = self.Transform:FindTransform("PanelJdEnable")
    self.PanelJdDisable = self.Transform:FindTransform("PanelJdDisable")
    self.PanelMiniEnable = self.Transform:FindTransform("PanelMiniEnable")
    self.PanelMiniDisable = self.Transform:FindTransform("PanelMiniDisable")
    local animEnable = self.Transform:FindTransform("AnimEnable")

    if animEnable then
        ---@type UnityEngine.Playables.PlayableDirector
        self.AnimEnableDirector = animEnable.transform:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    end

    self.GridScale = self.Transform.localScale.x
    -- 只能在协程里调用
    self.SyncPlayLocation = function()
        if XTool.UObjIsNil(self.EffectLocation) then
            return
        end
        
        local valid = false
        while true do
            if XTool.UObjIsNil(self.GameObject) then
                break
            end

            if self.GameObject.activeInHierarchy then
                valid = true
                break
            end

            asynWaitSecond(0.2)
        end

        if valid then
            self:TrySetActive(self.EffectLocation, false)
            self:TrySetActive(self.EffectLocation, true)
        end
        asynWaitSecond(2)
        self:TrySetActive(self.EffectLocation, false)
    end

    self:InitUi(...)
end

function XUiGridAreaWarBlockCommon:InitUi()
end

function XUiGridAreaWarBlockCommon:Refresh(...)
end

--战斗中状态
function XUiGridAreaWarBlockCommon:SetFighting(value)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(value)
    end
end

function XUiGridAreaWarBlockCommon:OnClick()
end

function XUiGridAreaWarBlockCommon:SetVisible(visible)
    if not XTool.UObjIsNil(self.AnimEnableDirector) then
        self.AnimEnableDirector.playOnAwake = not self.IsSmall
    end
    self.GameObject:SetActiveEx(visible)

    if visible then
        self:TryPlayReward()
    else
        self:TrySetActive(self.EffectLocation, false)
        self:TrySetActive(self.EffectConvert, false)
    end
end

function XUiGridAreaWarBlockCommon:TrySetActive(obj, value)
    if XTool.UObjIsNil(obj) then
        return
    end
    obj.gameObject:SetActiveEx(value)
end

function XUiGridAreaWarBlockCommon:PlayNearAnim()
    self:TryPlayTimeLineAnimation(self.PanelJdEnable, true)
end

function XUiGridAreaWarBlockCommon:PlayFarAnim()
    self:TryPlayTimeLineAnimation(self.PanelJdDisable, true)
end

function XUiGridAreaWarBlockCommon:PlayMiniEnable()
    if XTool.UObjIsNil(self.PanelMiniEnable) then
        return
    end
    if self.IsSmall or not (self.PanelMiniEnable.gameObject.activeInHierarchy) then
        return
    end
    self.IsSmall = true
    self:TryPlayTimeLineAnimation(self.PanelMiniEnable)
end

function XUiGridAreaWarBlockCommon:PlayMiniDisable()
    if XTool.UObjIsNil(self.PanelMiniDisable) then
        return
    end
    if not self.IsSmall or not (self.PanelMiniDisable.gameObject.activeInHierarchy) then
        return
    end
    self.IsSmall = false
    self:TryPlayTimeLineAnimation(self.PanelMiniDisable)
end

function XUiGridAreaWarBlockCommon:_HideMask()
    XLuaUiManager.SetMask(false)
end

---@param transform UnityEngine.Transform
function XUiGridAreaWarBlockCommon:TryPlayTimeLineAnimation(transform, isShowMask)
    if XTool.UObjIsNil(transform) then
        return
    end

    if not (transform.gameObject.activeInHierarchy) then
        return
    end
    local func
    if isShowMask then
        XLuaUiManager.SetMask(true)
        func =  self.HideMaskCb
    end
    transform:PlayTimelineAnimation(func)
end

--- 旋转
---@param angle UnityEngine.Quaternion
--------------------------
function XUiGridAreaWarBlockCommon:Rotate(angle)
    if not XTool.UObjIsNil(self.PanelRotate) then
        self.PanelRotate.transform.localRotation = angle
    end
end

function XUiGridAreaWarBlockCommon:GetLinePoint(index)
    index = index or 1
    local obj = self["ImgPoint"..index]
    local parentPos = self.Transform.parent.localPosition
    if not obj then
        XLog.Error("创建连线失败!" .. self.GameObject.name .. ", 第" .. index .. "个节点!")
        return parentPos
    end
    return parentPos + (obj.transform.localPosition * self.GridScale)
end

function XUiGridAreaWarBlockCommon:GetBindParam()
end

function XUiGridAreaWarBlockCommon:TryPlayLocation()
    if XTool.UObjIsNil(self.EffectLocation) then
        return
    end
    
    RunAsyn(self.SyncPlayLocation)
end

function XUiGridAreaWarBlockCommon:TryPlayReward()
end

return XUiGridAreaWarBlockCommon