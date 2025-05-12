--- 关卡详情基类
---@class XUiPanelStoryDetailBase: XUiNode
local XUiPanelStoryDetailBase = XClass(XUiNode, 'XUiPanelStoryDetailBase')

function XUiPanelStoryDetailBase:OnStart()
    self:InitCb()
end

--- 注册事件回调
function XUiPanelStoryDetailBase:InitCb()
    self.BtnMask.CallBack = handler(self, self.Close)
    self.BtnEnterStory.CallBack = handler(self, self.OnEnterClickEvent)
end

function XUiPanelStoryDetailBase:Refresh(cfg)
    ---@type XTableCharacterStory
    self.Cfg = cfg
    
    self._IsSimpleStory = not string.IsNilOrEmpty(self.Cfg.StoryId)
    self._IsStage = XTool.IsNumberValid(self.Cfg.StageId)
    
    self.IsUnlock = false
    self.CanUnlock = false

    if not self._IsSimpleStory and not self._IsStage then
        XLog.Error("好感度剧情没有关卡配置，Id:"..tostring(self.Cfg.Id))
    else
        local characterId = self.Parent.CurrentCharacterId
        
        if self._IsSimpleStory then
            self.IsUnlock = self._Control:IsStoryUnlock(characterId, self.Cfg.Id)
            self.CanUnlock = self._Control:IsStorySatisfyUnlock(characterId, self.Cfg.Id)
        elseif self._IsStage then
            self.IsUnlock = XMVCA.XFuben:CheckStageIsUnlock(self.Cfg.StageId)
        end
    end
    
    self:RefreshTagsShow()
end

--- 刷新标签
function XUiPanelStoryDetailBase:RefreshTagsShow()
    if not self.GridTag then
        return
    end
    -- 刷新标签
    XUiHelper.RefreshCustomizedList(self.PanelTag.transform, self.GridTag, self.Cfg.Tips and #self.Cfg.Tips or 0, function(index, go)
        local tipsCfg = self._Control:GetStoryTipsCfg(self.Cfg.Tips[index])
        local imgBg = go:GetComponentInChildren(typeof(CS.UnityEngine.UI.Image))
        local txtTag = go:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))

        txtTag.text = tipsCfg.Name

        imgBg.color = XUiHelper.Hexcolor2Color(string.gsub(tipsCfg.BgColor, '#', ''))
        txtTag.color = XUiHelper.Hexcolor2Color(string.gsub(tipsCfg.TxtColor, '#', ''))
    end)
end

--- 进入关卡的点击回调
function XUiPanelStoryDetailBase:OnEnterClickEvent()
    -- 需要先设置性别
    if not XPlayer.IsSetGender() then
        XPlayer.TipsSetGender("SetGenderTips")
        return
    end

    if self.CanUnlock or self.IsUnlock then
        if self._IsSimpleStory then
            XDataCenter.MovieManager.PlayMovie(self.Cfg.StoryId, nil)
        elseif self._IsStage then
            ---@type XTableStage
            local stageCfg = XMVCA.XFuben:GetStageCfg(self.Cfg.StageId)

            if stageCfg then
                local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.Cfg.StageId)

                if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT then
                    XMVCA.XFuben:EnterFightByStageId(self.Cfg.StageId)
                else
                    if XMVCA.XFuben:CheckStageIsPass(self.Cfg.StageId) then
                        XDataCenter.MovieManager.PlayMovie(beginStoryId, nil)
                    else
                        XMVCA.XFuben:FinishStoryRequest(self.Cfg.StageId, function()
                            XDataCenter.MovieManager.PlayMovie(beginStoryId, nil)
                        end)
                    end
                end
            end


        end
    else
        XUiManager.TipMsg(self.PlotData.ConditionDescript)
    end
end

return XUiPanelStoryDetailBase