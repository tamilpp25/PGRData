---@class XUi2023YuanXiaoRoomsceneChoiceGrid
local XUi2023YuanXiaoRoomsceneChoiceGrid = XClass(nil, "XUi2023YuanXiaoRoomsceneChoiceGrid")

function XUi2023YuanXiaoRoomsceneChoiceGrid:Ctor(ui)
    self._Data = false
    self._ClickCallback = false
    
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUi2023YuanXiaoRoomsceneChoiceGrid:Update(data)
    self._Data = data
    self.RImgBg:SetRawImage(data.Icon)
end

function XUi2023YuanXiaoRoomsceneChoiceGrid:UpdateSelected(dataSelected)
    self.Select.gameObject:SetActiveEx(self._Data == dataSelected)
end

function XUi2023YuanXiaoRoomsceneChoiceGrid:UpdateEquip(dataEquip)
    self.DressedTip.gameObject:SetActiveEx(self._Data == dataEquip)
end

function XUi2023YuanXiaoRoomsceneChoiceGrid:RegisterClick(callback)
    self._ClickCallback = callback
end

function XUi2023YuanXiaoRoomsceneChoiceGrid:Init()
    XUiHelper.RegisterClickEvent(self, self.Btn, function()
        if self._ClickCallback and self._Data then
            self._ClickCallback(self._Data)
        end
    end)
end

return XUi2023YuanXiaoRoomsceneChoiceGrid