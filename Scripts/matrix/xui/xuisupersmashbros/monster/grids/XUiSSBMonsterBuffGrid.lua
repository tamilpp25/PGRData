
local XUiSSBMonsterBuffGrid = XClass(nil, "XUiSSBMonsterBuffGrid")

function XUiSSBMonsterBuffGrid:Ctor(uiPrefab)
    
end

function XUiSSBMonsterBuffGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBMonsterBuffGrid:Refresh(fightEventId)
    local details = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    self.RImgIcon:SetRawImage(details and details.Icon)
end

return XUiSSBMonsterBuffGrid