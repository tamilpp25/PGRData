---@class XUiSpecialTrainBreakthroughRankTeamGrid
local XUiSpecialTrainBreakthroughRankTeamGrid = XClass(nil, "XUiSpecialTrainBreakthroughRankTeamGrid")

function XUiSpecialTrainBreakthroughRankTeamGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

---@param data SpecialTrainBreakthroughRankTeamData
function XUiSpecialTrainBreakthroughRankTeamGrid:Update(data)
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

    for i = 1, 3 do
        local dataPlayer = data.MemberInfo[i]
        local txtName = self["TxtPlayerName0" .. i]
        local uiHead = self["Head0" .. i]
        if dataPlayer then
            -- 昵称
            txtName.text = dataPlayer.Name
            -- 玩家头像
            XUiPlayerHead.InitPortrait(dataPlayer.HeadPortraitId, dataPlayer.HeadFrameId, uiHead)
            txtName.gameObject:SetActiveEx(true)
            uiHead.gameObject:SetActiveEx(true)

            XUiHelper.RegisterClickEvent(self, self["BtnInfoHead0" .. i], function()
                XDataCenter.PersonalInfoManager.ReqShowInfoPanel(dataPlayer.Id)
            end, true)
        else
            txtName.gameObject:SetActiveEx(false)
            uiHead.gameObject:SetActiveEx(false)
        end
    end

    -- 剩余轮次
    --self.TxtRound.text = data.Round

    -- 最高分数
    self.TxtScore.text = data.Score
end

return XUiSpecialTrainBreakthroughRankTeamGrid