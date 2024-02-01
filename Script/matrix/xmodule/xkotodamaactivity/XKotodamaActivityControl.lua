---@class XKotodamaActivityControl : XControl
---@field private _Model XKotodamaActivityModel
local XKotodamaActivityControl = XClass(XControl, "XKotodamaActivityControl")
function XKotodamaActivityControl:OnInit()
    --初始化内部变量
    self._Model:InitTmpCurWordList()
end

function XKotodamaActivityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XKotodamaActivityControl:RemoveAgencyEvent()

end

function XKotodamaActivityControl:OnRelease()
    
end

function XKotodamaActivityControl:IsJumpStage(stageId1,stageId2)
    local cfg1=self:GetKotodamaStageCfgById(stageId1)
    local cfg2=self:GetKotodamaStageCfgById(stageId2)

    if cfg1 and cfg2 then
        return math.abs(cfg1.Order-cfg2.Order)>1
    end
end

--region 配置表数据读取

--获取活动时间
function XKotodamaActivityControl:GetActivityTimeId()
    return self._Model:GetActivityTimeId()
end

--获取对应关卡的数据
function XKotodamaActivityControl:GetKotodamaStageCfgById(stageId)
    return self._Model:GetKotodamaStageCfgById(stageId)
end

function XKotodamaActivityControl:GetFirstKotodamaStageCfg()
    local allcfg=self._Model:GetKotodamaStage()
    local sequence={}
    for i, v in pairs(allcfg) do
        sequence[v.Order]=v
    end
    for i, v in ipairs(sequence) do
        return v
    end
end

function XKotodamaActivityControl:GetSentenceCfgById(sentenceId)
    return self._Model:GetKotodamaSentence()[sentenceId]
end

function XKotodamaActivityControl:GetSentencePatternCfgById(sentencePatternId)
    return self._Model:GetKotodamaSentencePattern()[sentencePatternId]
end

function XKotodamaActivityControl:GetCollectableSentenceCount()
    return self._Model:GetCollectableSentenceCount()
end

function XKotodamaActivityControl:GetSentenceGroupConfig(sentenceId)
    return self._Model:GetSentenceGroupConfig(sentenceId)
end

function XKotodamaActivityControl:GetShowItems(activityId)
    local cfg=self._Model:GetKotodamaActivity()[activityId]
    if cfg then
        return cfg.ShowItem 
    end
end

function XKotodamaActivityControl:GetWordGroupConfigByGroupId(groupIds)
    local id=table.concat(groupIds)
    --先看看缓存有没有
    local curWordList=self._Model:GetTmpCurWordList()
    if not XTool.IsTableEmpty(curWordList) then
        return curWordList
    end
    
    local cache=self._Model:GetTmpWordGroupCache()
    if not XTool.IsTableEmpty(cache) and not XTool.IsTableEmpty(cache[id]) then
        self._Model:SetTmpCurWordList(cache[id])
        return cache[id]
    end
    --初始化并写入缓存
    if cache==nil then
        cache={}
    end
    
    local result={}
    if not XTool.IsTableEmpty(groupIds) then
        for i, v in pairs(groupIds) do
            local words=self._Model:GetWordGroupConfig(v)
            for i2, word in pairs(words) do
                table.insert(result,word)
            end
        end
    end
    --排序
    table.sort(result,function(a,b)
        return a.Id<b.Id
    end)

    cache[id]=result
    self._Model:SetTmpCurWordList(result)
    self._Model:SetTmpWordGroupCache(cache)
    
    return result
end

function XKotodamaActivityControl:GetWordBlockCfgById(id)
    return self._Model:GetKotodamaWordBlock()[id]
end

function XKotodamaActivityControl:GetWordCfgByWordId(wordId)
    return self._Model:GetKotodamaWord()[wordId]
end

function XKotodamaActivityControl:GetPatternTargetByPatternId(patternId)
    local cfg=self._Model:GetKotodamaSentencePattern()[patternId]
    if cfg then
        return cfg.Target
    end
end

function XKotodamaActivityControl:GetCollectableSentenceCountByPatternId(patternId)
    return self._Model:GetCollectableSentenceCountByPatternId(patternId)
end

function XKotodamaActivityControl:GetSentenceIdByPatternIdAndWords(patternId,wordIds)
    local sentenceGroup=self._Model:GetSentenceGroupConfig(patternId)
    wordIds=wordIds or {}
    for i, sentenceCfg in pairs(sentenceGroup) do
        --如果配置的词数和填词数不一样则必然不匹配
        if #wordIds ~= #sentenceCfg.Words then
            
        else
            local mismatching=false
            for i, v in ipairs(sentenceCfg.Words) do
                if wordIds[i]~=sentenceCfg.Words[i] then
                    mismatching=true
                    break
                end
            end
            if not mismatching then
                return sentenceCfg.Id
            end
        end
    end
end

function XKotodamaActivityControl:GetCurStageSentenceExpandContent()
    local data=self._Model:GetCurStageData()
    local contentList={}
    if not XTool.IsTableEmpty(data.SpellSentences) then
        for index, sentenceData in pairs(data.SpellSentences) do
            local sentenceId=self:GetSentenceIdByPatternIdAndWords(sentenceData.PatternId,sentenceData.SelectWords)
            local sentenceCfg=self._Model:GetKotodamaSentence()[sentenceId]
            if sentenceCfg then
                table.insert(contentList,sentenceCfg.ExtraContent)
            end
        end
    end
    return table.concat(contentList)
end


--endregion

--region 活动数据条件读取
function XKotodamaActivityControl:GetAllLatestPassSentenceIds()
    if not self._Model:IsActivityDataExisit() then
        XLog.Error('不存在当前言灵活动的数据')
        return nil
    end
    local data={}
    local passStages = self._Model:GetPassStagesData()
    
    if not XTool.IsTableEmpty(passStages) then
        for i, v in pairs(passStages) do
            if not XTool.IsTableEmpty(v.CurSentences) then
                table.insert(data,v)
            end
        end
    end
    
    table.sort(data,function(a, b) 
        local aCfg=self:GetKotodamaStageCfgById(a.StageId)
        local bCfg=self:GetKotodamaStageCfgById(b.StageId)
        return aCfg.Order<bCfg.Order
    end)
    return data
end

function XKotodamaActivityControl:GetUnLockSentenceCountByStageId(stageId)
    return self._Model:GetKotodamaUnLockSentenceCountById(stageId)
end

function XKotodamaActivityControl:GetCollectUnLockSentenceCountById(stageId)
    return self._Model:GetKotodamaCollectUnLockSentenceCountById(stageId)
end

function XKotodamaActivityControl:GetCurStageId()
    local data=self._Model:GetCurStageData()
    return data and data.StageId or 0
end

function XKotodamaActivityControl:GetCurStageData()
    return self._Model:GetCurStageData()
end

function XKotodamaActivityControl:CheckSpellIsUsingInCurStage(wordId)
    local data=self._Model:GetCurStageData()
    if data then
        if not XTool.IsTableEmpty(data.SpellSentences) then
            for i, sentendata in pairs(data.SpellSentences) do
                if not XTool.IsTableEmpty(sentendata.SelectWords) then
                    for i2, _wordId in pairs(sentendata.SelectWords) do
                        if wordId==_wordId then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function XKotodamaActivityControl:GetSpellData(patternId,wordIndex)
    local data=self._Model:GetCurStageData()
    if data and data.SpellSentences then
        local patternData=data.SpellSentences[patternId]
        if patternData and patternData.SelectWords then
            return patternData.SelectWords[wordIndex]
        end
    end
end

function XKotodamaActivityControl:GetPassStageSpell(stageId)
    local passData=self._Model:GetPassStageDataById(stageId)
    if passData and not XTool.IsTableEmpty(passData.SelectSentences) then
        local spelldata={}
        for sentenceIndex, sentenceId in ipairs(passData.SelectSentences) do
            local sentenceCfg=self._Model:GetKotodamaSentence()[sentenceId]
            if sentenceCfg then
                spelldata[sentenceIndex]={
                    PatternId=sentenceCfg.PatternId,
                    SelectWords = XTool.Clone(sentenceCfg.Words)
                }
            end
        end
        return spelldata
    end
end

function XKotodamaActivityControl:GetDefaultWordByPatternIdAndWordIndex(patternId,wordIndex)
    --尝试查找默认词
    local patternCfg = self._Model:GetKotodamaSentencePatternCfgById(patternId)
    if patternCfg.DefaultWords[wordIndex] then
         return patternCfg.DefaultWords[wordIndex]
    end
end
--endregion

--region 活动数据本地写入
function XKotodamaActivityControl:SetWordSpell(patternIndex,patternId,wordIndex,wordId)
    local data=self._Model:GetCurStageData()
    if data then
        if not data.SpellSentences then
            data.SpellSentences={}
        end
        if not data.SpellSentences[patternIndex] then
            data.SpellSentences[patternIndex]={}
        end
        local patternData=data.SpellSentences[patternIndex]
        if patternData then
            patternData.PatternId=patternId
            if not patternData.SelectWords then
                patternData.SelectWords={}
            end
            --设置前需要对缓存进行处理
            if XTool.IsNumberValid(patternData.SelectWords[wordIndex]) and XTool.IsNumberValid(wordId) then
                local oldValue=patternData.SelectWords[wordIndex]
                self:SwarpWordPos(oldValue,wordId)
            end
            patternData.SelectWords[wordIndex]=wordId
        end
    end
end

function XKotodamaActivityControl:SetAndCheckWordSpell(patternIndex,patternId,wordIndex,wordId,cb)
    self:SetWordSpell(patternIndex,patternId,wordIndex,wordId)
    --填词后检测一次错误
    self:CheckPatternSpellErrorLocal()
    --如果填词填满了就判断整个句式的有效性
    local complete,hasEmpty,emptyPatternIds = self:CheckCurStageSpellComplete()
    if complete then
        local valid = self:CheckCurStageSpellValid()
        self._Model:SetTmpBtnStartIsValid(valid)
        if cb then
            cb()
        end
    else
        --如果整个关卡的填词没填满，则看看是否有错误的
        local success = not self:CheckHasBlockError()
        self._Model:SetTmpBtnStartIsValid(success)
        if cb then
            cb()
        end
    end
end

--此接口用于切换关卡时设置当前关本地数据
function XKotodamaActivityControl:KotodamaCurStageDataRewriteLocal(cb,stageId,sentenceSpell)
    --覆写数据
    local curStageData = self._Model:GetCurStageData()
    curStageData.StageId = stageId
    curStageData.SpellSentences = sentenceSpell
    --清空上一关的词缓存
    self._Model:InitTmpCurWordList()
    self._Model:SetTmpBtnStartIsValid(false)
    self:CheckPatternSpellErrorLocal()
    --需要请求到服务端记录当前选中关卡
    XMVCA.XKotodamaActivity:KotodamaSpellSentenceRequest(function(result)
        --提交数据成功后，需要清空可能存在的重置标记
        self._Model:ClearResetLocalMark()
        if result.Code~=XCode.Success then
            XUiManager.TipCode(result.Code)
        end
        if cb then
            cb(result.Code==XCode.Success)
        end
    end,curStageData.StageId,curStageData.SpellSentences)
end
--endregion

--region 协议请求

--此接口用于拼词正确后进入冒险时提交结果
function XKotodamaActivityControl:KotodamaSpellSentenceDataSubmit(cb)
    local curStageData=self._Model:GetCurStageData()

    XMVCA.XKotodamaActivity:KotodamaSpellSentenceRequest(function(result)
        --提交数据成功后，需要清空可能存在的重置标记
        self._Model:ClearResetLocalMark()
        if cb then
            cb(result.Code==XCode.Success)
        end
    end,curStageData.StageId,curStageData.SpellSentences)
end

--endregion

function XKotodamaActivityControl:IsBtnStartValid()
    local isValid=self._Model:GetTmpBtnStartIsValid() or false
    return isValid
end

function XKotodamaActivityControl:SwarpWordPos(wordId1,wordId2)
    local index1,index2
    local curCache = self._Model:GetTmpCurWordList()
    if not XTool.IsTableEmpty(curCache) then
        for i, v in ipairs(curCache) do
            if v.Id==wordId1 then
                index1=i
            elseif v.Id==wordId2 then
                index2=i   
            end
        end
        if XTool.IsNumberValid(index1) and XTool.IsNumberValid(index2) then
            local temp = curCache[index1]
            curCache[index1] = curCache[index2]
            curCache[index2] = temp
        end
    end
end

--region 本地拼词检测

--判断句式中单词空格是否填满
function XKotodamaActivityControl:CheckCurStageSpellComplete()
    local data=self._Model:GetCurStageData()
    local totalNum=0
    local spellNum=0
    local hasEmptyBlock=false
    local EmptyBlockPatternId={}
    --获取该关卡所有句式空格之和
    local stageCfg=self:GetKotodamaStageCfgById(data.StageId)
    for i, v in pairs(stageCfg.SentencePatterns) do
        local patternCfg=self:GetSentencePatternCfgById(v)
        totalNum=totalNum+patternCfg.BlockNum
        if patternCfg.BlockNum<=0 then
            hasEmptyBlock=true
            EmptyBlockPatternId[i]=v
        end
    end
    --获取该关卡已填词之和
    if data and data.SpellSentences then
        for i, v in pairs(data.SpellSentences) do
            spellNum=spellNum+XTool.GetTableCount(v.SelectWords)
        end
        return spellNum>=totalNum,hasEmptyBlock,EmptyBlockPatternId
    end
    return false,hasEmptyBlock,EmptyBlockPatternId
end

--词拼满，并且拼的数据能在配置表中一一对应即为有效
function XKotodamaActivityControl:CheckCurStageSpellValid()
    local complete,hasEmpty,emptyPatternIds = self:CheckCurStageSpellComplete()
    if complete then
        --拼完了的话判断有没有错
        if XTool.IsTableEmpty(self._Model:GetTmpBlockErrorCache()) then
            self:CheckPatternSpellErrorLocal()
        end
        local hasError=self:CheckHasBlockError()
        self._Model:SetTmpBtnStartIsValid(not hasError)
        return not hasError
    end
    self._Model:SetTmpBtnStartIsValid(false)
    return false
end

--检查当前关卡每个句式的拼词是否正确，并记录每个词的正确情况
function XKotodamaActivityControl:CheckPatternSpellErrorLocal()
    local data = self._Model:GetCurStageData()
    local errorData = self._Model:GetTmpBlockErrorCache()
    if errorData==nil then
        errorData = {}
    end
    --初始化记录
    for i, v in pairs(errorData) do
        errorData[i] = nil
    end
    --遍历每个句式的填词数据
    if not XTool.IsTableEmpty(data.SpellSentences) then
        for i, SpellData in pairs(data.SpellSentences) do
            if not XTool.IsTableEmpty(SpellData.SelectWords) then
                --检查拼词
                local sentenceGroup = self._Model:GetSentenceGroupConfig(SpellData.PatternId)
                for index, sentence in pairs(sentenceGroup) do
                    if XTool.GetTableCount(sentence.Words) == XTool.GetTableCount(SpellData.SelectWords) then
                        --对每个词进行一一匹配
                        local sentenceSpellSuccess = true
                        for index, words in pairs(sentence.Words) do
                            local error = words~=SpellData.SelectWords[index]

                            sentenceSpellSuccess = sentenceSpellSuccess and not error
                            --已经对这个词判断过且可以符合了，则无需再往下判断
                            if error==true and errorData[100000+i*100+index]==false then
                                break
                            end
                            
                            --记录结果
                            errorData[100000+i*100+index] = error
                        end
                        --如果其中一个句子匹配上，则无需再匹配其他句子
                        if sentenceSpellSuccess then
                            break
                        end
                    end
                end
            end
        end
    end
    self._Model:SetTmpBlockErrorCache(errorData)
end

function XKotodamaActivityControl:GetBlockErrorState(patternIndex,wordIndex)
    local errorData = self._Model:GetTmpBlockErrorCache()
    if XTool.IsTableEmpty(errorData) then
        return false
    end
    return errorData[100000+patternIndex*100+wordIndex]
end

function XKotodamaActivityControl:CheckHasBlockError()
    local errorData = self._Model:GetTmpBlockErrorCache()
    if XTool.IsTableEmpty(errorData) then
        return false
    end
    for i, v in pairs(errorData) do
        if v==true then
            return true
        end
    end
    return false
end

function XKotodamaActivityControl:TryToCheckBlockErrorWhileNoData()
    --如果此时数据是空的，则保底检测一次
    if XTool.IsTableEmpty(self._Model:GetTmpBlockErrorCache()) then
        self:CheckPatternSpellErrorLocal()
    end
end
--endregion

--region 本地重置选词相关

function XKotodamaActivityControl:ResetWordSelectionLocal()
    --获取当前关数据，把选词全设置为nil
    local curStageData = self:GetCurStageData()
    curStageData.SpellSentences = nil
    --刷新状态数据
    self._Model:SetTmpBtnStartIsValid(false)
    self._Model:InitTmpCurWordList()
    self._Model:ResetTmpBlockErrorCache()
    --标记当前关已重置
    self._Model:MarkStageHasResetLocal(curStageData.StageId)
end
--endregion

return XKotodamaActivityControl