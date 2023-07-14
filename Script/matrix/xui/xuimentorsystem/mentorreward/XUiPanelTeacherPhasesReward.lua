local XUiPanelTeacherPhasesReward = XClass(nil, "XUiPanelTeacherPhasesReward")
local XUiGridPhasesReward = require("XUi/XUiMentorSystem/MentorReward/XUiGridPhasesReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local Vector2 = CS.UnityEngine.Vector2

function XUiPanelTeacherPhasesReward:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.CollectionId = XMentorSystemConfigs.GetMentorSystemData("GraduateCollectionId")
end

function XUiPanelTeacherPhasesReward:SetButtonCallBack()
    self.BtnMedal.CallBack = function()
        self:OnBtnMedalClick()
    end
end

function XUiPanelTeacherPhasesReward:OnBtnMedalClick()
    local data = XDataCenter.MedalManager.GetMedalData(self.CollectionId)
    XLuaUiManager.Open("UiCollectionTip", data, XDataCenter.MedalManager.InType.Normal)
end

function XUiPanelTeacherPhasesReward:InitPhasesRewardGrid()
    self.PhasesRewardGrids = {}
    self.PhasesRewardGridRects = {}
    self.GridActive.gameObject:SetActiveEx(false)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local rewardList = mentorData:GetTeacherStageRewardList()
    local rewardCount = #rewardList
    for i = 1,rewardCount do
        local grid = self.PhasesRewardGrids[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridActive)
            obj.gameObject:SetActiveEx(true)
            obj.transform:SetParent(self.PanelContent, false)
            grid = XUiGridPhasesReward.New(obj, self, self.Root)
            self.PhasesRewardGrids[i] = grid
            self.PhasesRewardGridRects[i] = grid.Transform:GetComponent("RectTransform")
        end
    end
end

function XUiPanelTeacherPhasesReward:UpdatePanelPhasesReward()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    
    local icon = XDataCenter.MedalManager.GetMedalImg(self.CollectionId)
    local quality = XDataCenter.MedalManager.GetQuality(self.CollectionId)
    
    local levelIcon = XDataCenter.MedalManager.GetLevelIcon(self.CollectionId, quality)
    if levelIcon then
        self.IconLevel:SetSprite(levelIcon)
    end
    self.IconLevel.gameObject:SetActiveEx(levelIcon)
    
    self.IconMedal:SetRawImage(icon)
    self.TxtDailyActive.text = mentorData:GetGraduateStudentCount()
    self.TxtMax.text = string.format("/%d",mentorData:GetLastTeacherStageRewardCount())
    self.TextActive.text = CSTextManagerGetText("MentorTeacherPhasesRewardText")
    
    local rewardList = mentorData:GetTeacherStageRewardList()
    local rewardCount = #rewardList
    for i = 1, rewardCount do
        self.PhasesRewardGrids[i]:UpdateData(rewardList[i])
    end

    -- 自适应
    self.DaylyActiveProgressBg.sizeDelta = Vector2(rewardCount * self.GridActive.rect.width, self.DaylyActiveProgressBg.sizeDelta.y)
    self.PanelContent.sizeDelta = Vector2(rewardCount * self.GridActive.rect.width + self.GridActive.rect.width / 2, self.PanelContent.sizeDelta.y)
    self.ImgDaylyActiveProgress.fillAmount = mentorData:GetTeacherStageRewardAVGTotalPercent()
    
    local activeProgressRectSize = self.PanelContent.transform.rect.size
    for i = 1, #self.PhasesRewardGrids do
        local reward = rewardList[i]
        local valOffset = mentorData:GetTeacherStageRewardPercentByIndex(i)
        local adjustPosition = CS.UnityEngine.Vector3((activeProgressRectSize.x - self.GridActive.rect.width / 2) * valOffset, self.GridActive.anchoredPosition3D.y, 0)
        self.PhasesRewardGridRects[i].anchoredPosition3D = adjustPosition
    end
end
return XUiPanelTeacherPhasesReward