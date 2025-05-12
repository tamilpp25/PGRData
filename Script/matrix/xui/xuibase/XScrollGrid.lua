local XScrollGrid = XClass(nil, "XScrollGrid")

--==============================--
--desc: 活动列表节点
--@ui: 节点ui
--==============================--
function XScrollGrid:Ctor(rootUi, ui)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject

    self.Rect = self.Transform:GetComponent("RectTransform")
    self.GameObject:SetActive(true)
    self.CurveValue = 0
end

function XScrollGrid:SetIndex(index)
    self.Index = index
end

function XScrollGrid:SetParent(parent)
    self.Parent = parent
    self.Transform:SetParent(parent.Transform, false)
end

--==============================--
--desc: 滑动回掉
--@addValue: 增加的曲线值
--==============================--
function XScrollGrid:OnDrag()
    -- Override this function
end

return XScrollGrid