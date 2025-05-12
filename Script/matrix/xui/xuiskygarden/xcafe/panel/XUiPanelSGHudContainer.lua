---@class XUiGridSGCafeHud : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiPanelSGHudContainer
---@field _TrailEffect UnityEngine.GameObject
local XUiGridSGCafeHud = XClass(XUiNode, "XUiGridSGCafeHud")

local HudType = XMVCA.XSkyGardenCafe.HudType
local Pivot = Vector2(0.5, 0.5)
local CsEase = CS.DG.Tweening.Ease

function XUiGridSGCafeHud:OnStart()
    self._Enable = self.Transform:Find("Animation/GridEnable")
end

function XUiGridSGCafeHud:OnEnable()
    self._TimerId = XScheduleManager.ScheduleOnce(function() 
        self:DoFlyToTarget()
        self._TimerId = nil
    end, 2000)
    self:PlayEnableAnimation()
    if self:IsFlyType() then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_BEGIN_FLY)
    end
end

function XUiGridSGCafeHud:IsFlyType()
    return self._Type == HudType.ReviewHud or self._Type == HudType.CoffeeHud
end

function XUiGridSGCafeHud:DoFlyToTarget()
    self._Frying = true
    if not self:IsFlyType() then
        self:OnFlyComplete()
        return
    end
    self:LoadTrailEffect()
    if not self._TrailEffect then
        self:OnFlyComplete()
        return
    end
    self._TrailEffect.transform.localPosition = Vector3.zero
    self._TrailEffect.gameObject:SetActiveEx(true)
    local position = self._Control:GetTargetWorldPosition(self._Type)
    self._MoveTimer = self.Transform:DOMove(position, 1.0):SetEase(CsEase.InOutCubic):OnComplete(function()
        self:OnFlyComplete()
    end)
end

function XUiGridSGCafeHud:OnFlyComplete()
    if self._TrailEffect then
        self._TrailEffect.gameObject:SetActiveEx(false)
    end
    self.Parent:HideHud(self._Id)
    if self._TrailEffect then
        self._TrailEffect.transform.localPosition = Vector3.zero
    end
    self._Frying = false
    
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_FLY_COMPLETE)
end

function XUiGridSGCafeHud:LoadTrailEffect()
    if self._TrailEffect then
        return
    end
    ---@type XUiEffectLayer
    local effectLayer = self.Transform:GetComponent("XUiEffectLayer")
    if not effectLayer then
        return
    end
    
    local url = self._Control:GetTrailEffectUrl(self._Type)
    if string.IsNilOrEmpty(url) then
        return
    end
    local effect = self.Transform:LoadPrefabEx(url)
    effectLayer:Init()
    
    self._TrailEffect = effect
end

function XUiGridSGCafeHud:OnDisable()
    self:OnDispose()
end

function XUiGridSGCafeHud:OnDestroy()
    self:OnDispose()
end

function XUiGridSGCafeHud:OnDispose()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end

    if self._MoveTimer then
        self._MoveTimer:Kill()
        self._MoveTimer = nil
    end

    if self._TrailEffect then
        self._TrailEffect.gameObject:SetActiveEx(false)
    end
end

function XUiGridSGCafeHud:InitTarget(target, offset)
    self._Target = target
    self._Offset = offset
end

function XUiGridSGCafeHud:UpdateTransform()
    if self._Frying then
        return
    end
    if XTool.UObjIsNil(self.GameObject) or XTool.UObjIsNil(self._Target) then
        return
    end

    if not self.GameObject.activeInHierarchy 
            or not self._Target.gameObject.activeInHierarchy then
        return
    end
    
    XMVCA.XBigWorldGamePlay:SetViewPosToTransformLocalPosition(self.Transform, self._Target, self._Offset, Pivot)
end

function XUiGridSGCafeHud:PlayEnableAnimation()
    if not self._Enable then
        return
    end
    self._Enable.transform:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiGridSGCafeHud:Refresh(id, target, offset, type, value)
    self._Id = id
    self._Type = type
    self:InitTarget(target, offset)
    self:Open()
    if type == HudType.EmojiHud then
        local valid = not string.IsNilOrEmpty(value)
        self.RImgExpression.gameObject:SetActiveEx(valid)
        if valid then
            self.RImgExpression:SetRawImage(value)
        end
    elseif type == HudType.ReviewHud or type == HudType.CoffeeHud then
        local isAdd = value >= 0
        self.TxtAdd.gameObject:SetActiveEx(isAdd)
        self.TxtMinus.gameObject:SetActiveEx(not isAdd)
        if isAdd then
            self.TxtAdd.text = string.format("+%s", value)
        else
            self.TxtMinus.text = value
        end
    end
end

function XUiGridSGCafeHud:OnDisable()
    self._Offset = nil
    self._Target = nil
end

---@class XUiPanelSGHudContainer : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiSkyGardenCafeComponent
---@field _Control XSkyGardenCafeControl
local XUiPanelSGHudContainer = XClass(XUiNode, "XUiPanelSGHudContainer")

function XUiPanelSGHudContainer:OnStart(uiGrid)
    if not XTool.UObjIsNil(uiGrid) then
        uiGrid.gameObject:SetActiveEx(false)
    end
    self._UiGrid = uiGrid
    self._ShowList = {}
    self._PoolList = {}
    self:InitCb()
    self:InitView()
end

function XUiPanelSGHudContainer:InitCb()
end

function XUiPanelSGHudContainer:InitView()
end

function XUiPanelSGHudContainer:RefreshView()
end

function XUiPanelSGHudContainer:Update()
    for _, grid in pairs(self._ShowList) do
        grid:UpdateTransform()
    end
end

function XUiPanelSGHudContainer:RefreshHud(id, target, offset, type, value)
    local grid
    if XTool.IsTableEmpty(self._PoolList) then
        local ui = XUiHelper.Instantiate(self._UiGrid, self.Transform)
        grid = XUiGridSGCafeHud.New(ui, self)
    else
        grid = table.remove(self._PoolList)
    end
    grid:Refresh(id, target, offset, type, value)
    self._ShowList[id] = grid
end

function XUiPanelSGHudContainer:HideHud(id)
    local grid = self._ShowList[id]
    if not grid then
        return
    end
    self._ShowList[id] = nil
    self._PoolList[#self._PoolList + 1] = grid
    grid:Close()
end

return XUiPanelSGHudContainer