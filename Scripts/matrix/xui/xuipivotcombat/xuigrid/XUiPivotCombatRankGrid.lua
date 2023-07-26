
local XUiPivotCombatRankGrid = XClass(nil, "XUiPivotCombatRankGrid")


function XUiPivotCombatRankGrid:Ctor(ui)
    
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitCB()
    --头像UI控件
    self.UiHeadList = { 
        self.RImgTeam1, self.RImgTeam2, self.RImgTeam3 
    }
end

function XUiPivotCombatRankGrid:InitCB()
    self.BtnDetail.onClick:AddListener(function()
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankItem:GetPlayerId())
    end)
end

function XUiPivotCombatRankGrid:Init(rootUi)
    self.RootUi = rootUi
end

--@type XPivotCombatRankItem {rankItem}
function XUiPivotCombatRankGrid:Refresh(rankItem)
    self.RankItem = rankItem or self.RankItem
    --分数
    self.TxtRankScore.text = CS.XTextManager.GetText("PivotCombatRankScore", self.RankItem:GetScoreWithoutTimeScore())
    --昵称
    self.TxtPlayerName.text = self.RankItem:GetName()
    --通关时间
    self.TxtRankTime.text = CS.XTextManager.GetText("PivotCombatRankTime", self.RankItem:GetFightTime())
    --排名
    local isTop = self.RankItem:IsTopOnTheList()
    self.ImgRankSpecial.gameObject:SetActiveEx(isTop)
    self.TxtRankNormal.gameObject:SetActiveEx(not isTop)
    if isTop then
        self.ImgRankSpecial:SetSprite(XPivotCombatConfigs.GetRankingIcon(self.RankItem:GetRanking()))
    else
        self.TxtRankNormal.text = self.RankItem:GetRanking()
    end
    --玩家头像
    XUiPLayerHead.InitPortrait(self.RankItem:GetHeadPortraitId(), self.RankItem:GetHeadFrameId(), self.Head)
    --通关角色头像
    self.RankItem:RefreshHeadList(self.UiHeadList)
end

return XUiPivotCombatRankGrid