--- 好感剧情界面标题信息
---@class XUiPanelFavorabilityRegional: XUiNode
---@field private _Control XFavorabilityControl
local XUiPanelFavorabilityRegional = XClass(XUiNode, 'XUiPanelFavorabilityRegional')

function XUiPanelFavorabilityRegional:RefreshTitle()
    local curCharacterId = self.Parent.CurrentCharacterId
    
    ---@type XTableStoryLayout
    local layoutCfg = self._Control:GetStoryLayoutCfgById(curCharacterId)

    if layoutCfg then
        if layoutCfg.BgType == XEnumConst.Favorability.StoryLayoutBgType.Default then
            -- 默认背景使用背景通用参数
            ---@type XTableStoryLayoutBgType
            local bgTypeCfg = self._Control:GetStoryLayoutBgTypeCfg(layoutCfg.BgType)

            if bgTypeCfg and not string.IsNilOrEmpty(bgTypeCfg.CommonParams[1]) then
                self.TxtName.text = XUiHelper.FormatText(bgTypeCfg.CommonParams[1], XMVCA.XCharacter:GetCharacterLogName(curCharacterId))
                return
            end
        elseif layoutCfg.BgType == XEnumConst.Favorability.StoryLayoutBgType.Style3_4 then
            -- 3.4版样式使用剧情配置参数
            if not string.IsNilOrEmpty(layoutCfg.BgCustomParams[2]) then
                self.TxtName.text = XUiHelper.FormatText(layoutCfg.BgCustomParams[2], XMVCA.XCharacter:GetCharacterLogName(curCharacterId))
                return
            end
        end
    end

    -- 保底设置
    self.TxtName.text = XMVCA.XCharacter:GetCharacterLogName(curCharacterId)
end

function XUiPanelFavorabilityRegional:RefreshStoryData()
    local curCharacterId = self.Parent.CurrentCharacterId
    local unlockNum,storyNum=self._Control:GetStoryProgress(curCharacterId)

    local labelFormat = nil
    ---@type XTableStoryLayout
    local layoutCfg = self._Control:GetStoryLayoutCfgById(curCharacterId)
    
    local layoutProgressSuccess = false
    
    if layoutCfg then
        if layoutCfg.BgType == XEnumConst.Favorability.StoryLayoutBgType.Default then
            -- 默认背景使用背景通用参数
            
            ---@type XTableStoryLayoutBgType
            local bgTypeCfg = self._Control:GetStoryLayoutBgTypeCfg(layoutCfg.BgType)

            if bgTypeCfg and not string.IsNilOrEmpty(bgTypeCfg.CommonParams[2]) and not string.IsNilOrEmpty(bgTypeCfg.CommonParams[3])  then
                labelFormat = bgTypeCfg.CommonParams[2]
                self.TxtProgressNum.text = XUiHelper.FormatText(bgTypeCfg.CommonParams[3], unlockNum, storyNum)

                layoutProgressSuccess = true
            end
        elseif layoutCfg.BgType == XEnumConst.Favorability.StoryLayoutBgType.Style3_4 then

            if not string.IsNilOrEmpty(layoutCfg.BgCustomParams[3]) and not string.IsNilOrEmpty(layoutCfg.BgCustomParams[4]) then
                labelFormat = layoutCfg.BgCustomParams[3]
                self.TxtProgressNum.text = XUiHelper.FormatText(layoutCfg.BgCustomParams[4], unlockNum, storyNum)
                layoutProgressSuccess = true
            end
        end
    end

    if not layoutProgressSuccess then
        -- 进度显示保底
        self.TxtProgressNum.text = unlockNum..'/'..storyNum
        XLog.Error('好感度剧情进度显示文本缺少配置，characterId：'..tostring(curCharacterId))
    end

    -- 刷新标签
    if not string.IsNilOrEmpty(labelFormat) then
        if self._Control:CheckCharacterStoryIsStage(curCharacterId) then
            self.TxtProgressLabel.text = XUiHelper.FormatText(labelFormat, XUiHelper.GetText('FavorabilityStoryPassProgressLabel'))
        else
            self.TxtProgressLabel.text = XUiHelper.FormatText(labelFormat, XUiHelper.GetText('FavorabilityStoryUnlockProgressLabel'))
        end
    else
        -- 保底
        if self._Control:CheckCharacterStoryIsStage(curCharacterId) then
            self.TxtProgressLabel.text = XUiHelper.GetText('FavorabilityStoryPassProgressLabel')
        else
            self.TxtProgressLabel.text = XUiHelper.GetText('FavorabilityStoryUnlockProgressLabel')
        end

        XLog.Error('好感度剧情进度标题文本缺少配置，characterId：'..tostring(curCharacterId))
    end
end

return XUiPanelFavorabilityRegional