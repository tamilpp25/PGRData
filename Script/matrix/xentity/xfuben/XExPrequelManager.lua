local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
-- 间章旧闻
local XExPrequelManager = XClass(XExFubenBaseManager, "XExPrequelManager")

function XExPrequelManager:ExOpenChapterUi(viewModel)
    -- if not viewModel:GetConfig().ExtralData.CoverVal.Priority or viewModel:GetConfig().ExtralData.CoverVal.Priority <= 0 then -- 章节没配置开放字段 由Priority控制
    --     XUiManager.TipMsg(CS.XTextManager.GetText("PrequelChapterNotOpen"))
    -- end

    if viewModel:GetIsLocked() then
        XUiManager.TipMsg(XDataCenter.PrequelManager.GetChapterUnlockDescription(viewModel:GetConfig().Id))
        return
    end
    XLuaUiManager.Open("UiPrequelMain", viewModel:GetConfig().ExtralData.PequelChapterCfg)

    -- XLuaUiManager.Open("UiPrequel", viewModel:GetConfig().ExtralData)
end

function XExPrequelManager:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.Prequel
end

function XExPrequelManager:GetCharacterListIdByChapterViewModels()
    local result ={}
    for i, chapterViewModel in ipairs(self:ExGetChapterViewModels()) do
        local characterId = chapterViewModel:GetConfig().CharacterId
        result[i] = {Id = characterId}
        if not self.CharacterIdModelDic then
            self.CharacterIdModelDic = {}
        end
        self.CharacterIdModelDic[characterId] = chapterViewModel
    end
    return result
end

function XExPrequelManager:SortModelViewByCharacterList(characterList)
    local result = {}
    for i, v in ipairs(characterList) do
        table.insert(result, self.CharacterIdModelDic[v.Id])
    end
    return result
end

function XExPrequelManager:ExGetChapterViewModels()
    local result = {}
    local chapterList = XDataCenter.PrequelManager.GetChapterList()
    for _, chapterInfo in ipairs(chapterList) do
        -- local showChapterInfo = XPrequelConfigs.GetPrequelChapterById(cover.Id)
        -- if cover.CoverVal.Priority and cover.CoverVal.Priority > 0 then -- Priority为空则不显示间章
        -- end
        table.insert(result, CreateAnonClassInstance({
            GetCurrentAndMaxProgress = function(proxy)
                return XDataCenter.PrequelManager.GetChapterProgress(proxy.Config.Id)
            end,
            GetProgressTips = function(proxy)
                local finishedNum, totalNum = XDataCenter.PrequelManager.GetChapterProgress(proxy.Config.Id)
                return CS.XTextManager.GetText("PrequelCompletion", finishedNum, totalNum)
            end,
            CheckHasTimeLimitTag = function(proxy)
                return proxy.Config.ExtralData.IsActivity
            end,
            GetLockTip = function(proxy)
                return XDataCenter.PrequelManager.GetChapterUnlockDescription(proxy.Config.Id)
            end,
            GetIsLocked = function(proxy)
                return XDataCenter.PrequelManager.GetChapterLockStatus(proxy.Config.Id)
            end,
            GetMinCharacterName = function(proxy)
                return XCharacterConfigs.GetCharacterTradeName(chapterInfo.PequelChapterCfg.CharacterId)
            end
        }, XChapterViewModel
        , {
            Id = chapterInfo.ChapterId,
            ExtralName = nil,
            Name = chapterInfo.PequelChapterCfg.ChapterName,
            Icon = chapterInfo.PequelChapterCfg.Bg,
            ExtralData = chapterInfo,
            CharacterId = chapterInfo.PequelChapterCfg.CharacterId
        }))
    end
    return result
end

function XExPrequelManager:ExGetCurrentChapterIndex()
    return 1
end

return XExPrequelManager