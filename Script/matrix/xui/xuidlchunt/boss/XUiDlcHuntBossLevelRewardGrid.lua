---@class XUiDlcHuntBossLevelRewardGrid
local XUiDlcHuntBossLevelRewardGrid = XClass(nil, "XUiDlcHuntBossLevelRewardGrid")

function XUiDlcHuntBossLevelRewardGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self._Data = false
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
        self:OnClick()
    end)
end

function XUiDlcHuntBossLevelRewardGrid:Update(data)
    self._Data = data
    local id = data.TemplateId
    local itemIcon = XItemConfigs.GetItemIconById(id)
    local quality = XItemConfigs.GetQualityById(id)
    self.RImgIcon:SetRawImage(itemIcon)
    local color = XDlcHuntChipConfigs.GetQualityColor(quality)
    if color then
        self.ImgQuality.color = color
    end
end

function XUiDlcHuntBossLevelRewardGrid:OnClick()
    if not self._Data then
        return
    end
    local item = XDataCenter.ItemManager.GetItem(self._Data.TemplateId)
    XLuaUiManager.Open("UiDlcHuntTip", item)
end

return XUiDlcHuntBossLevelRewardGrid
