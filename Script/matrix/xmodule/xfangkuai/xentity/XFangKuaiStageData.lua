---@class XFangKuaiStageData 大方块关卡数据
local XFangKuaiStageData = XClass(nil, "XFangKuaiStageData")

function XFangKuaiStageData:Ctor()
    self:ResetData()
end

function XFangKuaiStageData:UpdateStageData(data)
    if not data then
        return
    end
    self.StageId = data.StageId
    self.LastLineNo = data.LastLineNo
    self.LastBlockId = data.LastBlockId
    self.Point = data.Point
    self.Round = data.Round
    self.ExtraRound = data.ExtraRound
    self.ItemIds = data.ItemIds
    self:UpdateBlocks(data.Blocks)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_UPDATESTAGE)
end

function XFangKuaiStageData:UpdateBlocks(datas)
    if not datas then
        return
    end
    self.Blocks = {}
    for _, data in pairs(datas) do
        self.Blocks[data.Id] = data
    end
end

function XFangKuaiStageData:ResetData()
    self.StageId = 0
    self.LastLineNo = 0
    self.LastBlockId = 0
    self.Point = 0
    self.Round = 0
    self.ExtraRound = 0
    self.ItemIds = {}
    self.Blocks = {}
end

return XFangKuaiStageData