---@class XUiGuildWarGuildGrid
local XUiGuildWarGuildGrid = XClass(nil, "XUiGuildWarGuildGrid")

function XUiGuildWarGuildGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiGuildWarGuildGrid:RefreshData(data)
    local guildIcon = XGuildConfig.GetGuildHeadPortraitIconById(data.IconId)
    self.ImgIcon:SetRawImage(guildIcon)
    self.TxtGuildName.text = data.Name
    self.TxtPointScore.text = data.Point
    self.TxtActiveScore.text = data.Activation
    local ranking = data.Rank
    if ranking <= 100 then
        --local icon = XDataCenter.SuperSmashBrosManager.GetRankingSpecialIcon(ranking)
        --if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
        self.TxtRankNormal.gameObject:SetActive(true)--icon == nil)
        self.ImgRankSpecial.gameObject:SetActive(false)--icon ~= nil)
        self.TxtRankNormal.text = ranking == 0 and "-" or ranking
    else
        local rankPercent = math.floor(ranking / data.MemberCount * 100)
        --向下取整低于1时应该也显示为1%
        if rankPercent < 1 then rankPercent = 1 end
        self.TxtRankNormal.gameObject:SetActive(true)
        self.ImgRankSpecial.gameObject:SetActive(false)
        self.TxtRankNormal.text = rankPercent .. "%"
    end
end

function XUiGuildWarGuildGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildWarGuildGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiGuildWarGuildGrid