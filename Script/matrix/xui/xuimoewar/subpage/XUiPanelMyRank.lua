local XUiPanelMyRank = XClass(nil, "XUiPanelMyRank")

local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_SPECIAL_NUM = 3
local MAX_RANK_COUNT = 100

function XUiPanelMyRank:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiPanelMyRank:Refresh(rankMyData, rankType)
    if rankMyData then
        self.RankMyData = rankMyData
    else
        return
    end

    if rankMyData.Rank <= MAX_RANK_COUNT and rankMyData.Rank > 0 then
        self.TxtRankPercent.gameObject:SetActive(false)
        self.TxtRankNormal.gameObject:SetActive(math.floor(rankMyData.Rank) > MAX_SPECIAL_NUM)
        self.ImgRankSpecial.gameObject:SetActive(rankMyData.Rank <= MAX_SPECIAL_NUM)

        if rankMyData.Rank <= MAX_SPECIAL_NUM then
            local icon = XMoeWarConfig.RankIcon[rankMyData.Rank]
            self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
        else
            self.TxtRankNormal.text = math.floor(rankMyData.Rank)
        end
    else
        self.TxtRankPercent.gameObject:SetActive(true)
        self.TxtRankNormal.gameObject:SetActive(false)
        self.ImgRankSpecial.gameObject:SetActive(false)
        local text
        if rankMyData.Rank > 0 then
            if not rankMyData.MemberCount or rankMyData.MemberCount == 0 then
                text = CS.XTextManager.GetText("None")
            else
                local num = math.floor(rankMyData.Rank / rankMyData.MemberCount * 100)
                if num < 1 then
                    num = 1
                elseif num > 99 then
                    num = 99
                end

                text = CS.XTextManager.GetText("BossSinglePercentDesc", num)
            end
        else
            text = CS.XTextManager.GetText("None")
        end
        self.TxtRankPercent.text = text
    end

    local textPrefix = ""
    if rankType == XMoeWarConfig.RankType.Player then
        textPrefix = CSXTextManagerGetText("MoeWarRankPlayer")
    elseif rankType == XMoeWarConfig.RankType.Daily then
        textPrefix = CSXTextManagerGetText("MoeWarRankDaily")
    end
    self.TxtRankScore.text = CSXTextManagerGetText("MoeWarMyRankScore", textPrefix, rankMyData.Score)
    local name = XPlayer.Name
    self.TxtPlayerName.text = name

    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
end

function XUiPanelMyRank:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelMyRank:ShowPanel()
    self.GameObject:SetActive(true)
end

return XUiPanelMyRank