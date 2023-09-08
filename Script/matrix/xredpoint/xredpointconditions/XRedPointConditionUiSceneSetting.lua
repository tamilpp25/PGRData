local XRedPointConditionUiSceneSetting={}

function XRedPointConditionUiSceneSetting.Check()
    --检查已拥有的场景是否未使用过或未预览过
    local scenes=XDataCenter.PhotographManager.GetSceneIdList()
    for index, sceneId in ipairs(scenes) do
        if XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneId) then
            local state=XSaveTool.GetData(XDataCenter.PhotographManager.GetSceneStateKey(sceneId))
            local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)

            --state==1表示预览过，2表示使用过
            if not state and sceneTemplate.IsFree==0 then
                return true
            end
        end
    end
    return false
end

return XRedPointConditionUiSceneSetting