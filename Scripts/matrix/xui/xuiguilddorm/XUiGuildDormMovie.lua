local XUiGuildDormMovie = XLuaUiManager.Register(XLuaUi, "UiGuildMovie")

function XUiGuildDormMovie:OnAwake()
    self.NeedCacheRepeatIds = {}
    self.CurrentTalkId = nil
    self.CurrentTalkConfig = nil
    self.Npc = nil
    self:RegisterUiEvents()
    self.BtnSkipDialog.gameObject:SetActiveEx(false)
end

function XUiGuildDormMovie:OnStart(talkId, npc)
    self.Npc = npc
    self:UpdateTalkId(talkId)
    XEventManager.AddEventListener('GuildDormNpcInteractEndTalk',self.OnEndTalkEvent,self)
end

function XUiGuildDormMovie:OnDestroy()
    XEventManager.RemoveEventListener('GuildDormNpcInteractEndTalk',self.OnEndTalkEvent,self)
end

function XUiGuildDormMovie:UpdateTalkId(talkId)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormNpcTalk, talkId)
    -- 如果有需要直接重复播放的id
    if config.RepeatId > 0 then
        table.insert(self.NeedCacheRepeatIds, config.Id)
        if XSaveTool.GetData(self:GetEndTalkSaveKey(talkId)) then
            talkId = config.RepeatId
            self:UpdateTalkId(talkId)
            return 
        end
    end
    self.CurrentTalkId = talkId
    self.CurrentTalkConfig = config
    -- 更新当前聊天的npc名称
    self.TxtName.text = self.Npc:GetName()
    -- 更新当前聊天的内容
    self.TxtWords.text = config.Content
    -- 更新当前npc播放的行为树
    if not string.IsNilOrEmpty(config.BehaviorId) then
        self.Npc:PlayBehavior(config.BehaviorId)
    end
    -- 刷新选项
    local optionCount = #config.Options
    self.PanelSelect.gameObject:SetActiveEx(false)
    XUiHelper.RefreshCustomizedList(self.TabBtnSelectGroup.transform, self.BtnSelect, optionCount, function(i, go)
        local button = go:GetComponent("XUiButton")
        button:SetNameByGroup(0, config.Options[i])
        XUiHelper.RegisterClickEvent(self, button, function()
            self:OnBtnOptionClicked(i)
        end)
    end)
    -- 间隔n秒更新选项配置
    if config.OptionShowTime > 0 then
        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.PanelSelect) then
                return
            end
            self.PanelSelect.gameObject:SetActiveEx(true)
        end, config.OptionShowTime)
    else
        self.PanelSelect.gameObject:SetActiveEx(false)
    end

    self.BtnSkipDialog.gameObject:SetActiveEx(false)
    if config.EmptySkipId > 0 or (#config.Options <= 0 and config.RepeatId <= 0) then
        self.BtnSkipDialog.gameObject:SetActiveEx(true)
    end
end

function XUiGuildDormMovie:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSkipDialog, self.OnBtnSkipDialogClicked)
end

function XUiGuildDormMovie:GetEndTalkSaveKey(id)
    return "XUiGuildDormMovie_" .. XPlayer.Id .. "_EDNTALK" .. id
end

function XUiGuildDormMovie:OnBtnSkipDialogClicked()
    self:CacheEndTalkSaveKeys()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnSelect
    dict["role_level"] = XPlayer.GetLevel()
    dict["skip_id"] = self.CurrentTalkConfig.EmptySkipId
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    -- 在没有选项的时候，直接关闭
    if #self.CurrentTalkConfig.Options <= 0 then
        if self.CurrentTalkConfig.EmptySkipId <= 0 then
            local npcDormData=XDataCenter.GuildDormManager.GetNpcDataFromDormData(self.Npc.NpcRefreshConfig.Id)
            --如果是动态NPC，需要发送结束对话的请求
            if npcDormData and npcDormData.State~=XGuildDormConfig.NpcState.Static then--not static
                XDataCenter.GuildDormManager.RequestInteractWithDynamicNpc(0,function(complete)
                    if complete then
                        npcDormData.lastState=nil
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_TALK_END)
                        self:Close()
                    end
                end)
            else
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_TALK_END)
                self:Close()
            end
        else
            self:UpdateTalkId(self.CurrentTalkConfig.EmptySkipId)
        end
    end
end

-- 缓存需要重复播放的对话id
function XUiGuildDormMovie:CacheEndTalkSaveKeys()
    for _, id in ipairs(self.NeedCacheRepeatIds) do
        XSaveTool.SaveData(self:GetEndTalkSaveKey(id), true)
    end
end

function XUiGuildDormMovie:OnBtnOptionClicked(index)
    local skipId = self.CurrentTalkConfig.SkipIds[index]
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnSelect
    dict["role_level"] = XPlayer.GetLevel()
    dict["skip_id"] = skipId
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    self:UpdateTalkId(skipId)
    self:CacheEndTalkSaveKeys()
end

--封装结束对话事件供外界直接调用
function XUiGuildDormMovie:OnEndTalkEvent()
    if not self.CurrentTalkConfig or XTool.IsTableEmpty(self.CurrentTalkConfig.SkipIds) then return end
    self:OnBtnOptionClicked(3)--配置3默认结束（再见）
    self:CacheEndTalkSaveKeys()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnSelect
    dict["role_level"] = XPlayer.GetLevel()
    dict["skip_id"] = self.CurrentTalkConfig.EmptySkipId
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_TALK_END)
    self:Close()
end

return XUiGuildDormMovie