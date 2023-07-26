--================
--词缀列表项控件
--================
local XUiSSBWordsWordsListGrid = XClass(nil, "XUiSSBWordsWordsListGrid")

function XUiSSBWordsWordsListGrid:Ctor()
    
end

function XUiSSBWordsWordsListGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBWordsWordsListGrid:Refresh(fightEventId)
    local details = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    self.RImgIcon:SetRawImage(details and details.Icon)
    self.TxtTitle.text = details and details.Name
    self.TxtDescription.text = details and details.Description
end

return XUiSSBWordsWordsListGrid