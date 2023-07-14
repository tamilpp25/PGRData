local XUiRpgMakerGameStage = require("XUi/XUiRpgMakerGame/Main/XUiRpgMakerGameStage")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--路线
local XUiRpgMakerGameStages = XClass(nil, "XUiRpgMakerGameStages")

function XUiRpgMakerGameStages:Ctor(ui, chapterId, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.CallBack = cb
    self.ChapterId = chapterId
    
    self.StageTemplateDic = {}
    self:InitStage()
end

function XUiRpgMakerGameStages:InitStage()
    local chapterId = self:GetChapterId()
    local stageIdList = XRpgMakerGameConfigs.GetRpgMakerGameStageIdList(chapterId)
    local stageGrid
    local prefabName
    local prefab

    for i, stageId in ipairs(stageIdList) do
        stageGrid = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Stage" .. i)
        stageGrid = stageGrid and XUiHelper.TryGetComponent(stageGrid.transform, "PanelGrid") or stageGrid
        if not stageGrid then
            XLog.Error(string.format("PanelStageContent下不存在%s，检查UI：%s和配置：%s，chapterId %s对应的stageId数量", 
                "Stage" .. i, self.GameObject.name, "RpgMakerGameStage", chapterId))
            goto continue
        end

        stageGrid.gameObject:SetActiveEx(true)
        prefabName = XRpgMakerGameConfigs.GetRpgMakerGameStagePrefab(stageId)
        prefab = stageGrid:LoadPrefab(prefabName)
        if prefab == nil or not prefab:Exist() then
            goto continue
        end

        self.StageTemplateDic[stageId] = XUiRpgMakerGameStage.New(prefab, stageId)

        :: continue ::
    end
end

function XUiRpgMakerGameStages:Refresh(newStageId)
    for _, stageTempalte in pairs(self.StageTemplateDic) do
        stageTempalte:Refresh(newStageId)
    end
end

function XUiRpgMakerGameStages:GetChapterId()
    return self.ChapterId
end

return XUiRpgMakerGameStages