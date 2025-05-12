local XRedPointConditionUiSceneSetting={}

function XRedPointConditionUiSceneSetting.Check()
    --检查已拥有的场景是否未使用过或未预览过
    local sceneCount = XDataCenter.PhotographManager.GetOwnSceneCount()
    -- 如果只有一个默认场景 则不需要蓝点
    if sceneCount == 1 then
        return false
    end

    local scenes = XDataCenter.PhotographManager.GetSceneIdList()
    for index, sceneId in pairs(scenes) do
        local checkData = XDataCenter.PhotographManager.CheckSceneIsNewInTempData(sceneId)
        local isHave = XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneId)
        if isHave and checkData then
            return true
        end
    end
    return false
end

return XRedPointConditionUiSceneSetting