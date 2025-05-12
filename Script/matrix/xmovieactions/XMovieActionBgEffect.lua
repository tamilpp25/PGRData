local XMovieActionBgEffect = XClass(XMovieActionBase, "XMovieActionBgEffect")

function XMovieActionBgEffect:Ctor(actionData)
    local params = actionData.Params
    self.IsShowEffect = params[1] == "1"
    self.EffectPath = params[2]

    -- 特效类型
    self.EFFECT_TYPE = {
        SCREENSHOT = 1,     -- 屏幕截图特效类型
    }
    self.EffectType = self:GetEffectType()
end

function XMovieActionBgEffect:OnInit()
    -- 隐藏特效
    if not self.IsShowEffect then
        if self.UiRoot.BgEffectGo then
            self.UiRoot.BgEffectGo.gameObject:SetActiveEx(false)
        end
        return
    end

    if self.EffectType == self.EFFECT_TYPE.SCREENSHOT then
        local fullScreenBackground = self.UiRoot.RImgBg1.transform.parent
        self:LoadScreenshotEffect(fullScreenBackground)
    else
        self:LoadEffect(self.UiRoot.RImgBg1)
    end
end

-- 加载屏幕截图特效
function XMovieActionBgEffect:LoadScreenshotEffect(parent)
    -- 截图组件
    local component = self.UiRoot.UIScreenTrigger
    if not component then
        component = self.UiRoot.GameObject:AddComponent(typeof(CS.XACaptureUIScreenTrigger))
        self.UiRoot.UIScreenTrigger = component
    end
    component.enabled = false
    component.enabled = true

    -- 截图超过1帧再加载特效
    XScheduleManager.ScheduleOnce(function()
        self:LoadEffect(parent)
    end, 50)
end

-- 加载特效
---@param parent transform 特效挂点
function XMovieActionBgEffect:LoadEffect(parent)
    if not parent or not self.EffectPath then return end

    local effectGo = parent.transform:LoadPrefab(self.EffectPath)
    effectGo.gameObject:SetActive(false)
    effectGo.gameObject:SetActive(true)
    self.UiRoot.BgEffectGo = effectGo

    -- 通用组件处理
    -- 动态模糊组件
    local component = effectGo:GetComponent("XARawImageMaterialAnimationBinder")
    if component then
        component.enabled = true
        component:SetupRenderer(parent)
        component:PlayAnimation()
    end
end

-- 获取特效类型
function XMovieActionBgEffect:GetEffectType()
    -- 需要截图的特效
    local params = XMVCA.XMovie:GetClientConfigParams("ScreenshotEffect")
    for _, effectPath in ipairs(params) do
        if self.EffectPath == effectPath then
            return self.EFFECT_TYPE.SCREENSHOT
        end
    end
end

return XMovieActionBgEffect