---@class XUiPanelRogueSimMapDistance : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimMapDistance = XClass(XUiNode, "XUiPanelRogueSimMapDistance")

function XUiPanelRogueSimMapDistance:OnStart()
    local params = self._Control:GetClientConfigParams("CameraDistanceRange")
    self.MinValue = tonumber(params[1])
    self.MaxValue = tonumber(params[2])
    self.OnceChangeValue = tonumber(params[3])
    self.ScrollStrengthen = tonumber(params[4]) -- 滚轮效果加强倍数
    self.DistanceSlider.minValue = self.MinValue
    self.DistanceSlider.maxValue = self.MaxValue
    self:RegisterUiEvents()
end

function XUiPanelRogueSimMapDistance:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_UP,
        XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_DOWN,
    }
end

function XUiPanelRogueSimMapDistance:OnNotify(event, ...)
    local scrollValue = ...
    local changeValue = scrollValue * self.ScrollStrengthen
    if event == XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_UP then
        self:ChangeDistanceSlider(changeValue)
    elseif event == XEventId.EVENT_ROGUE_SIM_MID_BUTTON_SCROLL_DOWN then
        self:ChangeDistanceSlider(changeValue)
    end
end

function XUiPanelRogueSimMapDistance:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnClickBtnAdd)
    XUiHelper.RegisterClickEvent(self, self.BtnReduce, self.OnClickBtnReduce)
    self.DistanceSlider.onValueChanged:AddListener(function(val)
        local cameraDistance = self:SliderValueToCameraDistance(val)
        self._Control:SetCameraDistance(cameraDistance)
    end)
    
    -- 监听pc滚轮
    self.Parent.InputHandler:AddMidButtonScrollUpListener(function(val)
        self:ChangeDistanceSlider(val * self.ScrollStrengthen)
    end)
    self.Parent.InputHandler:AddMidButtonScrollDownListener(function(val)
        self:ChangeDistanceSlider(val * self.ScrollStrengthen)
    end)
end

function XUiPanelRogueSimMapDistance:OnClickBtnAdd()
    self:ChangeDistanceSlider(self.OnceChangeValue)
end

function XUiPanelRogueSimMapDistance:OnClickBtnReduce()
    self:ChangeDistanceSlider(-self.OnceChangeValue)
end

function XUiPanelRogueSimMapDistance:ChangeDistanceSlider(changeValue)
    local curValue = self.DistanceSlider.value
    if (changeValue > 0 and curValue >= self.MaxValue) or (changeValue < 0 and curValue <= self.MinValue) then 
        return
    end
    local result = curValue + changeValue
    if result > self.MaxValue then
        result = self.MaxValue
    elseif result < self.MinValue then
        result = self.MinValue
    end
    self.DistanceSlider.value = result
end

function XUiPanelRogueSimMapDistance:Refresh()
    local cameraDistance = self._Control:GetClientConfig("CameraDistance")
    self.DistanceSlider.value = self:CameraDistanceToSliderValue(tonumber(cameraDistance))
end

-- 滑动条的值越大，高度越低。滑动条的值越小，高度越高。
-- 滑动条值转摄像机高度
function XUiPanelRogueSimMapDistance:SliderValueToCameraDistance(sliderValue)
    return self.MaxValue + self.MinValue - sliderValue
end

-- 摄像机高度转滑动条值
function XUiPanelRogueSimMapDistance:CameraDistanceToSliderValue(cameraDistance)
    return self.MaxValue + self.MinValue - cameraDistance
end

return XUiPanelRogueSimMapDistance
