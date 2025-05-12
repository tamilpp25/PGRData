---@class XUiGridTheatre4BubbleBuild : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4BubbleBuild
local XUiGridTheatre4BubbleBuild = XClass(XUiNode, "XUiGridTheatre4BubbleBuild")

function XUiGridTheatre4BubbleBuild:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    self.PanelEnough.gameObject:SetActiveEx(false)
    self.PanelNotEnough.gameObject:SetActiveEx(false)
    self.PanelCostGold.gameObject:SetActiveEx(false)
    self.EffectId = 0
    self:InitAlpha()
end

---@param talentId number 颜色天赋Id
function XUiGridTheatre4BubbleBuild:Refresh(talentId)
    self.TalentId = talentId
    -- 图标
    local icon = self._Control:GetColorTalentIcon(talentId)
    if icon and self.RImgBuild then
        self.RImgBuild:SetRawImage(icon)
    end
    -- 描述
    self.TxtDetail.text = self._Control:GetColorTalentDesc(talentId)
    -- 消耗
    local effectIds = self._Control.EffectSubControl:GetEffectIdsByTalentId(talentId)
    if XTool.IsTableEmpty(effectIds) then
        return
    end
    -- 默认取第一个效果
    self.EffectId = effectIds[1]
    -- 消耗
    local costCount, costType, costId = self._Control.EffectSubControl:GetEffectCostInfo(self.EffectId)
    local isEnough = self._Control.AssetSubControl:CheckAssetEnough(costType, costId, costCount, true)
    self.PanelEnough.gameObject:SetActiveEx(isEnough)
    self.PanelNotEnough.gameObject:SetActiveEx(not isEnough)
    local panelGo = isEnough and self.PanelEnough or self.PanelNotEnough
    local energy = XTool.InitUiObjectByUi({}, panelGo)
    local bpIcon = self._Control.AssetSubControl:GetAssetIcon(costType, costId)
    if bpIcon then
        energy.RImgEnergy:SetRawImage(bpIcon)
    end
    energy.TxtNum.text = costCount
end

function XUiGridTheatre4BubbleBuild:OnBtnBuildClick()
    if not self.Parent.IsClick then
        return
    end
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    -- 检查资产是否足够
    if not self._Control.EffectSubControl:CheckEffectAssetEnough(self.EffectId) then
        return
    end
    -- 检查建筑数量是否达到上限
    if self._Control.MapSubControl:CheckEffectBuildingCountLimit(nil, self.EffectId, true) then
        return
    end
    -- 先关闭当前界面，再打开建筑界面
    XLuaUiManager.PopThenOpen("UiTheatre4PopupBuild", self.TalentId, self.EffectId)
end

function XUiGridTheatre4BubbleBuild:PlayBuildInAnimation()
    self:PlayAnimation("GridBuildIn", function()
        if self.CanvasGroup then
            self.CanvasGroup.alpha = 1
        end
    end)
end

function XUiGridTheatre4BubbleBuild:InitAlpha()
    self.CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    if self.CanvasGroup then
        self.CanvasGroup.alpha = 0
    end
end

return XUiGridTheatre4BubbleBuild
