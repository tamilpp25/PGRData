-- 虚像地平线排行项控件
local XUiExpeditionRankGrid = XClass(nil, "XUiExpeditionRankGrid")
local XTeam = require("XEntity/XExpedition/XExpeditionTeam")
function XUiExpeditionRankGrid:Ctor()

end

function XUiExpeditionRankGrid:Init(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
    self.BtnComboList.CallBack = function() self:OnBtnComboListClick() end
end

--[[ XExpeditionRankData数据结构
int Id   玩家ID
string Name
int HeadPortraitId
int HeadFrameId
int Ranking
int StageId   最后通关的关卡ID
int NpcGroup  怪物波数
List<XExpeditionCharacter> FightCharacters
List<XExpeditionCharacter> OtherCharacters
]]

function XUiExpeditionRankGrid:RefreshData(rankingData, index)
    self.RankingData = rankingData
    self.Ranking = index
    XUiPLayerHead.InitPortrait(self.RankingData.HeadPortraitId, self.RankingData.HeadFrameId, self.Head)
    self.TxtPlayerName.text = self.RankingData.Name
    self:RefreshStageProgress()
    self:RefreshRankingText()
    self:RefreshRolePanel()
end

function XUiExpeditionRankGrid:RefreshStageProgress()
    local eStage = XDataCenter.ExpeditionManager.GetEStageByStageId(self.RankingData.StageId)
    if not eStage then return end
    if eStage:GetIsInfinity() then
        local wave = self.RankingData.NpcGroup > 0 and (self.RankingData.NpcGroup - 1) or 0
        self.TxtRankScore.text = CS.XTextManager.GetText("ExpeditionRankingWaveStr", wave)
    else
        self.TxtRankScore.text = eStage:GetStageName()
    end
end

function XUiExpeditionRankGrid:RefreshRankingText()
    local icon = XDataCenter.ExpeditionManager.GetRankSpecialIcon(self.Ranking)
    if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = self.Ranking
end

function XUiExpeditionRankGrid:RefreshRolePanel()
    local roleNum = self.RankingData.FightCharacters and #self.RankingData.FightCharacters or 0
    for i = 1, 3 do
        local grid = {}
        XTool.InitUiObjectByUi(grid, self["GridRole" .. i].gameObject)
        if grid and i > roleNum or self.RankingData.FightCharacters[i].ECharacterId == 0 then
            grid.GameObject:SetActiveEx(false)
        elseif grid and i <= roleNum then
            grid.GameObject:SetActiveEx(true)
            local eCharaCfg = XExpeditionConfig.GetCharacterCfgById(self.RankingData.FightCharacters[i].ECharacterId)
            local characterId = XExpeditionConfig.GetCharacterIdByBaseId(eCharaCfg.BaseId)
            local fashionId = XCharacterConfigs.GetCharacterTemplate(characterId).DefaultNpcFashtionId
            grid.RawImage:SetRawImage(XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId))
            grid.TxtLevel.text = eCharaCfg.Rank
        end
    end
end

function XUiExpeditionRankGrid:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankingData.Id)
end

function XUiExpeditionRankGrid:OnBtnComboListClick()
    local eCharaIds = {}
    if self.RankingData.FightCharacters then
        for _, data in pairs(self.RankingData.FightCharacters) do
            table.insert(eCharaIds, data.ECharacterId)
        end
    end
    if self.RankingData.OtherCharacters then
        for _, data in pairs(self.RankingData.OtherCharacters) do
            table.insert(eCharaIds, data.ECharacterId)
        end 
    end
    local tempTeam = XTeam.New()
    tempTeam:InitTeamPos(XDataCenter.ExpeditionManager.GetCurrentChapter():GetChapterId())
    tempTeam:AddMemberListByECharaIds(eCharaIds)
    XLuaUiManager.Open("UiExpeditionComboTips", nil, tempTeam)
end
return XUiExpeditionRankGrid