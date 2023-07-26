local tableSort = table.sort
local tableInsert = table.insert

local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XCharacterTowerViewModel = require("XEntity/XCharacterTower/XCharacterTowerViewModel")

-- 角色列表排序
local CharactersSortFunc = function(a, b)
    local inActivityA = a:CheckHasInActivityTag()
    local inActivityB = b:CheckHasInActivityTag()
    if inActivityA ~= inActivityB then
        return inActivityA
    end
    if a:GetPriority() ~= b:GetPriority() then
        return a:GetPriority() > b:GetPriority()
    end
    return a:GetId() > b:GetId()
end

---@class XExFubenCharacterTowerManager : XExFubenBaseManager
local XExFubenCharacterTowerManager = XClass(XExFubenBaseManager, "XExFubenCharacterTowerManager")

---@param viewModel XCharacterTowerViewModel
function XExFubenCharacterTowerManager:ExOpenChapterUi(viewModel)
    local id = viewModel:GetId()
    local isUnlock, tips = XDataCenter.CharacterTowerManager.IsUnlock(id)
    if not isUnlock then
        XUiManager.TipError(tips)
        return
    end
    local storyChapterIds = viewModel:GetChapterIdsByChapterType(XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story)
    local challengeChapterIds = viewModel:GetChapterIdsByChapterType(XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge)
    -- 是否是兼容模式
    local isCompatibleModel = #storyChapterIds == 1 and #challengeChapterIds == 1
    if isCompatibleModel then
        XDataCenter.CharacterTowerManager.OpenChapterUi(storyChapterIds[1], false)
    else
        XLuaUiManager.Open("UiCharacterTowerMain", id, {
            [XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story] = storyChapterIds,
            [XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge] = challengeChapterIds
        })
    end
end

function XExFubenCharacterTowerManager:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.CharacterTower
end

function XExFubenCharacterTowerManager:ExGetChapterViewModels()
    local characterList = self:GetCharacterList()
    if XTool.IsTableEmpty(characterList) then
        return {}
    end
    
    self.ChapterViewModelDic = {}
    for _, config in pairs(characterList) do
        local inOpenTime, _ = XDataCenter.CharacterTowerManager.CheckInOpenTime(config.ExtralData.OpenTimeId)
        if inOpenTime then
            local viewModel = XCharacterTowerViewModel.New(config)
            tableInsert(self.ChapterViewModelDic, viewModel)
        end
    end
    
    tableSort(self.ChapterViewModelDic, CharactersSortFunc)
    return self.ChapterViewModelDic
end

-- 获取角色列表
function XExFubenCharacterTowerManager:GetCharacterList()
    local CharacterList = {}
    -- 获取配置总的角色列表
    local characterTowerCfg = XFubenCharacterTowerConfigs.GetAllCharacterTowerCfg()

    for _, config in pairs(characterTowerCfg or {}) do
        tableInsert(CharacterList, {
            Id = config.Id,
            ExtralName = nil,
            Name = config.CharacterName,
            Icon = config.Img,
            ExtralData = {
                OpenTimeId = config.OpenTimeId,
                Priority = config.Priority,
                ChapterIds = config.ChapterIds,
            },
        })
    end
    return CharacterList
end

return XExFubenCharacterTowerManager