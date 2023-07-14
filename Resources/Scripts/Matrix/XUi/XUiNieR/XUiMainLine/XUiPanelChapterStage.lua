local XUiPanelChapterStage = XClass(nil, "XUiPanelChapterStage")
local XUiGridNierStage = require("XUi/XUiNieR/XUiGridNierStage")

local ALL_STAGE_NUM = 5
local TIME_TWEEN = 0.75
function XUiPanelChapterStage:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    local parent = self.RootUi:GetNieRLineBanner()
    self.GridAssignNierStage = parent.GridAssignNierStage
    self.GridRepeatNierStage = parent.GridRepeatNierStage
    self.GridBossNierStage = parent.GridBossNierStage

    self.StageLine = {}
    self.StageNode = {}
    for index = 1, ALL_STAGE_NUM do
        self.StageLine[index] = self["Line"..index]
        self.StageNode[index] = self["Stage"..index]
    end

    self.GridList = {}
end

function XUiPanelChapterStage:UpdateAllInfo(chapterData)
   
    

    local stageIds = chapterData:GetNierChapterStageIds()
    local bossStageId = chapterData:GetNieRBossStageId()

    local nieRBoss = XDataCenter.NieRManager.GetNieRBossDataById(bossStageId) 
    local leftHp = nieRBoss:GetLeftHp()
    local maxHp = nieRBoss:GetMaxHp()

    local stageNum = #stageIds
    stageNum = stageNum > 4 and 4 or stageNum
   
    local needShowBossStage = false

    for index = 1, stageNum do
        local prefab = self.GridAssignNierStage
        local stageType = XNieRConfigs.NieRStageType.AssignStage
        local labelStr
        if XDataCenter.FubenManager.CheckStageIsUnlock(stageIds[index]) then
            if index == chapterData:GetNieRRepeatPoStagePos() then
                prefab = self.GridRepeatNierStage
                stageType = XNieRConfigs.NieRStageType.RepeatPoStage
                needShowBossStage = true
                labelStr =  chapterData:GetNieRRepeatPoStageLabel()
            end
            self:CreatStageNode(index, prefab)
            self.GridList[index]:UpdateNieRStageGrid(stageIds[index], stageType, index, labelStr)
            if self.StageNode[index] then
               self.StageNode[index].gameObject:SetActiveEx(true)
            end
            if index > 1 and self.StageLine[index-1] then
                self.StageLine[index-1].gameObject:SetActiveEx(true)
            end
        else
            self.StageNode[index].gameObject:SetActiveEx(false)
            if index > 1 and self.StageLine[index-1] then
                self.StageLine[index-1].gameObject:SetActiveEx(false)
            end
        end
    end
    
    if needShowBossStage then
        local prefab = self.GridBossNierStage
        local stageType = XNieRConfigs.NieRStageType.BossStage
        local index = stageNum + 1
        self:CreatStageNode(index, prefab)
        self.GridList[index]:UpdateNieRStageGrid(bossStageId, stageType, index)
        if self.StageNode[index] then
            self.StageNode[index].gameObject:SetActiveEx(true)
        end
        if not  XDataCenter.FubenManager.CheckStageIsUnlock(bossStageId) then
            if self.StageLine[index-1] then
                self.StageLine[index - 1].gameObject:SetActiveEx(true)
            end
            if self.StageLine[index] then
                self.StageLine[index].gameObject:SetActiveEx(false)
            end
        else
            self.StageLine[index - 1].gameObject:SetActiveEx(false)
            self.StageLine[index].gameObject:SetActiveEx(true)
        end   
    else
        local index = stageNum + 1
        if self.StageNode[index] then
            self.StageNode[index].gameObject:SetActiveEx(false)
        end
        
        if self.StageLine[index-1] then
            self.StageLine[index-1].gameObject:SetActiveEx(false)
        end
        if self.StageLine[index] then
            self.StageLine[index].gameObject:SetActiveEx(false)
        end
    end

end

function XUiPanelChapterStage:CreatStageNode(index, prefab)
    local grid
    if self.GridList[index] then
        grid = self.GridList[index]
    else
        if not self.StageNode[index] then return end 
        local ui = CS.UnityEngine.Object.Instantiate(prefab)
        grid = XUiGridNierStage.New(ui, self.RootUi)
        grid.Transform:SetParent(self.StageNode[index], false)
        grid.Transform:GetComponent("RectTransform").anchoredPosition = CS.UnityEngine.Vector2(0, 0)
        self.GridList[index] = grid
    end 
end


return XUiPanelChapterStage
