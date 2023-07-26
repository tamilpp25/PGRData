---@class XUiGridFightEventBuff
local XUiGridFightEventBuff = XClass(nil, "XUiGridFightEventBuff")

function XUiGridFightEventBuff:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.RImgIcon:GetComponent("RawImage"), self.ShowInfo)
end

function XUiGridFightEventBuff:Refresh(showFightEventId)
    self.ShowFightEventId = showFightEventId
    local fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
    self.RImgIcon:SetRawImage(fightEventDetailConfig.Icon)
end

function XUiGridFightEventBuff:ShowInfo()
    local fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self.ShowFightEventId)
    XUiManager.UiFubenDialogTip(fightEventDetailConfig.Name, fightEventDetailConfig.Description)
end

return XUiGridFightEventBuff