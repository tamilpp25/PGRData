---@class XUiGridFubenSnowGameMedal
local XUiGridFubenSnowGameMedal = XClass(nil,"XUiGridFubenSnowGameMedal")

function XUiGridFubenSnowGameMedal:Refresh(id, curRankId)
    --段位图标
    local icon = XFubenSpecialTrainConfig.GetRankIconById(id)
    self.RankIcon:SetSprite(icon)
    --段位名称
    self.TierName.text = XFubenSpecialTrainConfig.GetRankTierNameById(id)
    --当前段位奖杯数
    local IsLowestGrade = XFubenSpecialTrainConfig.CheckLowestGrade(id)
    self.RankStar.gameObject:SetActiveEx(not IsLowestGrade)
    if IsLowestGrade then
        self.Score.text = XFubenSpecialTrainConfig.GetRankTierDescribeById(id)
    else
        self.Score.text = XFubenSpecialTrainConfig.GetRankScoreById(id)
    end
    self.BgSelect.gameObject:SetActiveEx(id == curRankId)
end

return XUiGridFubenSnowGameMedal