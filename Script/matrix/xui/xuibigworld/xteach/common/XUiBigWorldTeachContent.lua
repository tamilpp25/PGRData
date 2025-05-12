local XUiBigWorldTeachVisual = require("XUi/XUiBigWorld/XTeach/Common/XUiBigWorldTeachVisual")
local XUiBigWorldTeachDot = require("XUi/XUiBigWorld/XTeach/Common/XUiBigWorldTeachDot")

---@class XUiBigWorldTeachContent : XUiNode
---@field Visual UnityEngine.RectTransform
---@field PanelDot UnityEngine.RectTransform
---@field GridDot UnityEngine.RectTransform
---@field BtnLast XUiComponent.XUiButton
---@field BtnNext XUiComponent.XUiButton
---@field TxtTeachTitle UnityEngine.UI.Text
---@field TxtTeach UnityEngine.UI.Text
---@field _Control XBigWorldTeachControl
local XUiBigWorldTeachContent = XClass(XUiNode, "XUiBigWorldTeachContent")

function XUiBigWorldTeachContent:OnStart()
    self._TeachId = 0
    self._DotCount = 0
    self._CurrentIndex = 1

    ---@type XUiBigWorldTeachVisual
    self._VisualUi = XUiBigWorldTeachVisual.New(self.Visual, self)

    ---@type XUiBigWorldTeachDot[]
    self._TeachDotList = {}

    self:_RegisterButtonClicks()
end

function XUiBigWorldTeachContent:Refresh(teachId)
    self._TeachId = teachId
    self._CurrentIndex = 1

    self:_Refresh()
end

function XUiBigWorldTeachContent:OnBtnLastClick()
    self:_RefreshContent(self._CurrentIndex - 1, self._CurrentIndex)
    self:_RefreshButton()
end

function XUiBigWorldTeachContent:OnBtnNextClick()
    self:_RefreshContent(self._CurrentIndex + 1, self._CurrentIndex)
    self:_RefreshButton()
end

function XUiBigWorldTeachContent:_Refresh()
    self:_RefreshPanel()
    self:_RefreshDotList()
    self:_RefreshContent(self._CurrentIndex)
    self:_RefreshButton()
end

function XUiBigWorldTeachContent:_RefreshPanel()
    self.TxtTeachTitle.text = self._Control:GetTeachTitleByTeachId(self._TeachId)
end

function XUiBigWorldTeachContent:_RegisterButtonClicks()
    self.BtnLast.CallBack = Handler(self, self.OnBtnLastClick)
    self.BtnNext.CallBack = Handler(self, self.OnBtnNextClick)
end

function XUiBigWorldTeachContent:_RefreshContent(index, oldIndex)
    self._CurrentIndex = index
    self.TxtTeach.text = self._Control:GetTeachContentDescByTeachIdAndIndex(self._TeachId, index)
    self._VisualUi:Refresh(self._Control:GetTeachContentIdByTeachIdAndIndex(self._TeachId, index))
    self:_RefreshCurrentDot(oldIndex)
end

function XUiBigWorldTeachContent:_RefreshDotList()
    local count = self._Control:GetTeachContentCountByTeachId(self._TeachId)

    self._DotCount = count
    for i = 1, count do
        local dot = self._TeachDotList[i]

        if not dot then
            local dotGrid = XUiHelper.Instantiate(self.GridDot, self.PanelDot)

            dot = XUiBigWorldTeachDot.New(dotGrid, self)
            self._TeachDotList[i] = dot
        end

        dot:Open()
        dot:Refresh(i == self._CurrentIndex)
    end
    for i = count + 1, table.nums(self._TeachDotList) do
        self._TeachDotList[i]:Close()
    end
    self.GridDot.gameObject:SetActiveEx(false)
end

function XUiBigWorldTeachContent:_RefreshCurrentDot(oldIndex)
    local dot = self._TeachDotList[self._CurrentIndex]

    if dot then
        dot:Refresh(true)
    end
    if oldIndex then
        local oldDot = self._TeachDotList[oldIndex]

        if oldDot then
            oldDot:Refresh(false)
        end
    end
end

function XUiBigWorldTeachContent:_RefreshButton()
    if self._DotCount == 1 then
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnLast.gameObject:SetActiveEx(false)
    else
        self.BtnNext.gameObject:SetActiveEx(true)
        self.BtnLast.gameObject:SetActiveEx(true)
        if self._CurrentIndex < self._DotCount then
            self.BtnNext:SetDisable(false)
        else
            self.BtnNext:SetDisable(true, false)
        end
        if self._CurrentIndex > 1 then
            self.BtnLast:SetDisable(false)
        else
            self.BtnLast:SetDisable(true, false)
        end
    end
end

return XUiBigWorldTeachContent
