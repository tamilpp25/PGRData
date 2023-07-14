-- 通用关卡词缀列表项控件
local XUiStageFightEventItem = XClass(nil, "XUiStageFightEventItem")
function XUiStageFightEventItem:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiStageFightEventItem:RefreshData(data)
    self.Cfg = data
    self.RImgIcon:SetRawImage(self.Cfg.Icon)
    self.TxtName.text = self.Cfg.Name
    self.TxtDesc.text = self.Cfg.Description
end
return XUiStageFightEventItem