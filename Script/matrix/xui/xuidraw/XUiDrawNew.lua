local XUiDrawNew = XLuaUiManager.Register(XLuaUi,"UiDrawNew")
local MAX_DRAW_COUNT = 10
local COMPlETE_CUE_ID = CS.XGame.ClientConfig:GetInt("DrawCompleteCueId")
local DRAW_MUSIC_VOLUME_PERCENT = CS.XGame.ClientConfig:GetInt("DrawMusicVolumePercent")
function XUiDrawNew:OnStart(drawInfo,rewardList,background)
    self.DrawInfo = drawInfo
    self.RewardList = rewardList
    self.Background = background
    self:InitSceneObject()
    self:RegisterButton()
    self:RefreshItem()
    self.OriginMusicVolume = XLuaAudioManager.GetAisacVolumeSecondByType(XLuaAudioManager.SoundType.Music)   
end

function XUiDrawNew:OnEnable()
    XLuaAudioManager.SetAisacVolumeSecondByType(self.OriginMusicVolume * (DRAW_MUSIC_VOLUME_PERCENT / 100), XLuaAudioManager.SoundType.Music)
end

function XUiDrawNew:OnDisable()
    XLuaAudioManager.SetAisacVolumeSecondByType(self.OriginMusicVolume, XLuaAudioManager.SoundType.Music)
end

function XUiDrawNew:RegisterButton()
    self.BtnSkip.CallBack = function()
        self.IsSkip = true
        XLuaUiManager.Remove("UiDrawNew")
        local state = #self.RewardList == 1 and 1 or 2 -- 单抽的时候点击跳转停留在展示界面
        XLuaUiManager.Open("UiDrawShowNew", self.DrawInfo, self.RewardList, function()
        end, state)
    end
end

function XUiDrawNew:InitSceneObject()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Playables.PlayableDirector
    self.DrawEnableAnimationSingle = root:FindTransform("DrawEnable2"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    ---@type UnityEngine.Playables.PlayableDirector
    self.DrawEnableAnimationMulti = root:FindTransform("DrawEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.SliderTips = root:FindTransform("SlideTips")
    local isComplete = false --避免快速点击CompleteAction执行了两次导致Timeline不播放的问题
    ---@type XTimelineSlider
    self.TimelineSlider = root:FindTransform("Slider"):GetComponent(typeof(CS.XTimelineSlider))
    self.TimelineSlider.CompleteAction = function(slider)
        if COMPlETE_CUE_ID and COMPlETE_CUE_ID ~= 0 then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, COMPlETE_CUE_ID)
        end
        if not isComplete then
            isComplete = true
            if #self.RewardList > 1 then
                self.DrawEnableAnimationMulti.gameObject:PlayTimelineAnimation(function()
                    self:OnDrawEnd()
                end)
            else
                self.DrawEnableAnimationSingle.gameObject:PlayTimelineAnimation(function()
                    self:OnDrawEnd()
                end)
            end
        end
    end
    self.TimelineSlider.PointerUpAction = function()
        if self.SliderTips then
            self.SliderTips.gameObject:SetActiveEx(true)
        end
    end
    self.TimelineSlider.PointerDownAction = function()
        if self.SliderTips then
            self.SliderTips.gameObject:SetActiveEx(false)
        end
    end
    self.ItemParent = {}
    for i = 1, MAX_DRAW_COUNT do
        local obj = self.UiModelGo.transform:FindTransform("item" .. i)
        if obj then
            table.insert(self.ItemParent,obj)
        end
    end
    self.JiGuangRoot = self.UiModelGo.transform:FindTransform("Jiguang")
end

function XUiDrawNew:OnDrawEnd()
    if self.IsSkip then
        return
    end
    XLuaUiManager.Remove("UiDrawNew")
    XLuaUiManager.Open("UiDrawShowNew",self.DrawInfo,self.RewardList,function()
        XLuaUiManager.Open("UiDrawResult",self.DrawInfo,self.RewardList,function()

        end,self.Background)
    end,nil)
end

function XUiDrawNew:RefreshItem()
    local maxQuality = -1
    for i = 1,#self.RewardList do
        local item = self.RewardList[i]
        ---@type UnityEngine.Transform
        local parent = self.ItemParent[i]
        local quality = self:GetQuality(i)
        local effectPath = CS.XGame.ClientConfig:GetString("DrawRingQualityEffect"..quality)
        if maxQuality < quality then
            maxQuality = quality
        end
        parent:LoadPrefab(effectPath)
    end
    if maxQuality >= 0 and self.JiGuangRoot then
        local effectPath = CS.XGame.ClientConfig:GetString("DrawQualityEffect"..maxQuality)
        self.JiGuangRoot:LoadPrefab(effectPath)
    end
end

function XUiDrawNew:GetQuality(showIndex)
    local reward = self.RewardList[showIndex]
    local id = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
    if reward.ConvertFrom > 0 then
        id = reward.ConvertFrom
    end
    local quality
    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
    local Type = XTypeManager.GetTypeById(id)
    if Type == XArrangeConfigs.Types.Wafer then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Weapon then
        quality = templateIdData.Star
    elseif Type == XArrangeConfigs.Types.Character then
        quality = XMVCA.XCharacter:GetCharMinQuality(id)
    else
        quality = XTypeManager.GetQualityById(id)
    end
    local showTable = XDataCenter.DrawManager.GetDrawShow(Type)
    
    return showTable.DrawEffectGroupId[quality]
end

return XUiDrawNew