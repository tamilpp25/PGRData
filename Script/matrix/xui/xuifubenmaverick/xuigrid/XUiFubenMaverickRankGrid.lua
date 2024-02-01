local XUiFubenMaverickRankGrid = XClass(nil, "XUiFubenMaverickRankGrid")
local GetText = CS.XTextManager.GetText
local MinSpecialNum = 1
local MaxSpecialNum = 3

function XUiFubenMaverickRankGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)

    self:InitButtons()
end

function XUiFubenMaverickRankGrid:InitButtons()
    if (not self.IsMyself) and self.BtnDetail then
        self.BtnDetail.onClick:AddListener(function()
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankData.Id)
        end)
    end
end

function XUiFubenMaverickRankGrid:Refresh(data)
    self.RankData = data or self.RankData

    if self.IsMyself then
        if XTool.IsTableEmpty(self.RankData) then
            self.GameObject:SetActiveEx(false)
            return
        else
            self.GameObject:SetActiveEx(true)
        end
    end
    --排名数字
    local isSpecial = self.RankData.RankNum <= MaxSpecialNum and self.RankData.RankNum >= MinSpecialNum
    if isSpecial then
        self.ImgRankSpecial.gameObject:SetActiveEx(true)
        self.TxtRankNormal.gameObject:SetActiveEx(false)
        self.RootUi:SetUiSprite(self.ImgRankSpecial, XDataCenter.MaverickManager.GetNumIcon(self.RankData.RankNum))
    else
        self.ImgRankSpecial.gameObject:SetActiveEx(false)
        self.TxtRankNormal.gameObject:SetActiveEx(true)
        self.TxtRankNormal.text = self.RankData.RankNum
    end
    --自己的排名特殊处理
    if self.IsMyself then
        local isNotPlay = self.RankData.Score == 0
        self.TxtNotPlay.gameObject:SetActiveEx(isNotPlay)
        self.TxtNotInTop.gameObject:SetActiveEx(false) --fix:不需要的Ui
        self.ImgRankSpecial.gameObject:SetActiveEx((not isNotPlay) and isSpecial)
        self.TxtRankNormal.gameObject:SetActiveEx((not isNotPlay) and (not isSpecial))
        if (not isNotPlay) and self.RankData.RankNum > XDataCenter.MaverickManager.RankTopCount then --后Top名改成百分比显示
            self.TxtRankNormal.text = XMath.ToMinInt((self.RankData.RankNum / self.RootUi.MaxRankCount) * 100) .. "%"
        end
    end
    --玩家名称
    self.TxtPlayerName.text = self.RankData.Name
    --积分
    local rankScoreTextKey
    if self.IsMyself then
        rankScoreTextKey = "MaverickMyRankScore"
    else
        rankScoreTextKey = "MaverickRankScore"
    end
    self.TxtRankScore.text = GetText(rankScoreTextKey, self.RankData.Score)
    --玩家头像
    XUiPLayerHead.InitPortrait(self.RankData.HeadPortraitId, self.RankData.HeadFrameId, self.Head)
    --使用的角色的头像
    local robotId = self.RankData.RobotIds[1]
    if robotId then
        local charIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(robotId) --目前一次战斗只能上一个角色
        self.RImgTeam1:SetRawImage(charIcon)
        self.RImgTeam1.gameObject:SetActiveEx(true)
    else
        self.RImgTeam1.gameObject:SetActiveEx(false)
    end
end

return XUiFubenMaverickRankGrid