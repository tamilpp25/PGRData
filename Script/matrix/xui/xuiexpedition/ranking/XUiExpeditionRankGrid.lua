-- 虚像地平线排行项控件
local XUiExpeditionRankGrid = XClass(nil, "XUiExpeditionRankGrid")
function XUiExpeditionRankGrid:Ctor()

end

function XUiExpeditionRankGrid:Init(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
    self.BtnComboList.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
end

--[[ XExpeditionRankData数据结构
int Id   玩家ID
string Name
int HeadPortraitId
int HeadFrameId
int Ranking
int StageId   最后通关的关卡ID
int NpcGroup  怪物波数
int DefaultTeamId  预设队伍ID
List<XExpeditionCharacter> FightCharacters
List<XExpeditionCharacter> OtherCharacters
]]

function XUiExpeditionRankGrid:RefreshData(rankingData, index)
    self.RankingData = rankingData
    self.Ranking = index
    XUiPLayerHead.InitPortrait(self.RankingData.HeadPortraitId, self.RankingData.HeadFrameId, self.Head)
    self.TxtPlayerName.text = self.RankingData.Name
    self:RefreshRankingText()
    self:RefreshRankScore()
end

function XUiExpeditionRankGrid:RefreshRankingText()
    local icon = XDataCenter.ExpeditionManager.GetRankSpecialIcon(self.Ranking)
    if icon then self.RootUi:SetUiSprite(self.ImgRankSpecial, icon) end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = self.Ranking
end

function XUiExpeditionRankGrid:RefreshRankScore()
    local endlessStage = self:GetEndlessStage()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local infinityInfo = eActivity:GetInfinityStageInfo()
    local totalScore = 0
    
    for i = 1, 3 do
        local grid = self["Rank0" .. i]
        local txtRankScore = XUiHelper.TryGetComponent(grid, "TxtRankScore", "Text")

        if i == 3 then
            txtRankScore.text = totalScore
            break
        end
        
        local stageId = infinityInfo[i]
        local score = 0
        
        if XTool.IsNumberValid(stageId) then
            score = endlessStage[stageId] or 0
        end
        txtRankScore.text = score
        totalScore = totalScore +score
    end
end

-- 获取无限关得分 Key 为StageId value 为分数
function XUiExpeditionRankGrid:GetEndlessStage()
    local endlessStage = self.RankingData.EndlessStage
    local tempStage = {}
    for _, info in pairs(endlessStage) do
        if info then
            tempStage[info.Stage] = info.Scores
        end
    end
    return tempStage
end

function XUiExpeditionRankGrid:OnBtnDetailClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankingData.Id)
end
return XUiExpeditionRankGrid