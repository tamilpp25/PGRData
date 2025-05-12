---@class XUiPanelPcgGameCharacter : XUiNode
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
---@field GridCharacterDic table<number, XUiGridPcgCharacter>
local XUiPanelPcgGameCharacter = XClass(XUiNode, "XUiPanelPcgGameCharacter")

function XUiPanelPcgGameCharacter:OnStart()
    self.IsEnterUi = true
    self.IsPlayingAnim = false
    self:RegisterUiEvents()
    self:InitCharacters()
end

function XUiPanelPcgGameCharacter:OnEnable()
    
end

function XUiPanelPcgGameCharacter:OnDestroy()
    self:ClearInitTimer()
end

function XUiPanelPcgGameCharacter:RegisterUiEvents()

end

function XUiPanelPcgGameCharacter:Refresh()
    self:RefreshCharacters()
    
    -- 初始化动画
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.Init then
        self:PlayInitAnim()
    end
end

-- 设置角色移动到第一个位置
function XUiPanelPcgGameCharacter:SetCharacterToFirst(characterId)
    for i, grid in pairs(self.GridCharacterDic) do
        if grid:GetCfgId() == characterId then
            self:PlayCharacterChangeFirstAnim(i)
            break
        end
    end
end

---@return XUiGridPcgCharacter
function XUiPanelPcgGameCharacter:GetCharacter(idx)
    return self.GridCharacterDic[idx]
end

function XUiPanelPcgGameCharacter:GetCharacterPosition(idx)
    local grid = self.GridCharacterDic[idx]
    return grid.Transform.position
end

-- 获取Token的层数
function XUiPanelPcgGameCharacter:GetTokenLayer(tokenId)
    local layer = 0
    for _, character in pairs(self.GridCharacterDic) do
        layer = layer + character:GetTokenLayer(tokenId)
    end
    return layer
end

function XUiPanelPcgGameCharacter:InitCharacters()
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local XUiGridPcgCharacter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCharacter")
    self.GridCharacter.gameObject:SetActiveEx(false)
    
    self.GridCharacterDic = {}
    for i = 1, XEnumConst.PCG.MAX_CHAR_CNT do
        local go = CSInstantiate(self.GridCharacter.gameObject, self["Character"..i])
        ---@type XUiGridPcgCharacter
        local grid = XUiGridPcgCharacter.New(go, self)
        self.GridCharacterDic[i] = grid
        grid:SetInputCallBack(function(idx)
            self:OnPointerUp(idx)
        end, function(idx, time)
            self:OnPress(idx, time)
        end)
    end
end

-- 刷新角色
function XUiPanelPcgGameCharacter:RefreshCharacters()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCharacter[]
    local characterDatas = stageData:GetCharacters()
    for i, characterData in ipairs(characterDatas) do
        ---@type XUiGridPcgCharacter
        local grid = self.GridCharacterDic[i]
        local id = characterData:GetId()
        if id ~= 0 then
            local isQte = characterData:GetsIsQte()
            local tokens = characterData:GetTokens()
            grid:Open()
            grid:SetCharacterData(id, i, true)
            grid:SetTokens(tokens)
            grid:SetQTE(isQte)
        else
            grid:Close()
        end
    end
end

-- 播放初始化动画
function XUiPanelPcgGameCharacter:PlayInitAnim()
    for _, grid in pairs(self.GridCharacterDic) do
        grid:Close()
    end
    self:ClearInitTimer()

    -- 刚进入界面
    if self.IsEnterUi then
        self.IsEnterUi = false
        local playableDirector = self.Parent.Transform:Find("Animation/AnimStart"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
        local animStartTime = math.floor(playableDirector.duration * 1000)
        -- 播完开始动画之后进场
        self.InitTimer1 = XScheduleManager.ScheduleOnce(function()
            self:PlayCharacterEnable(1)
        end, animStartTime)
        -- 间隔出场
        self.InitTimer2 = XScheduleManager.ScheduleOnce(function()
            self:PlayCharacterEnable(2)
            self:PlayCharacterEnable(3)
        end, animStartTime + XEnumConst.PCG.ANIM_TIME_INIT_ENABLE_OFFSET)
    else
        self:PlayCharacterEnable(1)
        -- 间隔出场
        self.InitTimer2 = XScheduleManager.ScheduleOnce(function()
            self:PlayCharacterEnable(2)
            self:PlayCharacterEnable(3)
        end, XEnumConst.PCG.ANIM_TIME_INIT_ENABLE_OFFSET)
    end
end

-- 检测成员播放进场动画
function XUiPanelPcgGameCharacter:PlayCharacterEnable(idx)
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCharacter
    local charData = stageData:GetCharacter(idx)
    if charData and charData:GetId() ~= 0 then
        self.GridCharacterDic[idx]:Open()
        self.GridCharacterDic[idx]:PlayEnableAnim()
    end
end

function XUiPanelPcgGameCharacter:ClearInitTimer()
    if self.InitTimer then
        XScheduleManager.UnSchedule(self.InitTimer)
        self.InitTimer = nil
    end
    if self.InitTimer2 then
        XScheduleManager.UnSchedule(self.InitTimer2)
        self.InitTimer2 = nil
    end
end

function XUiPanelPcgGameCharacter:OnPointerUp(idx)
    -- 当前打开弹窗详情，不可操作
    if self.Parent:IsShowPanelPopupDetail() then
        self.Parent:ClosePanelPopupDetail()
        return
    end
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState(true) then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 动画播放中，不可操作
    if self.IsPlayingAnim then return end
    -- 当前出战，不需要切换位置
    if idx == 1 then return end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end
    
    -- 增加点击CD，防止鼠标左右键同时按下
    local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
    if self.LastPointerUpTime and (nowTime - self.LastPointerUpTime) < 0.2 then
        return
    end
    self.LastPointerUpTime = nowTime

    self:OnCharacterClick(idx)
end

function XUiPanelPcgGameCharacter:OnPress(idx, time)
    -- 长按超过0.2秒才响应操作
    if time < 0.2 then return end
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState() then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 当前打开弹窗详情，不可操作
    if self.Parent:IsShowPanelPopupDetail() then return end
    -- 动画播放中，不可操作
    if self.IsPlayingAnim then return end

    -- 打开详情
    self.Parent:ShowPanelPopupDetail(XEnumConst.PCG.POPUP_DETAIL_TYPE.CHARACTER, idx)
end

-- 点击角色
function XUiPanelPcgGameCharacter:OnCharacterClick(idx)
    -- 没有QTE、行动点不足，无法切人
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    local characterData = stageData:GetCharacter(idx)
    local isQte = characterData:GetsIsQte()
    local commander = stageData:GetCommander()
    local actionPoint = commander:GetActionPoint()
    if not isQte and actionPoint < 1 then
        local tips = self._Control:GetClientConfig("ActionPointNoEnoughTips")
        XUiManager.TipError(tips)
        return
    end

    if isQte then
        local qteCv = self._Control:GetCharacterQteCv(characterData:GetId())
        if XTool.IsNumberValid(qteCv) then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, qteCv)
        end
    end

    -- 请求切人
    XMVCA.XPcg:PcgChangeCharacterRequest(idx, function()
        self.Parent:PlayCacheEffectSettles(true, nil, true)
    end)
end

-- 播放角色切换到第一个位置的动画
function XUiPanelPcgGameCharacter:PlayCharacterChangeFirstAnim(index)
    local attackIndex = XEnumConst.PCG.ATTACK_CHAR_INDEX
    if index == nil or index == attackIndex then return end
    
    local grid = self.GridCharacterDic[index]
    local attackGrid =  self.GridCharacterDic[attackIndex]
    
    -- 修改预制体挂点和引用下标
    self.GridCharacterDic[attackIndex] = grid
    grid:ChangeIdx(attackIndex, self["Character"..attackIndex])
    grid:SetQTE(false)

    self.GridCharacterDic[index] = attackGrid
    attackGrid:ChangeIdx(index, self["Character"..index], function()
        self.IsPlayingAnim = false
    end)

    -- 切换音效
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.PCG.CUE_ID_CHARACTER_SWITCH)
end

return XUiPanelPcgGameCharacter
