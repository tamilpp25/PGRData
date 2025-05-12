---@class XUiRogueSimComponent : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimComponent = XLuaUiManager.Register(XLuaUi, "UiRogueSimComponent")

function XUiRogueSimComponent:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.PanelAssetDetailBubble.gameObject:SetActiveEx(false)
    self.PanelBuffDetailBubble.gameObject:SetActiveEx(false)
    self.PanelPopulationBubble.gameObject:SetActiveEx(false)
    self.PanelPropertyBubble.gameObject:SetActiveEx(false)
end

function XUiRogueSimComponent:OnStart(type, ...)
    self.Type = type
    if type == XEnumConst.RogueSim.BubbleType.Buff then
        self:OpenBuffDetailBubble(...)
    elseif type == XEnumConst.RogueSim.BubbleType.AssetDetail then
        self:OpenResourceDetailBubble(...)
    elseif type == XEnumConst.RogueSim.BubbleType.Population then
        self:OpenPopulationBubble(...)
    elseif type == XEnumConst.RogueSim.BubbleType.Property then
        self:OpenCommodityPropertyBubble(...)
    end
end

-- 货物详情弹框
---@param targetTransform UnityEngine.RectTransform
---@param id number 货物Id
function XUiRogueSimComponent:OpenResourceDetailBubble(targetTransform, id)
    if not self.AssetDetailBubble then
        ---@type XUiPanelCommodityBubble
        self.AssetDetailBubble = require("XUi/XUiRogueSim/Component/XUiPanelCommodityBubble").New(self.PanelAssetDetailBubble, self)
    end
    self.AssetDetailBubble:Open()
    self.AssetDetailBubble:Refresh(targetTransform, id)
end

-- 人口描述弹框
---@param targetTransform UnityEngine.RectTransform
---@param id number 资源Id
function XUiRogueSimComponent:OpenPopulationBubble(targetTransform, id)
    if not self.PopulationBubble then
        ---@type XUiPanelPopulationBubble
        self.PopulationBubble = require("XUi/XUiRogueSim/Component/XUiPanelPopulationBubble").New(self.PanelPopulationBubble, self)
    end
    self.PopulationBubble:Open()
    self.PopulationBubble:Refresh(targetTransform, id)
end

-- 货物属性弹框
---@param targetTransform UnityEngine.RectTransform
---@param id number 货物Id
function XUiRogueSimComponent:OpenCommodityPropertyBubble(targetTransform, id, info)
    if not self.PropertyBubble then
        ---@type XUiPanelCommodityPropertyBubble
        self.PropertyBubble = require("XUi/XUiRogueSim/Component/XUiPanelCommodityPropertyBubble").New(self.PanelPropertyBubble, self)
    end
    self.PropertyBubble:Open()
    self.PropertyBubble:Refresh(targetTransform, id, info)
end

-- Buff详情弹框
---@param targetTransform UnityEngine.RectTransform
function XUiRogueSimComponent:OpenBuffDetailBubble(targetTransform, info)
    if not self.BuffDetailBubble then
        ---@type XUiPanelBuffDetailBubble
        self.BuffDetailBubble = require("XUi/XUiRogueSim/Component/XUiPanelBuffDetailBubble").New(self.PanelBuffDetailBubble, self)
    end
    self.BuffDetailBubble:Open()
    self.BuffDetailBubble:Refresh(targetTransform, info)
end

function XUiRogueSimComponent:OnBtnCloseClick()
    self:Close()
end

return XUiRogueSimComponent
