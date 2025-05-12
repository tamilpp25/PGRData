---@class XUiSpecialTrainBreakthroughRankPersonalGrid
local XUiSpecialTrainBreakthroughRankPersonalGrid = XClass(nil, "XUiSpecialTrainBreakthroughRankPersonalGrid")

function XUiSpecialTrainBreakthroughRankPersonalGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

---@param data SpecialTrainBreakthroughRankPersonalData
function XUiSpecialTrainBreakthroughRankPersonalGrid:Update(data)
    --排名
    local ranking = data.Ranking
    if ranking ~= 0 then
        local isTop = ranking >= 1 and ranking <= 3
        self.ImgRankSpecial.gameObject:SetActiveEx(isTop)
        self.TxtRankNormal.gameObject:SetActiveEx(not isTop)
        if isTop then
            self.ImgRankSpecial:SetSprite(XUiHelper.GetRankIcon(ranking))
        else
            self.TxtRankNormal.text = ranking
        end
    else
        self.ImgRankSpecial.gameObject:SetActiveEx(false)
        self.TxtRankNormal.gameObject:SetActiveEx(true)
        self.TxtRankNormal.text = "--"--XUiHelper.GetText("UnionUnRank")
    end

    -- 昵称
    self.TxtName.text = data.Name

    -- 弱点伤害
    self.TxtHurt.text = data.PointScore or 0

    -- 最高分数
    self.TxtScore.text = data.Score or 0

    -- 玩家头像
    XUiPlayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
end

return XUiSpecialTrainBreakthroughRankPersonalGrid