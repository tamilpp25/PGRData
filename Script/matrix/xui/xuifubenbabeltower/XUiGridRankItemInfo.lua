---@class XUiGridRankItemInfo
local XUiGridRankItemInfo = XClass(nil, "XUiGridRankItemInfo")

local MAX_SPECIAL_NUM = 3

function XUiGridRankItemInfo:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
end

---@param uiRoot XUiFubenBabelTowerRank
function XUiGridRankItemInfo:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 刷新排名
function XUiGridRankItemInfo:Refresh(rankInfo)
    self.RankInfo = rankInfo
    self.TxtRankScore.text = string.format(CS.XTextManager.GetText("BabelTowerRankItemLevel"), rankInfo.Score)
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(rankInfo.PlayerId, rankInfo.Name)

    XUiPLayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)

    self.TxtRankNormal.gameObject:SetActive(rankInfo.Rank > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActive(rankInfo.Rank <= MAX_SPECIAL_NUM)
    if rankInfo.Rank <= MAX_SPECIAL_NUM then
        local icon = XFubenBabelTowerConfigs.RankIcon[rankInfo.Rank]
        self.UiRoot:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = rankInfo.Rank
    end
    -- 最短通关时间
    if self.TxtRankTime then
        local time = rankInfo.MinTime or 0
        self.TxtRankTime.text = XTime.TimestampToGameDateTimeString(time, "mm:ss")
    end
end

function XUiGridRankItemInfo:OnBtnDetailClick()
    if not self.RankInfo then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.PlayerId)
end

return XUiGridRankItemInfo
