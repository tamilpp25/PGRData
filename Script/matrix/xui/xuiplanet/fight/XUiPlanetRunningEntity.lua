local XUiPlanetUtil = require("XUi/XUiPlanet/Explore/View/XUiPlanetUtil")
local MAX_ACTION_POINT = 100

---@class XUiPlanetRunningEntity
local XUiPlanetRunningEntity = XClass(nil, "XUiPlanetRunningEntity")

function XUiPlanetRunningEntity:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Mover = self.Transform.parent.parent.transform
    self.Position = self:GetPositionOriginal()
    self.PositionAttacker = false

    self._TargetActionPoint = 0
    self._CurrentActionPoint = 0

    self.EffectBoom = self.EffectBoom or XUiHelper.TryGetComponent(self.Transform, "EffectBoom", "RectTransform")
    self.EffectTrail = self.EffectTrail or XUiHelper.TryGetComponent(self.Transform, "EffectTrail", "RectTransform")

    self._ComponentCanvas = XUiHelper.TryGetComponent(self.Transform, "", "Canvas")
    if self._ComponentCanvas then
        self._OrderInLayerNormal = self._ComponentCanvas.sortingOrder
        -- 因为特效的层级设置了24，最多6个角色，都有canvas，这里写40，在攻击时提高层级
        self._OrderInLayerOnAttack = self._OrderInLayerNormal + 40
    end
    self:Init()
end

function XUiPlanetRunningEntity:Init()
    self.ProgressHp.fillAmount = 0
    self.ProgressAction.fillAmount = 0
    self:HideHurt()
    self:HideCritical()
    self:HideEffectBeAttack()
    self:HideEffectMove()
end

function XUiPlanetRunningEntity:SetTargetActionPoint(value)
    self._CurrentActionPoint = self._TargetActionPoint
    self._TargetActionPoint = value
end

function XUiPlanetRunningEntity:SetMaxTargetActionPoint()
    self:SetTargetActionPoint(MAX_ACTION_POINT)
end

-- 行动条
function XUiPlanetRunningEntity:UpdateProgressAction(progress)
    local actionPoint = self._TargetActionPoint - self._CurrentActionPoint
    actionPoint = actionPoint * progress
    local fillAmount = self._CurrentActionPoint + actionPoint
    self.ProgressAction.fillAmount = fillAmount / MAX_ACTION_POINT
end

function XUiPlanetRunningEntity:ResetProgressAction()
    self._CurrentActionPoint = 0
    self._TargetActionPoint = 0
    --self.ProgressAction.fillAmount = 0
end

function XUiPlanetRunningEntity:SetHp(entity)
    if not entity then
        XLog.Error("[XUiPlanetRunningEntity] set hp failed, no target")
        return
    end
    local hp = entity.Attribute.Life
    local hpMax = math.max(1, entity.Attribute.MaxLife)
    self.ProgressHp.fillAmount = hp / hpMax
    XUiPlanetUtil.SetHp(self.ProgressHp, hp / hpMax)
    self.TextHp.text = string.format("%d/%d", math.floor(hp), math.floor(hpMax))
    if hp <= 0 then
        self.ProgressAction.fillAmount = 0
    end
end

function XUiPlanetRunningEntity:SetPosition(position)
    self.Mover.localPosition = position
end

function XUiPlanetRunningEntity:GetPositionOriginal()
    return self.Mover.localPosition
end

function XUiPlanetRunningEntity:ResetPosition()
    self:SetPosition(self.Position)
end

function XUiPlanetRunningEntity:SetPositionAttacker(position)
    self.PositionAttacker = position
end

function XUiPlanetRunningEntity:SetHurt(value)
    local text = string.format("-%d", math.abs(math.floor(value)))
    self.ComboCountText:TextToSprite(text, 0)
end

function XUiPlanetRunningEntity:HideHurt()
    self.ComboCountText:TextToSprite("", 0)
end

function XUiPlanetRunningEntity:SetIcon(icon)
    self.ImgIcon:SetRawImage(icon)
end

function XUiPlanetRunningEntity:ShowCritical()
    self.PanelIconBaoji.gameObject:SetActiveEx(true)
end

function XUiPlanetRunningEntity:HideCritical()
    self.PanelIconBaoji.gameObject:SetActiveEx(false)
end

function XUiPlanetRunningEntity:ShowSeckill()
    self.PanelIcoMiaosha.gameObject:SetActiveEx(true)
end

function XUiPlanetRunningEntity:HideSeckill()
    self.PanelIcoMiaosha.gameObject:SetActiveEx(false)
end

function XUiPlanetRunningEntity:ShowEffectBeAttack()
    self.EffectBoom.gameObject:SetActiveEx(true)
end

function XUiPlanetRunningEntity:HideEffectBeAttack()
    self.EffectBoom.gameObject:SetActiveEx(false)
end

function XUiPlanetRunningEntity:ShowEffectMove()
    self.EffectTrail.gameObject:SetActiveEx(true)
end

function XUiPlanetRunningEntity:HideEffectMove()
    self.EffectTrail.gameObject:SetActiveEx(false)
end

function XUiPlanetRunningEntity:SetOrderInLayerAttack()
    if self._ComponentCanvas then
        self._ComponentCanvas.sortingOrder = self._OrderInLayerOnAttack
    end
end

function XUiPlanetRunningEntity:SetOrderInLayerNormal()
    if self._ComponentCanvas then
        self._ComponentCanvas.sortingOrder = self._OrderInLayerNormal
    end
end

return XUiPlanetRunningEntity