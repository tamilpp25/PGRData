---@class XUiGridCharacterTowerBattleStar
local XUiGridCharacterTowerBattleStar = XClass(nil, "XUiGridCharacterTowerBattleStar")

function XUiGridCharacterTowerBattleStar:Ctor(ui, rootUi, treasureId, chapterId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self:InitAutoScript()
    self.TreasureId = treasureId
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    
    self:InitView()
end

function XUiGridCharacterTowerBattleStar:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridCharacterTowerBattleStar:AutoInitUi()
    self.BtnActive = self.Transform:Find("BtnActive"):GetComponent("Button")
    self.TxtValue = self.Transform:Find("TxtValue"):GetComponent("Text")
    self.PanelEffect = self.Transform:Find("PanelEffect")
    self.ImgRe = self.Transform:Find("ImgRe"):GetComponent("Image")
    self.GridCommon = self.Transform:Find("Grid128")
end

function XUiGridCharacterTowerBattleStar:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnActive, self.OnBtnActiveClick)
end

function XUiGridCharacterTowerBattleStar:InitView()
    self.RequireStar = XFubenCharacterTowerConfigs.GetRequireStarByTreasureId(self.TreasureId)
    self.TxtValue.text = self.RequireStar
    
    local rewardId = XFubenCharacterTowerConfigs.GetRewardIdByTreasureId(self.TreasureId)
    local data = XRewardManager.GetRewardList(rewardId)
    if #data >= 1 then
        self.GridCommon = XUiGridCommon.New(self.RootUi, self.GridCommon)
        self.GridCommon:Refresh(data[1])
    end
end

function XUiGridCharacterTowerBattleStar:Refresh(star)
    self.CurrentStar = star
    
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    if chapterInfo:CheckTreasureRewardReceived(self.TreasureId) then
        self:ChangeActiveState(true, false)
    else
        if self.CurrentStar >= self.RequireStar then
            self:ChangeActiveState(false, true)
        else
            self:ChangeActiveState(false, false)
        end
    end
end

function XUiGridCharacterTowerBattleStar:ChangeActiveState(imgRe, effect)
    self.ImgRe.gameObject:SetActive(imgRe)
    self.PanelEffect.gameObject:SetActive(effect)
end

function XUiGridCharacterTowerBattleStar:OnBtnActiveClick()
    if self.CurrentStar and self.TreasureId then
        local rewardId = XFubenCharacterTowerConfigs.GetRewardIdByTreasureId(self.TreasureId)
        local rewardList = XRewardManager.GetRewardList(rewardId)
        
        local chapterInfo = self.ChapterViewModel:GetChapterInfo()
        if chapterInfo:CheckTreasureRewardReceived(self.TreasureId) then
            self:ShowTips(rewardList)
        else
            if self.CurrentStar >= self.RequireStar then
                self:ReceiveAward(true)
            else
                self:ShowTips(rewardList)
            end
        end
    end
end

function XUiGridCharacterTowerBattleStar:ReceiveAward(isAnim)
    XDataCenter.CharacterTowerManager.CharacterTowerGetStarRewardRequest(self.ChapterId, self.TreasureId, function(rewards)
        self:ChangeActiveState(true, false)
        XUiManager.OpenUiObtain(rewards, CS.XTextManager.GetText("DailyActiveRewardTitle"), function()
            self.RootUi:OnRewardTaskFinish(isAnim)
        end, nil)
    end)
end

function XUiGridCharacterTowerBattleStar:ShowTips(rewardList)
    for _, v in pairs(rewardList or {}) do
        local templateId = v.TemplateId
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
        if goodsShowParams.RewardType == XRewardManager.XRewardType.Character then
            if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
                self.RootUi:Close()
            end
            XLuaUiManager.Open("UiCharacterDetail", templateId)
        elseif goodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
            if self.RootUi.Ui.UiData.UiType == CsXUiType.Tips then
                self.RootUi:Close()
            end
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(templateId)
        else
            XLuaUiManager.Open("UiTip", templateId)
        end
        break
    end
end

return XUiGridCharacterTowerBattleStar