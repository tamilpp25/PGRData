---@class XUiBigWorldMapSelect : XUiNode
---@field PanelImgSelect UnityEngine.RectTransform
---@field Options XUiButtonGroup
---@field BtnOption XUiComponent.XUiButton
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapSelect = XClass(XUiNode, "XUiBigWorldMapSelect")

function XUiBigWorldMapSelect:OnStart()
    self._LevelId = 0
    ---@type XBWMapPinData[]
    self._PinDatas = {}

    self._OptionCache = {}

    self:_InitUi()
end

function XUiBigWorldMapSelect:OnOptionClick(index)
    local pinData = self._PinDatas[index]

    if pinData then
        self.Parent:OpenSelectPinDetail(self._LevelId, pinData)
    end
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMapSelect:Refresh(levelId, pinDatas, position)
    self._PinDatas = pinDatas
    self._LevelId = levelId
    self:_RefreshOptions(pinDatas)
    self:_RefreshPosition(position)
    self:_RefreshRing(position)
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMapSelect:_RefreshOptions(pinDatas)
    local optionList = {}

    if not XTool.IsTableEmpty(pinDatas) then
        for i, pinData in pairs(pinDatas) do
            local option = self._OptionCache[i]

            if not option then
                option = XUiHelper.Instantiate(self.BtnOption, self.Options.transform)
                self._OptionCache[i] = option
            end

            option.gameObject:SetActiveEx(true)
            option:SetNameByGroup(0, pinData.Name)
            table.insert(optionList, option)
        end
    end
    for i = table.nums(optionList) + 1, table.nums(self._OptionCache) do
        local option = self._OptionCache[i]

        option.gameObject:SetActiveEx(false)
    end

    self.Options:Init(optionList, Handler(self, self.OnOptionClick))
    self.Options:CancelSelect()

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Options.transform)
end

function XUiBigWorldMapSelect:_RefreshPosition(position)
    local selectPosition = self._Control:ScreenToRectPosition2D(self.Transform, position.x, position.y)

    if selectPosition then
        local optionPosition = {
            x = selectPosition.x + 30 + self.PanelImgSelect.rect.width,
            y = selectPosition.y - 10,
        }

        self.PanelImgSelect.anchoredPosition = selectPosition
        self:_RefreshOptionsPosition(selectPosition, optionPosition)
    end
end

function XUiBigWorldMapSelect:_RefreshOptionsPosition(centerPosition, optionPosition)
    local width = CS.UnityEngine.Screen.width
    local optionWidth = self.Options.transform.rect.width
    local optionHeight = self.Options.transform.rect.height
    local position = Vector2(optionPosition.x + optionWidth / 2, optionPosition.y + optionHeight / 2)

    if position.x + optionWidth + 30 > width then
        position.x = centerPosition.x - optionWidth - 30
    end
    if position.y - optionHeight - 10 <= 0 then
        position.y = optionHeight + 10
    end

    self.Options.transform.anchoredPosition = position
end

function XUiBigWorldMapSelect:_RefreshRing(position)
    local size = self._Control:GetNearDistance()
    local leftPos = self._Control:ScreenToRectPosition2D(self.Parent:GetMapObject(), position.x - size, position.y - size)
    local rightPos = self._Control:ScreenToRectPosition2D(self.Parent:GetMapObject(), position.x + size, position.y + size)
    local width = rightPos.x - leftPos.x

    if self.Ring then
        self.Ring.sizeDelta = Vector2(width, width)
    end
    if self.RingOut then
        self.RingOut.sizeDelta = Vector2(width + 20, width + 20)
    end
end

function XUiBigWorldMapSelect:_InitUi()
    self.Ring = self.Transform:FindTransform("Ring")
    self.RingOut = self.Transform:FindTransform("Ring2")
    self.BtnOption.gameObject:SetActiveEx(false)
end

return XUiBigWorldMapSelect
