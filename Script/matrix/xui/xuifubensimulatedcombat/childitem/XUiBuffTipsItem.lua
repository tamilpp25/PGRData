--词缀展示界面：词缀详细显示控件 
local XUiBuffTipsItem = XClass(nil, "XUiBuffTipsItem")
function XUiBuffTipsItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiBuffTipsItem:RefreshData(buffId)
    self.Cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(buffId)
    self:RefreshStageType()
end

function XUiBuffTipsItem:RefreshStageType()
    self.RImgIcon:SetRawImage(self.Cfg.Icon)
    self.TxtName.text = self.Cfg.Name
    self.TxtDesc.text = self.Cfg.Description
end

return XUiBuffTipsItem