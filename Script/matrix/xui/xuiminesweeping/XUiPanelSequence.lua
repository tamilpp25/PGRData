local XUiPanelSequence = XClass(nil, "XUiPanelSequence")
local XUiGridStageReward = require("XUi/XUiMineSweeping/XUiGridStageReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
function XUiPanelSequence:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self.RewardList = {}
    self.GridStageReward.gameObject:SetActiveEx(false)
end

function XUiPanelSequence:UpdatePanel(curCharterIndex)
    if curCharterIndex then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(curCharterIndex)
        local img = chapterEntity:GetAllMineImg()
        self.MineSweepingRawImage:SetRawImage(img)
        self:UpdateReward(chapterEntity)
    end
end

function XUiPanelSequence:UpdateReward(chapterEntity)
    local stageList = chapterEntity:GetStageEntityDic()
    local stageCount = chapterEntity:GetStageCount()
    stageCount = math.max(stageCount, 1)
    
    local width = self.MineSweepingRawImage.transform:GetComponent("RectTransform").sizeDelta.x / stageCount
    local high = self.MineSweepingRawImage.transform:GetComponent("RectTransform").sizeDelta.y
    for index = 1, stageCount do
        if not self.RewardList[index] then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridStageReward, self.PanelAward)
            self.RewardList[index] = XUiGridStageReward.New(obj, self.Base)
        end
        local id = chapterEntity:GetShowActivityStageIdByIndex(index)
        local entity = stageList[id]
        self.RewardList[index].GameObject:SetActiveEx(true)
        self.RewardList[index].Transform:GetComponent("RectTransform").sizeDelta = Vector2(width, high)
        self.RewardList[index].Transform.localPosition = Vector3(width * index - width / 2, 0, 0)
        self.RewardList[index]:UpdateGrid(entity)
    end
    
    for index = stageCount + 1, #self.RewardList do
        self.RewardList[index].GameObject:SetActiveEx(false)
    end
end

function XUiPanelSequence:CheckPlayGridAnime()
    for _,grid in pairs(self.RewardList or {}) do
        grid:CheckPlayAnime()
    end
end

function XUiPanelSequence:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiPanelSequence