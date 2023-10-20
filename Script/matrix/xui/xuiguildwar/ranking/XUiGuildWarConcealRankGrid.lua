--region GridContent
--配合一下旧写法 新建个类
local XUiGuildWarConcealGrid = XClass(nil, "XUiGuildWarConcealGrid")
function XUiGuildWarConcealGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.BtnDetail.CallBack = function() self:OnDetial() end
    self.PlayerId = false;
end
--- data XGuildWarRankInfo
function XUiGuildWarConcealGrid:RefreshData(data)
    self.data = data
    --玩家头像
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self.PlayerId = data.Uid
    --玩家名字
    self.TxtPlayerName.text = data.Name
    --总分
    local point = 0
    for i,info in pairs(data.HideAreaMetas) do
        point = point + info.Point
    end
    self.TxtPointScore.text = point
    --排名显示
    local ranking = data.Rank
    if ranking <= 100 then
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
    --队伍头像
    for i=1,3 do
        local memberId = data.TeamLeaders[i]
        local parentObject = self["Team" .. i]
        local iconObject= self["RImgTeam" .. i]
        if memberId and not (memberId == 0) then
            local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(memberId)
            parentObject.gameObject:SetActiveEx(true)
            iconObject:SetRawImage(icon)
        else
            parentObject.gameObject:SetActiveEx(false)
        end
    end
    
end

function XUiGuildWarConcealGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildWarConcealGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarConcealGrid:OnDetial()
    XLuaUiManager.Open("UiGuildWarRankStage", self.data)
end
--endregion
--===================================================================

--公会战排位控件
local XUiGuildWarConcealRankGrid = XClass(nil, "XUiGuildWarConcealRankGrid")
function XUiGuildWarConcealRankGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.ConcealRank = XUiGuildWarConcealGrid.New(self.PanelPlayerRank)
end

function XUiGuildWarConcealRankGrid:RefreshData(data, rankTarget)
    self.ConcealRank:Show()
    self.ConcealRank:RefreshData(data)
end

return XUiGuildWarConcealRankGrid