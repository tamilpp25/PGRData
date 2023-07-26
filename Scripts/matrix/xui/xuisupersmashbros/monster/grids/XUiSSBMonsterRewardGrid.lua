
local XUiSSBMonsterRewardGrid = XClass(nil, "XUiSSBMonsterRewardGrid")

function XUiSSBMonsterRewardGrid:Ctor(uiPrefab, rootUi)
    --self:Init(uiPrefab, rootUi)
end

function XUiSSBMonsterRewardGrid:Init(uiPrefab, rootUi)
    XTool.InitUiObjectByUi(self, uiPrefab)
    --self.Reward = XUiGridCommon.New(rootUi, self.GridReward)
    local energyItem = require("XUi/XUiSuperSmashBros/Common/XUiSSBDisplayItem")
    self.Reward = energyItem.New(uiPrefab)
end
--==========
--刷新
--@param:
--isEnergy 是不是显示能量道具
--data: 当显示能量道具时这个表示道具数量，不是的时候表示道具Id
--==========
function XUiSSBMonsterRewardGrid:Refresh(data, isLevelItem)
    if isLevelItem then
        self.Reward:Refresh(XDataCenter.SuperSmashBrosManager.GetLevelItem(), data)
    elseif data then
        self.Reward:Refresh((data.TemplateId and data.TemplateId > 0) and data.TemplateId or data.Id, data.Count)
    end
end

return XUiSSBMonsterRewardGrid