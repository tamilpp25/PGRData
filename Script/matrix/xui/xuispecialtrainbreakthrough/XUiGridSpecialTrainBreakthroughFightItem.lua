local XUiGridYuanXiaoFightItem = require("XUi/XUiSpecialTrainYuanXiao/XUiGridYuanXiaoFightItem")
local XUiGridSpecialTrainBreakthroughFightItem = XClass(XUiGridYuanXiaoFightItem,
    "XUiGridSpecialTrainBreakthroughFightItem")

function XUiGridSpecialTrainBreakthroughFightItem:Ctor()
    self.DataItemNames = {XUiHelper.GetText("YuanXiaoText4"), XUiHelper.GetText("YuanXiaoText3")}
end

function XUiGridSpecialTrainBreakthroughFightItem:RefreshDataItem(data)
    if data then
        self.GridFightDataList[1]:Refresh(data.IsStageScoreMvp, data.StageScore or 0)
        self.GridFightDataList[2]:Refresh(data.IsScoreMvp, data.Score)
    else
        for _, grid in pairs(self.GridFightDataList) do
            grid:Refresh(false, 0)
        end
    end
end

function XUiGridSpecialTrainBreakthroughFightItem:GetHeadIcon(characterId, ...) 
    return XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId)
end
return XUiGridSpecialTrainBreakthroughFightItem
