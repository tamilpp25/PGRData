local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiStageMemoryRewardGrid : XUiNode
---@field _Control XStageMemoryControl
local XUiStageMemoryRewardGrid = XClass(XUiNode, "XUiStageMemoryRewardGrid")

function XUiStageMemoryRewardGrid:OnStart()
    ---@type XUiGridCommon
    self._GridCommon = XUiGridCommon.New(self, self.GridItem)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

---@param data XStageMemoryControlReward
function XUiStageMemoryRewardGrid:Update(data, index)
    self._Data = data
    self._Index = index
    if data and data.Rewards[index] then
        self:Open()
    else
        self:Close()
        return
    end
    if data.IsReceived then
        self.GetTag.gameObject:SetActiveEx(true)
        self.PanelEffect.gameObject:SetActiveEx(false)
    else
        self.GetTag.gameObject:SetActiveEx(false)
        if data.IsCanReceive then
            self.PanelEffect.gameObject:SetActiveEx(true)
        else
            self.PanelEffect.gameObject:SetActiveEx(false)
        end
    end
    local item = data.Rewards[index]
    --self.TxtNum.text = item.Count
    --
    --if self.ImgIcon then
    --    local id = item.TemplateId
    --    local icon = XItemConfigs.GetItemIconById(id)
    --    self.ImgIcon:SetRawImage(icon)
    --end
    self._GridCommon:Refresh(item)
end

function XUiStageMemoryRewardGrid:OnClick()
    local data = self._Data
    local index = self._Index
    if not data.IsReceived and data.IsCanReceive then
        self._Control:ReceiveReward(self._Data)
    else
        local itemId = data.Rewards[index]
        if itemId then
            XLuaUiManager.Open("UiTip", itemId)
        end
    end
end

return XUiStageMemoryRewardGrid